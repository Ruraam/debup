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
alpha-app|github|Acme/Alpha|alpha-deb
shared-tool|github|Acme/Shared
alpha-cli|github|Acme/Alpha
direct-alpha|direct|https://example.org/alpha.deb
malformed|github
invalid-repo|github|not a valid repository
uppercase-name|GITHUB|Acme/Uppercase
invalid-package-map|github|Acme/Invalid|INVALID_NAME
extra-field|github|Acme/Extra|valid-name|unexpected
EOF

actual="$(catalog_search_repositories "$CATALOG" "ALPHA")"
expected='Acme/Alpha|alpha-app|alpha-deb'
[[ "$actual" == "$expected" ]] || {
    printf 'FAIL: case-insensitive matching or repository deduplication failed\nExpected: %s\nActual: %s\n' "$expected" "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "$CATALOG" "shared")"
[[ "$actual" == 'Acme/Shared|shared-tool|' ]] || {
    printf 'FAIL: repository-name matching failed: %s\n' "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "$CATALOG" "shared-tool")"
[[ "$actual" == 'Acme/Shared|shared-tool|' ]] || {
    printf 'FAIL: legacy three-field entries must keep an empty expected package identity: %s\n' "$actual" >&2
    exit 1
}

actual="$(catalog_search_repositories "$CATALOG" "invalid-package-map")"
[[ -z "$actual" ]] || {
    printf 'FAIL: invalid Debian package identity mapping was accepted: %s\\n' "$actual" >&2
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

actual="$(parse_search_selection '1 3-4,2 1' 5)"
expected=$'1\n3\n4\n2'
[[ "$actual" == "$expected" ]] || {
    printf 'FAIL: selection order, range expansion, or deduplication failed\nExpected:\n%s\nActual:\n%s\n' "$expected" "$actual" >&2
    exit 1
}

actual="$(parse_search_selection '0002,08 10' 10)"
expected=$'2\n8\n10'
[[ "$actual" == "$expected" ]] || {
    printf 'FAIL: leading-zero decimal indices were not parsed safely\n' >&2
    exit 1
}

for invalid in '1,11' '1,invalid' '0' '3-2' '1-999999999999999999999999999' ',1' '1,' '1,,2' '1 - 2'; do
    if parse_search_selection "$invalid" 10 >/dev/null 2>&1; then
        printf 'FAIL: invalid selection was accepted: %s\n' "$invalid" >&2
        exit 1
    fi
done

if parse_search_selection '   ' 10 >/dev/null 2>&1; then
    printf 'FAIL: empty selection parser input was accepted\n' >&2
    exit 1
fi

printf 'PASS: curated lookup and strict ordered multi-selection parsing
'
