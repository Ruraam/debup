#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../debup-pkg/usr/local/share/debup/search.sh
source "${ROOT_DIR}/debup-pkg/usr/local/share/debup/search.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT
CATALOG="${TEST_DIR}/curated_db.txt"

cat > "$CATALOG" <<'EOF'
alpha-app|github|Acme/Alpha
shared-tool|github|Acme/Shared
alpha-cli|github|Acme/Alpha
direct-alpha|direct|https://example.org/alpha.deb
malformed|github
invalid-repo|github|not a valid repository
uppercase-name|GITHUB|Acme/Uppercase
EOF

actual="$(catalog_search_repositories "$CATALOG" "ALPHA")"
expected='Acme/Alpha|alpha-app'
[[ "$actual" == "$expected" ]] || {
    printf 'FAIL: case-insensitive matching or repository deduplication failed\nExpected: %s\nActual: %s\n' "$expected" "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "$CATALOG" "shared")"
[[ "$actual" == 'Acme/Shared|shared-tool' ]] || {
    printf 'FAIL: repository-name matching failed: %s\n' "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "$CATALOG" '[')"
[[ -z "$actual" ]] || {
    printf 'FAIL: literal query matching treated punctuation as a pattern: %s\n' "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "${TEST_DIR}/missing.txt" "alpha")"
[[ -z "$actual" ]] || {
    printf 'FAIL: missing catalog should return no candidates\n' >&2
    exit 1
}

printf 'PASS: curated catalog matching, validation, deduplication, and missing-file handling\n'
