#!/usr/bin/env bash

set -euo pipefail

WORK_DIR="/tmp/deb-get"
CATALOG_FILE="curated_db.txt"
TMP_RAW="/tmp/catalog_raw.tmp"

echo "[*] Nettoyage et clonage..."
rm -rf "$WORK_DIR" "$TMP_RAW"
git clone --depth 1 https://github.com/wimpysworld/deb-get.git "$WORK_DIR"

> "$TMP_RAW"

echo "[*] Analyse des recettes..."
for f in "$WORK_DIR"/01-main/packages/*; do
[ -f "$f" ] || continue
pkg=$(basename "$f")

(
export HOST_ARCH="amd64"
exportARCH="amd64"
export DEB_GET_TEMP="/tmp"

GITHUB_REPO=""
DIRECT_URL=""
APT_PPA=""
APT_REPO=""

source "$f" >/dev/null 2>&1 || true

if [ -n "$GITHUB_REPO" ]; then
echo "${pkg}|github|${GITHUB_REPO}"
elif [ -n "$DIRECT_URL" ] && [ -z "$APT_PPA" ] && [ -z "$APT_REPO" ]; then
echo "${pkg}|direct|${DIRECT_URL}"
fi
) >> "$TMP_RAW" 2>/dev/null
done

echo "[*] Nettoyage et validation..."
grep -E'^[a-zA-Z0-9._-]+(\|(github|direct)\|)[^|]+$' "$TMP_RAW" | sort -u > "$CATALOG_FILE"

rm -rf "$WORK_DIR" "$TMP_RAW"

TOTAL=$(wc -l < "$CATALOG_FILE")
echo "[+] Fait : $TOTAL paquets dans $CATALOG_FILE"
