#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

ETC_DIR="${TEST_DIR}/etc/debup"
SCRIPT_DIR="${TEST_DIR}/scripts"
mkdir -p "$ETC_DIR" "$SCRIPT_DIR"

sed "s|/etc/debup|$ETC_DIR|g" "$ROOT_DIR/debup-pkg/DEBIAN/postinst" > "$SCRIPT_DIR/postinst"
sed "s|/etc/debup|$ETC_DIR|g" "$ROOT_DIR/debup-pkg/DEBIAN/postrm" > "$SCRIPT_DIR/postrm"
chmod 0755 "$SCRIPT_DIR/postinst" "$SCRIPT_DIR/postrm"

# Existing legacy registration and unrelated entries must be preserved/migrated.
cat > "$ETC_DIR/sources.list" <<'SOURCES'
other-app|https://github.com/vendor/other-app
debup|Ruraam/debup
SOURCES

"$SCRIPT_DIR/postinst" configure
expected=$'other-app|https://github.com/vendor/other-app\ndebup|Ruraam/debup'
[[ "$(cat "$ETC_DIR/sources.list")" == "$expected" ]] || {
    printf 'FAIL: postinst did not migrate the source list correctly.\n' >&2
    exit 1
}
[[ "$(stat -c '%a' "$ETC_DIR/sources.list")" == "644" ]] || {
    printf 'FAIL: sources.list permissions are not 0644.\n' >&2
    exit 1
}

# Reconfiguration must be idempotent.
"$SCRIPT_DIR/postinst" configure
[[ "$(grep -Fc 'debup|https://github.com/Ruraam/debup' "$ETC_DIR/sources.list")" -eq 1 ]] || {
    printf 'FAIL: postinst created duplicate source entries.\n' >&2
    exit 1
}

# Purge removes package-owned configuration but leaves unrelated user files.
printf 'keep this file\n' > "$ETC_DIR/custom.conf"
"$SCRIPT_DIR/postrm" purge
[[ ! -e "$ETC_DIR/sources.list" ]] || {
    printf 'FAIL: postrm did not remove sources.list on purge.\n' >&2
    exit 1
}
[[ -f "$ETC_DIR/custom.conf" ]] || {
    printf 'FAIL: postrm deleted unrelated user configuration.\n' >&2
    exit 1
}

printf 'PASS: maintainer script migration, idempotency, permissions, and purge preservation\n'
