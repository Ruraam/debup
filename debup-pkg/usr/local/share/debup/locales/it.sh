#!/usr/bin/env bash

# General
MSG_ENTER_PAT="Inserisci il tuo Personal Access Token (PAT) GitHub:"
MSG_ERR_EMPTY_TOKEN="[X] Errore: Il token non può essere vuoto."
MSG_TOKEN_SUCCESS="[✓] GITHUB_TOKEN configurato con successo!"

# check_and_update
MSG_PINNED_SKIPPED="[BLOCCATO]Il pacchetto %s è bloccato. Aggiornamento saltato."
MSG_ERR_FETCH_RELEASE="[X] Errore: Impossibile recuperare informazioni sulla release per %s"
MSG_ERR_GH_API="[X] Risposta API GitHub: %s"
MSG_PACKAGE_HEADER="==> Pacchetto:"
MSG_NEW_PACKAGE="Nuovo pacchetto"
MSG_NOT_INSTALLED="Non installato"
MSG_LATEST_VERSION="Ultima versione: %s"
MSG_ALREADY_UP_TO_DATE="[✓] Il pacchetto è già aggiornato!"
MSG_ERR_NO_COMPAT_DEB="[X] Errore: Nessun file .deb compatibile trovato per l'architettura (%s)."
MSG_DRY_WOULD_DOWNLOAD="[SIMULAZIONE] Scaricherebbe: %s"
MSG_DRY_WOULD_INSTALL="[SIMULAZIONE] Installerebbe e monitorerebbe: %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] Vuoiscaricarlo e installarlo? [s/N]: "
MSG_OP_CANCELED="[X] Operazione annullata."
MSG_DOWNLOADING="[*] Download in corso: %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Download non riuscito."
MSG_INSTALLING_PKG="[*] Installazione del pacchetto (richiesto sudo)..."
MSG_SUCCESS_INSTALLED="[✓] %s (%s) installato/aggiornato con successo!"
MSG_ERR_INSTALL_FAILED="[X] Installazione non riuscita."

# debup_search
MSG_USAGE_SEARCH="[!] Errore: Uso: dbp -s|search <nome_strumento>"
MSG_SEARCHING_GH=":: Ricerca di '%s' su GitHub..."
MSG_NO_REPOS_FOUND="[!] Nessun repository trovato per '%s'."
MSG_VERIFYING_DEBS=":: Verifica delle release .deb per i candidati..."
MSG_NO_DESC="Nessuna descrizione fornita"
MSG_NO_DEB_IN_REPOS="[!] Trovati repository per '%s', manessuno ha release .deb."
MSG_REPOS_FOUND_HEADER="Repository trovati con release .deb:"
MSG_PROMPT_SELECT_PKG="Seleziona un pacchetto da installare [1-%d] (Premi Invio per annullare): "
MSG_INSPECTING_ASSETS=":: Ispezione delle risorse dell'ultima releaseper %s..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Errore: Nessun pacchetto .deb trovato nell'ultima release di questo repository."
MSG_CANNOT_INSTALL="Impossibile installare tramite debup."
MSG_WARN_NO_ARCH_MATCH="[!] Avviso: Ipacchetti .deb esistono, ma nessuno sembra corrispondere alla tua architettura (%s)."
MSG_PROMPT_FORCE_INSTALL="Vuoi comunque procedere con l'installazione? [s/N]: "
MSG_INSTALL_CANCELED="Installazione annullata."
MSG_COMPAT_PKG_DETECTED="[✓] Pacchetto compatibile rilevato. Aggiunta del repository..."

# debup_info
MSG_USAGE_INFO="[!] Errore: Uso: dbp -i|nfo <proprietario/repo>"
MSG_FETCHING_METADATA=":: Recupero metadati per %s..."
MSG_ERR_REPO_NOT_FOUND="[X] Errore: Repository '%s' non trovato su GitHub."
MSG_WARN_NO_RELEASES="[!] Il repository esiste, ma non ha release pubblicate."
MSG_INFO_NO_DESC="Nessuna descrizione fornita."
MSG_INFO_NONE="Nessuno"
MSG_INFO_PKG="Pacchetto:"
MSG_INFO_LATEST="Ultima:"
MSG_INFO_STARS="Stelle:"
MSG_INFO_LICENSE="Licenza:"
MSG_INFO_DESC="Descrizione:"
MSG_INFO_COMPAT_DEBS="Compatibile .deb (%s):"
MSG_WARN_NO_ARCH_DEBS="[!] .deb trovato, ma NESSUNO corrisponde alla tua architettura (%s):"
MSG_ERR_NO_DEB_IN_REL="[X] Nessun pacchetto .deb trovato in questa release."

# case / CLI Commands
MSG_USAGE_ADD="Uso: dbp -a|add [-y]<proprietario/repo | url_github>"
MSG_NO_TRACKED_PACKAGES="[!]Nessun pacchetto ancora gestito da debup."
MSG_DRY_UPGRADE_SUMMARY="[SIMULAZIONE] %dpacchetto/i verrebbero aggiornati su %d."
MSG_UPGRADE_SUMMARY="[✓] Fatto! %d pacchetto/i aggiornati su %d."
MSG_NO_PKGS_REGISTERED="[!] Nessun pacchetto registrato."

# list
MSG_COL_PACKAGE="PACCHETTO"
MSG_COL_REPO="REPOSITORY"
MSG_COL_STATUS="STATO"
MSG_STATUS_ACTIVE="attivo"
MSG_STATUS_PINNED="bloccato"

# remove
MSG_USAGE_REMOVE="[!] Uso: dbp -r|remove [-d|--dry-run] <nome_pacchetto>"
MSG_DRY_REMOVE_TRACK="[SIMULAZIONE] Rimuoverebbe %s dal monitoraggio (%s)."
MSG_DRY_REMOVE_APT="[SIMULAZIONE] Eseguirebbe: sudo apt-get remove --purge -y %s"
MSG_REMOVE_TRACK_SUCCESS="[✓] %s rimosso dal monitoraggio di debup."
MSG_PROMPT_PURGE_APT="Vuoi anche eliminare completamente il pacchetto dal sistema usando apt? [s/N]: "

# pin/ unpin
MSG_USAGE_PIN="[!] Uso: dbp -p|pin <nome_pacchetto>"
MSG_DRY_PIN="[SIMULAZIONE] Eseguirebbe: sudo apt-markhold %s"
MSG_PIN_SUCCESS="[✓] %s bloccato con successo (aggiornamenti bloccati)."
MSG_USAGE_UNPIN="[!] Uso: dbp -n|unpin <nome_pacchetto>"
MSG_DRY_UNPIN="[SIMULAZIONE] Eseguirebbe: sudo apt-mark unhold%s"
MSG_UNPIN_SUCCESS="[✓] %s sbloccato con successo (aggiornamenti consentiti)."

# Help / Usage
MSG_HELP_SEC_PKG="Operazioni pacchetto:"
MSG_HELP_ADD="Installa pacchetto da repo o URL"
MSG_HELP_UPGRADE="Aggiorna tutti i pacchetti monitorati"
MSG_HELP_REMOVE="Rimuovi dal monitoraggio (e opzionalmente elimina) un pacchetto"
MSG_HELP_PIN="Blocca o sblocca versione pacchetto"

MSG_HELP_SEC_DISCOVERY="Ricerca & Info:"
MSG_HELP_SEARCH="Cerca repository in modo interattivo"
MSG_HELP_INFO="Mostra metadati del pacchetto e architettura"
MSG_HELP_LIST="Elenca pacchetti monitorati estato"

MSG_HELP_SEC_CONFIG="Configurazione:"
MSG_HELP_AUTH="Imposta GitHub Personal Access Token"

MSG_HELP_SEC_OPTIONS="Opzioni:"
MSG_HELP_DRY="Simula operazioni senza apportare modifiche"
MSG_HELP_HELP="Mostra questo messaggio di aiuto"

# Default fallback
MSG_ERR_UNKNOWN_CMD="[X] Comando sconosciuto: %s"
MSG_RUN_HELP_HINT="Esegui '%s' per le istruzioni sull'uso."