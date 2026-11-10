#!/usr/bin/env bash
#
# Curated GitHub repository lookup helpers for debup.
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
        $1 !~ /^[A-Za-z0-9][A-Za-z0-9+.-]*$/ {
            next
        }
        $3 !~ /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/ {
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
