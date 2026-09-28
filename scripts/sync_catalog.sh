#!/usr/bin/env bash

WORK_DIR="/tmp/deb-get"
CATALOG_FILE="curated_db.txt"

echo "[*] Clonage de deb-get..."
rm -rf "$WORK_DIR" "$CATALOG_FILE"
git clone --depth 1 https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

> "$CATALOG_FILE"

echo "[*] Analyse des recettes..."
for f in "$WORK_DIR"/01-main/packages/*; do
[ -f "$f" ] || continue
pkg=$(basename "$f")
gh_repo=$(grep -Eo '([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)' "$f" | grep -v 'wimpysworld/deb-get'| head -n 1)

if grep -q"say_github" "$f" || grep -q "github.com" "$f"; then
repo=$(grep -E 'say_github|GITHUB_REPO' "$f" | head -n 1 | sed -E 's/.*say_github[[:space:]]+"?([^" ]+)"?.*/\1/' |sed -E 's/.*GITHUB_REPO="?([^" ]+)"?.*/\1/')
if [ -n "$repo" ] && [[ "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
echo "${pkg}|github|${repo}" >> "$CATALOG_FILE" || true
continue
fi
fi

if grep -qE 'say_direct|DIRECT_URL' "$f"; then
if ! grep -qE 'say_ppa|say_repo|APT_PPA|APT_REPO' "$f"; then
url=$(grep -E 'say_direct|DIRECT_URL' "$f"| head -n 1 | sed -E 's/.*say_direct[[:space:]]+"?([^" ]+)"?.*/\1/' | sed -E 's/.*DIRECT_URL="?([^" ]+)"?.*/\1/')
if [ -n "$url" ] && [[ "$url" =~ ^https?:// ]]; then
echo "${pkg}|direct|${url}" >> "$CATALOG_FILE" || true
continue
fi
fi
fi
done

sort -u -o "$CATALOG_FILE" "$CATALOG_FILE"
rm -rf "$WORK_DIR"

TOTAL=$(wc -l < "$CATALOG_FILE")
echo "[+] SUCCÈS ! $TOTAL paquets indexés dans $CATALOG_FILE"
echo "--- Exemples extraits ---"
head -n 15 "$CATALOG_FILE"
