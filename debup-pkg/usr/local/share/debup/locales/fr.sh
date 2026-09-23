#!/usr/bin/env bash

#Général
MSG_ENTER_PAT="Entrez votre jeton d'accès personnel GitHub (PAT) :"
MSG_ERR_EMPTY_TOKEN="[X] Erreur : Le jeton ne peut pas être vide."
MSG_TOKEN_SUCCESS="[✓] GITHUB_TOKEN configuré avec succès !"

# check_and_update
MSG_PINNED_SKIPPED="[ÉPINGLÉ] Le paquet %s est verrouillé (held). Mise à jour ignorée."
MSG_ERR_FETCH_RELEASE="[X] Erreur : Impossible de récupérer les infos de publication pour %s"
MSG_ERR_GH_API="[X] Réponse de l'API GitHub : %s"
MSG_PACKAGE_HEADER="==> Paquet :"
MSG_NEW_PACKAGE="Nouveau paquet"
MSG_NOT_INSTALLED="Non installé"
MSG_LATEST_VERSION="Dernière version :  %s"
MSG_ALREADY_UP_TO_DATE="[✓] Le paquet est déjà à jour !"
MSG_ERR_NO_COMPAT_DEB="[X] Erreur : Aucun fichier .deb compatible trouvé pour l'architecture (%s)."
MSG_DRY_WOULD_DOWNLOAD="[DRY-RUN] Téléchargerait : %s"
MSG_DRY_WOULD_INSTALL="[DRY-RUN] Installerait et suivrait : %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] Voulez-vous le télécharger et l'installer ? [o/N] :"
MSG_OP_CANCELED="[X] Opération annulée."
MSG_DOWNLOADING="[*] Téléchargement : %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Échec du téléchargement."
MSG_INSTALLING_PKG="[*] Installation du paquet (sudo requis)..."
MSG_SUCCESS_INSTALLED="[✓] Installation/mise à jour réussie de %s (%s)!"
MSG_ERR_INSTALL_FAILED="[X] Échec de l'installation."

# debup_search
MSG_USAGE_SEARCH="[!] Erreur : Utilisation : debup search <nom_outil>"
MSG_SEARCHING_GH=":: Recherche de '%s' sur GitHub..."
MSG_NO_REPOS_FOUND="[!] Aucun dépôt trouvé pour '%s'."
MSG_VERIFYING_DEBS=":: Vérification des paquets .deb disponibles..."
MSG_NO_DESC="Aucune description fournie"
MSG_NO_DEB_IN_REPOS="[!] Dépôts trouvés pour '%s', mais aucun ne contient de paquets .deb."
MSG_REPOS_FOUND_HEADER="Dépôts trouvés avec des paquets.deb :"
MSG_PROMPT_SELECT_PKG="Sélectionnez un paquet à installer [1-%d] (Entrée pour annuler) : "
MSG_INSPECTING_ASSETS=":: Examen des fichiers de la dernière version pour %s..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Erreur :Aucun paquet .deb trouvé dans la dernière version de ce dépôt."
MSG_CANNOT_INSTALL="Impossible d'installer via debup."
MSG_WARN_NO_ARCH_MATCH="[!] Attention : Des paquets .deb existent, mais aucun ne correspond à votre architecture (%s)."
MSG_PROMPT_FORCE_INSTALL="Voulez-vous quand même pour suivre l'installation ? [o/N] : "
MSG_INSTALL_CANCELED="Installation annulée."
MSG_COMPAT_PKG_DETECTED="[✓] Paquet compatible détecté. Ajout du dépôt..."

# debup_info
MSG_USAGE_INFO="[!] Erreur: Utilisation : debup info <propriétaire/dépôt>"
MSG_FETCHING_METADATA=":: Récupération des métadonnées pour %s..."
MSG_ERR_REPO_NOT_FOUND="[X] Erreur : Dépôt '%s' introuvable sur GitHub."
MSG_WARN_NO_RELEASES="[!] Le dépôt existe, mais aucune publication (release) n'est disponible."
MSG_INFO_NO_DESC="Aucune description fournie."
MSG_INFO_NONE="Aucune"
MSG_INFO_PKG="Paquet:"
MSG_INFO_LATEST="Dernière:"
MSG_INFO_STARS="Étoiles:"
MSG_INFO_LICENSE="Licence:"
MSG_INFO_DESC="Description:"
MSG_INFO_COMPAT_DEBS="Paquets .deb compatibles (%s) :"
MSG_WARN_NO_ARCH_DEBS="[!] .deb trouvés, mais AUCUN ne correspond à votre architecture (%s) :"
MSG_ERR_NO_DEB_IN_REL="[X] Aucun paquet .deb trouvé dans cette publication."

# case / CLI Commands
MSG_USAGE_ADD="Utilisation : debup add|install [-y] <propriétaire/dépôt | url_github>"
MSG_NO_TRACKED_PACKAGES="[!] Aucun paquet géré par debup pour le moment."
MSG_DRY_UPGRADE_SUMMARY="[DRY-RUN] %d paquet(s) seraient mis à jour sur %d."
MSG_UPGRADE_SUMMARY="[✓] Terminé !%d paquet(s) mis à jour sur %d."
MSG_NO_PKGS_REGISTERED="[!] Aucun paquet enregistré."

# list
MSG_COL_PACKAGE="PAQUET"
MSG_COL_REPO="DÉPÔT"
MSG_COL_STATUS="STATUT"
MSG_STATUS_ACTIVE="actif"
MSG_STATUS_PINNED="épinglé"

# remove
MSG_USAGE_REMOVE="[!] Utilisation : dbp -r|remove [-d|--dry-run] <nom_paquet>"
MSG_DRY_REMOVE_TRACK="[DRY-RUN] Supprimerait %s du suivi (%s)."
MSG_DRY_REMOVE_APT="[DRY-RUN] Exécuterait : sudo apt-get remove --purge -y%s"
MSG_REMOVE_TRACK_SUCCESS="[✓] %s retiré du suivi debup."
MSG_PROMPT_PURGE_APT="Voulez-vous aussi purger le paquet du système avec apt ? [o/N] : "

# pin / unpin
MSG_USAGE_PIN="[!] Utilisation : dbp -p|pin <nom_paquet>"
MSG_DRY_PIN="[DRY-RUN] Exécuterait : sudo apt-mark hold%s"
MSG_PIN_SUCCESS="[✓] %s épinglé avec succès (mises à jour bloquées)."
MSG_USAGE_UNPIN="[!] Utilisation : dbp -n|unpin <nom_paquet>"
MSG_DRY_UNPIN="[DRY-RUN] Exécuterait : sudo apt-mark unhold %s"
MSG_UNPIN_SUCCESS="[✓] %s désépinglé avec succès (mises à jour autorisées)."

# Help / Usage
MSG_HELP_SEC_PKG="Opérations sur les paquets :"
MSG_HELP_ADD="Installer un paquet depuis un dépôt ou une URL"
MSG_HELP_UPGRADE="Mettre à jour tous les paquets suivis"
MSG_HELP_REMOVE="Ne plus suivre (et purger facultativement) un paquet"
MSG_HELP_PIN="Verrouiller ou déverrouiller la version d'un paquet"

MSG_HELP_SEC_DISCOVERY="Recherche & Informations :"
MSG_HELP_SEARCH="Rechercher des dépôts de manière interactive"
MSG_HELP_INFO="Afficher les métadonnées et architectures supportées"
MSG_HELP_LIST="Lister les paquets suivis et leur statut"

MSG_HELP_SEC_CONFIG="Configuration :"
MSG_HELP_AUTH="Configurer le jeton d'accès personnel GitHub (PAT)"

MSG_HELP_SEC_OPTIONS="Options :"
MSG_HELP_DRY="Simuler les opérations sans appliquer de modifications"
MSG_HELP_HELP="Afficher ce message d'aide"

# Default fallback
MSG_ERR_UNKNOWN_CMD="[X] Commande inconnue : %s"
MSG_RUN_HELP_HINT="Exécutez '%s' pour voir les instructions d'utilisation."