#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\\n\\t'

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=../debup-pkg/usr/local/share/debup/api_cache.sh
source "${ROOT_DIR}/debup-pkg/usr/local/share/debup/api_cache.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/tmp"
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
if [[ -n "${CURL_MARKER:-}" ]]; then
    printf 'called\\n' >> "$CURL_MARKER"
fi
printf '%s' "${CURL_BODY:-{\"tag_name\":\"v1.0\"}}" > "$output"
exit "${CURL_EXIT:-0}"
CURL
chmod +x "$TEST_DIR/bin/curl"
PATH="$TEST_DIR/bin:$PATH"
export PATH

CACHE_API_DIR="$TEST_DIR/cache"
TEMP_DIR="$TEST_DIR/tmp"
AUTH_HEADER=()
DRY_RUN=false
endpoint="repos/example/project/releases/latest"
cache_key="$(printf '%s' "$endpoint" | sha256sum)"
cache_key="${cache_key%% *}"
cache_file="$CACHE_API_DIR/$cache_key.json"
CURL_MARKER="$TEST_DIR/curl.calls"
export CURL_MARKER

CURL_BODY='{"tag_name":"v1.0"}'
export CURL_BODY
first="$(fetch_github_api "$endpoint" 30)"
[[ "$first" == '{"tag_name":"v1.0"}' ]]
[[ -s "$cache_file" ]]
[[ "$(stat -c '%a' "$CACHE_API_DIR")" == 700 ]]
[[ "$(stat -c '%a' "$cache_file")" == 600 ]]

rm -f "$CURL_MARKER"
CURL_EXIT=22
export CURL_EXIT
fresh="$(fetch_github_api "$endpoint" 30)"
[[ "$fresh" == '{"tag_name":"v1.0"}' ]]
[[ ! -e "$CURL_MARKER" ]]

touch -d '2 hours ago' "$cache_file"
if stale="$(fetch_github_api "$endpoint" 30 2>/dev/null)"; then
    printf 'FAIL: stale cache was returned after an API failure: %s\\n' "$stale" >&2
    exit 1
fi
[[ -z "$stale" ]]
[[ ! -s "$CURL_MARKER" || "$(wc -l < "$CURL_MARKER")" -eq 1 ]]
shopt -s nullglob
staging=("$CACHE_API_DIR"/.api.*)
[[ "${#staging[@]}" -eq 0 ]]

CURL_EXIT=0
CURL_BODY='[]'
export CURL_EXIT CURL_BODY
if fetch_github_api "$endpoint" 30 >/dev/null 2>&1; then
    printf 'FAIL: non-object JSON API response was accepted\\n' >&2
    exit 1
fi
[[ "$(cat "$cache_file")" == '{"tag_name":"v1.0"}' ]]

DRY_RUN=true
CACHE_API_DIR="$TEST_DIR/dry-cache"
CURL_BODY='{"tag_name":"v2.0"}'
export CURL_BODY
dry_result="$(fetch_github_api "$endpoint" 30)"
[[ "$dry_result" == '{"tag_name":"v2.0"}' ]]
[[ ! -e "$CACHE_API_DIR" ]]
tmp_files=("$TEMP_DIR"/*)
[[ "${#tmp_files[@]}" -eq 0 ]]

if fetch_github_api 'repos/example/../../etc/passwd' 30 >/dev/null 2>&1; then
    printf 'FAIL: invalid API endpoint was accepted\\n' >&2
    exit 1
fi

printf 'PASS: GitHub API cache freshness, failure handling, atomic writes, permissions, and dry-run behavior\\n'
