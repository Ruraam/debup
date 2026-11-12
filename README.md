<div align="center">

<img src="assets/debup-animated.svg" alt="debup" width="560">

# debup

### The bridge between GitHub Releases and APT.

**Discover · Inspect · Install · Track · Update**

A lightweight Bash package manager connecting native Debian packages with compatible `.deb` releases from GitHub.

<p>
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/v/release/Ruraam/debup?style=for-the-badge&color=16a34a" alt="Latest release"></a>
<a href="https://github.com/Ruraam/debup/actions"><img src="https://img.shields.io/github/actions/workflow/status/Ruraam/debup/installer-validation.yml?branch=main&style=for-the-badge&label=CI" alt="CI"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-2563eb?style=for-the-badge" alt="GPL-3.0"></a>
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"></a>
</p>

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md)

**[📘 User guide](docs/USER_GUIDE.md)** · **[🇫🇷 Guide français](docs/GUIDE_FR.md)** · [Releases](https://github.com/Ruraam/debup/releases) · [Issues](https://github.com/Ruraam/debup/issues)

</div>

---

## Why debup?

Debian's package ecosystem is dependable. GitHub Releases host thousands of upstream projects. debup brings both worlds into one APT-oriented workflow: discover compatible packages, inspect them, install them natively and track their updates.

> **Not a sandbox:** GitHub `.deb` packages are installed as native system packages. Their maintainer scripts may run with root privileges.

## ✨ Highlights

| Feature | Description |
|---|---|
| 🔎 **Unified search** | Search APT and compatible GitHub Release assets together. |
| 📦 **Direct install** | Install from APT or a GitHub repository (`owner/repo`). |
| 🎯 **Release selection** | Pin an install to a specific tag with `owner/repo@tag`. |
| 🔍 **Package inspection** | Review release metadata, package contents and maintainer scripts. |
| 🔐 **Integrity checks** | Verify published SHA-256 checksums before installing downloaded packages. |
| 🛡️ **APT safeguards** | Simulate relevant transactions, reject removal plans and use `--no-remove` where applicable. |
| 🔄 **Update tracking** | Check tracked GitHub applications alongside native APT updates. |
| 🧪 **Dry-run** | Preview supported operations before applying changes. |
| 📌 **Package holds** | Use native `apt-mark hold/unhold`. |
| 🌍 **Localization** | CLI translations: EN, FR, DE, ES, IT and PT. |

## 🚀 Install

**Interactive installer (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

**Non-interactive installer:**

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

The installer presents the available methods and validates the APT repository key fingerprint and release-package checksums. Review the installer and its trust prompts before running it.

**Upgrade via APT:**

```bash
sudo apt update
sudo apt upgrade debup
```

For release/source installations:

```bash
dbp upgrade
```

## ⚡ Quick start

```bash
# Search both package sources
dbp search terminal

# Inspect a project before installation
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Install and track a GitHub package
dbp install Ruraam/Uraam

# Install a native APT package
dbp install ripgrep

# Check for updates (also the default action)
dbp

# Apply available updates
dbp upgrade

# Preview without applying changes
dbp upgrade --dry-run

# List tracked GitHub sources
dbp list
```

Install a specific upstream release with `dbp install owner/repository@tag`.

## 🧭 Command reference

| Command | Alias | Action |
|---|---|---|
| `install <repo/package>` | `-i`, `-a` | Install a GitHub or APT package |
| `search <query>` | `-s` | Search APT and GitHub |
| `info <owner/repo>` | `-f` | Show release metadata and assets |
| `inspect <owner/repo>` | `-I` | Inspect package files and scripts |
| `update` | `-v`, no argument | Check for updates |
| `upgrade` | `-u` | Apply updates |
| `list` | `-l` | List tracked sources |
| `remove <package>` | `-r` | Purge and untrack a package |
| `pin <package>` / `unpin <package>` | `-p` / `-n` | Hold or unhold a package |
| `stats` | `-S` | Show package, cache and API status |
| `token [PAT]` | `-t` | Configure a GitHub token |
| `clean` | `-c` | Clean supported caches |
| `help` | `-h` | Display help |

Global options are command-specific: `--dry-run` / `-d` previews supported operations; `--yes` / `-y` accepts supported prompts. Run `dbp help` for the exact CLI help of your installed version.

## 🔐 Security model

- The APT installer pins the expected primary GPG fingerprint before trusting the repository key.
- GitHub Release downloads are checked against published SHA-256 checksums when supported.
- A checksum proves consistency with the published checksum file; it does not independently authenticate the publisher.
- Debian maintainer scripts may execute as root. Inspect unfamiliar packages with `dbp inspect`.
- debup simulates relevant APT transactions and refuses plans that remove installed packages; `--no-remove` is also used where applicable.
- Installed packages are native system packages. **debup does not sandbox applications.**

See **[Security, verification and limitations](docs/USER_GUIDE.md#package-inspection-and-integrity)** before installing software from an unfamiliar publisher.

## 📚 Documentation

- **[Complete user & administrator guide (EN)](docs/USER_GUIDE.md)**
- **[Guide utilisateur et administrateur (FR)](docs/GUIDE_FR.md)**
- [Release history](https://github.com/Ruraam/debup/releases)
- [GitHub Actions](https://github.com/Ruraam/debup/actions)
- [Issue tracker](https://github.com/Ruraam/debup/issues)

## 📡 APT repository publishing

Stable GitHub Releases are configured to trigger the reusable APT publisher after the Debian package build. Prereleases are excluded. Publishing requires the repository secret `GPG_PRIVATE_KEY`, whose primary fingerprint must match the value pinned in the installer.

A green validation CI run does not by itself prove a real Pages deployment or client installation. The next stable release must validate the complete publishing, signature and APT client path.

## 🧩 Compatibility

debup targets Debian and Ubuntu-based systems using APT and dpkg. The debup package itself is architecture-independent; GitHub binary selection checks the host architecture and supported asset-name aliases. Compatibility with other Debian-derived environments can vary.

## 🤝 Contributing

Focused pull requests, reproducible bug reports and test cases are welcome. Include your distribution, architecture, debup version and exact command/output when reporting a problem.

## 📄 License

[GNU General Public License v3.0](LICENSE).

<div align="center">

**Built for Debian. Connected to upstream.** 🐧

</div>
