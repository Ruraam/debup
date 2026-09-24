<div align="center">
 
<img src="https://api.iconify.design/lucide:package-check.svg?color=%23d70a53&width=130&height=130" alt="debup logo" />
<h1>debup</h1>
<p><strong>The AUR-like CLI package manager for Debian/Ubuntu-based distributions,Raspberry Pi, Docker, WSL & Android Linux Terminals (AVF, Proot debian/ubuntu).</strong></p>
<p>Search, discover, track, install, and upgrade <code>.deb</code> packages directly from GitHub Releases via <strong>APT</strong>.</p>
<p><em>No PPAs, no bloated sandboxes, no third-party repositories — just native <code>.deb</code> binaries fetched straight from upstream.
Easy installation with <a href="#option-1-apt-repository-recommended">APT repository</a> or <a href="#option-2-quick-one-liner">One-line installer</a>.</em></p>
  
</div>

<br/>

<div align="center">
<a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="GPL v3"></a> &nbsp;
<a href="https://debian.org"><img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu-red.svg" alt="Platform"></a> &nbsp;
<ahref="#"><img src="https://img.shields.io/badge/Arch-all%20(any)-orange.svg" alt="Arch"></a> &nbsp;
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/Language-Bash-4EAA25.svg" alt="Bash"></a>
</div>

<div align="center">
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/v/release/Ruraam/debup?color=brightgreen" alt="Release"></a> &nbsp;
<a href="#"><img src="https://img.shields.io/badge/Package_Size-6.24_Ko-success.svg" alt="Size"></a> &nbsp;
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/downloads/Ruraam/debup/total?color=blueviolet" alt="Total Downloads"></a>
</div>

<br/>

<div align="center">

<a href="README.md"><img src="https://api.iconify.design/circle-flags:gb.svg" width="16" height="16" alt="English" style="vertical-align: middle;"> English</a> &nbsp;•&nbsp;
<a href="README.fr.md"><img src="https://api.iconify.design/circle-flags:fr.svg" width="16" height="16" alt="Français" style="vertical-align: middle;"> Français</a> &nbsp;•&nbsp;
<a href="README.es.md"><img src="https://api.iconify.design/circle-flags:es.svg" width="16" height="16" alt="Español" style="vertical-align: middle;"> Español</a>

</div>

<div align="center">

| [Usage](https://github.com/Ruraam/debup/tree/main#%EF%B8%8F-usage) | [GitHub Token](https://github.com/Ruraam/debup/blob/main/README.md#-configure-a-github-token-optionnal--dbp-token-) | [Search & Install](https://github.com/Ruraam/debup/tree/main#-discover-search--install-packages--dbp-search) | [Uninstallation](https://github.com/Ruraam/debup/tree/main#%EF%B8%8F-uninstallation) |
| :---: | :---: | :---: | :---: |
| [Configuration](https://github.com/Ruraam/debup/blob/main/README.md#%EF%B8%8F-configuration) | [Screenshots](https://github.com/Ruraam/debup/tree/main#screenshots) | [Changelog](https://github.com/Ruraam/debup/releases) | [License](LICENSE) |
</div>

---

## <img src="https://camo.githubusercontent.com/2d3f8510295d6086cf513dc08de9138bcab9ddfd73e45368011bee2a5a44bd84/68747470733a2f2f6170692e69636f6e6966792e64657369676e2f6c75636964653a7061636b6167652d636865636b2e7376673f636f6c6f723d2532336437306135332677696474683d313330266865696768743d313330" width="27"> debup [ `dbp` ] - The Missing Bridge Between GitHub & APT

Missing the AUR convenience on Debian/Ubuntu? **debup** turns GitHub Releases into your personal rolling third-party repository.
**Discover, inspect, install, and update Debian packages directly from GitHub Releases with the simplicity of `apt`.**

## ✨ Core Features
🔍 **Discover** [`dbp -s <query>`] :
* Find tools and applications directly on GitHub without leaving your terminal, pre-filtered for Debian-compatible repositories.
* Supports release targeting during search & info inspections: fetch and query exact tags directly via GitHub API's `/releases/tags/...` endpoint.

📦 **Direct Add** [`dbp -a <owner/repo>`]:
* No need to hunt down release URLs. Point to any repository, and debup detects, matches your architecture (`amd64` / `arm64`), downloads, and installs the right `.deb`.
* Supports version pins on installation: `dbp -a owner/repo@vX.Y.Z`

ℹ️ **Inspect** [`dbp -i <owner/repo>`]:
* Preview metadata before touching your system (stars, license, description, latest release, asset architecture compatibility).

🔄 **Native APT Lifecycle**:
* Seamlessly install, update [`dbp -u `], and remove [`dbp -r`] tracked packages using your system's native APT engine.

⚡ **High-Rate API Tracking** [`dbp -t`]:
* Securely store a personal GitHub token (`chmod 600`) to unlock 5,000 req/h for heavy searches and automated background update checks.

**Native Bash completion**:
* Autocompletion support for both `debup` and the `dbp` alias, featuring context-aware dynamic package suggestions for `remove`, `pin`, and `unpin`.

**🛡️ Package Pinning** (`apt-mark hold`)
* **Freeze package updates :** Lock specific packages to their current version using the `pin` (or `hold`) command to prevent unwanted updates.
* **Unfreeze updates :** Restore automatic updates anytime with `unpin` (or `unhold`).
* **Native APT integration :** Relies directly on Debian's standard `apt-mark` mechanism under the hood, ensuring 100% consistency with native system tools.

## 🎯 Smart Asset Detection

`debup` automatically picks the right `.deb` binary from GitHub Releases without guesswork:

***Flexible Architectures:** Matches standard & alias names:
* **x86_64:** `amd64`, `x86_64`, `x86-64`, `x64`, `all`
* **ARM64:** `arm64`, `aarch64`, `armv8`, `arm64v8`, `all`
* **Cross-Architecture Protection:** Actively filters out conflicting assets (e.g., prevents downloading `arm64` on `amd64` machines).
* **Distro Prioritization:** Prefers distro-specific builds (`debian` vs `ubuntu`) when multiple compatible packages are published.
* **Safe Fallback:** Cleanly aborts with an explicit warning if no compatible package exists for your CPU architecture.

---

## 📦 Installation

### ⚡ Quick Interactive Setup

Run the automated installer wizard to choose your preferred setup method (APT Repository, Latest Release, or Build from source):
```bash
curl -sSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```
---
*(Or choose one of the manual installation methods below)*

### Option 1: APT Repository (Recommended)
*To install `debup` and receive automatic updates through APT:*

1. Install prerequisites
```bash
sudo apt update && sudo apt install -y curl gpg
```
2. **Create the keyrings directory**
```bash
sudo install -m 0755 -d /etc/apt/keyrings
```
3. **Download and install the GPG signing key**
```bash
sudo curl -fsSL https://ruraam.github.io/debup/debup.gpg -o /etc/apt/keyrings/debup.gpg
```
4. **Add the official debup repository**
```bash
echo "deb [signed-by=/etc/apt/keyrings/debup.gpg] https://ruraam.github.io/debup/ stable main" | sudo tee /etc/apt/sources.list.d/debup.list
```
5. **Install debup**
```bash
sudo apt update && sudo apt install debup
```

### Option 2: Quick One-Liner
*If you just want to run the deb package installation directly via curl and apt:*

```bash
curl -fsSL https://github.com/Ruraam/debup/releases/latest/download/debup_3.4.1_all.deb -o /tmp/debup.deb && sudo apt-get install -y /tmp/debup.deb && rm -f /tmp/debup.deb
```

### 🛠️ Build it yourself from source
*If you prefer to inspect the source code and build the `.deb` package manually:**

1. **Clone the repository:**
```bash
git clone https://github.com/Ruraam/debup.git
cd debup
```
2. **Ensure proper file permissions:**
```bash
chmod 755 debup-pkg/DEBIAN/postinst debup-pkg/DEBIAN/postrm
chmod 755 debup-pkg/usr/local/bin/debup
```
3. **Build the `.deb` package:**
```bash
dpkg-deb --build --root-owner-group debup-pkg debup.deb
```
4. **Install it:**

Via Apt (recommended for dependencies):
```bash
sudo apt install -y ./debup.deb
```
or

Via dpkg:
```bash
sudo dpkg -i debup.deb
```

---

### 🔑 Configure a GitHub Token (optional) [ `dbp token` ]

By default, GitHub limits anonymous requests to 60 requests/hour. Adding a token increases this limit to 5000 requests/hour.

**1.Generate a token:**
Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic) > Generate new token (no scopes/permissions needed, leave everything unchecked).

**2.Link it to debup:**
```bash
dbp token
```
Paste your token and confirm. That's it!

`debup` will automatically detect and use it, boosting your limit to 5,000 requests per hour.

> ***🔒 Security Note:** Your token is securely stored in `/etc/debup/debup.conf` with restricted permissions (`chmod600`), ensuring only root can read it.*

---

## 🛠️ Usage

### Package Management
**Add a repository to install `.deb` & track:**
```bash
dbp -a <owner>/<repo>
```
for exemple:
```bash
dbp -a Ruraam/Uraam
```

**List tracked repositories**
```bash
dbp -l
```
**Remove a tracked repository**
```bash
dbp -r <package-name>
```

Prevent an app from updating**
```bash
dbp -p <package-name>
```
**Allow an app to update again**
```bash
dbp -n <package-name>
```


### Package Updates/Upgrade
**Download and upgrade tracked packages with confirmation (with & without APT repository)**
```bash
dbp -u [-y]
```
**Update debup via APT repository:**
```bash
sudo apt update && sudo apt upgrade debup
```

### 🔍 Discover, Search & Install Packages [ `dbp search`] 

Find & discover any GitHub project providing .deb packages compatible with your architecture and install it in one click:
Search informations on a repository:
```bash
dbp -i <owner>/<repo>
```
##### Example: dbp -i Ruraam/Uraam

```bash
dbp -s <keyword>
```
##### Example: [ `dbp -s uraam`] 
**How it works:**

Enter the package number from the list and press Enter. debup downloads the matching .deb, installs it via apt, and automatically adds it to your tracking list for future updates.

<p align="center">
<img src="/assets/debup_search1.png" width="200"> <img src="/assets/debup_search2.png" width="200"> <img src="/assets/debup_search3.png" width="200"></p>

---

## Short CLI flag aliases: Standard single-letter POSIX flags for streamlined terminal workflows:
[-a : add / install] [-u : update / upgrade] [-r : remove] [-p : pin] [-n : unpin] [-s : search] [-i : info / show] [-l :list] [-t : token / auth]

>|
>**💡 Tip:** Combine official repos and GitHub releases by aliasing `sudo apt update && sudo apt upgrade -y && dbp upgrade` in your `~/.bashrc`.
>|

---

## ⚙️ Configuration

**Tracked sources are stored in:** `/etc/debup/sources.list`

**Format:** `<package-name>|<github-user>/<github-repo>`

**Github Token is stored in:** `/etc/debup/debup.conf`

---

## 🗑️ Uninstallation
**Remove package sudo**
```bash
dbp -r debup [-y]
```
Prompted for purge configuration or not.

or
```bash
sudo apt remove debup [-y]
```
**Remove package and clean configuration**
```bash
sudo apt --purge debup [-y]
```

---

## Screenshots
<p align="center">
<img src="/assets/debup_1.png" width="400"> <img src="/assets/debup_2.png" width="400"> <img src="/assets/debup3.png" width="400"> <img src="/assets/debup4.png" width="400"></p>

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

---
> How to install .deb packages downloaded from Github on Debian Ubuntu based
> 
> How to automatically update .deb packages downloaded from GitHub on Debian Ubuntu based

