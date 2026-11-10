#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../debup-pkg/usr/local/share/debup/package_validation.sh
source "${ROOT_DIR}/debup-pkg/usr/local/share/debup/package_validation.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/pkg/DEBIAN" "$TEST_DIR/pkg/usr/share/debup-validation"
cat > "$TEST_DIR/pkg/DEBIAN/control" <<'EOF'
Package: debup-validation-fixture
Version: 1.2.3-1
Architecture: all
Maintainer: Test Fixture <test@example.invalid>
Description: Minimal package used by debup validation tests
EOF
printf 'fixture\n' > "$TEST_DIR/pkg/usr/share/debup-validation/fixture.txt"
dpkg-deb --build "$TEST_DIR/pkg" "$TEST_DIR/valid.deb" >/dev/null

validate_deb_metadata "$TEST_DIR/valid.deb" "$(dpkg --print-architecture)" "debup-validation-fixture"
[[ "$DEB_VALIDATED_PACKAGE" == "debup-validation-fixture" ]]
[[ "$DEB_VALIDATED_VERSION" == "1.2.3-1" ]]
[[ "$DEB_VALIDATED_ARCHITECTURE" == "all" ]]

if validate_deb_metadata "$TEST_DIR/valid.deb" "$(dpkg --print-architecture)" "wrong-package" 2>/dev/null; then
    printf 'FAIL: package-name mismatch was accepted\n' >&2
    exit 1
fi

sed 's/^Architecture: all$/Architecture: amd64/' "$TEST_DIR/pkg/DEBIAN/control" > "$TEST_DIR/pkg/DEBIAN/control.tmp"
mv "$TEST_DIR/pkg/DEBIAN/control.tmp" "$TEST_DIR/pkg/DEBIAN/control"
dpkg-deb --build "$TEST_DIR/pkg" "$TEST_DIR/wrong-architecture.deb" >/dev/null 2>&1
if validate_deb_metadata "$TEST_DIR/wrong-architecture.deb" "definitely-not-this-architecture" 2>/dev/null; then
    printf 'FAIL: architecture mismatch was accepted\n' >&2
    exit 1
fi

printf 'valid package\n' > "$TEST_DIR/manifest.deb"
hash=$(sha256sum "$TEST_DIR/manifest.deb" | awk '{print $1}')
printf '%s  package.deb\n' "$hash" > "$TEST_DIR/SHA256SUMS"
verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/SHA256SUMS" "package.deb"

printf '%s\n' "$hash" > "$TEST_DIR/single.sha256"
verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/single.sha256" "package.deb"

printf '%s  package.deb\n%s  package.deb\n' "$hash" "$hash" > "$TEST_DIR/duplicate.SHA256SUMS"
if verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/duplicate.SHA256SUMS" "package.deb" 2>/dev/null; then
    printf 'FAIL: duplicate checksum entries were accepted\n' >&2
    exit 1
fi

printf '%064d  package.deb\n' 0 > "$TEST_DIR/wrong.SHA256SUMS"
if verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/wrong.SHA256SUMS" "package.deb" 2>/dev/null; then
    printf 'FAIL: checksum mismatch was accepted\n' >&2
    exit 1
fi

printf '%s  another.deb\n' "$hash" > "$TEST_DIR/wrong-name.SHA256SUMS"
if verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/wrong-name.SHA256SUMS" "package.deb" 2>/dev/null; then
    printf 'FAIL: checksum for a different filename was accepted\n' >&2
    exit 1
fi

printf '%s  another.deb\n%s\n' "$hash" "$hash" > "$TEST_DIR/mixed-bare.SHA256SUMS"
if verify_deb_sha256 "$TEST_DIR/manifest.deb" "$TEST_DIR/mixed-bare.SHA256SUMS" "package.deb" 2>/dev/null; then
    printf 'FAIL: bare digest in a multi-entry manifest was accepted\n' >&2
    exit 1
fi

if validate_deb_metadata "$TEST_DIR/not-a-deb" "$(dpkg --print-architecture)" 2>/dev/null; then
    printf 'FAIL: missing archive was accepted\n' >&2
    exit 1
fi

if ! deb_version_matches_release_floor "1.2.3-1" "1.2.3"; then
    printf 'FAIL: Debian revision above release tag was rejected\\n' >&2
    exit 1
fi
if deb_version_matches_release_floor "1.2.2-1" "1.2.3"; then
    printf 'FAIL: package version older than release tag was accepted\\n' >&2
    exit 1
fi
if ! deb_version_is_not_newer "1.2.3-1" "1.2.3-1"; then
    printf 'FAIL: identical installed package version was not detected\\n' >&2
    exit 1
fi
if deb_version_is_not_newer "1.2.4-1" "1.2.3-1"; then
    printf 'FAIL: newer package version was incorrectly marked stale\\n' >&2
    exit 1
fi

if apt_plan_has_removals "Inst safe-package (1.0 Debian:stable)"; then
    printf 'FAIL: safe APT transaction was flagged as removing packages\n' >&2
    exit 1
fi
if ! apt_plan_has_removals $'Inst replacement (2.0 Debian:stable)\nRemv conflicting-package [1.0]'; then
    printf 'FAIL: APT transaction package removal was not detected\n' >&2
    exit 1
fi

mkdir -p "$TEST_DIR/bin"
cat > "$TEST_DIR/bin/curl" <<'CURL'
#!/usr/bin/env bash
set -u
output=""
while (($#)); do
    case "$1" in
        -o) output="$2"; shift 2 ;;
        *) shift ;;
    esac
done
[[ -n "$output" ]] || exit 2
printf '%s' "${CURL_BODY-downloaded-content}" > "$output"
exit "${CURL_EXIT:-0}"
CURL
chmod +x "$TEST_DIR/bin/curl"
PATH="$TEST_DIR/bin:$PATH"
export PATH

printf 'old-content' > "$TEST_DIR/atomic.deb"
CURL_BODY='complete-new-content'
CURL_EXIT=0
export CURL_BODY CURL_EXIT
download_file_atomic "https://example.invalid/package.deb" "$TEST_DIR/atomic.deb" 30 false
[[ "$(cat "$TEST_DIR/atomic.deb")" == 'complete-new-content' ]]

CURL_BODY='partial-content'
CURL_EXIT=22
export CURL_BODY CURL_EXIT
if download_file_atomic "https://example.invalid/package.deb" "$TEST_DIR/atomic.deb" 30 false 2>/dev/null; then
    printf 'FAIL: failed download was reported as successful\n' >&2
    exit 1
fi
[[ "$(cat "$TEST_DIR/atomic.deb")" == 'complete-new-content' ]]
shopt -s nullglob
staging=("$TEST_DIR"/atomic.deb.part.*)
[[ "${#staging[@]}" -eq 0 ]]

CURL_BODY=''
CURL_EXIT=0
export CURL_BODY CURL_EXIT
if download_file_atomic "https://example.invalid/package.deb" "$TEST_DIR/atomic.deb" 30 false 2>/dev/null; then
    printf 'FAIL: empty download was accepted\n' >&2
    exit 1
fi
[[ "$(cat "$TEST_DIR/atomic.deb")" == 'complete-new-content' ]]

if download_file_atomic "http://example.invalid/package.deb" "$TEST_DIR/atomic.deb" 30 false 2>/dev/null; then
    printf 'FAIL: non-HTTPS download URL was accepted\n' >&2
    exit 1
fi

printf 'PASS: package metadata, checksums, atomic downloads, and APT transaction validation\n'
