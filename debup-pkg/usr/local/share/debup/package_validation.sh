#!/usr/bin/env bash
#
# Strict validation helpers for downloaded Debian packages.
#

DEB_VALIDATED_PACKAGE=""
DEB_VALIDATED_VERSION=""
DEB_VALIDATED_ARCHITECTURE=""

deb_version_is_not_newer() {
    local candidate_version="$1"
    local installed_version="$2"
    dpkg --compare-versions "$candidate_version" le "$installed_version"
}

deb_version_matches_release_floor() {
    local package_version="$1"
    local release_version="$2"

    if ! dpkg --validate-version "$release_version" >/dev/null 2>&1; then
        return 0
    fi
    dpkg --compare-versions "$package_version" ge "$release_version"
}

apt_plan_has_removals() {
    local plan="$1"
    awk '$1 == "Remv" || $1 == "Purg" { found = 1 } END { exit !found }' <<< "$plan"
}

download_file_atomic() {
    local url="$1"
    local destination="$2"
    local timeout="${3:-300}"
    local show_progress="${4:-false}"
    local staging_file
    local -a curl_args=(-fsSL --proto '=https' --proto-redir '=https' --max-redirs 10 --connect-timeout 10 --max-time "$timeout" --retry 2 --retry-delay 1)

    [[ "$url" =~ ^https://[^[:space:]]+$ && -n "$destination" ]] || {
        printf 'Invalid HTTPS download URL or destination.\n' >&2
        return 1
    }
    [[ "$timeout" =~ ^[0-9]+$ && "$timeout" -gt 0 ]] || {
        printf 'Download timeout must be a positive integer.\n' >&2
        return 1
    }

    staging_file=$(mktemp "${destination}.part.XXXXXX") || {
        printf 'Unable to create a staging file for the download.\n' >&2
        return 1
    }
    if [[ "$show_progress" == true ]]; then
        curl_args+=(--progress-bar)
    fi

    if ! curl "${curl_args[@]}" -o "$staging_file" "$url"; then
        rm -f -- "$staging_file"
        printf 'Download failed; the destination was not replaced.\n' >&2
        return 1
    fi
    if [[ ! -s "$staging_file" ]]; then
        rm -f -- "$staging_file"
        printf 'Download returned an empty file; the destination was not replaced.\n' >&2
        return 1
    fi
    if ! mv -f -- "$staging_file" "$destination"; then
        rm -f -- "$staging_file"
        printf 'Unable to atomically publish the downloaded file.\n' >&2
        return 1
    fi
}

validate_deb_metadata() {
    local deb_file="$1"
    local expected_arch="$2"
    local expected_package="${3:-}"
    local package version architecture

    [[ -f "$deb_file" && -s "$deb_file" ]] || {
        printf 'Downloaded Debian package is missing or empty.\n' >&2
        return 1
    }

    package=$(dpkg-deb -f "$deb_file" Package) || {
        printf 'Unable to read the Debian Package field.\n' >&2
        return 1
    }
    version=$(dpkg-deb -f "$deb_file" Version) || {
        printf 'Unable to read the Debian Version field.\n' >&2
        return 1
    }
    architecture=$(dpkg-deb -f "$deb_file" Architecture) || {
        printf 'Unable to read the Debian Architecture field.\n' >&2
        return 1
    }

    [[ "$package" =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || {
        printf 'Invalid Debian package name in downloaded archive.\n' >&2
        return 1
    }
    [[ -n "$version" && "$version" != *[$'\n\\r']* ]] && dpkg --validate-version "$version" >/dev/null 2>&1 || {
        printf 'Invalid or missing Debian package version.\n' >&2
        return 1
    }
    [[ "$architecture" == "all" || "$architecture" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
        printf 'Invalid Debian architecture in downloaded archive.\n' >&2
        return 1
    }
    [[ "$architecture" == "$expected_arch" || "$architecture" == "all" ]] || {
        printf 'Package architecture (%s) does not match system architecture (%s).\n' "$architecture" "$expected_arch" >&2
        return 1
    }
    if [[ -n "$expected_package" && "$package" != "$expected_package" ]]; then
        printf 'Package name mismatch: expected %s, received %s.\n' "$expected_package" "$package" >&2
        return 1
    fi

    DEB_VALIDATED_PACKAGE="$package"
    DEB_VALIDATED_VERSION="$version"
    DEB_VALIDATED_ARCHITECTURE="$architecture"
}

verify_deb_sha256() {
    local deb_file="$1"
    local manifest="$2"
    local expected_name="$3"
    local expected_hash actual_hash

    [[ -s "$deb_file" && -s "$manifest" && -n "$expected_name" ]] || {
        printf 'Package or checksum manifest is missing or empty.\n' >&2
        return 1
    }

    expected_hash=$(awk -v wanted="$expected_name" '
        function valid_hash(value) {
            return length(value) == 64 && value ~ /^[[:xdigit:]]+$/
        }
        NF == 1 {
            records++
            if (valid_hash($1)) {
                bare_count++
                bare_hash = tolower($1)
            }
            next
        }
        NF >= 2 {
            records++
            hash = $1
            file = $2
            sub(/^\*/, "", file)
            sub(/^\.\//, "", file)
            n = split(file, parts, "/")
            if (parts[n] == wanted) {
                if (valid_hash(hash)) {
                    matches++
                    selected = tolower(hash)
                } else {
                    invalid_matches++
                }
            }
        }
        END {
            if (matches == 1 && invalid_matches == 0) {
                print selected
                exit 0
            }
            if (matches > 1 || invalid_matches > 0) {
                exit 2
            }
            if (records == 1 && bare_count == 1) {
                print bare_hash
                exit 0
            }
            exit 1
        }
    ' "$manifest") || {
        printf 'Checksum manifest has no unique valid SHA-256 entry for %s.\n' "$expected_name" >&2
        return 1
    }

    actual_hash=$(sha256sum -- "$deb_file") || {
        printf 'Unable to calculate the downloaded package SHA-256.\n' >&2
        return 1
    }
    actual_hash="${actual_hash%% *}"
    [[ "$actual_hash" =~ ^[[:xdigit:]]{64}$ ]] || {
        printf 'Local SHA-256 calculation returned an invalid digest.\n' >&2
        return 1
    }

    if [[ "${actual_hash,,}" != "$expected_hash" ]]; then
        printf 'SHA-256 mismatch for %s.\n' "$expected_name" >&2
        return 1
    fi
}
