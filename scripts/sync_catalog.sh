#!/usr/bin/env bash

WORK_DIR="/tmp/deb-get-repo"
CATALOG_FILE="curated_db.txt"
TMP_CSV="/tmp/deb-get.csv"

echo "[*] Clonage officiel du repo deb-get..."
rm-rf "$WORK_DIR" "$CATALOG_FILE" "$TMP_CSV"
git clone --depth 1https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

echo "[*] Extractionde la liste via le moteur deb-get..."
chmod +x "$WORK_DIR/deb-get"
"$WORK_DIR/deb-get" csv> "$TMP_CSV"

echo "[*] Formatage pour debup..."
> "$CATALOG_FILE"

while IFS=',' read -r pkg method target _rest; do
pkg=$(echo "$pkg" | tr -d ' "')
method=$(echo "$method" | tr -d ' "')
target=$(echo "$target" | tr -d ' "')

if [ "$method" = "github" ] && [ -n "$target" ]; then
echo "${pkg}|github|${target}" >> "$CATALOG_FILE"
elif [ "$method" = "direct" ] && [ -n "$target" ]; then
echo "${pkg}|direct|${target}" >> "$CATALOG_FILE"
fi
done < "$TMP_CSV"

sort -u -o "$CATALOG_FILE" "$CATALOG_FILE"
rm -rf "$WORK_DIR" "$TMP_CSV"

TOTAL=$(wc -l < "$CATALOG_FILE")
echo "[+] SUCCÈS TOTAL! $TOTAL paquets indexés dans $CATALOG_FILE"
echo ""
echo "--- Aperçu des 15premiers paquets ---"
head -n 15 "$CATALOG_FILE"
