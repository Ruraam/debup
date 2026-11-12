#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

mkdir -p "$TEST_DIR/mock-bin" "$TEST_DIR/home" "$TEST_DIR/etc"
export TEST_DIR
export TEST_CONF_DIR="$TEST_DIR/etc/debup"
export HOME="$TEST_DIR/home"
export XDG_CONFIG_HOME="$TEST_DIR/home/config"
export GITHUB_TOKEN=""
export DRY_RUN=false
export PATH="$TEST_DIR/mock-bin:$PATH"

# The CLI requires root for its system configuration setup. Report root only
# for the effective-UID check; preserve normal id behavior for other calls.
cat > "$TEST_DIR/mock-bin/id" <<'MOCK_ID'
#!/usr/bin/env bash
if [[ "$*" == "-ru" ]]; then
    printf '0\n'
else
    exec /usr/bin/id "$@"
fi
MOCK_ID

# Stub external package/network tools. Argument-validation failures must happen
# before any transaction; the log lets the test assert dry-run stays inert.
for command_name in curl jq apt apt-get apt-cache apt-mark dpkg dpkg-deb sha256sum; do
    cat > "$TEST_DIR/mock-bin/$command_name" <<'MOCK_COMMAND'
#!/usr/bin/env bash
if [[ "$(basename "$0")" == "dpkg" && "$1" == "--print-architecture" ]]; then
    printf 'amd64\n'
else
    printf '%s %s\n' "$(basename "$0")" "$*" >> "$TEST_DIR/commands.log"
fi
exit 0
MOCK_COMMAND
    chmod 0755 "$TEST_DIR/mock-bin/$command_name"
done
chmod 0755 "$TEST_DIR/mock-bin/id"

# Copy the real package tree and redirect only the hard-coded system config
# directory into this test's temporary sandbox.
cp -a "$ROOT_DIR/debup-pkg" "$TEST_DIR/debup-pkg"
sed "s|^CONF_DIR=\"/etc/debup\"$|CONF_DIR=\"$TEST_CONF_DIR\"|" \
    "$TEST_DIR/debup-pkg/usr/local/bin/debup" > "$TEST_DIR/debup-pkg/usr/local/bin/debup.test"
mv "$TEST_DIR/debup-pkg/usr/local/bin/debup.test" "$TEST_DIR/debup-pkg/usr/local/bin/debup"
cp "$TEST_DIR/debup-pkg/usr/local/bin/debup" "$TEST_DIR/debup-pkg/usr/local/bin/dbp"
chmod 0755 "$TEST_DIR/debup-pkg/usr/local/bin/debup" "$TEST_DIR/debup-pkg/usr/local/bin/dbp"
DEBUP="$TEST_DIR/debup-pkg/usr/local/bin/debup"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

expect_rejected() {
    local label="$1"
    shift
    local status=0
    if "$DEBUP" "$@" >"$TEST_DIR/stdout" 2>"$TEST_DIR/stderr"; then
        fail "$label was accepted (args: $*)"
    else
        status=$?
    fi
    [[ "$status" -ne 0 ]] || fail "$label returned success"
}

expect_rejected "add with multiple targets" add package-one package-two
expect_rejected "add with unknown option" add --not-a-real-option package-one
expect_rejected "remove with multiple packages" remove package-one package-two
expect_rejected "remove with unknown option" remove --not-a-real-option package-one
expect_rejected "upgrade with unknown option" upgrade --not-a-real-option
expect_rejected "upgrade with positional target" upgrade package-one
expect_rejected "pin without a package" pin
expect_rejected "pin with multiple packages" pin package-one package-two
expect_rejected "unpin without a package" unpin
expect_rejected "unpin with multiple packages" unpin package-one package-two

# Supported confirmation flags remain accepted, and dry-run must not reach
# apt-mark for pin/unpin or apt-get for remove.
: > "$TEST_DIR/commands.log"
"$DEBUP" --dry-run remove --yes package-one >"$TEST_DIR/stdout" 2>"$TEST_DIR/stderr" ||
    fail "remove --dry-run --yes <package> was rejected"
"$DEBUP" --dry-run pin package-one >"$TEST_DIR/stdout" 2>"$TEST_DIR/stderr" ||
    fail "pin --dry-run <package> was rejected"
"$DEBUP" --dry-run unpin package-one >"$TEST_DIR/stdout" 2>"$TEST_DIR/stderr" ||
    fail "unpin --dry-run <package> was rejected"

if [[ -s "$TEST_DIR/commands.log" ]]; then
    fail "dry-run invoked an external package/network command: $(cat "$TEST_DIR/commands.log")"
fi

cmp -s "$TEST_DIR/debup-pkg/usr/local/bin/debup" "$TEST_DIR/debup-pkg/usr/local/bin/dbp" ||
    fail "packaged debup/dbp launchers differ"

printf 'PASS: strict CLI argument rejection, supported flags, dry-run safety, and launcher parity.\n'
