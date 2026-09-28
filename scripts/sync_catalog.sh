#!/usr/bin/env bash

WORK_DIR="/tmp/deb-get"
CATALOG_FILE="curated_db.txt"
TMP_RAW="/tmp/catalog_raw.tmp"

echo "[*] Clonage de deb-get..."
rm-rf "$WORK_DIR" "$TMP_RAW"
git clone --depth 1 https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

> "$TMP_RAW"

echo"[*] Analyse des recettes..."
for f in "$WORK_DIR"/01-main/packages/*; do
[ -f "$f" ] || continue
pkg=$(basename "$f")

(
export HOST_ARCH="amd64"
export ARCH="amd64"
export DEB_GET_TEMP="/tmp"

say_github() { echo "$1"; }
say_direct() { echo "$1"; }

source "$f" >/dev/null 2>&1 || true

fn_gh="${pkg//-/_}_github"
if declare -f "$fn_gh" >/dev/null 2>&1; then
res=$("$fn_gh" 2>/dev/null | tr -d ' "' | head -n 1)
if [[ "$res" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]; then
echo "${pkg}|github|${res}"
exit 0
fi
fi

fn_dir="${pkg//-/_}_direct"
if declare -f "$fn_dir" >/dev/null 2>&1; then
res=$("$fn_dir" 2>/dev/null | tr -d ' "' | head -n 1)
if [[ "$res" =~ ^https?:// ]]; then
echo "${pkg}|direct|${res}"
exit 0
fi
fi

gh_match=$(grep -Eo 'https://github\.com/[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+' "$f" | sed 's#https://github.com/##' | grep -v 'wimpysworld/deb-get' |head -n 1)
if [ -n "$gh_match" ]; then
echo "${pkg}|github|${gh_match}"
exit 0
fi
) >> "$TMP_RAW"2>/dev/null || true
done

echo "[*] Nettoyage et formatage..."
grep -E '^[a-zA-Z0-9._-]+(\|(github|direct)\|)[^|]+$' "$TMP_RAW" | sort -u > "$CATALOG_FILE" || true

rm -rf "$WORK_DIR" "$TMP_RAW"

TOTAL=$(wc -l < "$CATALOG_FILE")
echo "[+] SUCCÈS ! $TOTAL paquets indexés dans $CATALOG_FILE"
echo "--- Exemples extraits ---"
head -n 20 "$CATALOG_FILE"
