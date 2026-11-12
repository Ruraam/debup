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

printf 'PASS: CLI functions are independently defined at global scope; debup and dbp are identical.\n'
