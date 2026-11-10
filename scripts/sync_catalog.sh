#!/usr/bin/env bash
#
# Synchronize the curated package catalog from deb-get recipes.
#

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
readonly CATALOG_FILE="${REPO_ROOT}/curated_db.txt"
readonly SOURCE_REPO="https://github.com/wimpysworld/deb-get.git"

WORK_DIR=""
TMP_CATALOG=""

cleanup() {
    [[ -z "${WORK_DIR}" ]] || rm -rf -- "$WORK_DIR"
    [[ -z "${TMP_CATALOG}" ]] || rm -f -- "$TMP_CATALOG"
}
trap cleanup EXIT

die() {
    printf '[!] Error: %s\n' "$*" >&2
    exit 1
}

for command in git awk sort mktemp; do
    command -v "$command" >/dev/null 2>&1 || die "Required command not found: $command"
done

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/debup-catalog.XXXXXX")"
TMP_CATALOG="$(mktemp "${REPO_ROOT}/.curated_db.txt.XXXXXX")"

printf '[*] Cloning deb-get recipes...\n'
git clone --depth 1 --filter=blob:none "$SOURCE_REPO" "$WORK_DIR/deb-get" ||
    die "Failed to clone the deb-get repository."

readonly PACKAGE_DIR="${WORK_DIR}/deb-get/01-main/packages"
[[ -d "$PACKAGE_DIR" ]] || die "The expected deb-get package directory is missing."

printf '[*] Parsing package recipes...\n'

shopt -s nullglob
recipe_files=("${PACKAGE_DIR}"/*)
shopt -u nullglob
(("${#recipe_files[@]}" > 0)) || die "No package recipes were found."

for recipe in "${recipe_files[@]}"; do
    [[ -f "$recipe" ]] || continue
    package_name="$(basename -- "$recipe")"

    # Only accept literal, quoted upstream values. Dynamic shell expressions
    # are intentionally ignored instead of being evaluated.
    github_repo="$(awk '
        /^[[:space:]]*get_github_releases[[:space:]]+/ {
            if (match($0, /get_github_releases[[:space:]]+"[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+"/)) {
                value = substr($0, RSTART, RLENGTH)
                sub(/^[^"]*"/, "", value)
                sub(/"$/, "", value)
                print value
                exit
            }
        }
    ' "$recipe")"

    if [[ -n "$github_repo" && "$github_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
        printf '%s|github|%s\n' "$package_name" "$github_repo" >> "$TMP_CATALOG"
        continue
    fi

    # Recipes requiring external repositories/PPAs are not portable catalog
    # entries and must not be emitted as direct-download packages.
    if grep -Eq '^[[:space:]]*(add_ppa|add_apt_repo)([[:space:]]|$)' "$recipe"; then
        continue
    fi

    direct_url="$(awk '
        /^[[:space:]]*direct_download[[:space:]]+/ {
            if (match($0, /direct_download[[:space:]]+"https?:\/\/[^"]+"/)) {
                value = substr($0, RSTART, RLENGTH)
                sub(/^[^"]*"/, "", value)
                sub(/"$/, "", value)
                print value
                exit
            }
        }
    ' "$recipe")"

    if [[ "$direct_url" =~ ^https?://[^[:space:]]+$ ]]; then
        printf '%s|direct|%s\n' "$package_name" "$direct_url" >> "$TMP_CATALOG"
    fi
done

if [[ -s "$TMP_CATALOG" ]]; then
    LC_ALL=C sort -u -o "$TMP_CATALOG" "$TMP_CATALOG" ||
        die "Failed to sort the generated catalog."
else
    die "Catalog generation produced no entries; preserving the existing catalog."
fi

# Validate every generated record before replacing the tracked catalog.
awk -F'|' '
    NF != 3 || $1 == "" || ($2 != "github" && $2 != "direct") || $3 == "" {
        exit 1
    }
    $2 == "github" && $3 !~ /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/ {
        exit 1
    }
    $2 == "direct" && $3 !~ /^https?:\/\// {
        exit 1
    }
' "$TMP_CATALOG" || die "Generated catalog failed structural validation."

total="$(wc -l < "$TMP_CATALOG")"
chmod 0644 "$TMP_CATALOG" || die "Failed to set catalog permissions."
mv -f -- "$TMP_CATALOG" "$CATALOG_FILE" || die "Failed to atomically replace the catalog."
TMP_CATALOG=""

printf '[+] Catalog synchronized: %s packages written to %s\n' "$total" "$CATALOG_FILE"
printf '\n--- Sample entries ---\n'
head -n 25 "$CATALOG_FILE"
