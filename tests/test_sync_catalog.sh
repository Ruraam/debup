#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

REPO_DIR="${TEST_DIR}/repo"
BIN_DIR="${TEST_DIR}/bin"
mkdir -p "${REPO_DIR}/scripts" "$BIN_DIR"
cp "${ROOT_DIR}/scripts/sync_catalog.sh" "${REPO_DIR}/scripts/sync_catalog.sh"
chmod +x "${REPO_DIR}/scripts/sync_catalog.sh"

cat > "${BIN_DIR}/git" <<'MOCK_GIT'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${MOCK_GIT_FAIL:-0}" == 1 ]]; then
    exit 42
fi
destination="${@: -1}"
mkdir -p "$destination/01-main/packages"
cat > "$destination/01-main/packages/github-app" <<'RECIPE'
get_github_releases "vendor/github-app"
RECIPE
cat > "$destination/01-main/packages/direct-app" <<'RECIPE'
direct_download "https://example.org/releases/direct-app.deb"
RECIPE
cat > "$destination/01-main/packages/ppa-app" <<'RECIPE'
add_apt_repo "vendor/ppa"
direct_download "https://example.org/ppa-app.deb"
RECIPE
cat > "$destination/01-main/packages/dynamic-app" <<'RECIPE'
get_github_releases "$UPSTREAM_REPOSITORY"
RECIPE
MOCK_GIT
chmod +x "${BIN_DIR}/git"

export PATH="${BIN_DIR}:${PATH}"
CATALOG="${REPO_DIR}/curated_db.txt"

# A failed upstream clone must leave the previous catalog untouched.
printf 'preserve|github|owner/repository\ngithub-app|github|vendor/github-app|github-app-deb\n' > "$CATALOG"
if MOCK_GIT_FAIL=1 "${REPO_DIR}/scripts/sync_catalog.sh" >/dev/null 2>&1; then
    printf 'FAIL: expected clone failure\n' >&2
    exit 1
fi
expected_preserved=$'preserve|github|owner/repository\ngithub-app|github|vendor/github-app|github-app-deb'
[[ "$(cat "$CATALOG")" == "$expected_preserved" ]] || {
    printf 'FAIL: existing catalog was modified after clone failure\n' >&2
    exit 1
}

# Successful synchronization must include literal supported entries and preserve explicit mappings.
MOCK_GIT_FAIL=0 "${REPO_DIR}/scripts/sync_catalog.sh" >/dev/null
expected='github-app|github|vendor/github-app|github-app-deb'
actual="$(cat "$CATALOG")"
[[ "$actual" == "$expected" ]] || {
    printf 'FAIL: unexpected generated catalog\nExpected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
    exit 1
}

printf 'PASS: catalog generation, filtering, sorting, mapping preservation, and failure preservation\n'
