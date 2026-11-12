#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

cmp -s "$ROOT_DIR/debup-pkg/usr/local/bin/debup" "$ROOT_DIR/debup-pkg/usr/local/bin/dbp" || {
    printf 'FAIL: debup and dbp launchers differ.\n' >&2
    exit 1
}

# Load only the production function block, without running the CLI dispatcher
# or touching system configuration. A nested declaration silently disappears
# from the global function table; this catches that regression.
awk '
    /^debup_inspect\(\) \{$/ { capture = 1 }
    /^debup_check_updates\(\) \{$/ { capture = 0 }
    capture { print }
' "$ROOT_DIR/debup-pkg/usr/local/bin/debup" > "$TEST_DIR/functions.sh"

[[ -s "$TEST_DIR/functions.sh" ]] || {
    printf 'FAIL: could not extract the CLI function block.\n' >&2
    exit 1
}

# shellcheck source=/dev/null
source "$TEST_DIR/functions.sh"

for function_name in \
    debup_inspect \
    install_apt_package \
    check_and_update \
    debup_search \
    debup_info; do
    declare -F "$function_name" >/dev/null || {
        printf 'FAIL: %s is not defined at global scope.\n' "$function_name" >&2
        exit 1
    }
done

# Exercise token persistence without touching /etc or requiring root.
mkdir -p "$TEST_DIR/mock-bin" "$TEST_DIR/home"
cat > "$TEST_DIR/mock-bin/id" <<'MOCK_ID'
#!/usr/bin/env bash
if [[ "$*" == "-ru" ]]; then
    printf '1000\n'
else
    exec /usr/bin/id "$@"
fi
MOCK_ID
chmod 0755 "$TEST_DIR/mock-bin/id"
PATH="$TEST_DIR/mock-bin:$PATH"
export PATH
export HOME="$TEST_DIR/home"
export XDG_CONFIG_HOME="$TEST_DIR/home/config"
export CONF_DIR="$TEST_DIR/etc/debup"
export ELEVATE=""
export DRY_RUN=false

awk '
    /^set_github_token\(\) \{$/ { capture = 1 }
    capture { print }
    capture && /^\}$/ { exit }
' "$ROOT_DIR/debup-pkg/usr/local/bin/debup" > "$TEST_DIR/token-function.sh"
[[ -s "$TEST_DIR/token-function.sh" ]]
# shellcheck source=/dev/null
source "$TEST_DIR/token-function.sh"

set_github_token 'ghp_A1B2C3D4'
token_dir="$XDG_CONFIG_HOME/debup"
[[ "$(stat -c '%a' "$token_dir")" == "700" ]]
[[ "$(stat -c '%a' "$token_dir/token")" == "600" ]]
[[ "$(cat "$token_dir/token")" == 'ghp_A1B2C3D4' ]]

if set_github_token 'invalid token' >/dev/null 2>&1; then
    printf 'FAIL: token containing whitespace was accepted.\n' >&2
    exit 1
fi
[[ "$(cat "$token_dir/token")" == 'ghp_A1B2C3D4' ]] || {
    printf 'FAIL: invalid token input overwrote the stored credential.\n' >&2
    exit 1
}

DRY_RUN=true
set_github_token 'ghp_DRYRUN123' >/dev/null
[[ "$(cat "$token_dir/token")" == 'ghp_A1B2C3D4' ]] || {
    printf 'FAIL: dry-run modified the stored token.\n' >&2
    exit 1
}

printf 'PASS: CLI function scope, token permissions, atomic persistence, and dry-run safety.\n'
