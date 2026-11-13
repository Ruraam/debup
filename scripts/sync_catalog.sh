#!/usr/bin/env bash
#
# Synchronize the curated GitHub release package catalog from deb-get recipes.
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

# Preserve explicit Debian Package: identity mappings across catalog refreshes.
declare -A expected_package_mappings=()
if [[ -r "$CATALOG_FILE" ]]; then
    while IFS='|' read -r existing_package existing_provider existing_repo existing_expected extra || [[ -n "${existing_package:-}" ]]; do
        [[ -z "${extra:-}" &&
           "$existing_provider" == "github" &&
           "$existing_package" =~ ^[a-z0-9][a-z0-9+.-]*$ &&
           "$existing_repo" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*$ &&
           "$existing_expected" =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || continue
        expected_package_mappings["$existing_package"]="${existing_repo}|${existing_expected}"
    done < "$CATALOG_FILE"
fi

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
        mapped_identity="${expected_package_mappings[$package_name]:-}"
        if [[ "$mapped_identity" == "${github_repo}|"* ]]; then
            expected_deb_package="${mapped_identity#*|}"
            printf '%s|github|%s|%s\n' "$package_name" "$github_repo" "$expected_deb_package" >> "$TMP_CATALOG"
        else
            printf '%s|github|%s\n' "$package_name" "$github_repo" >> "$TMP_CATALOG"
        fi
        continue
    fi

    # Only GitHub release repositories are supported by debup's curated search.
    # Direct-download recipes are intentionally excluded until they have a
    # dedicated validation, integrity, and update-tracking implementation.

done

if [[ -s "$TMP_CATALOG" ]]; then
    LC_ALL=C sort -u -o "$TMP_CATALOG" "$TMP_CATALOG" ||
        die "Failed to sort the generated catalog."
else
    die "Catalog generation produced no entries; preserving the existing catalog."
fi

# Validate every generated record before replacing the tracked catalog.
awk -F'|' '
    (NF != 3 && NF != 4) || $1 !~ /^[a-z0-9][a-z0-9+.-]*$/ || $2 != "github" || $3 !~ /^[A-Za-z0-9][A-Za-z0-9_.-]*\/[A-Za-z0-9][A-Za-z0-9_.-]*$/ || (NF == 4 && $4 !~ /^[a-z0-9][a-z0-9+.-]*$/) {
        exit 1
    }
    seen[$1] && seen[$1] != $3 {
        exit 1
    }
    {
        seen[$1] = $3
    }
' "$TMP_CATALOG" || die "Generated catalog failed validation or contains ambiguous package names."

total="$(wc -l < "$TMP_CATALOG")"
chmod 0644 "$TMP_CATALOG" || die "Failed to set catalog permissions."
mv -f -- "$TMP_CATALOG" "$CATALOG_FILE" || die "Failed to atomically replace the catalog."
TMP_CATALOG=""

printf '[+] Catalog synchronized: %s packages written to %s\n' "$total" "$CATALOG_FILE"
printf '\n--- Sample entries ---\n'
head -n 25 "$CATALOG_FILE"
