#!/usr/bin/env bash
#
# Curated GitHub repository lookup and interactive selection helpers.
#

catalog_search_repositories() {
    local catalog_file="$1"
    local query="$2"

    [[ -n "$query" && -r "$catalog_file" ]] || return 0

    awk -F'|' -v query="$query" '
        BEGIN {
            query = tolower(query)
        }
        NF != 3 || $2 != "github" {
            next
        }
        $1 !~ /^[a-z0-9][a-z0-9+.-]*$/ {
            next
        }
        $3 !~ /^[A-Za-z0-9][A-Za-z0-9_.-]*\/[A-Za-z0-9][A-Za-z0-9_.-]*$/ {
            next
        }
        {
            package_name = tolower($1)
            repository = tolower($3)
            if (index(package_name, query) || index(repository, query)) {
                if (!seen[repository]++) {
                    print $3 "|" $1
                    count++
                    if (count >= 10) {
                        exit
                    }
                }
            }
        }
    ' "$catalog_file"
}

search_selection_index() {
    local number="$1"
    local maximum="$2"

    [[ "$number" =~ ^[0-9]+$ ]] || return 1
    while [[ "${#number}" -gt 1 && "${number:0:1}" == "0" ]]; do
        number="${number:1}"
    done

    if (( ${#number} > ${#maximum} )); then
        return 1
    fi
    if (( ${#number} == ${#maximum} )) && [[ "$number" > "$maximum" ]]; then
        return 1
    fi

    printf '%d\n' "$((10#$number))"
}

parse_search_selection() {
    local input="$1"
    local total_options="$2"
    local token start end selected idx
    local -a tokens=()
    local -a ordered_selection=()
    local -A seen=()
    local IFS=$' \t\n'

    [[ "$total_options" =~ ^[1-9][0-9]*$ ]] || return 2
    [[ -n "${input//[[:space:]]/}" ]] || return 2
    [[ ! "$input" =~ ^[[:space:]]*, && ! "$input" =~ ,[[:space:]]*$ &&
       ! "$input" =~ ,[[:space:]]*, ]] || return 2

    input="${input//,/ }"
    read -r -a tokens <<< "$input"
    (("${#tokens[@]}" > 0)) || return 2

    for token in "${tokens[@]}"; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start=$(search_selection_index "${BASH_REMATCH[1]}" "$total_options") || return 2
            end=$(search_selection_index "${BASH_REMATCH[2]}" "$total_options") || return 2
            (( start >= 1 && end >= start )) || return 2

            for ((idx=start; idx<=end; idx++)); do
                if [[ -z "${seen[$idx]+present}" ]]; then
                    ordered_selection+=("$idx")
                    seen[$idx]=1
                fi
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            selected=$(search_selection_index "$token" "$total_options") || return 2
            (( selected >= 1 )) || return 2
            if [[ -z "${seen[$selected]+present}" ]]; then
                ordered_selection+=("$selected")
                seen[$selected]=1
            fi
        else
            return 2
        fi
    done

    printf '%s\n' "${ordered_selection[@]}"
}
