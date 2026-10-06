# [jarch] packages

Everything in this directory is served from Jarch's own pacman repository,
`[jarch]`. Each subdirectory is one package with a `PKGBUILD`. CI builds them
and publishes the repo; `jarch-install` adds it to `/etc/pacman.conf`, so
updates arrive with a normal `pacman -Syu`.

| Package | What it is |
|---|---|
| `jarch-manager` | The system manager (`tools/jarch-manager`) |
| `jarch-install` | `/usr/bin/jarch-install`: runs the installer from your checkout, cloning it if needed |
| `jarch-pkg` | The tool for this directory: build, fork and update [jarch] packages |

Profiles choose which ones get installed, in `profiles/<name>/jarch`
(`base` gets `jarch-manager` and `jarch-install`, `dev` adds `jarch-pkg`).

## Adding a Jarch tool

```bash
jarch-pkg new jarch-foo          # writes pkgbuilds/jarch-foo/PKGBUILD
# put the script at tools/jarch-foo/jarch-foo, add jarch-foo to a profile's jarch list
```

Jarch's own PKGBUILDs install files straight from this repo's tree. Their
version is `<base>.r<N>`, where N counts the commits touching the tool, so every
merged change becomes a new version and pacman picks it up. Bump `_basever`
for releases you want to mark.

## Serving a custom build of an open-source package

```bash
jarch-pkg import <pkgbase>       # from the Arch repos (gitlab.archlinux.org)
jarch-pkg import <name> --aur    # from the AUR
```

This copies upstream's packaging into `pkgbuilds/<name>/`, writes
`jarch.upstream` (where it came from, which commit, which version) and marks the
fork in `pkgrel` (`1` becomes `1.1`). Then customise it like any PKGBUILD:
add patches to `source=()` and apply them in `prepare()`, change configure
flags, swap dependencies. Run `updpkgsums`, commit, and once it's on `main`
the fork is in [jarch].

Because `[jarch]` is listed above `[core]` and the fork's version sorts above
upstream's, `pacman -Syu` replaces the official build with yours. To add a
package the official repos don't have (an AUR package, say), import it the same
way and list it in a profile's `jarch` file.

Keeping forks current:

```bash
jarch-pkg outdated               # which forks have a newer upstream version
jarch-pkg update <name>          # 3-way merge of upstream's changes into your fork
```

`update` keeps your edits and marks real conflicts with `<<<<<<<` in the
files. The fork mark is handled for you (new upstream `2.0-3` becomes `2.0-3.1`);
bump the last number yourself for rebuilds of your own (`3.1` to `3.2`).

To stop overriding a package, delete its directory: the next publish drops it
from [jarch] and pacman goes back to the official build on the next upgrade
that bumps its version (or `pacman -S extra/<name>` right away).

## Building locally

On Arch, with `base-devel`:

```bash
jarch-pkg build                  # everything, into out/repo (skips versions already built)
jarch-pkg build jarch-manager    # just one
jarch-pkg list
```

`out/repo` is a working pacman repo: add
`[jarch]` / `Server = file:///home/you/.jarch/out/repo` to test it.

## How it's published

The **Package repo** workflow (`.github/workflows/repo.yml`) runs on every push
to `main` that touches `pkgbuilds/` or `tools/`, and on demand. In an Arch
container it downloads the published database, builds only versions that aren't
in it yet, and uploads the packages and database as assets of the `repo-x86_64`
release. pacman reads them from:

```
https://github.com/J-wgit/jarch/releases/download/repo-$arch
```

That URL is `JARCH_REPO_SERVER` in `jarch.conf`. Release downloads only work
without a login on a **public** repository. While the repo is private, the
installer can't reach [jarch] and builds the packages it needs from this
directory instead (it says so); to serve [jarch] anyway, publish to a separate
public repo: set the `JARCH_PUBLISH_REPO` Actions variable (e.g.
`J-wgit/jarch-packages`), a `JARCH_PUBLISH_TOKEN` secret that can write to it,
and point `JARCH_REPO_SERVER` there.

Pull requests build every package too (CI's `packages` job) and run a real
install from that freshly built repo.

## Signing

Packages are **unsigned by default**: `[jarch]` uses `SigLevel = Optional
TrustAll`, and you're trusting GitHub's HTTPS and whoever can push to `main`
(as you already do for the installer itself). To sign:

1. Make a signing key with no passphrase (CI signs unattended):
   `gpg --quick-gen-key "Jarch packages <you@example.com>" ed25519 sign never`
   (press Enter at the passphrase prompt).
2. Add the private key as the `JARCH_SIGNING_KEY` Actions secret:
   `gpg --armor --export-secret-keys <fingerprint>`.
3. Run the **Package repo** workflow by hand with **rebuild** ticked, so every
   package gets signed.
4. Commit the public key as `keys/jarch.asc`:
   `gpg --armor --export <fingerprint> > keys/jarch.asc`.

From then on `jarch-install` imports and locally signs that key with
`pacman-key` and switches `[jarch]` to `SigLevel = Required DatabaseOptional`.
Do step 4 after step 3, or installs will refuse the still-unsigned packages.
CI tests the signed path on every pull request with a throwaway key.
