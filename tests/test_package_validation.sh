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
    printf 'FAIL: Debian revision above release tag was rejected\n' >&2
    exit 1
fi
if deb_version_matches_release_floor "1.2.2-1" "1.2.3"; then
    printf 'FAIL: package version older than release tag was accepted\n' >&2
    exit 1
fi
if ! deb_version_is_not_newer "1.2.3-1" "1.2.3-1"; then
    printf 'FAIL: identical installed package version was not detected\n' >&2
    exit 1
fi
if deb_version_is_not_newer "1.2.4-1" "1.2.3-1"; then
    printf 'FAIL: newer package version was incorrectly marked stale\n' >&2
    exit 1
fi

valid_release='{"id":123,"tag_name":"v1.2.3","assets":[{"name":"tool_amd64.deb","browser_download_url":"https://github.com/acme/tool/releases/download/v1.2.3/tool_amd64.deb"}]}'
validate_release_asset_selection "$valid_release" "123" "tool_amd64.deb"
if validate_release_asset_selection "$valid_release" "124" "tool_amd64.deb"; then
    printf 'FAIL: mismatched GitHub release ID was accepted\n' >&2
    exit 1
fi
duplicate_asset='{"id":123,"tag_name":"v1.2.3","assets":[{"name":"tool_amd64.deb","browser_download_url":"https://github.com/acme/tool/releases/download/a/tool_amd64.deb"},{"name":"tool_amd64.deb","browser_download_url":"https://github.com/acme/tool/releases/download/b/tool_amd64.deb"}]}'
if validate_release_asset_selection "$duplicate_asset" "123" "tool_amd64.deb"; then
    printf 'FAIL: duplicate GitHub asset names were accepted\n' >&2
    exit 1
fi
external_asset='{"id":123,"tag_name":"v1.2.3","assets":[{"name":"tool_amd64.deb","browser_download_url":"https://attacker.invalid/tool_amd64.deb"}]}'
if validate_release_asset_selection "$external_asset" "123" "tool_amd64.deb"; then
    printf 'FAIL: non-GitHub browser download URL was accepted\n' >&2
    exit 1
fi
unsafe_tag='{"id":123,"tag_name":"v1.2.3\u001b[31m","assets":[{"name":"tool_amd64.deb","browser_download_url":"https://github.com/acme/tool/releases/download/v1.2.3/tool_amd64.deb"}]}'
if validate_release_asset_selection "$unsafe_tag" "123" "tool_amd64.deb"; then
    printf 'FAIL: terminal-control release tag was accepted\n' >&2
    exit 1
fi

asset_list=$'tool_amd64.deb\ntool_ubuntu_amd64.deb\ntool_debian_amd64.deb'
selected_asset="$(select_compatible_deb_asset "$asset_list" "debian")"
[[ "$selected_asset" == "tool_debian_amd64.deb" ]] || {
    printf 'FAIL: distro-preferred compatible asset was not selected\n' >&2
    exit 1
}
selected_asset="$(select_compatible_deb_asset "$asset_list" "fedora")"
[[ "$selected_asset" == "tool_amd64.deb" ]] || {
    printf 'FAIL: compatible fallback asset was not selected deterministically\n' >&2
    exit 1
}
selected_asset="$(select_compatible_deb_asset $'../escape_amd64.deb\nsafe_amd64.deb' "debian")"
[[ "$selected_asset" == "safe_amd64.deb" ]] || {
    printf 'FAIL: unsafe asset filename was not filtered before selection\n' >&2
    exit 1
}

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

# Installer checksum-asset selection regression tests. Extract the real
# function from installer.sh so the test exercises production logic without
# executing the interactive installer.
resolver_file="$TEST_DIR/find_checksum_url.sh"
awk '
    /^find_checksum_url\(\) \{/ { capture=1 }
    capture { print }
    capture && /^\}$/ { exit }
' "$ROOT_DIR/installer.sh" > "$resolver_file"
[[ -s "$resolver_file" ]]
# shellcheck source=/dev/null
source "$resolver_file"

one_exact='{"assets":[{"name":"debup.deb.sha256","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup.deb.sha256"}]}'
[[ "$(find_checksum_url "$one_exact" "debup.deb")" == "https://github.com/Ruraam/debup/releases/download/v1/debup.deb.sha256" ]]

duplicate_exact='{"assets":[{"name":"debup.deb.sha256","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/a"},{"name":"debup.deb.sha256","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/b"}]}'
if find_checksum_url "$duplicate_exact" "debup.deb" >/dev/null 2>&1; then
    printf 'FAIL: ambiguous exact checksum assets were accepted\n' >&2
    exit 1
fi

one_generic='{"assets":[{"name":"SHA256SUMS","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/SHA256SUMS"},{"name":"other.txt","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/other.txt"}]}'
[[ "$(find_checksum_url "$one_generic" "debup.deb")" == "https://github.com/Ruraam/debup/releases/download/v1/SHA256SUMS" ]]

duplicate_generic='{"assets":[{"name":"SHA256SUMS","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/SHA256SUMS"},{"name":"checksums.txt","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/checksums.txt"}]}'
if find_checksum_url "$duplicate_generic" "debup.deb" >/dev/null 2>&1; then
    printf 'FAIL: ambiguous generic checksum assets were accepted\n' >&2
    exit 1
fi

fallback='{"assets":[{"name":"tool.sha256","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/tool.sha256"}]}'
[[ "$(find_checksum_url "$fallback" "debup.deb")" == "https://github.com/Ruraam/debup/releases/download/v1/tool.sha256" ]]

if find_checksum_url '{"assets":[]}' "debup.deb" >/dev/null 2>&1; then
    printf 'FAIL: missing checksum assets were accepted\n' >&2
    exit 1
fi
if find_checksum_url '{"assets":[{"name":"SHA256SUMS","browser_download_url":"http://github.com/Ruraam/debup/SHA256SUMS"}]}' "debup.deb" >/dev/null 2>&1; then
    printf 'FAIL: non-HTTPS checksum asset URL was accepted\n' >&2
    exit 1
fi
if find_checksum_url '{"invalid":true}' "debup.deb" >/dev/null 2>&1; then
    printf 'FAIL: malformed release metadata was accepted\n' >&2
    exit 1
fi

printf 'PASS: installer checksum asset selection and ambiguity rejection\n'


# Installer release package selection must never fall back to an incompatible .deb.
selector_file="$TEST_DIR/select_release_deb_url.sh"
awk '
    /^select_release_deb_url\(\) \{/ { capture=1 }
    capture { print }
    capture && /^\}$/ { exit }
' "$ROOT_DIR/installer.sh" > "$selector_file"
[[ -s "$selector_file" ]]
# shellcheck source=/dev/null
source "$selector_file"

multiarch_release='{"assets":[{"name":"debup_amd64.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup_amd64.deb"},{"name":"debup_arm64.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup_arm64.deb"},{"name":"debup_all.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup_all.deb"}]}'
[[ "$(select_release_deb_url "$multiarch_release" amd64)" == "https://github.com/Ruraam/debup/releases/download/v1/debup_amd64.deb" ]]
[[ "$(select_release_deb_url "$multiarch_release" arm64)" == "https://github.com/Ruraam/debup/releases/download/v1/debup_arm64.deb" ]]
[[ "$(select_release_deb_url "$multiarch_release" i386)" == "https://github.com/Ruraam/debup/releases/download/v1/debup_all.deb" ]]

armhf_release='{"assets":[{"name":"debup_armv7l.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup_armv7l.deb"}]}'
[[ "$(select_release_deb_url "$armhf_release" armhf)" == "https://github.com/Ruraam/debup/releases/download/v1/debup_armv7l.deb" ]]

wrong_arch_release='{"assets":[{"name":"debup_arm64.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/debup_arm64.deb"}]}'
if select_release_deb_url "$wrong_arch_release" amd64 >/dev/null 2>&1; then
    printf 'FAIL: incompatible architecture fallback was accepted\n' >&2
    exit 1
fi

ambiguous_arch_release='{"assets":[{"name":"debup_amd64.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/a.deb"},{"name":"debup-x86_64.deb","browser_download_url":"https://github.com/Ruraam/debup/releases/download/v1/b.deb"}]}'
if select_release_deb_url "$ambiguous_arch_release" amd64 >/dev/null 2>&1; then
    printf 'FAIL: ambiguous architecture assets were accepted\n' >&2
    exit 1
fi

external_arch_release='{"assets":[{"name":"debup_amd64.deb","browser_download_url":"https://attacker.invalid/debup_amd64.deb"}]}'
if select_release_deb_url "$external_arch_release" amd64 >/dev/null 2>&1; then
    printf 'FAIL: external package download URL was accepted\n' >&2
    exit 1
fi

printf 'PASS: installer architecture-aware release asset selection\n'

printf 'PASS: Debian metadata, checksums, release asset validation, version comparisons, APT transaction and atomic download tests\n'