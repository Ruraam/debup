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

if validate_deb_metadata "$TEST_DIR/valid.deb" "definitely-not-this-architecture" 2>/dev/null; then
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

printf 'PASS: Debian metadata and SHA-256 validation regression tests\n'
