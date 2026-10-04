# Jarch

A customized, riced Arch Linux, built as a re-runnable installer over a vanilla
Arch install. An archiso image comes later and wraps the same installer.

**Status:** phase 1 (installer MVP). Theming is phase 2, packaging phase 3, ISO phase 4.

## Install

1. Install Arch with `archinstall` (minimal profile is fine). Create your user with sudo.
2. Log in as that user and run:

```bash
sudo pacman -S --needed git
git clone https://github.com/J-wgit/jarch ~/.jarch
~/.jarch/install/jarch-install            # base + desktop
# or: ~/.jarch/install/jarch-install --profile desktop,dev
```

3. Reboot. SDDM starts; pick Hyprland.

Keep `~/.jarch` where it is: your dotfiles are symlinks into it. To update, `git -C ~/.jarch pull && jarch-install`.

### Options

```
-p, --profile LIST   base (always), desktop, dev
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
| `00-preflight` | Checks it's Arch, you're not root, sudo and network work; turns on pacman Color, ParallelDownloads, ILoveCandy (and multilib if enabled) |
| `10-packages` | `pacman -Syu --needed` everything in `profiles/<profile>/pacman` |
| `20-aur` | Installs `paru` (or `yay`) from the AUR if missing or broken: the prebuilt `-bin` first, falling back to a source build if it can't run against your pacman. Then installs `profiles/<profile>/aur` |
| `30-dotfiles` | Links `dotfiles/<pkg>` into `$HOME` with GNU stow (`--no-folding`). Anything in the way is moved to `~/.local/state/jarch/backup/<timestamp>/` first |
| `40-services` | Enables `profiles/<profile>/services`, adds you to `groups`, sets your login shell |
| `50-tools` | Installs `jarch-manager` and links `jarch-install` into `/usr/local/bin` |
| `90-post` | Refreshes user dirs and font cache, records what was installed |

## Layout

```
jarch.conf              settings (AUR helper, pacman tweaks, default profiles, login shell)
install/
  jarch-install         entry point
  lib/common.sh         logging, dry-run, list helpers
  stages/NN-name.sh     one file per stage, run in order
profiles/<name>/        pacman, aur, dotfiles, services, user-services, groups (one item per line, # comments)
dotfiles/<pkg>/         stow packages: bash, starship, hypr, waybar, kitty, rofi, dunst
tools/jarch-manager/    Arch system manager (moved in from J-wgit/Scripts)
tests/                  CI tests (see below)
```

### Profiles

- **base**: CLI system: bash + starship prompt, your aliases and functions, neovim, paru, maintenance tools, NetworkManager.
- **desktop**: Hyprland, Waybar, Kitty, Rofi, Dunst, hyprlock/hypridle/hyprpaper, PipeWire, Bluetooth, SDDM, Thunar, Firefox, Nerd fonts.
- **dev**: Python tooling, Node, Rust (rustup), Go, Docker, ctags, GitHub CLI.

Add a profile by creating `profiles/<name>/` with any of the list files.

### Machine-specific settings

- `~/.config/jarch/jarch.conf`: overrides `jarch.conf` (same syntax).
- `~/.bashrc.local`: extra shell config.
- `~/.config/hypr/local.conf`: monitors, keyboard layout, etc. (created empty; default layout is `gb`).

### Your shell

`dotfiles/bash` holds your `.bash_aliases` and `.bash-functions` unchanged, plus a
`.bashrc` that loads them and starship. `DOTFILES_DIR` points at `~/.jarch/dotfiles`,
so the `dots_stow_*` functions manage Jarch's dotfiles.

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
- `tests/check-packages.sh`: every listed package exists in the Arch repos.

CI runs all three plus shellcheck.
