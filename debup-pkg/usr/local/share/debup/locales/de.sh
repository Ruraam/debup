#!/usr/bin/env bash

# General
MSG_ENTER_PAT="Geben Sie Ihr GitHub Personal Access Token (PAT) ein:"
MSG_ERR_EMPTY_TOKEN="[X] Fehler: Das Token darf nicht leer sein."
MSG_TOKEN_SUCCESS="[✓]GITHUB_TOKEN erfolgreich konfiguriert!"

# check_and_update
MSG_PINNED_SKIPPED="[GEPINNT] Paket %s ist zurückgehalten. Aktualisierung wird übersprungen."
MSG_ERR_FETCH_RELEASE="[X] Fehler: Release-Informationen für %s konnten nicht abgerufen werden"
MSG_ERR_GH_API="[X] GitHub-API-Antwort: %s"
MSG_PACKAGE_HEADER="==> Paket:"
MSG_NEW_PACKAGE="Neues Paket"
MSG_NOT_INSTALLED="Nicht installiert"
MSG_LATEST_VERSION="Neueste Version: %s"
MSG_ALREADY_UP_TO_DATE="[✓] Paket ist bereits auf dem neuesten Stand!"
MSG_ERR_NO_COMPAT_DEB="[X] Fehler: Keine kompatible .deb-Datei für Architektur (%s) gefunden."
MSG_DRY_WOULD_DOWNLOAD="[SIMULATION] Würde herunterladen: %s"
MSG_DRY_WOULD_INSTALL="[SIMULATION] Würde installieren und überwachen: %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] Möchten Sie es herunterladen und installieren? [j/N]: "
MSG_OP_CANCELED="[X] Vorgang abgebrochen."
MSG_DOWNLOADING="[*] Wird heruntergeladen: %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Herunterladen fehlgeschlagen."
MSG_INSTALLING_PKG="[*] Paket wird installiert (sudoerforderlich)..."
MSG_SUCCESS_INSTALLED="[✓] %s (%s) erfolgreich installiert/aktualisiert!"
MSG_ERR_INSTALL_FAILED="[X] Installation fehlgeschlagen."

# debup_search
MSG_USAGE_SEARCH="[!] Fehler: Verwendung: dbp -s|search <tool_name>"
MSG_SEARCHING_GH=":: Auf GitHub nach '%s' suchen..."
MSG_NO_REPOS_FOUND="[!] Keine Repositories für '%s' gefunden."
MSG_VERIFYING_DEBS=":: .deb-Releases für Kandidaten werdenüberprüft..."
MSG_NO_DESC="Keine Beschreibung angegeben"
MSG_NO_DEB_IN_REPOS="[!]Repositories für '%s' gefunden, aber keines hat .deb-Releases."
MSG_REPOS_FOUND_HEADER="Gefundene Repositories mit .deb-Releases:"
MSG_PROMPT_SELECT_PKG="Wählen Sie ein Paket zum Installieren [1-%d] (Eingabetaste zum Abbrechen): "
MSG_INSPECTING_ASSETS=":: Dateien des neuesten Releases für %s werden überprüft..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Fehler: Keine .deb-Pakete im neuesten Release dieses Repositories gefunden."
MSG_CANNOT_INSTALL="Kann nicht über debup installiert werden."
MSG_WARN_NO_ARCH_MATCH="[!] Warnung: .deb-Pakete vorhanden, aber keines scheint Ihrer Architektur (%s) zu entsprechen."
MSG_PROMPT_FORCE_INSTALL="Möchten Sie trotzdem mit der Installation fortfahren? [j/N]:"
MSG_INSTALL_CANCELED="Installation abgebrochen."
MSG_COMPAT_PKG_DETECTED="[✓] Kompatibles Paket erkannt. Repository wird hinzugefügt..."

# debup_info
MSG_USAGE_INFO="[!] Fehler: Verwendung: dbp -i|nfo <besitzer/repo>"
MSG_FETCHING_METADATA=":: Metadaten für %s werden abgerufen..."
MSG_ERR_REPO_NOT_FOUND="[X] Fehler: Repository '%s' nicht auf GitHub gefunden."
MSG_WARN_NO_RELEASES="[!] Repository existiert, hat aber keine veröffentlichten Releases."
MSG_INFO_NO_DESC="Keine Beschreibung angegeben."
MSG_INFO_NONE="Keine"
MSG_INFO_PKG="Paket:"
MSG_INFO_LATEST="Neueste:"
MSG_INFO_STARS="Sterne:"
MSG_INFO_LICENSE="Lizenz:"
MSG_INFO_DESC="Beschreibung:"
MSG_INFO_COMPAT_DEBS="Kompatible .deb (%s):"
MSG_WARN_NO_ARCH_DEBS="[!] .deb gefunden, aber KEINES entspricht Ihrer Architektur (%s):"
MSG_ERR_NO_DEB_IN_REL="[X] Keine .deb-Pakete in diesem Release gefunden."

# case / CLICommands
MSG_USAGE_ADD="Verwendung: dbp -a|add [-y] <besitzer/repo | github_url>"
MSG_NO_TRACKED_PACKAGES="[!] Bisher keine Pakete von debup verwaltet."
MSG_DRY_UPGRADE_SUMMARY="[SIMULATION] %d Paket(e) von %d würdenaktualisiert werden."
MSG_UPGRADE_SUMMARY="[✓] Fertig! %d Paket(e) von %d aktualisiert."
MSG_NO_PKGS_REGISTERED="[!] Keine Pakete registriert."

# list
MSG_COL_PACKAGE="PAKET"
MSG_COL_REPO="REPOSITORY"
MSG_COL_STATUS="STATUS"
MSG_STATUS_ACTIVE="aktiv"
MSG_STATUS_PINNED="gepinnt"

# remove
MSG_USAGE_REMOVE="[!] Verwendung: dbp -r|remove [-d|--dry-run] <paket_name>"
MSG_DRY_REMOVE_TRACK="[SIMULATION] Würde %s aus der Überwachungentfernen (%s)."
MSG_DRY_REMOVE_APT="[SIMULATION] Würde ausführen: sudo apt-get remove --purge -y %s"
MSG_REMOVE_TRACK_SUCCESS="[✓] %s aus der debup-Überwachung entfernt."
MSG_PROMPT_PURGE_APT="Möchten Sie dasPaket auch mit apt vollständig vom System löschen (purge)? [j/N]: "

# pin / unpin
MSG_USAGE_PIN="[!] Verwendung: dbp -p|pin <paket_name>"
MSG_DRY_PIN="[SIMULATION] Würde ausführen: sudo apt-mark hold %s"
MSG_PIN_SUCCESS="[✓] %s erfolgreich gepinnt (Aktualisierungen blockiert)."
MSG_USAGE_UNPIN="[!] Verwendung: dbp-n|unpin <paket_name>"
MSG_DRY_UNPIN="[SIMULATION] Würde ausführen: sudo apt-mark unhold %s"
MSG_UNPIN_SUCCESS="[✓]Pin für %s erfolgreich aufgehoben (Aktualisierungen erlaubt)."

# Help / Usage
MSG_HELP_SEC_PKG="Paket-Operationen:"
MSG_HELP_ADD="Paket aus Repo oder URL installieren"
MSG_HELP_UPGRADE="Alleüberwachten Pakete aktualisieren"
MSG_HELP_REMOVE="Überwachung beenden (und optional Paket löschen)"
MSG_HELP_PIN="Paketversion festhalten oder freigeben"

MSG_HELP_SEC_DISCOVERY="Entdeckung& Info:"
MSG_HELP_SEARCH="Repositories interaktiv durchsuchen"
MSG_HELP_INFO="Paket- und Architektur-Metadaten anzeigen"
MSG_HELP_LIST="Überwachte Pakete und Status auflisten"

MSG_HELP_SEC_CONFIG="Konfiguration:"
MSG_HELP_AUTH="GitHub Personal Access Token festlegen"

MSG_HELP_SEC_OPTIONS="Optionen:"
MSG_HELP_DRY="Operationen simulieren, ohne Änderungen vorzunehmen"
MSG_HELP_HELP="Diese Hilfemeldung anzeigen"

# Default fallback
MSG_ERR_UNKNOWN_CMD="[X] Unbekannter Befehl: %s"
MSG_RUN_HELP_HINT="Führen Sie '%s'aus, um Bedienungshinweise anzuzeigen."