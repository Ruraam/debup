#!/usr/bin/env bash
#
# GitHub API cache with atomic writes and fail-closed network handling.
#

fetch_github_api() {
    local endpoint="${1:-}"
    local ttl="${2:-30}"
    local cache_key cache_file cache_root tmp_file cache_enabled=false
    local -a curl_args=()

    [[ -n "$endpoint" ]] || {
        printf 'GitHub API endpoint is empty.\n' >&2
        return 1
    }
    [[ "$ttl" =~ ^[0-9]+$ ]] || {
        printf 'GitHub API cache TTL must be a non-negative integer.\n' >&2
        return 1
    }

    endpoint="${endpoint#https://api.github.com/}"
    endpoint="${endpoint#/}"
    [[ "$endpoint" =~ ^[A-Za-z0-9._~/?=&%+-]+$ && "$endpoint" != *"/../"* ]] || {
        printf 'GitHub API endpoint contains unsupported characters.\n' >&2
        return 1
    }

    cache_root="${CACHE_API_DIR:-}"
    if [[ "${DRY_RUN:-false}" != "true" && -n "$cache_root" ]]; then
        if install -d -m 700 -- "$cache_root" && chmod 700 -- "$cache_root"; then
            cache_enabled=true
            cache_key=$(printf '%s' "$endpoint" | sha256sum) || return 1
            cache_key="${cache_key%% *}"
            cache_file="${cache_root}/${cache_key}.json"
        fi
    fi

    if [[ "$cache_enabled" == true && -s "$cache_file" ]] &&
       find "$cache_file" -mmin "-$ttl" -print -quit 2>/dev/null | grep -q .; then
        if jq -e 'type == "object"' "$cache_file" >/dev/null 2>&1; then
            cat -- "$cache_file"
            return $?
        fi
    fi

    if [[ "$cache_enabled" == true ]]; then
        tmp_file=$(mktemp "${cache_root}/.api.XXXXXX") || {
            printf 'Unable to create a temporary GitHub API cache file.\n' >&2
            return 1
        }
    else
        tmp_file=$(mktemp "${TEMP_DIR:-/tmp}/debup-api.XXXXXX") || return 1
    fi

    curl_args=(-fsSL --connect-timeout 10 --max-time 25 --retry 2 --retry-delay 1)
    if ! curl "${curl_args[@]}" "${AUTH_HEADER[@]}" \
        -H "Accept: application/vnd.github+json" \
        -H "User-Agent: debup-tool" \
        -o "$tmp_file" "https://api.github.com/${endpoint}"; then
        rm -f -- "$tmp_file"
        printf 'GitHub API request failed; stale cached data will not be used.\n' >&2
        return 1
    fi

    if ! jq -e 'type == "object"' "$tmp_file" >/dev/null 2>&1; then
        rm -f -- "$tmp_file"
        printf 'GitHub API returned an invalid JSON object.\n' >&2
        return 1
    fi

    if [[ "$cache_enabled" == true ]]; then
        if ! mv -f -- "$tmp_file" "$cache_file"; then
            rm -f -- "$tmp_file"
            printf 'Unable to atomically update the GitHub API cache.\n' >&2
            return 1
        fi
        chmod 600 -- "$cache_file" || {
            printf 'Unable to secure the GitHub API cache file permissions.\n' >&2
            return 1
        }
        cat -- "$cache_file"
    else
        cat -- "$tmp_file"
        local output_status=$?
        rm -f -- "$tmp_file"
        return "$output_status"
    fi
}
