#!/usr/bin/env bash

# General
MSG_ENTER_PAT="Enter your GitHub Personal Access Token (PAT):"
MSG_ERR_EMPTY_TOKEN="[X] Error: Token cannot be empty."
MSG_TOKEN_SUCCESS="[✓] GITHUB_TOKEN configured successfully!"

# check_and_update
MSG_PINNED_SKIPPED="[PINNED] Package %s is held. Skipping update."
MSG_ERR_FETCH_RELEASE="[X] Error: Unable to fetch release info for %s"
MSG_ERR_GH_API="[X] GitHub API response: %s"
MSG_PACKAGE_HEADER="==> Package:"
MSG_NEW_PACKAGE="New package"
MSG_NOT_INSTALLED="Not installed"
MSG_LATEST_VERSION="Latest version:  %s"
MSG_ALREADY_UP_TO_DATE="[✓] Package is already up to date!"
MSG_ERR_NO_COMPAT_DEB="[X] Error:No compatible .deb asset found for architecture (%s)."
MSG_DRY_WOULD_DOWNLOAD="[DRY-RUN] Would download: %s"
MSG_DRY_WOULD_INSTALL="[DRY-RUN]Would install and track: %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] Do you want to download and install it? [y/N]:"
MSG_OP_CANCELED="[X] Operation canceled."
MSG_DOWNLOADING="[*] Downloading: %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Download failed."
MSG_INSTALLING_PKG="[*] Installing package (sudo required)..."
MSG_SUCCESS_INSTALLED="[✓] Successfully installed/updated %s (%s)!"
MSG_ERR_INSTALL_FAILED="[X] Installation failed."

# debup_search
MSG_USAGE_SEARCH="[!] Error: Usage: dbp -s|search <tool_name>"
MSG_SEARCHING_GH=":: Searching for '%s' on GitHub..."
MSG_NO_REPOS_FOUND="[!] No repositories found for '%s'."
MSG_VERIFYING_DEBS=":: Verifying .deb releases for candidates..."
MSG_NO_DESC="No description provided"
MSG_NO_DEB_IN_REPOS="[!] Found repositories for '%s', but none have .deb releases."
MSG_REPOS_FOUND_HEADER="Repositories found with .deb releases:"
MSG_PROMPT_SELECT_PKG="Select a package to install [1-%d] (Press Enter to cancel): "
MSG_INSPECTING_ASSETS=":: Inspecting latest release assets for %s..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Error: No .deb packages found in the latest release of this repository."
MSG_CANNOT_INSTALL="Cannot install via debup."
MSG_WARN_NO_ARCH_MATCH="[!] Warning: .deb packages exist, but none seem to match your architecture (%s)."
MSG_PROMPT_FORCE_INSTALL="Do you still want to proceed with the installation? [y/N]: "
MSG_INSTALL_CANCELED="Installation cancelled."
MSG_COMPAT_PKG_DETECTED="[✓] Compatible package detected. Adding repository..."

# debup_info
MSG_USAGE_INFO="[!] Error: Usage: dbp -i|nfo <owner/repo>"
MSG_FETCHING_METADATA=":: Fetching metadata for %s..."
MSG_ERR_REPO_NOT_FOUND="[X] Error: Repository '%s'not found on GitHub."
MSG_WARN_NO_RELEASES="[!] Repository exists, but has no releases published."
MSG_INFO_NO_DESC="No description provided."
MSG_INFO_NONE="None"
MSG_INFO_PKG="Package:"
MSG_INFO_LATEST="Latest:"
MSG_INFO_STARS="Stars:"
MSG_INFO_LICENSE="License:"
MSG_INFO_DESC="Description:"
MSG_INFO_COMPAT_DEBS="Compatible .deb (%s):"
MSG_WARN_NO_ARCH_DEBS="[!] .deb found, but NONE match your architecture (%s):"
MSG_ERR_NO_DEB_IN_REL="[X] No .deb packages found in this release."

# case / CLI Commands
MSG_USAGE_ADD="Usage: dbp -a|add [-y] <owner/repo | github_url>"
MSG_NO_TRACKED_PACKAGES="[!] No packages managed by debup yet."
MSG_DRY_UPGRADE_SUMMARY="[DRY-RUN] %d package(s) would be updated out of %d."
MSG_UPGRADE_SUMMARY="[✓] Done! %d package(s) updated out of %d."
MSG_NO_PKGS_REGISTERED="[!] No packages registered."

# list
MSG_COL_PACKAGE="PACKAGE"
MSG_COL_REPO="REPOSITORY"
MSG_COL_STATUS="STATUS"
MSG_STATUS_ACTIVE="active"
MSG_STATUS_PINNED="pinned"

# remove
MSG_USAGE_REMOVE="[!] Usage: dbp -r|remove [-d|--dry-run] <package_name>"
MSG_DRY_REMOVE_TRACK="[DRY-RUN] Would remove %s from tracking (%s)."
MSG_DRY_REMOVE_APT="[DRY-RUN] Would run: sudo apt-get remove --purge-y %s"
MSG_REMOVE_TRACK_SUCCESS="[✓] %s removed from debup tracking."
MSG_PROMPT_PURGE_APT="Do you also want to purge the package from the system using apt? [y/N]: "

# pin / unpin
MSG_USAGE_PIN="[!] Usage: dbp -p|pin <package_name>"
MSG_DRY_PIN="[DRY-RUN] Would run: sudo apt-mark hold %s"
MSG_PIN_SUCCESS="[✓] %s pinned successfully (updates blocked)."
MSG_USAGE_UNPIN="[!] Usage: dbp -n|unpin <package_name>"
MSG_DRY_UNPIN="[DRY-RUN] Would run: sudo apt-mark unhold %s"
MSG_UNPIN_SUCCESS="[✓] %s unpinned successfully (updates allowed)."

# Help / Usage
MSG_HELP_SEC_PKG="Package Operations:"
MSG_HELP_ADD="Install package from repo or URL"
MSG_HELP_UPGRADE="Update all tracked packages"
MSG_HELP_REMOVE="Untrack (and optionally purge) a package"
MSG_HELP_PIN="Hold or unhold package version"

MSG_HELP_SEC_DISCOVERY="Discovery & Info:"
MSG_HELP_SEARCH="Search repositories interactively"
MSG_HELP_INFO="Show package & architecture metadata"
MSG_HELP_LIST="List tracked packages and status"

MSG_HELP_SEC_CONFIG="Configuration:"
MSG_HELP_AUTH="Set GitHub Personal Access Token"

MSG_HELP_SEC_OPTIONS="Options:"
MSG_HELP_DRY="Simulate operations without making changes"
MSG_HELP_HELP="Show this help message"

# Defaultfallback
MSG_ERR_UNKNOWN_CMD="[X] Unknown command: %s"
MSG_RUN_HELP_HINT="Run '%s' for usage instructions."