#!/usr/bin/env bash

WORK_DIR="/tmp/deb-get-repo"
CATALOG_FILE="curated_db.txt"
TMP_CSV="/tmp/deb-get.csv"

echo "[*] Clonage de deb-get..."
rm -rf "$WORK_DIR" "$CATALOG_FILE" "$TMP_CSV"
git clone --depth 1 https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

echo "[*] Parsing direct des recettes..."
> "$CATALOG_FILE"

for f in "$WORK_DIR"/01-main/packages/*; do
[ -f "$f" ] || continue
pkg=$(basename "$f")

gh_repo=$(grep -E '^[[:space:]]*get_github_releases[[:space:]]+' "$f" | head -n 1 | sed -E 's/.*get_github_releases[[:space:]]+"([^"]+)".*/\1/')

if [ -n "$gh_repo" ] && [[ "$gh_repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
echo "${pkg}|github|${gh_repo}" >> "$CATALOG_FILE"
continue
fi

direct_url=$(grep -E '^[[:space:]]*direct_download[[:space:]]+' "$f" | head -n 1 | sed -E 's/.*direct_download[[:space:]]+"([^"]+)".*/\1/')

if [ -n "$direct_url" ] && [[ "$direct_url" =~ ^https?:// ]]; then
if ! grep -qE 'add_ppa|add_apt_repo' "$f"; then
echo "${pkg}|direct|${direct_url}" >> "$CATALOG_FILE"
fi
fi
done

sort -u -o "$CATALOG_FILE" "$CATALOG_FILE"
rm -rf "$WORK_DIR" "$TMP_CSV"

TOTAL=$(wc -l < "$CATALOG_FILE")
echo "[+] SUCCÈS TOTAL : $TOTAL paquets indexés dans $CATALOG_FILE !"
echo ""
echo "--- Exemples extraits ---"
head -n 25 "$CATALOG_FILE"
