#!/usr/bin/env bash
#
# Debup - Interactive Setup & Installer
# Repository: https://github.com/Ruraam/debup
#

set -e

RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Reset color

clear
echo -e "${RED}"
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
   ***        **   *** ****   
    *****     **    *****     
       ****** ** *    *       
           ********
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

echo -e "  ${YELLOW}[2]${NC} ${BOLD}Download Latest Release (.deb)${NC}"
echo -e "      ${GRAY}Fetches the latest official pre-built package from GitHub releases${NC}"
echo -e "      ${GRAY}and installs it using APT directly.${NC}\n"

echo -e "  ${YELLOW}[3]${NC} ${BOLD}Build from Source (dpkg-deb)${NC}"
echo -e "      ${GRAY}Clones or detects the source tree, builds a local package,${NC}"
echo -e "      ${GRAY}and lets you install or keep the binary.${NC}\n"

echo -e "  ${YELLOW}[4]${NC} ${RED}Exit${NC}\n"

read -rp "Selection [1-4] (default: 1): " choice </dev/tty
choice=${choice:-1}
echo -e "${BLUE}------------------------------------------------------------${NC}"

case "$choice" in
1)
# ==========================================================
# OPTION 1: Add APT Repository + GPG Key
# ==========================================================
echo -e "${CYAN}[*] Setting up official Debup APT repository...${NC}"

elevate apt-get update -qq
elevate apt-get install -y -qq curl gnupg lsb-release >/dev/null

KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="${KEYRING_DIR}/debup-archive-keyring.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/debup.list"

echo -e "${CYAN}[*] Importing GPG signing key...${NC}"
elevate mkdir -p "$KEYRING_DIR"
curl -fsSL https://ruraam.github.io/debup/debup-archive-keyring.gpg | elevate gpg--dearmor -o "$KEYRING_PATH" --yes

echo -e "${CYAN}[*] Configuring repository sources list...${NC}"
echo "deb [signed-by=${KEYRING_PATH}] https://ruraam.github.io/debup/ stable main" | elevate tee "$SOURCES_LIST" > /dev/null

echo -e "${CYAN}[*] Refreshing package lists and installing debup...${NC}"
elevate apt-get update -qq
elevate apt-get install -y debup

echo -e "\n${GREEN}✔ Debup was installed successfully via the official APT repository!${NC}"
echo -e "You will now receive seamless updates whenever you run ${CYAN}apt upgrade${NC}."
;;

2)
# ==========================================================
# OPTION 2: Fetch and Install Latest Release via GitHub API
# ==========================================================
echo -e "${BLUE}[*] Fetching latest release info from GitHub API...${NC}"

TEMP_DIR=$(mktemp -d "/tmp/debup-install.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT INT TERM

API_URL="https://api.github.com/repos/Ruraam/debup/releases/latest"
RELEASE_JSON=$(curl -sSL -H "User-Agent: debup-installer" "$API_URL")

if ! command -v jq >/dev/null2>&1; then
echo -e "${YELLOW}[!] 'jq' is missing. Installing jq temporarily...${NC}"
elevate apt-get update -qq && elevate apt-get install -y -qq jq >/dev/null
fi

LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null)

if [ -z "$LATEST_TAG" ]; then
echo -e "${RED}Error: Unable to fetch release information from GitHub API.${NC}"
exit 1
fi

echo -e "Latest detected release: ${GREEN}${LATEST_TAG}${NC}"

DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)

if [ -z "$DEB_URL" ]; then
echo-e "${RED}Error: No .deb package found in release ${LATEST_TAG}.${NC}"
exit 1
fi

DEB_FILE="${TEMP_DIR}/debup_latest.deb"
echo -e "${BLUE}[*] Downloading package:${NC} ${GRAY}${DEB_URL}${NC}"
curl -L --progress-bar -o "$DEB_FILE" "$DEB_URL"

echo -e "${BLUE}[*] Installing package using APT...${NC}"
elevate apt-get install -y "$DEB_FILE"

echo -e "\n${GREEN}✔ debup ${LATEST_TAG} has been installed successfully!${NC}"
;;

3)
# ==========================================================
#OPTION 3: Auto-Build from Source
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

echo -e "${BLUE}[*] Configuring file permissions...${NC}"
chmod 755 debup-pkg/DEBIAN/postinst debup-pkg/DEBIAN/postrm 2>/dev/null || true
chmod 755 debup-pkg/usr/local/bin/debup debup-pkg/usr/local/bin/dbp 2>/dev/null || true

echo -e "${BLUE}[*] Compiling .deb package with dpkg-deb...${NC}"
dpkg-deb --build --root-owner-group debup-pkg debup.deb

echo -e "\n${GREEN}✔ Package built successfully: ${REPO_DIR}/debup.deb${NC}\n"

read -rp "Would youlike to install debup now using APT? [Y/n]: " install_choice </dev/tty
install_choice=${install_choice:-Y}

if [[ "$install_choice" =~ ^[YyOosSjJ]$ ]]; then
echo -e "${BLUE}[*] Installing generated package...${NC}"
elevate apt-get install -y ./debup.deb
echo -e "\n${GREEN}✔ debup has been installed successfully!${NC}"
else
echo -e "${YELLOW}[i] Installation skipped.${NC}"
echo -e "You can manually install it anytime with: ${CYAN}sudo apt install${REPO_DIR}/debup.deb${NC}"
fi
;;

4)
echo -e "${CYAN}Installation aborted by user.${NC}"
exit 0
;;

*)
echo -e "${RED}Invalid option selected. Exiting.${NC}"
exit 1
;;
esac

echo -e "\n${GREEN}All done! Test it now with:${NC} ${BOLD}${CYAN}dbp -s <package_name>${NC}\n"