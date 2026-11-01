# ADR-0002: Each profile is also a meta-package in [jarch]

Status: proposed · 2026-11-01

## Context

Profiles are plain lists (`profiles/<name>/pacman`, `jarch`, ...) that
`jarch-install` applies. Once a machine is installed, nothing connects it to the
lists any more: a package added to a profile reaches a machine only if someone
re-runs the installer. Phase 3 of the plan calls for meta-packages
(`jarch-meta-desktop` and friends) so that `pacman -Syu` carries profile changes
too. Writing those dependency lists by hand would give every package two homes
that drift apart.

## Decision

Every profile gets a `jarch-meta-<profile>` package, generated from its lists:

- `pkgbuilds/jarch-meta-<profile>/PKGBUILD` sets `_profile` and sources the shared
  `pkgbuilds/jarch-meta.sh`. The lists stay the only place packages are named.
- Its dependencies are the profile's `pacman` and `jarch` lists, plus
  `jarch-meta-base`. pacman groups are expanded to their members at build time.
  `aur` and other lists are left out: pacman can't resolve them. An AUR package
  that should be tracked is served from `[jarch]` and listed in `jarch`.
- The dependencies are set inside `package()`, not at the top of the PKGBUILD,
  so sourcing it stays cheap (the installer and `jarch-pkg` do that often) and
  `makepkg --syncdeps` doesn't try to fetch `[jarch]` packages it can't see.
- The version is `1.0.0.r<N>`, N counting commits touching the profile's lists
  or the meta PKGBUILDs, like Jarch's other own packages. The publish workflow
  runs on list changes.
- Each profile's `jarch` list names its own meta-package, so the installer's
  tools stage installs it (from `[jarch]`, or built locally when `[jarch]` is
  unreachable). `tests/meta-packages.sh` checks every profile has one and that
  its dependencies match the lists exactly.

## Consequences

- Adding a package to a profile reaches installed machines on their next
  `pacman -Syu`, without re-running the installer.
- Removing a package from a profile does not uninstall it anywhere: the
  installer and pacman both installed it explicitly, so it simply stops being
  required. Clean-up stays a manual choice.
- A new profile needs its three-line PKGBUILD and a `jarch` list entry, or
  `tests/meta-packages.sh` fails.
- `pacman -Rs jarch-meta-<profile>` removes only the meta-package, not the
  profile's packages (they're explicitly installed).
