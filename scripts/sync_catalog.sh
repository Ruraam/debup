#!/usr/bin/env bash

WORK_DIR="/tmp/deb-get-repo"
CATALOG_FILE="curated_db.txt"
TMP_CSV="/tmp/deb-get.csv"

echo "[*] 1. Clonage de deb-get..."
rm-rf "$WORK_DIR" "$CATALOG_FILE" "$TMP_CSV"
git clone --depth 1 https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

echo "[*] 2. Inspection des dossiers clonés..."
ls -d "$WORK_DIR"/*
echo "Nombre de recettes trouvées :"
find "$WORK_DIR" -type f | wc -l

echo "[*] 3. Tentative viale binaire deb-get csv..."
chmod +x "$WORK_DIR/deb-get"
export DEBIAN_FRONTEND=noninteractive
which jq || sudo apt-get update && sudo apt-get install -y jq curl

"$WORK_DIR/deb-get" csv > "$TMP_CSV" 2>&1 || true

echo "--- 10 premières lignes produites par deb-get csv ---"
head -n 10 "$TMP_CSV"
echo "----------------------------------------------------"

> "$CATALOG_FILE"

if grep -q"," "$TMP_CSV" 2>/dev/null; then
echo "[*] deb-get csv a fonctionné ! Traitement..."
while IFS=',' read -r pkg method target _rest; do
pkg=$(echo "$pkg" | tr -d ' "\r')
method=$(echo "$method" | tr -d ' "\r')
target=$(echo "$target" | tr -d ' "\r')

if [ "$method" = "github" ] && [ -n "$target" ]; then
echo "${pkg}|github|${target}" >> "$CATALOG_FILE"
elif [ "$method" = "direct" ] && [ -n "$target" ]; then
echo "${pkg}|direct|${target}" >> "$CATALOG_FILE"
fi
done < "$TMP_CSV"
else
echo "[!] deb-get csv n'a rien renvoyé. Activation du mode dump statique..."
sample_file=$(find "$WORK_DIR" -path "*/packages/*" -type f | head -n 1)
echo "Exemple de recette ($sample_file) :"
cat "$sample_file" || true
echo "----------------------------------------------------"
fi

sort -u -o "$CATALOG_FILE" "$CATALOG_FILE" || true
TOTAL=$(wc -l < "$CATALOG_FILE" || echo 0)

echo "[+] Total paquets : $TOTAL"
if [ "$TOTAL" -gt 0 ]; then
head -n 20 "$CATALOG_FILE"
fi

rm -rf "$WORK_DIR" "$TMP_CSV"
