#!/usr/bin/env bash
#
# Debup - Interactive Setup & Installer
# Repository: https://github.com/Ruraam/debup
#

set -euo pipefail

EXPECTED_GPG_FINGERPRINT="0F43E2925658EB3CAC8BA4B6B3C2F87E36A62AE2"
REPO_GPG_URL="https://ruraam.github.io/debup/debup.gpg"
API_URL="https://api.github.com/repos/Ruraam/debup/releases/latest"

BOLD='\033[1m'
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# ==========================================================
# Global cleanup state
# ==========================================================
_DEBUP_CLEANUP_TMPKEY=""
_DEBUP_CLEANUP_TMPKEYRING=""
_DEBUP_CLEANUP_TMPSOURCES=""
_DEBUP_CLEANUP_TEMPDIR=""

_cleanup_all() {
    [ -n "${_DEBUP_CLEANUP_TMPKEY:-}" ] && rm -f -- "$_DEBUP_CLEANUP_TMPKEY"
    [ -n "${_DEBUP_CLEANUP_TMPKEYRING:-}" ] && $SUDO rm -f -- "$_DEBUP_CLEANUP_TMPKEYRING"
    [ -n "${_DEBUP_CLEANUP_TMPSOURCES:-}" ] && $SUDO rm -f -- "$_DEBUP_CLEANUP_TMPSOURCES"
    [ -n "${_DEBUP_CLEANUP_TEMPDIR:-}" ] && rm -rf -- "$_DEBUP_CLEANUP_TEMPDIR"
    return 0
}

cleanup_tempdir_now() {
    if [ -n "${_DEBUP_CLEANUP_TEMPDIR:-}" ] && [ -d "$_DEBUP_CLEANUP_TEMPDIR" ]; then
        rm -rf -- "$_DEBUP_CLEANUP_TEMPDIR"
    fi
    _DEBUP_CLEANUP_TEMPDIR=""
}

trap _cleanup_all EXIT
trap 'exit 130' INT TERM

# ==========================================================
# Privilege Escalation Handling
# ==========================================================
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    elif command -v doas >/dev/null 2>&1; then
        SUDO="doas"
    else
        echo -e "${RED}[!] Error: Root privileges required. Please install sudo or run as root.${NC}" >&2
        exit 1
    fi
fi

NON_INTERACTIVE=false
for arg in "$@"; do
    case "$arg" in
        --non-interactive|-y|--yes) NON_INTERACTIVE=true ;;
        --help|-h)
            echo "Usage: $0 [--non-interactive|-y|--help]"
            exit 0
            ;;
        *)
            printf 'Error: Unknown argument: %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done

# ==========================================================
# prompt_read safe (TTY / pipe / non-interactive)
# ==========================================================
prompt_read() {
    local _var="$1"
    local _prompt="${2:-}"
    local _default="${3:-}"

    [ -n "$_prompt" ] && echo -en "$_prompt" >&2

    local _answer=""

    if [ -t 0 ]; then
        IFS= read -r _answer || _answer=""
    elif [ -e /dev/tty ] && [ -r /dev/tty ] && [ -w /dev/tty ]; then
        IFS= read -r _answer </dev/tty || _answer=""
    else
        if [ -n "$_default" ]; then
            echo -e "${YELLOW}⚠ No TTY available: defaulting to '${_default}'.${NC}" >&2
            printf -v "$_var" '%s' "$_default"
            return 0
        else
            echo -e "${RED}✖ No TTY available and no default provided. Aborting.${NC}" >&2
            return 1
        fi
    fi

    [ -z "$_answer" ] && [ -n "$_default" ] && _answer="$_default"

    printf -v "$_var" '%s' "$_answer"
    return 0
}

# ==========================================================
# GPG fingerprint fail-closed
# ==========================================================
verify_gpg_fingerprint() {
    local key_file="$1"

    if [[ -z "$EXPECTED_GPG_FINGERPRINT" ]]; then
        return 0
    fi

    echo -e "${BLUE}[*] Validating GPG keyring fingerprint...${NC}"

    if [[ ! -s "$key_file" ]]; then
        echo -e "${RED}✖ SECURITY ALERT: GPG key file is empty or missing: $key_file${NC}" >&2
        exit 1
    fi

    if ! gpg --show-keys "$key_file" >/dev/null 2>&1; then
        echo -e "${RED}✖ SECURITY ALERT: File is not a valid GPG key: $key_file${NC}" >&2
        exit 1
    fi

    local key_data actual expected primary_count
    if ! key_data=$(gpg --show-keys --with-fingerprint --with-colons "$key_file" 2>/dev/null); then
        echo -e "${RED}✖ SECURITY ALERT: Unable to inspect GPG key material.${NC}" >&2
        exit 1
    fi

    primary_count=$(printf '%s\n' "$key_data" | awk -F: '$1 == "pub" { count++ } END { print count+0 }')
    if [[ "$primary_count" -ne 1 ]]; then
        echo -e "${RED}✖ SECURITY ALERT: Expected exactly one primary GPG key; found ${primary_count}.${NC}" >&2
        exit 1
    fi

    actual=$(printf '%s\n' "$key_data" | awk -F: '
        $1 == "pub" { awaiting_fingerprint = 1; next }
        awaiting_fingerprint && $1 == "fpr" { print $10; exit }
    ' | tr -d ' ')
    expected=$(printf '%s' "$EXPECTED_GPG_FINGERPRINT" | tr -d ' ')

    if [[ -z "$actual" ]]; then
        echo -e "${RED}✖ SECURITY ALERT: Unable to extract fingerprint from key.${NC}" >&2
        exit 1
    fi

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
    local original_name="${3:-}"

    if [[ -z "$sha_url" || "$sha_url" == "null" ]]; then
        echo -e "${RED}✖ No checksum asset provided in this release.${NC}" >&2
        echo -e "${YELLOW}  Refusing to install without integrity verification.${NC}" >&2
        echo -e "${YELLOW}  If this is expected, use option [1] (APT repository) or [3] (build from source).${NC}" >&2
        exit 1
    fi

    local -a sha_cmd
    if command -v sha256sum >/dev/null 2>&1; then
        sha_cmd=(sha256sum)
    elif command -v shasum >/dev/null 2>&1; then
        sha_cmd=(shasum -a 256)
    else
        echo -e "${RED}✖ Neither 'sha256sum' nor 'shasum' found. Cannot verify integrity.${NC}" >&2
        exit 1
    fi

    echo -e "${BLUE}[*] Verifying package integrity (SHA-256)...${NC}"

    local deb_name
    if [ -n "$original_name" ]; then
        deb_name="$original_name"
    else
        deb_name=$(basename "$deb_file")
    fi

    local checksums
    checksums=$(curl -fsSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
        "$sha_url" 2>/dev/null || true)

    if [[ -z "$checksums" ]]; then
        echo -e "${RED}✖ Failed to download checksums from ${sha_url}${NC}" >&2
        exit 1
    fi

    local expected actual checksum_count
    expected=$(awk -v name="$deb_name" '
        NF >= 2 {
            filename = $2
            sub(/^\*/, "", filename)
            if (filename == name) {
                print tolower($1)
            }
        }
    ' <<< "$checksums")
    checksum_count=$(printf '%s\n' "$expected" | awk 'NF { count++ } END { print count+0 }')

    if [[ "$checksum_count" -eq 0 && "$checksums" =~ ^[[:space:]]*[[:xdigit:]]{64}[[:space:]]*$ ]]; then
        expected=$(printf '%s' "$checksums" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        checksum_count=1
    fi

    if [[ "$checksum_count" -ne 1 || ! "$expected" =~ ^[[:xdigit:]]{64}$ ]]; then
        echo -e "${RED}✖ SECURITY ERROR: Expected exactly one valid SHA-256 checksum for '${deb_name}'.${NC}" >&2
        exit 1
    fi

    if ! actual=$("${sha_cmd[@]}" "$deb_file" | awk '{print $1}'); then
        echo -e "${RED}✖ Failed to calculate SHA-256 for ${deb_file}.${NC}" >&2
        exit 1
    fi
    actual="${actual,,}"

    if [[ "$actual" == "$expected" ]]; then
        echo -e "${GREEN}✔ SHA-256 hash verified: ${actual}${NC}"
    else
        echo -e "${RED}✖ SECURITY ERROR: SHA-256 hash mismatch! Aborting installation.${NC}" >&2
        echo -e "   Expected: $expected" >&2
        echo -e "   Computed: $actual" >&2
        exit 1
    fi
}

# ==========================================================
# Prioritized checksum asset resolution
# ==========================================================
select_release_deb_url() {
    local release_json="$1"
    local architecture="$2"
    local aliases=""
    local selected=""
    local priority=""
    local -a candidates=()

    case "$architecture" in
        amd64) aliases="amd64|x86_64|x64" ;;
        arm64) aliases="arm64|aarch64|arm64v8" ;;
        armhf) aliases="armhf|armv7l" ;;
        i386)  aliases="i386|i686" ;;
        *)     aliases="$architecture" ;;
    esac

    if ! jq -e '.assets | type == "array"' >/dev/null 2>&1 <<<"$release_json"; then
        printf 'Invalid GitHub release asset metadata.\n' >&2
        return 1
    fi

    for priority in architecture all; do
        if [[ "$priority" == "architecture" ]]; then
            mapfile -t candidates < <(
                jq -r --arg arch "$aliases" '
                    .assets[]
                    | select(.name | type == "string" and endswith(".deb"))
                    | select(.name | test("(^|[-_.])(" + $arch + ")([-_.]|$)"; "i"))
                    | select(.browser_download_url | type == "string" and test("^https://github\\.com/[^/]+/[^/]+/releases/download/"))
                    | .browser_download_url
                ' <<<"$release_json"
            )
        else
            mapfile -t candidates < <(
                jq -r '
                    .assets[]
                    | select(.name | type == "string" and endswith(".deb"))
                    | select(.name | test("(^|[-_])all([-_.]|$)"; "i"))
                    | select(.browser_download_url | type == "string" and test("^https://github\\.com/[^/]+/[^/]+/releases/download/"))
                    | .browser_download_url
                ' <<<"$release_json"
            )
        fi

        if (("${#candidates[@]}" > 1)); then
            printf 'Ambiguous %s-compatible Debian package assets in release metadata.\n' "$priority" >&2
            return 1
        fi
        if (("${#candidates[@]}" == 1)); then
            selected="${candidates[0]}"
            printf '%s\n' "$selected"
            return 0
        fi
    done

    printf 'No Debian package compatible with architecture %s was found.\n' "$architecture" >&2
    return 1
}

find_checksum_url() {
    local release_json="$1"
    local deb_name="$2"
    local matches

    # A malformed release payload must never be interpreted as an empty asset list.
    if ! jq -e '.assets | type == "array"' >/dev/null 2>&1 <<< "$release_json"; then
        echo "Invalid GitHub release asset metadata." >&2
        return 1
    fi

    # Resolve one priority class at a time. Multiple candidates at the same
    # priority are ambiguous and must fail closed instead of choosing head -n1.
    matches=$(jq -r --arg n "$deb_name" '
        [.assets[]
         | select(.name == ($n + ".sha256") or .name == ($n + ".sha256sum"))
         | [.name, .browser_download_url]]
        | .[]
        | @tsv
    ' <<< "$release_json") || return 1
    if [[ -n "$matches" ]]; then
        :
    else
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("^(checksums?|SHA256SUMS|sha256sums)(\\.txt)?$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi
    if [[ -z "$matches" ]]; then
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("\\.sha256$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi

    [[ -n "$matches" ]] || return 1
    local -a candidates=()
    mapfile -t candidates <<< "$matches"
    if [[ "${#candidates[@]}" -ne 1 ]]; then
        printf 'Ambiguous checksum assets: expected exactly one candidate at the selected priority, found %s.\n' "${#candidates[@]}" >&2
        return 1
    fi

    local asset_name asset_url
    IFS=    local release_json="$1"
    local deb_name="$2"
    local matches

    # A malformed release payload must never be interpreted as an empty asset list.
    if ! jq -e '.assets | type == "array"' >/dev/null 2>&1 <<< "$release_json"; then
        echo "Invalid GitHub release asset metadata." >&2
        return 1
    fi

    # Resolve one priority class at a time. Multiple candidates at the same
    # priority are ambiguous and must fail closed instead of choosing head -n1.
    matches=$(jq -r --arg n "$deb_name" '
        [.assets[]
         | select(.name == ($n + ".sha256") or .name == ($n + ".sha256sum"))
         | [.name, .browser_download_url]]
        | .[]
        | @tsv
    ' <<< "$release_json") || return 1
    if [[ -n "$matches" ]]; then
        :
    else
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("^(checksums?|SHA256SUMS|sha256sums)(\\.txt)?$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi
    if [[ -z "$matches" ]]; then
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("\\.sha256$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi

    [[ -n "$matches" ]] || return 1
    local -a candidates=()
    mapfile -t candidates <<< "$matches"
    if [[ "${#candidates[@]}" -ne 1 ]]; then
        printf 'Ambiguous checksum assets: expected exactly one candidate at the selected priority, found %s.\n' "${#candidates[@]}" >&2
        return 1
    fi

    local asset_name asset_url
    IFS=$'\t' read -r asset_name asset_url <<< "${candidates[0]}"
    if [[ -z "$asset_name" || ! "$asset_url" =~ ^https://github\.com/ ]]; then
        echo "Invalid checksum asset metadata or non-GitHub HTTPS URL." >&2
        return 1
    fi

    printf '%s\n' "$asset_url"
}

# Auto-tracking after install (options 2/3)
# ==========================================================
ensure_debup_tracked() {
    local sources_file="/etc/debup/sources.list"
    local entry="debup|Ruraam/debup"

    if [ ! -f "$sources_file" ]; then
        $SUDO mkdir -p /etc/debup
        $SUDO touch "$sources_file"
        $SUDO chmod 644 "$sources_file"
    fi

    # Regex anchor, not -F (which treats ^ literally)
    if $SUDO grep -q '^debup|' "$sources_file" 2>/dev/null; then
        echo -e "${GRAY}[i] debup is already tracked for self-updates.${NC}"
        return 0
    fi

    echo "$entry" | $SUDO tee -a "$sources_file" >/dev/null
    echo -e "${GREEN}✔ debup added to self-update tracking (dbp -u).${NC}"
}

# ==========================================================
# Banner + menu
# ==========================================================
if [[ "$NON_INTERACTIVE" == false ]]; then
    if [[ ! -t 0 && ! ( -e /dev/tty && -r /dev/tty && -w /dev/tty ) ]]; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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
    echo -e "  ${YELLOW}[2]${NC} ${BOLD}Download Latest Release (.deb)${NC}"
    echo -e "      ${GRAY}Fetches the latest official pre-built package from GitHub releases${NC}"
    echo -e "      ${GRAY}and installs it using APT directly.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"
    echo -e "  ${YELLOW}[3]${NC} ${BOLD}Build from Source (dpkg-deb)${NC}"
    echo -e "      ${GRAY}Clones or detects the source tree, builds a local package,${NC}"
    echo -e "      ${GRAY}and lets you install or keep the binary.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"

    echo -e "  ${YELLOW}[4]${NC} ${RED}Exit${NC}\n"

    if ! prompt_read choice "Selection [1-4] (default: 1): " "1"; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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

        $SUDO apt-get update -qq || echo -e "${YELLOW}[!] apt update had warnings, continuing...${NC}"

        if ! command -v curl >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing required tools (curl, gnupg)...${NC}"
            $SUDO apt-get install -y -qq curl gnupg >/dev/null
        fi

        KEYRING_DIR="/etc/apt/keyrings"
        KEYRING_PATH="${KEYRING_DIR}/debup.gpg"
        SOURCES_LIST="/etc/apt/sources.list.d/debup.list"

        echo -e "${CYAN}[*] Checking GPG key availability...${NC}"
        HTTP_PROBE=$(curl -sIL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -o /dev/null -w '%{http_code} %{content_type}' "$REPO_GPG_URL" 2>/dev/null || echo "000 unknown")

        HTTP_CODE="${HTTP_PROBE%% *}"
        CONTENT_TYPE="${HTTP_PROBE#* }"

        if [[ "$HTTP_CODE" != "200" ]]; then
            echo -e "${RED}✖ GPG URL returned HTTP ${HTTP_CODE} (expected 200). Aborting.${NC}" >&2
            echo -e "${YELLOW}  URL: ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        if [[ "$CONTENT_TYPE" == text/html* ]]; then
            echo -e "${RED}✖ GPG URL returns HTML (likely a 404 page). Aborting.${NC}" >&2
            exit 1
        fi

        # Download to temp, verify BEFORE writing to /etc
        echo -e "${CYAN}[*] Fetching GPG signing key...${NC}"
        TMP_KEY=$(mktemp /tmp/debup-key.XXXXXX.gpg)
        chmod 600 "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY="$TMP_KEY"

        if ! curl -fsSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
                -o "$TMP_KEY" "$REPO_GPG_URL"; then
            echo -e "${RED}✖ Failed to fetch GPG key from ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        verify_gpg_fingerprint "$TMP_KEY"

        echo -e "${CYAN}[*] Importing GPG signing key...${NC}"
        $SUDO mkdir -p "$KEYRING_DIR"
        TMP_KEYRING=$($SUDO mktemp "${KEYRING_DIR}/.debup.gpg.XXXXXX")
        _DEBUP_CLEANUP_TMPKEYRING="$TMP_KEYRING"
        if ! $SUDO gpg --dearmor --yes -o "$TMP_KEYRING" "$TMP_KEY"; then
            echo -e "${RED}✖ Failed to convert the verified GPG key to a keyring.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_KEYRING"
        $SUDO mv -f -- "$TMP_KEYRING" "$KEYRING_PATH"
        _DEBUP_CLEANUP_TMPKEYRING=""
        rm -f "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY=""

        echo -e "${CYAN}[*] Configuring repository sources list...${NC}"
        TMP_SOURCES=$($SUDO mktemp "${SOURCES_LIST}.XXXXXX")
        _DEBUP_CLEANUP_TMPSOURCES="$TMP_SOURCES"
        if ! printf '%s\n' "deb [signed-by=${KEYRING_PATH}] https://ruraam.github.io/debup/ stable main" | $SUDO tee "$TMP_SOURCES" >/dev/null; then
            echo -e "${RED}✖ Failed to write the APT sources file.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_SOURCES"
        $SUDO mv -f -- "$TMP_SOURCES" "$SOURCES_LIST"
        _DEBUP_CLEANUP_TMPSOURCES=""

        echo -e "${CYAN}[*] Refreshing package lists and installing debup...${NC}"
        $SUDO apt-get update -qq
        $SUDO apt-get install -y debup

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Debup was installed successfully via the official APT repository!${NC}"
        echo -e "You will now receive seamless updates whenever you run ${CYAN}apt upgrade${NC}."
        ;;

    2)
        # ==========================================================
        # OPTION 2: Fetch and Install Latest Release via GitHub API
        # ==========================================================
        echo -e "${BLUE}[*] Fetching latest release info from GitHub API...${NC}"

        TEMP_DIR=$(mktemp -d "/tmp/debup-install.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$TEMP_DIR"

        if ! command -v jq >/dev/null 2>&1; then
            echo -e "${YELLOW}[!] 'jq' is missing. Installing jq temporarily...${NC}"
            $SUDO apt-get update -qq && $SUDO apt-get install -y -qq jq >/dev/null
        fi

        RELEASE_JSON=$(curl -sSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -H "User-Agent: debup-installer" "$API_URL")

        LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null)

        if [ -z "$LATEST_TAG" ]; then
            echo -e "${RED}Error: Unable to fetch release information from GitHub API.${NC}" >&2
            exit 1
        fi

        echo -e "Latest detected release: ${GREEN}${LATEST_TAG}${NC}"

        if ! ARCH=$(dpkg --print-architecture 2>/dev/null) || [[ -z "$ARCH" ]]; then
            echo -e "${RED}✖ Unable to determine the system architecture with dpkg.${NC}" >&2
            exit 1
        fi
        if ! command -v dpkg-deb >/dev/null 2>&1; then
            echo -e "${RED}✖ 'dpkg-deb' is required to validate downloaded packages.${NC}" >&2
            exit 1
        fi

        if ! DEB_URL=$(select_release_deb_url "$RELEASE_JSON" "$ARCH"); then
            echo -e "${RED}✖ No unambiguous, architecture-compatible .deb is available for '$ARCH'.${NC}" >&2
            exit 1
        fi

        if [ -z "$DEB_URL" ]; then
            DEB_URL=$(echo "$RELEASE_JSON" | jq -r '
                .assets[]
                | select(.name | endswith(".deb"))
                | select(.name | test("(^|[-_])all([-_.]|$)"; "i"))
                | .browser_download_url
            ' | head -n1)

            if [ -n "$DEB_URL" ]; then
                echo -e "${GRAY}[i] Using architecture-independent package (all).${NC}" >&2
            else
                DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)
                echo -e "${YELLOW}[!] No .deb matching architecture '$ARCH'. Falling back to first .deb.${NC}" >&2
            fi
        fi

        if [ -z "$DEB_URL" ]; then
            echo -e "${RED}Error: No .deb package found in release ${LATEST_TAG}.${NC}" >&2
            exit 1
        fi

        DEB_NAME=$(basename "$DEB_URL")
        DEB_FILE="${TEMP_DIR}/${DEB_NAME}"

        echo -e "${BLUE}[*] Downloading package:${NC} ${GRAY}${DEB_URL}${NC}"
        if ! curl -fsSL --connect-timeout 10 --max-time 300 --retry 2 --retry-delay 1 \
                --progress-bar -o "$DEB_FILE" "$DEB_URL"; then
            echo -e "${RED}✖ Failed to download ${DEB_URL}${NC}" >&2
            exit 1
        fi

        if command -v dpkg-deb >/dev/null 2>&1; then
            DEB_ARCH=$(dpkg-deb -f "$DEB_FILE" Architecture 2>/dev/null || true)
            if [[ -n "$DEB_ARCH" && "$DEB_ARCH" != "$ARCH" && "$DEB_ARCH" != "all" ]]; then
                echo -e "${RED}✖ Downloaded package architecture (${DEB_ARCH}) is incompatible with your system (${ARCH}).${NC}" >&2
                exit 1
            fi
        else
            echo -e "${YELLOW}[!] 'dpkg-deb' not found. Skipping post-download architecture check.${NC}" >&2
        fi

        SHA_URL=$(find_checksum_url "$RELEASE_JSON" "$DEB_NAME" || true)

        if [ -z "$SHA_URL" ]; then
            echo -e "${RED}✖ No checksum asset found for ${DEB_NAME}.${NC}" >&2
            exit 1
        fi

        verify_sha256 "$DEB_FILE" "$SHA_URL" "$DEB_NAME"

        echo -e "${BLUE}[*] Installing package using APT...${NC}"
        if ! $SUDO apt-get update -qq; then
            echo -e "${RED}✖ APT package index update failed; refusing to continue installation.${NC}" >&2
            exit 1
        fi
        if ! $SUDO apt-get install -y "$DEB_FILE"; then
            echo -e "${RED}✖ Failed to install ${DEB_FILE}.${NC}" >&2
            echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
            exit 1
        fi

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        ensure_debup_tracked

        echo -e "\n${GREEN}✔ debup ${LATEST_TAG} has been installed successfully!${NC}"

        cleanup_tempdir_now
        ;;

    3)
        # ==========================================================
        # OPTION 3: Auto-Build from Source
        # ==========================================================
        echo -e "${BLUE}[*] Setting up build environment...${NC}"

        missing_build_deps=()
        for cmd in git dpkg-deb; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_build_deps+=("$cmd")
            fi
        done

        if [ "${#missing_build_deps[@]}" -gt 0 ]; then
            echo -e "${YELLOW}[!] Missing build dependencies: ${missing_build_deps[*]}${NC}"
            echo -e "${BLUE}[*] Installing required tools...${NC}"
            $SUDO apt-get update -qq || true
            if ! $SUDO apt-get install -y -qq git dpkg-dev >/dev/null; then
                echo -e "${RED}✖ Failed to install build dependencies.${NC}" >&2
                echo -e "${YELLOW}  Install manually: sudo apt-get install git dpkg-dev${NC}" >&2
                exit 1
            fi
        fi

        ORIGINAL_PWD="$(pwd)"
        BUILD_DIR=$(mktemp -d "/tmp/debup-build.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$BUILD_DIR"

        if [ -d "debup-pkg/DEBIAN" ] && [ -f "debup-pkg/usr/local/bin/debup" ]; then
            echo -e "${BLUE}[*] Local source tree detected in ${ORIGINAL_PWD}.${NC}"
            REPO_DIR="$ORIGINAL_PWD"

            if [ "$(id -u)" -ne 0 ]; then
                foreign=$(find "$REPO_DIR/debup-pkg" \
                    \( -not -user "$(id -un)" -o -not -group "$(id -gn)" \) \
                    -print -quit 2>/dev/null || true)
                if [ -n "$foreign" ]; then
                    echo -e "${YELLOW}[!] Some files in your local source tree belong to another user.${NC}" >&2
                    echo -e "${YELLOW}    (Usually happens after a previous 'sudo dpkg-deb --build'.)${NC}" >&2
                    echo -e "${YELLOW}    Fix ownership with:${NC}" >&2
                    echo -e "${CYAN}    sudo chown -R $(id -u):$(id -g) ${REPO_DIR}/debup-pkg${NC}" >&2
                    echo -e "${YELLOW}    Then re-run this installer.${NC}" >&2
                    exit 1
                fi
            fi
        else
            echo -e "${BLUE}[*] Cloning repository to ${BUILD_DIR}...${NC}"
            if ! git clone --depth 1 https://github.com/Ruraam/debup.git "$BUILD_DIR/src"; then
                echo -e "${RED}✖ git clone failed.${NC}" >&2
                exit 1
            fi
            REPO_DIR="$BUILD_DIR/src"
        fi

        echo -e "${BLUE}[*] Configuring file permissions...${NC}"
        for f in "$REPO_DIR"/debup-pkg/DEBIAN/postinst \
                 "$REPO_DIR"/debup-pkg/DEBIAN/postrm \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/debup \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/dbp; do
            if [[ -f "$f" ]] && ! chmod 755 "$f"; then
                echo -e "${RED}✖ Failed to set executable permissions on: $f${NC}" >&2
                exit 1
            fi
        done

        RAW_OUTPUT="${ORIGINAL_PWD}/debup.deb"
        if command -v realpath >/dev/null 2>&1; then
            OUTPUT_DEB="$(realpath -m "$RAW_OUTPUT")"
        else
            OUTPUT_DEB="$(cd "$(dirname "$RAW_OUTPUT")" && pwd)/$(basename "$RAW_OUTPUT")"
        fi

        echo -e "${BLUE}[*] Compiling .deb package with dpkg-deb...${NC}"
        if ! dpkg-deb --build --root-owner-group "$REPO_DIR/debup-pkg" "$OUTPUT_DEB"; then
            echo -e "${RED}✖ dpkg-deb build failed.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Package built successfully: ${OUTPUT_DEB}${NC}\n"

        if [[ "$NON_INTERACTIVE" == true ]]; then
            install_choice="Y"
        else
            if ! prompt_read install_choice "Would you like to install debup now using APT? [Y/n]: " "Y"; then
                echo -e "${RED}✖ No terminal available. Re-run with -y.${NC}" >&2
                exit 1
            fi
        fi

        if [[ "$install_choice" =~ ^[YyOosSjJ]$ ]]; then
            echo -e "${BLUE}[*] Installing generated package...${NC}"

            # APT requires either an absolute path or a ./-prefixed one.
            # OUTPUT_DEB is already absolute (realpath), but guard anyway.
            APT_TARGET="$OUTPUT_DEB"
            case "$APT_TARGET" in
                /*) ;;                              # already absolute: OK
                *)  APT_TARGET="./$APT_TARGET" ;;   # force local-file interpretation
            esac

            if ! $SUDO apt-get install -y "$APT_TARGET"; then
                echo -e "${RED}✖ Installation failed.${NC}" >&2
                echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
                echo -e "${YELLOW}  Package preserved at: ${OUTPUT_DEB}${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
                echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            ensure_debup_tracked

            echo -e "\n${GREEN}✔ debup has been installed successfully!${NC}"

            cleanup_tempdir_now
        else
            echo -e "${YELLOW}[i] Installation skipped.${NC}"
            echo -e "You can manually install it anytime with: ${CYAN}${SUDO:+sudo }apt install ${OUTPUT_DEB}${NC}"

            cleanup_tempdir_now
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
\t' read -r asset_name asset_url <<< "${candidates[0]}"
    if [[ -z "$asset_name" || ! "$asset_url" =~ ^https://github\.com/ ]]; then
        echo "Invalid checksum asset metadata or non-GitHub HTTPS URL." >&2
        return 1
    fi

    printf '%s\n' "$asset_url"
}

# Auto-tracking after install (options 2/3)
# ==========================================================
ensure_debup_tracked() {
    local sources_file="/etc/debup/sources.list"
    local entry="debup|Ruraam/debup"

    if [ ! -f "$sources_file" ]; then
        $SUDO mkdir -p /etc/debup
        $SUDO touch "$sources_file"
        $SUDO chmod 644 "$sources_file"
    fi

    # Regex anchor, not -F (which treats ^ literally)
    if $SUDO grep -q '^debup|' "$sources_file" 2>/dev/null; then
        echo -e "${GRAY}[i] debup is already tracked for self-updates.${NC}"
        return 0
    fi

    echo "$entry" | $SUDO tee -a "$sources_file" >/dev/null
    echo -e "${GREEN}✔ debup added to self-update tracking (dbp -u).${NC}"
}

# ==========================================================
# Banner + menu
# ==========================================================
if [[ "$NON_INTERACTIVE" == false ]]; then
    if [[ ! -t 0 && ! ( -e /dev/tty && -r /dev/tty && -w /dev/tty ) ]]; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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
    echo -e "  ${YELLOW}[2]${NC} ${BOLD}Download Latest Release (.deb)${NC}"
    echo -e "      ${GRAY}Fetches the latest official pre-built package from GitHub releases${NC}"
    echo -e "      ${GRAY}and installs it using APT directly.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"
    echo -e "  ${YELLOW}[3]${NC} ${BOLD}Build from Source (dpkg-deb)${NC}"
    echo -e "      ${GRAY}Clones or detects the source tree, builds a local package,${NC}"
    echo -e "      ${GRAY}and lets you install or keep the binary.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"

    echo -e "  ${YELLOW}[4]${NC} ${RED}Exit${NC}\n"

    if ! prompt_read choice "Selection [1-4] (default: 1): " "1"; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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

        $SUDO apt-get update -qq || echo -e "${YELLOW}[!] apt update had warnings, continuing...${NC}"

        if ! command -v curl >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing required tools (curl, gnupg)...${NC}"
            $SUDO apt-get install -y -qq curl gnupg >/dev/null
        fi

        KEYRING_DIR="/etc/apt/keyrings"
        KEYRING_PATH="${KEYRING_DIR}/debup.gpg"
        SOURCES_LIST="/etc/apt/sources.list.d/debup.list"

        echo -e "${CYAN}[*] Checking GPG key availability...${NC}"
        HTTP_PROBE=$(curl -sIL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -o /dev/null -w '%{http_code} %{content_type}' "$REPO_GPG_URL" 2>/dev/null || echo "000 unknown")

        HTTP_CODE="${HTTP_PROBE%% *}"
        CONTENT_TYPE="${HTTP_PROBE#* }"

        if [[ "$HTTP_CODE" != "200" ]]; then
            echo -e "${RED}✖ GPG URL returned HTTP ${HTTP_CODE} (expected 200). Aborting.${NC}" >&2
            echo -e "${YELLOW}  URL: ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        if [[ "$CONTENT_TYPE" == text/html* ]]; then
            echo -e "${RED}✖ GPG URL returns HTML (likely a 404 page). Aborting.${NC}" >&2
            exit 1
        fi

        # Download to temp, verify BEFORE writing to /etc
        echo -e "${CYAN}[*] Fetching GPG signing key...${NC}"
        TMP_KEY=$(mktemp /tmp/debup-key.XXXXXX.gpg)
        chmod 600 "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY="$TMP_KEY"

        if ! curl -fsSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
                -o "$TMP_KEY" "$REPO_GPG_URL"; then
            echo -e "${RED}✖ Failed to fetch GPG key from ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        verify_gpg_fingerprint "$TMP_KEY"

        echo -e "${CYAN}[*] Importing GPG signing key...${NC}"
        $SUDO mkdir -p "$KEYRING_DIR"
        TMP_KEYRING=$($SUDO mktemp "${KEYRING_DIR}/.debup.gpg.XXXXXX")
        _DEBUP_CLEANUP_TMPKEYRING="$TMP_KEYRING"
        if ! $SUDO gpg --dearmor --yes -o "$TMP_KEYRING" "$TMP_KEY"; then
            echo -e "${RED}✖ Failed to convert the verified GPG key to a keyring.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_KEYRING"
        $SUDO mv -f -- "$TMP_KEYRING" "$KEYRING_PATH"
        _DEBUP_CLEANUP_TMPKEYRING=""
        rm -f "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY=""

        echo -e "${CYAN}[*] Configuring repository sources list...${NC}"
        TMP_SOURCES=$($SUDO mktemp "${SOURCES_LIST}.XXXXXX")
        _DEBUP_CLEANUP_TMPSOURCES="$TMP_SOURCES"
        if ! printf '%s\n' "deb [signed-by=${KEYRING_PATH}] https://ruraam.github.io/debup/ stable main" | $SUDO tee "$TMP_SOURCES" >/dev/null; then
            echo -e "${RED}✖ Failed to write the APT sources file.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_SOURCES"
        $SUDO mv -f -- "$TMP_SOURCES" "$SOURCES_LIST"
        _DEBUP_CLEANUP_TMPSOURCES=""

        echo -e "${CYAN}[*] Refreshing package lists and installing debup...${NC}"
        $SUDO apt-get update -qq
        $SUDO apt-get install -y debup

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Debup was installed successfully via the official APT repository!${NC}"
        echo -e "You will now receive seamless updates whenever you run ${CYAN}apt upgrade${NC}."
        ;;

    2)
        # ==========================================================
        # OPTION 2: Fetch and Install Latest Release via GitHub API
        # ==========================================================
        echo -e "${BLUE}[*] Fetching latest release info from GitHub API...${NC}"

        TEMP_DIR=$(mktemp -d "/tmp/debup-install.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$TEMP_DIR"

        if ! command -v jq >/dev/null 2>&1; then
            echo -e "${YELLOW}[!] 'jq' is missing. Installing jq temporarily...${NC}"
            $SUDO apt-get update -qq && $SUDO apt-get install -y -qq jq >/dev/null
        fi

        RELEASE_JSON=$(curl -sSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -H "User-Agent: debup-installer" "$API_URL")

        LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null)

        if [ -z "$LATEST_TAG" ]; then
            echo -e "${RED}Error: Unable to fetch release information from GitHub API.${NC}" >&2
            exit 1
        fi

        echo -e "Latest detected release: ${GREEN}${LATEST_TAG}${NC}"

        if ! ARCH=$(dpkg --print-architecture 2>/dev/null) || [[ -z "$ARCH" ]]; then
            echo -e "${RED}✖ Unable to determine the system architecture with dpkg.${NC}" >&2
            exit 1
        fi
        case "$ARCH" in
            amd64) ARCH_ALIASES="amd64|x86_64|x64" ;;
            arm64) ARCH_ALIASES="arm64|aarch64" ;;
            armhf) ARCH_ALIASES="armhf|armv7l" ;;
            i386)  ARCH_ALIASES="i386|i686|x86" ;;
            *)     ARCH_ALIASES="$ARCH" ;;
        esac

        DEB_URL=$(echo "$RELEASE_JSON" | jq -r --arg arch "$ARCH_ALIASES" '
            .assets[]
            | select(.name | endswith(".deb"))
            | select(.name | test("(" + $arch + ")"; "i"))
            | .browser_download_url
        ' | head -n1)

        if [ -z "$DEB_URL" ]; then
            DEB_URL=$(echo "$RELEASE_JSON" | jq -r '
                .assets[]
                | select(.name | endswith(".deb"))
                | select(.name | test("(^|[-_])all([-_.]|$)"; "i"))
                | .browser_download_url
            ' | head -n1)

            if [ -n "$DEB_URL" ]; then
                echo -e "${GRAY}[i] Using architecture-independent package (all).${NC}" >&2
            else
                DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)
                echo -e "${YELLOW}[!] No .deb matching architecture '$ARCH'. Falling back to first .deb.${NC}" >&2
            fi
        fi

        if [ -z "$DEB_URL" ]; then
            echo -e "${RED}Error: No .deb package found in release ${LATEST_TAG}.${NC}" >&2
            exit 1
        fi

        DEB_NAME=$(basename "$DEB_URL")
        DEB_FILE="${TEMP_DIR}/${DEB_NAME}"

        echo -e "${BLUE}[*] Downloading package:${NC} ${GRAY}${DEB_URL}${NC}"
        if ! curl -fsSL --connect-timeout 10 --max-time 300 --retry 2 --retry-delay 1 \
                --progress-bar -o "$DEB_FILE" "$DEB_URL"; then
            echo -e "${RED}✖ Failed to download ${DEB_URL}${NC}" >&2
            exit 1
        fi

        if command -v dpkg-deb >/dev/null 2>&1; then
            DEB_ARCH=$(dpkg-deb -f "$DEB_FILE" Architecture 2>/dev/null || true)
            if [[ -n "$DEB_ARCH" && "$DEB_ARCH" != "$ARCH" && "$DEB_ARCH" != "all" ]]; then
                echo -e "${RED}✖ Downloaded package architecture (${DEB_ARCH}) is incompatible with your system (${ARCH}).${NC}" >&2
                exit 1
            fi
        else
            echo -e "${YELLOW}[!] 'dpkg-deb' not found. Skipping post-download architecture check.${NC}" >&2
        fi

        SHA_URL=$(find_checksum_url "$RELEASE_JSON" "$DEB_NAME" || true)

        if [ -z "$SHA_URL" ]; then
            echo -e "${RED}✖ No checksum asset found for ${DEB_NAME}.${NC}" >&2
            exit 1
        fi

        verify_sha256 "$DEB_FILE" "$SHA_URL" "$DEB_NAME"

        echo -e "${BLUE}[*] Installing package using APT...${NC}"
        if ! $SUDO apt-get update -qq; then
            echo -e "${RED}✖ APT package index update failed; refusing to continue installation.${NC}" >&2
            exit 1
        fi
        if ! $SUDO apt-get install -y "$DEB_FILE"; then
            echo -e "${RED}✖ Failed to install ${DEB_FILE}.${NC}" >&2
            echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
            exit 1
        fi

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        ensure_debup_tracked

        echo -e "\n${GREEN}✔ debup ${LATEST_TAG} has been installed successfully!${NC}"

        cleanup_tempdir_now
        ;;

    3)
        # ==========================================================
        # OPTION 3: Auto-Build from Source
        # ==========================================================
        echo -e "${BLUE}[*] Setting up build environment...${NC}"

        missing_build_deps=()
        for cmd in git dpkg-deb; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_build_deps+=("$cmd")
            fi
        done

        if [ "${#missing_build_deps[@]}" -gt 0 ]; then
            echo -e "${YELLOW}[!] Missing build dependencies: ${missing_build_deps[*]}${NC}"
            echo -e "${BLUE}[*] Installing required tools...${NC}"
            $SUDO apt-get update -qq || true
            if ! $SUDO apt-get install -y -qq git dpkg-dev >/dev/null; then
                echo -e "${RED}✖ Failed to install build dependencies.${NC}" >&2
                echo -e "${YELLOW}  Install manually: sudo apt-get install git dpkg-dev${NC}" >&2
                exit 1
            fi
        fi

        ORIGINAL_PWD="$(pwd)"
        BUILD_DIR=$(mktemp -d "/tmp/debup-build.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$BUILD_DIR"

        if [ -d "debup-pkg/DEBIAN" ] && [ -f "debup-pkg/usr/local/bin/debup" ]; then
            echo -e "${BLUE}[*] Local source tree detected in ${ORIGINAL_PWD}.${NC}"
            REPO_DIR="$ORIGINAL_PWD"

            if [ "$(id -u)" -ne 0 ]; then
                foreign=$(find "$REPO_DIR/debup-pkg" \
                    \( -not -user "$(id -un)" -o -not -group "$(id -gn)" \) \
                    -print -quit 2>/dev/null || true)
                if [ -n "$foreign" ]; then
                    echo -e "${YELLOW}[!] Some files in your local source tree belong to another user.${NC}" >&2
                    echo -e "${YELLOW}    (Usually happens after a previous 'sudo dpkg-deb --build'.)${NC}" >&2
                    echo -e "${YELLOW}    Fix ownership with:${NC}" >&2
                    echo -e "${CYAN}    sudo chown -R $(id -u):$(id -g) ${REPO_DIR}/debup-pkg${NC}" >&2
                    echo -e "${YELLOW}    Then re-run this installer.${NC}" >&2
                    exit 1
                fi
            fi
        else
            echo -e "${BLUE}[*] Cloning repository to ${BUILD_DIR}...${NC}"
            if ! git clone --depth 1 https://github.com/Ruraam/debup.git "$BUILD_DIR/src"; then
                echo -e "${RED}✖ git clone failed.${NC}" >&2
                exit 1
            fi
            REPO_DIR="$BUILD_DIR/src"
        fi

        echo -e "${BLUE}[*] Configuring file permissions...${NC}"
        for f in "$REPO_DIR"/debup-pkg/DEBIAN/postinst \
                 "$REPO_DIR"/debup-pkg/DEBIAN/postrm \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/debup \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/dbp; do
            if [[ -f "$f" ]] && ! chmod 755 "$f"; then
                echo -e "${RED}✖ Failed to set executable permissions on: $f${NC}" >&2
                exit 1
            fi
        done

        RAW_OUTPUT="${ORIGINAL_PWD}/debup.deb"
        if command -v realpath >/dev/null 2>&1; then
            OUTPUT_DEB="$(realpath -m "$RAW_OUTPUT")"
        else
            OUTPUT_DEB="$(cd "$(dirname "$RAW_OUTPUT")" && pwd)/$(basename "$RAW_OUTPUT")"
        fi

        echo -e "${BLUE}[*] Compiling .deb package with dpkg-deb...${NC}"
        if ! dpkg-deb --build --root-owner-group "$REPO_DIR/debup-pkg" "$OUTPUT_DEB"; then
            echo -e "${RED}✖ dpkg-deb build failed.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Package built successfully: ${OUTPUT_DEB}${NC}\n"

        if [[ "$NON_INTERACTIVE" == true ]]; then
            install_choice="Y"
        else
            if ! prompt_read install_choice "Would you like to install debup now using APT? [Y/n]: " "Y"; then
                echo -e "${RED}✖ No terminal available. Re-run with -y.${NC}" >&2
                exit 1
            fi
        fi

        if [[ "$install_choice" =~ ^[YyOosSjJ]$ ]]; then
            echo -e "${BLUE}[*] Installing generated package...${NC}"

            # APT requires either an absolute path or a ./-prefixed one.
            # OUTPUT_DEB is already absolute (realpath), but guard anyway.
            APT_TARGET="$OUTPUT_DEB"
            case "$APT_TARGET" in
                /*) ;;                              # already absolute: OK
                *)  APT_TARGET="./$APT_TARGET" ;;   # force local-file interpretation
            esac

            if ! $SUDO apt-get install -y "$APT_TARGET"; then
                echo -e "${RED}✖ Installation failed.${NC}" >&2
                echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
                echo -e "${YELLOW}  Package preserved at: ${OUTPUT_DEB}${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
                echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            ensure_debup_tracked

            echo -e "\n${GREEN}✔ debup has been installed successfully!${NC}"

            cleanup_tempdir_now
        else
            echo -e "${YELLOW}[i] Installation skipped.${NC}"
            echo -e "You can manually install it anytime with: ${CYAN}${SUDO:+sudo }apt install ${OUTPUT_DEB}${NC}"

            cleanup_tempdir_now
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
    local release_json="$1"
    local deb_name="$2"
    local matches

    # A malformed release payload must never be interpreted as an empty asset list.
    if ! jq -e '.assets | type == "array"' >/dev/null 2>&1 <<< "$release_json"; then
        echo "Invalid GitHub release asset metadata." >&2
        return 1
    fi

    # Resolve one priority class at a time. Multiple candidates at the same
    # priority are ambiguous and must fail closed instead of choosing head -n1.
    matches=$(jq -r --arg n "$deb_name" '
        [.assets[]
         | select(.name == ($n + ".sha256") or .name == ($n + ".sha256sum"))
         | [.name, .browser_download_url]]
        | .[]
        | @tsv
    ' <<< "$release_json") || return 1
    if [[ -n "$matches" ]]; then
        :
    else
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("^(checksums?|SHA256SUMS|sha256sums)(\\.txt)?$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi
    if [[ -z "$matches" ]]; then
        matches=$(jq -r '
            [.assets[]
             | select(.name | test("\\.sha256$"; "i"))
             | [.name, .browser_download_url]]
            | .[]
            | @tsv
        ' <<< "$release_json") || return 1
    fi

    [[ -n "$matches" ]] || return 1
    local -a candidates=()
    mapfile -t candidates <<< "$matches"
    if [[ "${#candidates[@]}" -ne 1 ]]; then
        printf 'Ambiguous checksum assets: expected exactly one candidate at the selected priority, found %s.\n' "${#candidates[@]}" >&2
        return 1
    fi

    local asset_name asset_url
    IFS=$'\t' read -r asset_name asset_url <<< "${candidates[0]}"
    if [[ -z "$asset_name" || ! "$asset_url" =~ ^https://github\.com/ ]]; then
        echo "Invalid checksum asset metadata or non-GitHub HTTPS URL." >&2
        return 1
    fi

    printf '%s\n' "$asset_url"
}

# Auto-tracking after install (options 2/3)
# ==========================================================
ensure_debup_tracked() {
    local sources_file="/etc/debup/sources.list"
    local entry="debup|Ruraam/debup"

    if [ ! -f "$sources_file" ]; then
        $SUDO mkdir -p /etc/debup
        $SUDO touch "$sources_file"
        $SUDO chmod 644 "$sources_file"
    fi

    # Regex anchor, not -F (which treats ^ literally)
    if $SUDO grep -q '^debup|' "$sources_file" 2>/dev/null; then
        echo -e "${GRAY}[i] debup is already tracked for self-updates.${NC}"
        return 0
    fi

    echo "$entry" | $SUDO tee -a "$sources_file" >/dev/null
    echo -e "${GREEN}✔ debup added to self-update tracking (dbp -u).${NC}"
}

# ==========================================================
# Banner + menu
# ==========================================================
if [[ "$NON_INTERACTIVE" == false ]]; then
    if [[ ! -t 0 && ! ( -e /dev/tty && -r /dev/tty && -w /dev/tty ) ]]; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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
    echo -e "  ${YELLOW}[2]${NC} ${BOLD}Download Latest Release (.deb)${NC}"
    echo -e "      ${GRAY}Fetches the latest official pre-built package from GitHub releases${NC}"
    echo -e "      ${GRAY}and installs it using APT directly.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"
    echo -e "  ${YELLOW}[3]${NC} ${BOLD}Build from Source (dpkg-deb)${NC}"
    echo -e "      ${GRAY}Clones or detects the source tree, builds a local package,${NC}"
    echo -e "      ${GRAY}and lets you install or keep the binary.${NC}"
    echo -e "      ${GRAY}Enables self-updates via '${CYAN}dbp -u${GRAY}' (debup tracks itself).${NC}\n"

    echo -e "  ${YELLOW}[4]${NC} ${RED}Exit${NC}\n"

    if ! prompt_read choice "Selection [1-4] (default: 1): " "1"; then
        echo -e "${RED}✖ No terminal available. Use --non-interactive (-y) for automated setup.${NC}" >&2
        exit 1
    fi
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

        $SUDO apt-get update -qq || echo -e "${YELLOW}[!] apt update had warnings, continuing...${NC}"

        if ! command -v curl >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1; then
            echo -e "${BLUE}[*] Installing required tools (curl, gnupg)...${NC}"
            $SUDO apt-get install -y -qq curl gnupg >/dev/null
        fi

        KEYRING_DIR="/etc/apt/keyrings"
        KEYRING_PATH="${KEYRING_DIR}/debup.gpg"
        SOURCES_LIST="/etc/apt/sources.list.d/debup.list"

        echo -e "${CYAN}[*] Checking GPG key availability...${NC}"
        HTTP_PROBE=$(curl -sIL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -o /dev/null -w '%{http_code} %{content_type}' "$REPO_GPG_URL" 2>/dev/null || echo "000 unknown")

        HTTP_CODE="${HTTP_PROBE%% *}"
        CONTENT_TYPE="${HTTP_PROBE#* }"

        if [[ "$HTTP_CODE" != "200" ]]; then
            echo -e "${RED}✖ GPG URL returned HTTP ${HTTP_CODE} (expected 200). Aborting.${NC}" >&2
            echo -e "${YELLOW}  URL: ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        if [[ "$CONTENT_TYPE" == text/html* ]]; then
            echo -e "${RED}✖ GPG URL returns HTML (likely a 404 page). Aborting.${NC}" >&2
            exit 1
        fi

        # Download to temp, verify BEFORE writing to /etc
        echo -e "${CYAN}[*] Fetching GPG signing key...${NC}"
        TMP_KEY=$(mktemp /tmp/debup-key.XXXXXX.gpg)
        chmod 600 "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY="$TMP_KEY"

        if ! curl -fsSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
                -o "$TMP_KEY" "$REPO_GPG_URL"; then
            echo -e "${RED}✖ Failed to fetch GPG key from ${REPO_GPG_URL}${NC}" >&2
            exit 1
        fi

        verify_gpg_fingerprint "$TMP_KEY"

        echo -e "${CYAN}[*] Importing GPG signing key...${NC}"
        $SUDO mkdir -p "$KEYRING_DIR"
        TMP_KEYRING=$($SUDO mktemp "${KEYRING_DIR}/.debup.gpg.XXXXXX")
        _DEBUP_CLEANUP_TMPKEYRING="$TMP_KEYRING"
        if ! $SUDO gpg --dearmor --yes -o "$TMP_KEYRING" "$TMP_KEY"; then
            echo -e "${RED}✖ Failed to convert the verified GPG key to a keyring.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_KEYRING"
        $SUDO mv -f -- "$TMP_KEYRING" "$KEYRING_PATH"
        _DEBUP_CLEANUP_TMPKEYRING=""
        rm -f "$TMP_KEY"
        _DEBUP_CLEANUP_TMPKEY=""

        echo -e "${CYAN}[*] Configuring repository sources list...${NC}"
        TMP_SOURCES=$($SUDO mktemp "${SOURCES_LIST}.XXXXXX")
        _DEBUP_CLEANUP_TMPSOURCES="$TMP_SOURCES"
        if ! printf '%s\n' "deb [signed-by=${KEYRING_PATH}] https://ruraam.github.io/debup/ stable main" | $SUDO tee "$TMP_SOURCES" >/dev/null; then
            echo -e "${RED}✖ Failed to write the APT sources file.${NC}" >&2
            exit 1
        fi
        $SUDO chmod 644 "$TMP_SOURCES"
        $SUDO mv -f -- "$TMP_SOURCES" "$SOURCES_LIST"
        _DEBUP_CLEANUP_TMPSOURCES=""

        echo -e "${CYAN}[*] Refreshing package lists and installing debup...${NC}"
        $SUDO apt-get update -qq
        $SUDO apt-get install -y debup

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Debup was installed successfully via the official APT repository!${NC}"
        echo -e "You will now receive seamless updates whenever you run ${CYAN}apt upgrade${NC}."
        ;;

    2)
        # ==========================================================
        # OPTION 2: Fetch and Install Latest Release via GitHub API
        # ==========================================================
        echo -e "${BLUE}[*] Fetching latest release info from GitHub API...${NC}"

        TEMP_DIR=$(mktemp -d "/tmp/debup-install.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$TEMP_DIR"

        if ! command -v jq >/dev/null 2>&1; then
            echo -e "${YELLOW}[!] 'jq' is missing. Installing jq temporarily...${NC}"
            $SUDO apt-get update -qq && $SUDO apt-get install -y -qq jq >/dev/null
        fi

        RELEASE_JSON=$(curl -sSL --connect-timeout 10 --max-time 30 --retry 2 --retry-delay 1 \
            -H "User-Agent: debup-installer" "$API_URL")

        LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty' 2>/dev/null)

        if [ -z "$LATEST_TAG" ]; then
            echo -e "${RED}Error: Unable to fetch release information from GitHub API.${NC}" >&2
            exit 1
        fi

        echo -e "Latest detected release: ${GREEN}${LATEST_TAG}${NC}"

        if ! ARCH=$(dpkg --print-architecture 2>/dev/null) || [[ -z "$ARCH" ]]; then
            echo -e "${RED}✖ Unable to determine the system architecture with dpkg.${NC}" >&2
            exit 1
        fi
        case "$ARCH" in
            amd64) ARCH_ALIASES="amd64|x86_64|x64" ;;
            arm64) ARCH_ALIASES="arm64|aarch64" ;;
            armhf) ARCH_ALIASES="armhf|armv7l" ;;
            i386)  ARCH_ALIASES="i386|i686|x86" ;;
            *)     ARCH_ALIASES="$ARCH" ;;
        esac

        DEB_URL=$(echo "$RELEASE_JSON" | jq -r --arg arch "$ARCH_ALIASES" '
            .assets[]
            | select(.name | endswith(".deb"))
            | select(.name | test("(" + $arch + ")"; "i"))
            | .browser_download_url
        ' | head -n1)

        if [ -z "$DEB_URL" ]; then
            DEB_URL=$(echo "$RELEASE_JSON" | jq -r '
                .assets[]
                | select(.name | endswith(".deb"))
                | select(.name | test("(^|[-_])all([-_.]|$)"; "i"))
                | .browser_download_url
            ' | head -n1)

            if [ -n "$DEB_URL" ]; then
                echo -e "${GRAY}[i] Using architecture-independent package (all).${NC}" >&2
            else
                DEB_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith(".deb")) | .browser_download_url' | head -n1)
                echo -e "${YELLOW}[!] No .deb matching architecture '$ARCH'. Falling back to first .deb.${NC}" >&2
            fi
        fi

        if [ -z "$DEB_URL" ]; then
            echo -e "${RED}Error: No .deb package found in release ${LATEST_TAG}.${NC}" >&2
            exit 1
        fi

        DEB_NAME=$(basename "$DEB_URL")
        DEB_FILE="${TEMP_DIR}/${DEB_NAME}"

        echo -e "${BLUE}[*] Downloading package:${NC} ${GRAY}${DEB_URL}${NC}"
        if ! curl -fsSL --connect-timeout 10 --max-time 300 --retry 2 --retry-delay 1 \
                --progress-bar -o "$DEB_FILE" "$DEB_URL"; then
            echo -e "${RED}✖ Failed to download ${DEB_URL}${NC}" >&2
            exit 1
        fi

        if command -v dpkg-deb >/dev/null 2>&1; then
            DEB_ARCH=$(dpkg-deb -f "$DEB_FILE" Architecture 2>/dev/null || true)
            if [[ -n "$DEB_ARCH" && "$DEB_ARCH" != "$ARCH" && "$DEB_ARCH" != "all" ]]; then
                echo -e "${RED}✖ Downloaded package architecture (${DEB_ARCH}) is incompatible with your system (${ARCH}).${NC}" >&2
                exit 1
            fi
        else
            echo -e "${YELLOW}[!] 'dpkg-deb' not found. Skipping post-download architecture check.${NC}" >&2
        fi

        SHA_URL=$(find_checksum_url "$RELEASE_JSON" "$DEB_NAME" || true)

        if [ -z "$SHA_URL" ]; then
            echo -e "${RED}✖ No checksum asset found for ${DEB_NAME}.${NC}" >&2
            exit 1
        fi

        verify_sha256 "$DEB_FILE" "$SHA_URL" "$DEB_NAME"

        echo -e "${BLUE}[*] Installing package using APT...${NC}"
        if ! $SUDO apt-get update -qq; then
            echo -e "${RED}✖ APT package index update failed; refusing to continue installation.${NC}" >&2
            exit 1
        fi
        if ! $SUDO apt-get install -y "$DEB_FILE"; then
            echo -e "${RED}✖ Failed to install ${DEB_FILE}.${NC}" >&2
            echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
            exit 1
        fi

        if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
            echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
            exit 1
        fi

        ensure_debup_tracked

        echo -e "\n${GREEN}✔ debup ${LATEST_TAG} has been installed successfully!${NC}"

        cleanup_tempdir_now
        ;;

    3)
        # ==========================================================
        # OPTION 3: Auto-Build from Source
        # ==========================================================
        echo -e "${BLUE}[*] Setting up build environment...${NC}"

        missing_build_deps=()
        for cmd in git dpkg-deb; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                missing_build_deps+=("$cmd")
            fi
        done

        if [ "${#missing_build_deps[@]}" -gt 0 ]; then
            echo -e "${YELLOW}[!] Missing build dependencies: ${missing_build_deps[*]}${NC}"
            echo -e "${BLUE}[*] Installing required tools...${NC}"
            $SUDO apt-get update -qq || true
            if ! $SUDO apt-get install -y -qq git dpkg-dev >/dev/null; then
                echo -e "${RED}✖ Failed to install build dependencies.${NC}" >&2
                echo -e "${YELLOW}  Install manually: sudo apt-get install git dpkg-dev${NC}" >&2
                exit 1
            fi
        fi

        ORIGINAL_PWD="$(pwd)"
        BUILD_DIR=$(mktemp -d "/tmp/debup-build.XXXXXX")
        _DEBUP_CLEANUP_TEMPDIR="$BUILD_DIR"

        if [ -d "debup-pkg/DEBIAN" ] && [ -f "debup-pkg/usr/local/bin/debup" ]; then
            echo -e "${BLUE}[*] Local source tree detected in ${ORIGINAL_PWD}.${NC}"
            REPO_DIR="$ORIGINAL_PWD"

            if [ "$(id -u)" -ne 0 ]; then
                foreign=$(find "$REPO_DIR/debup-pkg" \
                    \( -not -user "$(id -un)" -o -not -group "$(id -gn)" \) \
                    -print -quit 2>/dev/null || true)
                if [ -n "$foreign" ]; then
                    echo -e "${YELLOW}[!] Some files in your local source tree belong to another user.${NC}" >&2
                    echo -e "${YELLOW}    (Usually happens after a previous 'sudo dpkg-deb --build'.)${NC}" >&2
                    echo -e "${YELLOW}    Fix ownership with:${NC}" >&2
                    echo -e "${CYAN}    sudo chown -R $(id -u):$(id -g) ${REPO_DIR}/debup-pkg${NC}" >&2
                    echo -e "${YELLOW}    Then re-run this installer.${NC}" >&2
                    exit 1
                fi
            fi
        else
            echo -e "${BLUE}[*] Cloning repository to ${BUILD_DIR}...${NC}"
            if ! git clone --depth 1 https://github.com/Ruraam/debup.git "$BUILD_DIR/src"; then
                echo -e "${RED}✖ git clone failed.${NC}" >&2
                exit 1
            fi
            REPO_DIR="$BUILD_DIR/src"
        fi

        echo -e "${BLUE}[*] Configuring file permissions...${NC}"
        for f in "$REPO_DIR"/debup-pkg/DEBIAN/postinst \
                 "$REPO_DIR"/debup-pkg/DEBIAN/postrm \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/debup \
                 "$REPO_DIR"/debup-pkg/usr/local/bin/dbp; do
            if [[ -f "$f" ]] && ! chmod 755 "$f"; then
                echo -e "${RED}✖ Failed to set executable permissions on: $f${NC}" >&2
                exit 1
            fi
        done

        RAW_OUTPUT="${ORIGINAL_PWD}/debup.deb"
        if command -v realpath >/dev/null 2>&1; then
            OUTPUT_DEB="$(realpath -m "$RAW_OUTPUT")"
        else
            OUTPUT_DEB="$(cd "$(dirname "$RAW_OUTPUT")" && pwd)/$(basename "$RAW_OUTPUT")"
        fi

        echo -e "${BLUE}[*] Compiling .deb package with dpkg-deb...${NC}"
        if ! dpkg-deb --build --root-owner-group "$REPO_DIR/debup-pkg" "$OUTPUT_DEB"; then
            echo -e "${RED}✖ dpkg-deb build failed.${NC}" >&2
            exit 1
        fi

        echo -e "\n${GREEN}✔ Package built successfully: ${OUTPUT_DEB}${NC}\n"

        if [[ "$NON_INTERACTIVE" == true ]]; then
            install_choice="Y"
        else
            if ! prompt_read install_choice "Would you like to install debup now using APT? [Y/n]: " "Y"; then
                echo -e "${RED}✖ No terminal available. Re-run with -y.${NC}" >&2
                exit 1
            fi
        fi

        if [[ "$install_choice" =~ ^[YyOosSjJ]$ ]]; then
            echo -e "${BLUE}[*] Installing generated package...${NC}"

            # APT requires either an absolute path or a ./-prefixed one.
            # OUTPUT_DEB is already absolute (realpath), but guard anyway.
            APT_TARGET="$OUTPUT_DEB"
            case "$APT_TARGET" in
                /*) ;;                              # already absolute: OK
                *)  APT_TARGET="./$APT_TARGET" ;;   # force local-file interpretation
            esac

            if ! $SUDO apt-get install -y "$APT_TARGET"; then
                echo -e "${RED}✖ Installation failed.${NC}" >&2
                echo -e "${YELLOW}  Try: sudo apt-get install -f${NC}" >&2
                echo -e "${YELLOW}  Package preserved at: ${OUTPUT_DEB}${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            if ! command -v dbp >/dev/null 2>&1 && ! command -v debup >/dev/null 2>&1; then
                echo -e "${RED}✖ Installation completed but 'dbp'/'debup' not found in PATH.${NC}" >&2
                cleanup_tempdir_now
                exit 1
            fi

            ensure_debup_tracked

            echo -e "\n${GREEN}✔ debup has been installed successfully!${NC}"

            cleanup_tempdir_now
        else
            echo -e "${YELLOW}[i] Installation skipped.${NC}"
            echo -e "You can manually install it anytime with: ${CYAN}${SUDO:+sudo }apt install ${OUTPUT_DEB}${NC}"

            cleanup_tempdir_now
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
