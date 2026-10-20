# Jarch roadmap

_Last reviewed: 2026-10-20_

## Where it stands

Jarch is a riced Arch Linux, delivered as a re-runnable, idempotent installer
over a vanilla Arch install. Stages cover preflight, packages, AUR, stow'd
dotfiles, KDE config, services, Jarch's own tools and post-install. Profiles are
base, desktop (Hyprland), kde and dev. A `[jarch]` pacman repo is built and
published by CI.

- **Status:** phase 1 (installer MVP) plus the package repo.
- **Planned:** theming is phase 2 and the ISO is phase 4.
- **CI:** shellcheck, plus container and offline install tests in an Arch container.
- **This review:** shellcheck 0.11 is clean on every file CI checks. The Arch-container tests weren't run here.

## Fixed in this pass

| Issue | Severity | Fix |
|---|---|---|
| **An unsigned repo could override `[core]`.** `keys/jarch.asc` doesn't exist yet, so `[jarch]` is configured `SigLevel = Optional TrustAll`, and `JARCH_REPO_FIRST=1` placed it *above* `[core]`. Any package in the GitHub release (from a compromised token, CI or account) could replace `glibc` or `pacman` on every Jarch machine at the next `pacman -Syu`, with no signature check. Today the repo only ships Jarch's own tools, so nothing is shadowed yet. | High | The repo goes above `[core]` only while signatures are required. Unsigned, it goes last and preflight warns. `tests/verify.sh` now expects "above" when signed and "below" when unsigned, and the README and `jarch.conf` say so. The placement logic was tested both ways against a sample `pacman.conf`. CI's repo test signs with a throwaway key, so it still covers the above-`[core]` path. |

## Next tasks

### P0
- [ ] **Turn on signing.** Generate the Jarch signing key (ed25519, offline primary), add the private key as the `JARCH_SIGNING_KEY` Actions secret, and commit the public key as `keys/jarch.asc`. After that, `[jarch]` requires signatures and moves back above `[core]` automatically. Steps are in `pkgbuilds/README.md`.
- [ ] **Run the CI container tests after this change.** Confirm `container-install base/kde` and both `offline-install` jobs pass on the PR.

### P1: phase 2, theming
- [ ] One palette source (e.g. a `theme.toml`) rendered into kitty, waybar, rofi, dunst, hypr and KDE colour schemes, so a theme change is one edit.
- [ ] Wallpaper, cursor, icons and font set as a `jarch-theme` package in `[jarch]`.
- [ ] SDDM theme matching the desktop.
- [ ] Ship strata (the TUI file manager in `J-wgit/Tools`) as a `[jarch]` package once it has release builds.

### P2: phase 3/4, ISO and beyond
- [ ] archiso profile that runs `jarch-install --yes` from a first-boot service (phase 4).
- [ ] A rollback story: snapper/btrfs snapshots before `jarch-install` and before `pacman -Syu` (a `snap-pac`-style hook).
- [ ] `jarch-manager`: replace the inherited docs (`AUTOMATION_EXAMPLES.md`, `QUICK_REFERENCE.md`, `SOURCE.md`) with one page that matches the shipped commands.

## What I need from you

1. **The signing key.** It has to be generated and held by you, and I can't create the Actions secret. I can write the exact commands to run.
2. **Theme direction for phase 2:** palette (Catppuccin? custom?), fonts, and whether Hyprland or KDE is the primary desktop.
3. **Hardware notes:** GPU vendor and laptop/desktop. NVIDIA needs different Hyprland packages and environment settings.

## Work to do together

- **Signing setup (about 20 minutes).** You run the key generation and add the secret, then I verify a signed CI build and an install that requires signatures.
- **VM install test.** Install Arch in a VM with `archinstall`, run `jarch-install --profile desktop,dev`, and note everything that looks or works wrong. That list becomes phase 2.
