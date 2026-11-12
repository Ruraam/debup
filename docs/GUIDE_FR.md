# debup — Guide utilisateur et administrateur

**Le pont entre GitHub Releases et APT.** Ce guide présente l'installation, les commandes, la configuration, la vérification des paquets et la publication du dépôt APT.

- Projet : https://github.com/Ruraam/debup
- Versions : https://github.com/Ruraam/debup/releases
- Problèmes : https://github.com/Ruraam/debup/issues
- Licence : GPL-3.0

## 1. Présentation

debup est un outil CLI en Bash pour Debian et Ubuntu. Il relie :
- **APT**, les dépôts configurés sur le système ;
- **GitHub Releases**, les projets qui publient des fichiers Debian `.deb` compatibles.

Il recherche dans ces deux sources, installe les paquets via l'outillage Debian natif, suit les projets GitHub sélectionnés et vérifie leurs nouvelles versions.

**Important :** debup n'est ni un conteneur ni un sandbox. Un fichier `.deb` est installé comme un paquet natif. Ses scripts mainteneur peuvent s'exécuter avec les privilèges root.

## 2. Installation

### Prérequis

Le paquet déclare Bash (>= 4.0), curl et jq. Les opérations utilisent également l'outillage Debian (APT, dpkg, dpkg-deb, apt-mark) et des utilitaires courants comme sha256sum et awk.

Utilisez Debian/Ubuntu avec APT et dpkg. Les actions administratives nécessitent root, généralement via sudo ou doas.

### Installeur interactif

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

### Installation automatisée

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

L'installeur présente les méthodes disponibles. Lisez les choix et les avertissements de confiance avant de poursuivre. Pour une automatisation de production, inspectez l'installeur et épinglez la révision vérifiée plutôt que d'exécuter aveuglément une branche mobile.

### Mise à niveau

Installation APT :

```bash
sudo apt update
sudo apt upgrade debup
```

Installation depuis une release ou les sources :

```bash
dbp upgrade
```

Vérification :

```bash
command -v dbp
command -v debup
dbp help
```

## 3. Premiers pas

```bash
# Recherche APT et GitHub Releases
dbp search terminal

# Examiner les métadonnées et le contenu d'un paquet
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Installer et suivre un projet GitHub
dbp install Ruraam/Uraam

# Installer un paquet APT natif
dbp install ripgrep

# Vérifier les mises à jour (également l'action par défaut)
dbp

# Appliquer les mises à jour APT et GitHub suivies
dbp upgrade

# Prévisualiser une opération
dbp upgrade --dry-run

# Lister les sources suivies
dbp list
```

Pour choisir une release précise :

```bash
dbp install proprietaire/depot@vX.Y.Z
```

## 4. Référence des commandes

| Commande | Alias | Rôle |
|---|---|---|
| `install <owner/repo>` | `-i`, `-a` | Installer un paquet GitHub et suivre sa source |
| `install <paquet>` | `-i`, `-a` | Installer un paquet APT natif |
| `install <owner/repo>@<tag>` | — | Installer une release précise |
| `search <requête>` | `-s` | Rechercher dans APT et GitHub |
| `info <owner/repo>` | `-f` | Afficher métadonnées et assets compatibles |
| `inspect <owner/repo>` | `-I` | Inspecter le contenu et les scripts mainteneur |
| `update` | `-v`, sans argument | Vérifier les mises à jour |
| `upgrade` | `-u` | Appliquer les mises à jour disponibles |
| `list` | `-l` | Lister les sources suivies |
| `remove <paquet>` | `-r` | Purger un paquet et retirer son suivi |
| `pin <paquet>` | `-p` | Bloquer un paquet avec APT |
| `unpin <paquet>` | `-n` | Lever un blocage APT |
| `stats` | `-S` | Afficher l'état des paquets, caches et API |
| `token [PAT]` | `-t` | Configurer un token GitHub |
| `clean` | `-c` | Nettoyer les caches pris en charge |
| `help` | `-h` | Afficher l'aide |

Options courantes :
- `-d`, `--dry-run` : prévisualiser les actions compatibles sans appliquer les changements correspondants.
- `-y`, `--yes` : accepter les confirmations prises en charge pour une exécution non interactive.

La prise en charge dépend de la commande. Consultez `dbp help` sur la version installée.

## 5. Suivi des sources GitHub

Les associations entre paquets et sources suivies sont enregistrées dans :

```text
/etc/debup/sources.list
```

Format :

```text
<nom-du-paquet>|<proprietaire-github>/<depot-github>
```

Utilisez `dbp list` pour consulter les projets suivis, `dbp update` pour vérifier les nouvelles versions et `dbp upgrade` pour appliquer les mises à jour disponibles. `dbp remove <paquet>` purge le paquet via APT et supprime son entrée de suivi. Lisez attentivement la confirmation ; n'utilisez `--yes` que si l'action est voulue.

## 6. Inspection et intégrité

### Scripts mainteneur

Un paquet Debian peut contenir `preinst`, `postinst`, `prerm` et `postrm`. Ces scripts peuvent s'exécuter avec les privilèges administrateur pendant l'installation, la mise à niveau ou la suppression.

Avant d'installer un paquet inconnu :

```bash
dbp info proprietaire/depot
dbp inspect proprietaire/depot
```

L'inspection aide à examiner un paquet ; elle ne certifie pas son innocuité.

### Sommes SHA-256

Pour les téléchargements GitHub Releases, debup recherche les assets de checksum pris en charge et vérifie le paquet avant installation. L'installeur vérifie également les sommes des paquets téléchargés via le chemin d'installation directe depuis une release.

Une somme valide détecte une corruption ou une différence avec le fichier publié. Elle ne prouve pas à elle seule l'identité de l'éditeur si un attaquant peut remplacer le paquet et sa somme. Privilégiez les projets upstream de confiance et les signatures indépendantes lorsqu'elles existent.

### Sélection de l'architecture

La sélection se base sur l'architecture rapportée par dpkg et des alias courants :

| Architecture dpkg | Alias courants |
|---|---|
| `amd64` | `amd64`, `x86_64`, `x64` |
| `arm64` | `arm64`, `aarch64`, `arm64v8` |
| `armhf` | `armhf`, `armv7l` |
| `i386` | `i386`, `i686` |

Les paquets indépendants de l'architecture nommés `all` peuvent également être sélectionnés. Si plusieurs assets sont ambigus, debup doit s'arrêter plutôt que deviner.

## 7. Dry-run et sécurité APT

Exemples :

```bash
dbp install proprietaire/depot --dry-run
dbp upgrade --dry-run
dbp remove nom-du-paquet --dry-run
dbp clean --dry-run
```

Le dry-run peut effectuer des requêtes réseau/API en lecture seule. Ce n'est pas une simulation hors ligne complète. Pour un paquet GitHub, il ne télécharge pas le paquet et ne résout donc pas intégralement ses dépendances.

Pour les transactions concernées, debup simule le plan APT et refuse les opérations qui supprimeraient ou purgeraient des paquets installés. Le chemin d'installation réel utilise aussi `--no-remove` lorsque cela s'applique. Examinez toujours les opérations prévues et conservez des sauvegardes.

## 8. Configuration et chemins

| Chemin | Utilité |
|---|---|
| `/etc/debup/sources.list` | Associations des paquets GitHub suivis |
| `${XDG_CONFIG_HOME:-$HOME/.config}/debup/token` | Token GitHub utilisateur |
| `/etc/debup/debup.conf` | Configuration/token root lorsqu'il est configuré depuis root |
| `${XDG_CACHE_HOME:-$HOME/.cache}/debup/api` | Cache des réponses de l'API GitHub |
| `/usr/share/debup/locales` | Traductions CLI installées |
| `/usr/local/share/debup/locales` | Traductions locales/personnalisées si présentes |

Le token GitHub est facultatif ; les requêtes anonymes ont un quota plus faible. Ne publiez jamais de token dans les logs, captures d'écran ou rapports de bug. Pour les métadonnées publiques, n'accordez aucune permission inutile.

## 9. Publication du dépôt APT

Le pipeline de release comporte deux étapes :

1. Construire le paquet Debian et le joindre à la GitHub Release.
2. Pour une release stable (non pré-release), appeler le workflow réutilisable de publication APT après la construction du paquet.

Le publisher importe la clé de signature configurée et publie les métadonnées du dépôt. Le secret GitHub `GPG_PRIVATE_KEY` doit contenir la clé privée attendue par le workflow. Son empreinte primaire doit correspondre à celle épinglée dans l'installeur.

Le déclenchement manuel reste disponible, mais la publication normale d'une release stable ne dépend plus d'une requête séparée `gh workflow run`.

**La validation de bout en bout reste nécessaire :** une CI verte ne prouve pas à elle seule qu'un déploiement GitHub Pages réel, des métadonnées signées et une installation APT côté client ont réussi. Après la prochaine release stable, vérifiez le job publisher, le déploiement Pages, les métadonnées, la signature et une installation propre depuis un client.

## 10. Dépannage

### Commande introuvable

```bash
command -v dbp
command -v debup
```

Si aucune commande n'existe, vérifiez que l'installation s'est terminée et que le répertoire des binaires est dans `PATH`. Rouvrez le shell si nécessaire.

### Quota API GitHub atteint

Configurez un token facultatif :

```bash
dbp token
```

Suivez l'invite et ne partagez jamais le token.

### Aucun asset compatible

Consultez la release upstream. Vérifiez qu'elle contient un fichier `.deb` pour votre architecture ou un paquet indépendant `all`, avec un nom reconnu. debup évite de deviner en cas d'ambiguïté.

### Checksum absent ou invalide

Ne contournez pas l'échec à la légère. Vérifiez que la release publie une somme correspondant exactement au nom du fichier téléchargé. Si l'erreur persiste, arrêtez et contactez le mainteneur upstream.

### Transaction APT refusée

Examinez le plan simulé. Si APT prévoit de supprimer des paquets installés, debup refuse l'opération par sécurité. Corrigez les conflits de dépôts ou de dépendances au lieu de forcer une suppression inattendue.

### Aucun terminal interactif

Certaines invites adoptent volontairement une réponse négative par défaut sans TTY. N'utilisez `--yes` que pour des opérations préalablement examinées.

## 11. Limites et sécurité

- debup cible APT/dpkg ; ce n'est pas un gestionnaire de paquets RPM, Arch ou Alpine.
- L'hébergement sur GitHub ne rend pas automatiquement un projet fiable ou audité.
- Un paquet Debian natif peut modifier des fichiers système, installer des services et exécuter des scripts mainteneur en root.
- Les sommes SHA-256 vérifient les octets par rapport à la somme publiée, mais n'authentifient pas seules l'éditeur.
- La signature APT authentifie les métadonnées par rapport à la clé configurée. Protégez la clé privée et vérifiez l'empreinte épinglée.
- debup ne sandboxe pas les applications installées.
- La disponibilité d'un binaire dépend des mainteneurs upstream et du nommage de leurs assets.

En cas de doute : inspectez le paquet, vérifiez le projet upstream, examinez la transaction APT et conservez une sauvegarde récupérable.

---

*Ce guide décrit le comportement documenté du dépôt. Consultez toujours `dbp help` et les notes de version pour les changements propres à la version installée.*
