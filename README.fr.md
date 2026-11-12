<div align="center">

<img src="assets/debup-animated.svg" alt="debup" width="560">

# debup

### Le pont entre GitHub Releases et APT.

**Découvrir · Inspecter · Installer · Suivre · Mettre à jour**

Un gestionnaire de paquets léger en Bash qui relie les paquets Debian natifs aux fichiers `.deb` compatibles publiés sur GitHub.

<p>
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/v/release/Ruraam/debup?style=for-the-badge&color=16a34a" alt="Dernière version"></a>
<a href="https://github.com/Ruraam/debup/actions"><img src="https://img.shields.io/github/actions/workflow/status/Ruraam/debup/installer-validation.yml?branch=main&style=for-the-badge&label=CI" alt="CI"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/licence-GPL--3.0-2563eb?style=for-the-badge" alt="GPL-3.0"></a>
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"></a>
</p>

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md)

**[📘 Guide utilisateur (FR)](docs/GUIDE_FR.md)** · **[🇬🇧 User guide](docs/USER_GUIDE.md)** · [Versions](https://github.com/Ruraam/debup/releases) · [Problèmes](https://github.com/Ruraam/debup/issues)

</div>

---

## Pourquoi debup ?

L'écosystème Debian est fiable. GitHub Releases héberge des milliers de projets upstream. debup relie ces deux univers dans un workflow basé sur APT : découvrir les paquets compatibles, les inspecter, les installer nativement et suivre leurs mises à jour.

> **Ce n'est pas un sandbox :** les paquets GitHub `.deb` sont installés comme des paquets natifs. Leurs scripts mainteneur peuvent s'exécuter avec les privilèges root.

## ✨ Fonctionnalités

| Fonction | Description |
|---|---|
| 🔎 **Recherche unifiée** | Recherche simultanément dans APT et les GitHub Releases compatibles. |
| 📦 **Installation directe** | Installe depuis APT ou un dépôt GitHub (`owner/repo`). |
| 🎯 **Choix de release** | Cible un tag précis avec `owner/repo@tag`. |
| 🔍 **Inspection** | Consulte les métadonnées, le contenu et les scripts mainteneur. |
| 🔐 **Intégrité** | Vérifie les sommes SHA-256 publiées avant l'installation des paquets téléchargés. |
| 🛡️ **Garde-fous APT** | Simule les transactions concernées, refuse les plans de suppression et utilise `--no-remove` lorsque cela s'applique. |
| 🔄 **Suivi des mises à jour** | Vérifie les applications GitHub suivies avec les mises à jour APT natives. |
| 🧪 **Dry-run** | Prévisualise les opérations compatibles avant application. |
| 📌 **Verrouillage** | Utilise `apt-mark hold/unhold`. |
| 🌍 **Traductions** | CLI en EN, FR, DE, ES, IT et PT. |

## 🚀 Installation

**Installeur interactif (recommandé) :**

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

**Installation non interactive :**

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

L'installeur présente les méthodes disponibles et vérifie l'empreinte de la clé du dépôt APT ainsi que les sommes des paquets téléchargés. Lisez l'installeur et ses avertissements de confiance avant exécution.

**Mise à niveau via APT :**

```bash
sudo apt update
sudo apt upgrade debup
```

Pour les installations depuis une release ou les sources :

```bash
dbp upgrade
```

## 🖥️ Aperçu de l'installateur

L'installateur interactif propose trois méthodes : le dépôt APT officiel, la dernière release GitHub ou une compilation locale depuis les sources.

<div align="center">
  <img src="assets/installer_menu1.jpg" alt="Installateur interactif debup présentant les trois méthodes d'installation" width="560">
  <p><em>Choisissez la méthode adaptée à votre système.</em></p>
</div>

## ⚡ Démarrage rapide

```bash
# Rechercher dans les deux sources
dbp search terminal

# Inspecter un projet avant installation
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Installer et suivre un paquet GitHub
dbp install Ruraam/Uraam

# Installer un paquet APT natif
dbp install ripgrep

# Vérifier les mises à jour (action par défaut)
dbp

# Appliquer les mises à jour disponibles
dbp upgrade

# Prévisualiser sans appliquer les changements
dbp upgrade --dry-run

# Lister les sources GitHub suivies
dbp list
```

Pour installer une release précise : `dbp install proprietaire/depot@tag`.

## 🧭 Référence des commandes

| Commande | Alias | Action |
|---|---|---|
| `install <repo/paquet>` | `-i`, `-a` | Installer un paquet GitHub ou APT |
| `search <requête>` | `-s` | Rechercher dans APT et GitHub |
| `info <owner/repo>` | `-f` | Afficher les métadonnées et assets |
| `inspect <owner/repo>` | `-I` | Inspecter les fichiers et scripts |
| `update` | `-v`, sans argument | Vérifier les mises à jour |
| `upgrade` | `-u` | Appliquer les mises à jour |
| `list` | `-l` | Lister les sources suivies |
| `remove <paquet>` | `-r` | Purger et retirer le suivi |
| `pin <paquet>` / `unpin <paquet>` | `-p` / `-n` | Bloquer ou débloquer un paquet |
| `stats` | `-S` | État des paquets, caches et API |
| `token [PAT]` | `-t` | Configurer un token GitHub |
| `clean` | `-c` | Nettoyer les caches pris en charge |
| `help` | `-h` | Afficher l'aide |

Les options sont spécifiques aux commandes : `--dry-run` / `-d` prévisualise les opérations compatibles ; `--yes` / `-y` accepte les confirmations prises en charge. Lancez `dbp help` pour obtenir l'aide exacte de votre version.

## 🔐 Modèle de sécurité

- L'installeur APT épingle l'empreinte primaire GPG attendue avant de faire confiance à la clé du dépôt.
- Les téléchargements GitHub Releases sont comparés aux sommes SHA-256 publiées lorsque celles-ci sont disponibles.
- Une somme prouve la cohérence avec le fichier de checksum publié ; elle n'authentifie pas à elle seule l'éditeur.
- Les scripts mainteneur Debian peuvent s'exécuter en root. Inspectez les paquets inconnus avec `dbp inspect`.
- debup simule les transactions APT concernées et refuse les plans supprimant des paquets installés ; `--no-remove` est aussi utilisé lorsque cela s'applique.
- Les paquets installés sont natifs. **debup ne sandboxe pas les applications.**

Consultez **[Sécurité, vérification et limites](docs/GUIDE_FR.md#inspection-et-intégrité)** avant d'installer un logiciel provenant d'un éditeur inconnu.

## 📚 Documentation

- **[Guide utilisateur et administrateur (FR)](docs/GUIDE_FR.md)**
- **[User & administrator guide (EN)](docs/USER_GUIDE.md)**
- [Historique des versions](https://github.com/Ruraam/debup/releases)
- [GitHub Actions](https://github.com/Ruraam/debup/actions)
- [Signaler un problème](https://github.com/Ruraam/debup/issues)

## 📡 Publication du dépôt APT

Les releases GitHub stables sont configurées pour déclencher le publisher APT réutilisable après la construction du paquet Debian. Les pré-releases sont exclues. La publication nécessite le secret GitHub `GPG_PRIVATE_KEY`, dont l'empreinte primaire doit correspondre à celle épinglée dans l'installeur.

Une CI de validation verte ne prouve pas à elle seule qu'un déploiement Pages réel ou une installation cliente a réussi. La prochaine release stable devra valider toute la chaîne de publication, de signature et d'installation APT.

## 🧩 Compatibilité

debup cible Debian et les systèmes basés sur Ubuntu utilisant APT et dpkg. Le paquet debup est indépendant de l'architecture ; la sélection des binaires GitHub vérifie l'architecture de la machine et les alias de nommage pris en charge. La compatibilité avec d'autres dérivées peut varier.

## 🤝 Contribution

Les pull requests ciblées, rapports de bugs reproductibles et cas de test sont les bienvenus. Indiquez la distribution, l'architecture, la version de debup et la commande/sortie exacte lors d'un signalement.

## 📄 Licence

[GNU General Public License v3.0](LICENSE).

<div align="center">

**Conçu pour Debian. Connecté aux projets upstream.** 🐧

</div>
