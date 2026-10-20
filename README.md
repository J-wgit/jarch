# Jarch

A customized, riced Arch Linux, built as a re-runnable installer over a vanilla
Arch install. An archiso image comes later and wraps the same installer.

**Status:** phase 1 (installer MVP) and the `[jarch]` package repo. Theming is phase 2, ISO phase 4.

## Install

1. Install Arch with `archinstall` (minimal profile is fine). Create your user with sudo.
2. Log in as that user and run:

```bash
sudo pacman -S --needed git
git clone https://github.com/J-wgit/jarch ~/.jarch
~/.jarch/install/jarch-install            # base + desktop (Hyprland)
# or: ~/.jarch/install/jarch-install --profile kde        # KDE Plasma workstation
# or: ~/.jarch/install/jarch-install --profile desktop,dev
```

3. Reboot. SDDM starts; pick Hyprland or Plasma.

To make KDE the default on a machine, put `DEFAULT_PROFILES=(base kde)` in
`~/.config/jarch/jarch.conf`.

Keep `~/.jarch` where it is: your dotfiles are symlinks into it. To update, `git -C ~/.jarch pull && jarch-install`.

### Options

```
-p, --profile LIST   base (always), desktop, kde, dev
    --only LIST      run only some stages, e.g. --only dotfiles
    --skip LIST      e.g. --skip aur,services
-n, --dry-run        show what would happen, change nothing
-y, --yes            no prompts (passes --noconfirm)
-l, --list           list stages
```

Every stage is idempotent: re-running only does what's missing. Logs go to
`~/.local/state/jarch/install.log`.

## What it does

| Stage | |
|---|---|
| `00-preflight` | Checks it's Arch, you're not root, sudo and network work; turns on pacman Color, ParallelDownloads, ILoveCandy (and multilib if enabled); adds the `[jarch]` repo if it can reach it (above `[core]` once it's signed) |
| `10-packages` | `pacman -Syu --needed` everything in `profiles/<profile>/pacman` |
| `20-aur` | Installs `paru` (or `yay`) from the AUR if missing or broken: the prebuilt `-bin` first, falling back to a source build if it can't run against your pacman. Then installs `profiles/<profile>/aur` |
| `30-dotfiles` | Links `dotfiles/<pkg>` into `$HOME` with GNU stow (`--no-folding`). Anything in the way is moved to `~/.local/state/jarch/backup/<timestamp>/` first |
| `35-kconfig` | Applies the KDE settings in `profiles/<profile>/kconfig` with `kwriteconfig6`, only where the value differs |
| `40-services` | Enables `profiles/<profile>/services`, adds you to `groups`, sets your login shell |
| `50-tools` | Installs the packages in `profiles/<profile>/jarch` (`jarch-manager`, `jarch-install`, ...) from `[jarch]`, or builds them from `pkgbuilds/` if `[jarch]` isn't reachable |
| `90-post` | Refreshes user dirs and font cache, records what was installed |

## Layout

```
jarch.conf              settings (AUR helper, pacman tweaks, [jarch] repo, default profiles, login shell)
install/
  jarch-install         entry point
  lib/common.sh         logging, dry-run, list helpers
  stages/NN-name.sh     one file per stage, run in order
profiles/<name>/        pacman, aur, jarch, dotfiles, services, user-services, groups, kconfig (one item per line, # comments)
dotfiles/<pkg>/         stow packages: bash, starship, hypr, waybar, kitty, rofi, dunst, kde
pkgbuilds/<name>/       packages served from [jarch]: Jarch's tools and custom builds of upstream packages
tools/                  jarch-manager (moved in from J-wgit/Scripts), jarch-pkg, the jarch-install launcher
tests/                  CI tests (see below)
```

### Profiles

- **base**: CLI system: bash + starship prompt, your aliases and functions, neovim, paru, maintenance tools, NetworkManager.
- **desktop**: Hyprland, Waybar, Kitty, Rofi, Dunst, hyprlock/hypridle/hyprpaper, PipeWire, Bluetooth, SDDM, Thunar, Firefox, Nerd fonts.
- **kde**: a trimmed KDE Plasma workstation, FOSS only, KDE apps first. See below.
- **dev**: Python tooling, Node, Rust (rustup), Go, Docker, ctags, GitHub CLI.

Add a profile by creating `profiles/<name>/` with any of the list files.

### The KDE profile

Plasma (Wayland) without the full `plasma` group: no Discover, no Akonadi, no
games or demo apps. Apps, KDE wherever there's a good one:

| | |
|---|---|
| Terminal, files, editor | Konsole, Dolphin (+ git plugin, open-as-root), Kate |
| Documents, images | Okular, Gwenview, Spectacle, LibreOffice |
| Media | Elisa (music), Haruna (video) |
| Utilities | Ark, KCalc, KCharSelect, KFind, Filelight, Partition Manager, KSystemLog, System Monitor, Skanpage |
| Desktop | Network, audio, Bluetooth, power profiles, printing, firewall (ufw), SMART disk warnings, KDE Connect, KWallet with ssh passphrase prompts |
| Not KDE | Firefox (with Plasma integration), Thunderbird (KMail needs Akonadi), KeePassXC |

Settings (`profiles/kde/kconfig`): UK keyboard, Konsole as terminal with a Jarch
profile in JetBrainsMono Nerd Font so the starship prompt renders, Meta+Return
for a terminal and Meta+Q to close windows (as in the Hyprland profile), 4
virtual desktops, file search on names only, lock after 10 minutes, Breeze login
screen. Breeze Dark is applied once at your first Plasma login; after that the
look is yours to change.

KDE rewrites its own config files, so these settings are applied as individual
keys, not linked. Re-running `jarch-install` puts back any listed key you changed
in System Settings: change it in `profiles/kde/kconfig` instead, or run with
`--skip kconfig`. Only the Konsole profile, the Plasma login environment and the
first-login script are stow links (`dotfiles/kde`).

`desktop` and `kde` can be installed together; SDDM lets you pick a session.

### Machine-specific settings

- `~/.config/jarch/jarch.conf`: overrides `jarch.conf` (same syntax).
- `~/.bashrc.local`: extra shell config.
- `~/.config/hypr/local.conf`: monitors, keyboard layout, etc. (created empty; default layout is `gb`).

### Your shell

`dotfiles/bash` holds your `.bash_aliases` and `.bash-functions` unchanged, plus a
`.bashrc` that loads them and starship. `DOTFILES_DIR` points at `~/.jarch/dotfiles`,
so the `dots_stow_*` functions manage Jarch's dotfiles.

## The [jarch] package repo

Jarch's own tools are pacman packages, served from Jarch's own repository
alongside custom builds of open-source packages. Each lives in
`pkgbuilds/<name>/`; CI builds them and publishes `[jarch]` on every merge to
`main`, and `jarch-install` adds it to `/etc/pacman.conf`, so they update with
`pacman -Syu`.

- New Jarch tool: `jarch-pkg new <name>`, then list it in a profile's `jarch` file.
- Patched or reconfigured build of an Arch or AUR package: `jarch-pkg import <name> [--aur]`,
  edit the PKGBUILD, commit. Once the repo is signed, `[jarch]` sits above `[core]`, so
  your build replaces the official one (unsigned, it sits last and official packages win).
  `jarch-pkg outdated` and `jarch-pkg update <name>` keep forks current.

Packages are unsigned until you add a signing key. Details, signing and
hosting: [pkgbuilds/README.md](pkgbuilds/README.md). Repo settings
(`JARCH_REPO*`) are in `jarch.conf`.

## jarch-manager

Menu-driven and CLI system manager: updates, orphans, cache/log cleanup, services,
monitoring, package-list backup/restore, kernels, diagnostics. `jarch-manager help`.
See `tools/jarch-manager/README.md`.

## Tests

- `tests/offline-install.sh`: runs the real installer in a container with pacman,
  makepkg and systemctl stubbed: a dry run (must change nothing), an install, then a
  re-run (must be a no-op), and checks dotfiles, backups, services and pacman.conf.
- `tests/container-install.sh [profiles]`: a real install in an `archlinux` container,
  run twice, then `tests/verify.sh`. Set `JARCH_TEST_CA` behind a TLS-intercepting proxy.
- `tests/check-packages.sh`: every listed package exists in the Arch repos, and every
  `jarch` list entry has a PKGBUILD.

CI also builds every package into a signed `[jarch]` repo (throwaway key) and does the
base install from it; the offline test runs with `[jarch]` reachable and unreachable.
