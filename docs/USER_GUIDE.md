# debup — User & Administrator Guide

**The bridge between GitHub Releases and APT.** This guide covers installation, daily use, configuration, package verification and APT repository publishing.

- Repository: https://github.com/Ruraam/debup
- Releases: https://github.com/Ruraam/debup/releases
- Issues: https://github.com/Ruraam/debup/issues
- License: GPL-3.0

## 1. Overview

debup is a Bash CLI for Debian/Ubuntu systems. It connects:
- **APT repositories** configured on the host;
- **GitHub Releases** that publish compatible Debian `.deb` assets.

It searches both sources, installs packages through the native Debian package toolchain, tracks selected GitHub projects and checks them for newer releases.

**Important:** debup is not a sandbox or container runtime. A downloaded `.deb` is installed as a native system package. Its maintainer scripts may execute with root privileges.

## 2. Installation

### Requirements

The package declares Bash (>= 4.0), curl and jq. Runtime operations also use the Debian toolchain (APT, dpkg, dpkg-deb, apt-mark) and standard utilities such as sha256sum and awk.

Use a Debian/Ubuntu-based system with APT and dpkg. Administrative actions require root privileges, normally via sudo or doas.

### Interactive installer

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

### Non-interactive installer

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

The installer offers the available installation methods. Review the displayed choices and trust prompts before proceeding. For production automation, inspect the installer and pin the revision you have reviewed rather than piping an unreviewed moving branch into a shell.

### Upgrade

APT installation:

```bash
sudo apt update
sudo apt upgrade debup
```

Release/source installation:

```bash
dbp upgrade
```

Verify:

```bash
command -v dbp
command -v debup
dbp help
```

## 3. Quick start

```bash
# Search APT and GitHub Releases
dbp search terminal

# Review project metadata and package contents
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Install a GitHub project and track it
dbp install Ruraam/Uraam

# Install a native APT package
dbp install ripgrep

# Check for updates (also the default action with no arguments)
dbp

# Apply APT and tracked GitHub updates
dbp upgrade

# Preview an operation
dbp upgrade --dry-run

# List tracked GitHub sources
dbp list
```

To select a specific upstream release:

```bash
dbp install owner/repository@vX.Y.Z
```

## 4. Command reference

| Command | Alias | Purpose |
|---|---|---|
| `install <owner/repo>` | `-i`, `-a` | Install a GitHub package and track its source |
| `install <package>` | `-i`, `-a` | Install a native APT package |
| `install <owner/repo>@<tag>` | — | Install a specific release |
| `search <query>` | `-s` | Search APT and GitHub |
| `info <owner/repo>` | `-f` | Show release metadata and compatible assets |
| `inspect <owner/repo>` | `-I` | Inspect package contents and maintainer scripts |
| `update` | `-v`, no argument | Check for available updates |
| `upgrade` | `-u` | Apply available upgrades |
| `list` | `-l` | List tracked sources |
| `remove <package>` | `-r` | Purge a package and remove its tracking entry |
| `pin <package>` | `-p` | Hold a package with APT |
| `unpin <package>` | `-n` | Release an APT hold |
| `stats` | `-S` | Show package, cache and API status |
| `token [PAT]` | `-t` | Configure a GitHub token |
| `clean` | `-c` | Clean supported temporary and package caches |
| `help` | `-h` | Show CLI help |

Common flags:
- `-d`, `--dry-run`: preview supported actions without applying the corresponding changes.
- `-y`, `--yes`: accept supported prompts for non-interactive use.

Flag support is command-specific. Run `dbp help` on the installed version for the authoritative CLI summary.

## 5. GitHub source tracking

Tracked source associations are stored in:

```text
/etc/debup/sources.list
```

Record format:

```text
<package-name>|<github-owner>/<github-repository>
```

Use `dbp list` to review tracked projects, `dbp update` to check for newer releases and `dbp upgrade` to apply available updates. `dbp remove <package>` purges the package through APT and removes its tracking record. Review the confirmation prompt; use `--yes` only when the operation is intended.

## 6. Package inspection and integrity

### Maintainer scripts

Debian packages may contain `preinst`, `postinst`, `prerm` and `postrm`. These scripts can run with administrative privileges during install, upgrade or removal.

Inspect unfamiliar packages before installation:

```bash
dbp info owner/repository
dbp inspect owner/repository
```

Inspection helps you review a package; it is not a safety certification.

### SHA-256 checksums

For GitHub Release downloads, debup resolves supported checksum assets and verifies the downloaded package before installation. The installer also verifies checksums for direct-release installation.

A matching checksum detects corruption or a mismatch against the published checksum file. It does **not** independently authenticate the publisher if an attacker can replace both the package and checksum. Prefer trusted upstream projects and independently authenticated signatures where available.

### Architecture matching

Asset selection uses the architecture reported by dpkg and recognized filename aliases:

| dpkg architecture | Common asset aliases |
|---|---|
| `amd64` | `amd64`, `x86_64`, `x64` |
| `arm64` | `arm64`, `aarch64`, `arm64v8` |
| `armhf` | `armhf`, `armv7l` |
| `i386` | `i386`, `i686` |

Architecture-independent assets named `all` may also be selected. Naming conventions differ between upstream projects. If an asset cannot be identified unambiguously, debup should stop rather than guess.

## 7. Dry-run and APT transaction safety

Examples:

```bash
dbp install owner/repository --dry-run
dbp upgrade --dry-run
dbp remove package-name --dry-run
dbp clean --dry-run
```

Dry-run may still make read-only network/API requests. It is not a full offline simulation. A GitHub package dry-run does not download the package and therefore cannot fully resolve its dependencies.

For relevant APT transactions, debup simulates the plan and refuses operations that would remove or purge installed packages. The actual installation path also uses APT's `--no-remove` safeguard where applicable. Always review transaction output and keep system backups.

## 8. Configuration and data paths

| Path | Purpose |
|---|---|
| `/etc/debup/sources.list` | Tracked GitHub package/source associations |
| `${XDG_CONFIG_HOME:-$HOME/.config}/debup/token` | User-level GitHub token |
| `/etc/debup/debup.conf` | Root-level configuration/token location when configured by a root invocation |
| `${XDG_CACHE_HOME:-$HOME/.cache}/debup/api` | GitHub API response cache |
| `/usr/share/debup/locales` | Installed CLI translations |
| `/usr/local/share/debup/locales` | Local/custom translations when present |

A GitHub token is optional. Anonymous API requests have a lower rate limit. Do not share tokens in logs, screenshots or issue reports. Use no unnecessary token permissions for public metadata access.

## 9. APT repository publishing

The release pipeline has two stages:

1. Build the Debian package and attach it to the GitHub Release.
2. For a stable (non-prerelease) release, call the reusable APT publisher after the package build completes.

The APT publisher imports the configured signing key and publishes repository metadata. The repository secret `GPG_PRIVATE_KEY` must contain the private key expected by the workflow. Its primary fingerprint must match the fingerprint pinned by the installer.

Manual workflow dispatch remains available, but normal stable-release publishing no longer depends on a separate `gh workflow run` dispatch request.

**End-to-end validation still matters:** a green validation CI run does not by itself prove that a real GitHub Pages deployment, signed repository metadata and client-side APT installation succeeded. After the next stable release, verify the publisher job, Pages deployment, repository metadata, signature and a clean client install.

## 10. Troubleshooting

### Command not found

```bash
command -v dbp
command -v debup
```

If neither command exists, confirm that installation completed and that its binary directory is in `PATH`. Reopen the shell if necessary.

### GitHub API rate limit

Configure an optional token:

```bash
dbp token
```

Follow the prompt and never publish the token.

### No compatible release asset

Check the upstream release page. Confirm that it contains a `.deb` for your architecture or an architecture-independent `all` package, using a recognized filename. debup intentionally avoids guessing when assets are ambiguous.

### Checksum missing or invalid

Do not casually bypass the failure. Confirm that the upstream release publishes a checksum asset for the exact downloaded filename. If the mismatch persists, stop and contact the upstream maintainer.

### APT transaction refused

Review the simulated transaction. If APT proposes removing installed packages, debup refuses the operation as a safety measure. Resolve repository or dependency conflicts rather than forcing an unexpected removal.

### No TTY

Some prompts default to a safe negative answer when no interactive terminal is available. Use supported `--yes` flags only for operations you have already reviewed.

## 11. Limitations and security notes

- debup targets APT/dpkg-based systems; it is not a package manager for RPM, Arch or Alpine.
- GitHub hosting does not make an upstream project trusted or audited.
- Native `.deb` packages can modify system files, install services and execute root maintainer scripts.
- SHA-256 checksums verify bytes against a published checksum; they do not authenticate the publisher on their own.
- APT signatures authenticate repository metadata against the configured signing key. Protect the private key and verify the pinned fingerprint.
- debup does not sandbox installed applications.
- Binary availability depends on upstream maintainers and their release asset naming.

When in doubt: inspect the package, verify the upstream project, review the APT transaction and keep a recoverable backup.

---

*This guide describes documented repository behavior. Check `dbp help` and the release notes for version-specific changes.*
