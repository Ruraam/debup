#!/usr/bin/env bash
#
# Debup - Interactive Setup & Installer
# Repository: https://github.com/Ruraam/debup
#

set -euo pipefail

EXPECTED_GPG_FINGERPRINT="0F43E2925658EB3CAC8BA4B6B3C2F87E36A62AE2"
REPO_GPG_URL="https://ruraam.github.io/debup/debup.gpg"
API_URL="https://api.github.com/repos/Ruraam/debup/releases/latest"

NON_INTERACTIVE=false
for arg in "$@"; do
case "$arg" in
--non-interactive|-y|--yes)
NON_INTERACTIVE=true
;;
--help|-h)
echo "Usage: $0[--non-interactive|-y]"
exit 0
;;
esac
done

BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # Reset color

verify_gpg_fingerprint() {
local key_file="$1"
if [[ -z "$EXPECTED_GPG_FINGERPRINT" ]]; then
return 0
fi

echo -e "${BLUE}[*] Validating GPG keyring fingerprint...${NC}"
local actual expected
actual=$(gpg --show-keys --with-fingerprint --with-colons "$key_file" 2>/dev/null | awk -F: '/^fpr:/ {print $10; exit}' | tr -d ' ')
expected=$(echo "$EXPECTED_GPG_FINGERPRINT" | tr -d ' ')

if [[ "$actual" == "$expected" ]]; then
echo -e "${GREEN}✔ GPG fingerprint verified: ${actual}${NC}"
else
echo -e "${RED}✖ SECURITY ALERT: GPG key fingerprint mismatch!${NC}" >&2
echo -e "   Expected: $expected" >&2
echo -e "   Found   : $actual" >&2
exit 1
fi
}

verify_sha256() {
local deb_file="$1"
local sha_url="${2:-}"

if [[ -z "$sha_url" || "$sha_url" == "null" ]]; then
echo -e "${YELLOW}[!] No checksum asset provided in release. Skipping hash verification.${NC}"
return 0
fi

echo -e "${BLUE}[*] Verifying package integrity (SHA-256)...${NC}"
local deb_name expected actual
deb_name=$(basename "$deb_file")

expected=$(curl -fsSL "$sha_url" 2>/dev/null | grep -F "$deb_name" | awk '{print $1}' | head -n1)

if [[ -z "$expected" ]]; then
expected=$(curl -fsSL "$sha_url" 2>/dev/null | head -n1 | awk '{print $1}')
fi

actual=$(sha256sum "$deb_file" | awk '{print $1}')

if [[ -n "$expected" && "$actual" == "$expected" ]]; then
echo -e "${GREEN}✔ SHA-256 hash verified: ${actual}${NC}"
elif [[ -n "$expected" && "$actual" != "$expected" ]]; then
echo -e "${RED}✖ SECURITY ERROR: SHA-256 hash mismatch! Aborting installation.${NC}" >&2
echo -e "   Expected: $expected" >&2
echo -e "   Computed: $actual" >&2
exit 1
else
echo -e "${YELLOW}[!] Unable to parse checksum from ${sha_url}. Skipping check.${NC}"
fi
}

BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

if [[ "$NON_INTERACTIVE" == false ]]; then
clear
echo -e "${BOLD}${RED}"
cat << 'EOF'
           ********           
       ******    ******       
    ***** *****      *****    
   ****      *****     ****   
  *********      ***********  
  ***    *****  *****    ***  
  ***       ******       **   
  ***         **              
  ***         **         **** 
   ***        **   *** ****     _      _
    *****     **    *****      | | ___| |__  _   _ _ __
       ****** ** *    *     / _` |/ _ \ '_ \| | | | '_ \
           ********        | (_| |  __/ |_) | |_| | |_) |
                            \__,_|\___|_.__/ \__,_| .__/
                                                  |_|
EOF
echo -e "${NC}"
echo -e "${BOLD}${CYAN}Welcome to the Debup Installation Wizard${NC}"
echo -e "${GRAY}Debup: A native GitHub .deb package manager & helper${NC}"
echo -e "${BLUE}------------------------------------------------------------${NC}\n"
echo -e ""
echo -e "${BOLD}Please choose an installation method:${NC}\n"
echo -e "  ${YELLOW}[1]${NC} ${BOLD}APT Repository (Recommended)${NC}"
echo -e "      ${GRAY}Installs GPG key and adds the official APT repository.${NC}"
echo -e "      ${GRAY}Enables automatic updates with 'apt update && apt upgrade'.${NC}\n"
echo -e ". ${YELLOW}[2]${NC} ${BOLD}Download Latest Release (.deb)${NC}"
echo -e "      ${GRAY}Fetches the latest official pre-built package from GitHub releases${NC}"
echo -e "      ${GRAY}and installs it using APT directly.${NC}"
echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"
echo -e ". ${YELLOW}[3]${NC} ${BOLD}Build from Source (dpkg-deb)${NC}"
echo -e "      ${GRAY}Clones or detects the source tree, builds a local package,${NC}"
echo -e "      ${GRAY}and lets you install or keep the binary.${NC}"
echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"

echo -e "  ${YELLOW}[4]${NC} ${RED}Exit${NC}\n"

read -rp "Selection [1-4] (default: 1): " choice </dev/tty
choice=${choice:-1}
else
choice=1
fi

echo -e "${BLUE}------------------------------------------------------------${NC}"

case "$choice" in
1)
# ==========================================================
# OPTION 1: Add APT Repository + GPG Key
# ==========================================================
echo -e "${CYAN}[*] Setting up official Debup APT repository...${NC}"

sudo apt-get update -qq
sudo apt-get install -y -qq curl gnupg lsb-release >/dev/null

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="${KEYRING_DIR}/debup.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/debup.list"

echo -e "${CYAN}[*] Importing GPG signing key...${NC}"
sudo mkdir -p "$KEYRING_DIR"
curl -fsSL "$REPO_GPG_URL" | sudo gpg --dearmor -o "$KEYRING_PATH" --yes
sudo chmod 644 "$KEYRING_PATH"

# Fingerprint integrity check (if configured)
verify_gpg_fingerprint "$KEYRING_PATH"

echo -e "${CYAN}[*] Configuring repository sources list...${NC}"
echo "deb[signed-by=${KEYRING_PATH}] https://ruraam.github.io/debup/ stable main" | sudo tee "$SOURCES_LIST" >/dev/null

echo -e "${CYAN}[*] Refreshing packagelists and installing debup...${NC}"
sudo apt-get update -qq
sudo apt-get install -y debup

echo -e "\n${GREEN}✔ Debup was installed successfully via the official APT repository!${NC}"
echo -e "You will now receive seamless updates whenever you run ${CYAN}apt upgrade${NC}."
;;

2)
# ==========================================================
#OPTION 2: Fetch and Install Latest Release via GitHub API
# ==========================================================
echo -e "${BLUE}[*] Fetching latest release info from GitHub API...${NC}"

TEMP_DIR=$(mktemp -d "/tmp/debup-install.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT INT TERM

if ! command -v jq >/dev/null 2>&1; then
echo -e "${YELLOW}[!] 'jq' is missing. Installing jq temporarily...${NC}"
sudo apt-get update -qq && sudo apt-get install -y -qq jq >/dev/null
fi

RELEASE_JSON=$(curl -sSL -H "User-Agent: debup-installer" "$API_URL")
LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null)

if [ -z "$LATEST_TAG" ]; then
echo -e "${RED}Error: Unable to fetch release information from GitHub API.${NC}"
sleep 3
clear
exit 1
fi

echo -e "Latest detected release: ${GREEN}${LATEST_TAG}${NC}"

DEB_URL=$(echo "$RELEASE_JSON" | jq -r'.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)

if [ -z "$DEB_URL" ]; then
echo -e "${RED}Error: No .deb package found in release ${LATEST_TAG}.${NC}"
sleep 3
exit 1
fi

DEB_FILE="${TEMP_DIR}/debup_latest.deb"
echo -e "${BLUE}[*] Downloading package:${NC} ${GRAY}${DEB_URL}${NC}"
curl -L --progress-bar -o "$DEB_FILE" "$DEB_URL"

# Checksum verification (SHA-256)
SHA_URL=$(echo "$RELEASE_JSON" | jq -r'.assets[] | select(.name | test("sha256|SHA256|checksums"; "i")) | .browser_download_url' | head -n1)
verify_sha256 "$DEB_FILE" "$SHA_URL"

echo -e "${BLUE}[*] Installing package using APT...${NC}"
sudo apt-get install -y "$DEB_FILE"

echo -e "\n${GREEN}✔ debup ${LATEST_TAG} has been installed successfully!${NC}"
;;

3)
# ==========================================================
# OPTION 3: Auto-Build from Source
# ==========================================================
echo -e "${BLUE}[*] Setting up build environment...${NC}"

if [ -d "debup-pkg" ]; then
echo -e "${BLUE}[*] Local repository detected.${NC}"
REPO_DIR="$(pwd)"
else
TARGET_DIR="${HOME}/debup"
echo -e "${BLUE}[*] Cloning repository to ${TARGET_DIR}...${NC}"

if [ -d "$TARGET_DIR/.git" ]; then
echo -e "${YELLOW}[!] Directory exists. Updating via git pull...${NC}"
cd "$TARGET_DIR"
git pull
else
git clone https://github.com/Ruraam/debup.git "$TARGET_DIR"
cd "$TARGET_DIR"
fi
REPO_DIR="$TARGET_DIR"
fi

echo -e "${BLUE}[*] Configuring filepermissions...${NC}"
chmod 755 debup-pkg/DEBIAN/postinst debup-pkg/DEBIAN/postrm 2>/dev/null || true
chmod 755 debup-pkg/usr/local/bin/debup debup-pkg/usr/local/bin/dbp 2>/dev/null || true

echo -e "${BLUE}[*] Compiling .debpackage with dpkg-deb...${NC}"
dpkg-deb --build --root-owner-group debup-pkg debup.deb

echo -e "\n${GREEN}✔ Package built successfully: ${REPO_DIR}/debup.deb${NC}\n"

if [[ "$NON_INTERACTIVE" == true ]]; then
install_choice="Y"
else
read -rp "Would you like to install debup now using APT? [Y/n]: " install_choice </dev/tty
install_choice=${install_choice:-Y}
fi

if [[ "$install_choice" =~ ^[YyOosSjJ]$ ]]; then
echo -e "${BLUE}[*] Installing generated package...${NC}"
sudo apt-get install -y ./debup.deb
echo -e "\n${GREEN}✔ debup has been installed successfully!${NC}"
else
echo -e "${YELLOW}[i] Installation skipped.${NC}"
echo -e "You can manually install it anytime with: ${CYAN}sudo apt install ${REPO_DIR}/debup.deb${NC}"
fi
;;

4)
echo -e "${CYAN}Installation aborted by user.${NC}"
sleep 2
clear
exit 0
;;

*)
echo -e "${RED}Invalid option selected. Exiting.${NC}"
sleep 2
clear
exit 1
;;
esac

echo -e "\n${GREEN}All done! Test it now with:${NC} ${BOLD}${CYAN}dbp -s <package_name>${NC}\n"