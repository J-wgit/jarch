#!/usr/bin/env bash
# Build [jarch] and publish it as the assets of a GitHub release, which pacman
# reads as Server = https://github.com/<repo>/releases/download/repo-$arch
#
# Only packages whose version isn't published yet are built: the current
# database is downloaded first and jarch-pkg skips what it already lists.
# Needs GH_TOKEN and GH_REPO (gh CLI); passes the build-repo.sh environment on.
set -euo pipefail
cd "$(dirname "$0")/../.."
tag="repo-$(uname -m)"
out=out/repo

pacman -Syu --noconfirm --needed github-cli >/dev/null

if ! gh release view "$tag" >/dev/null 2>&1; then
    gh release create "$tag" --latest=false --title "[jarch] package repo ($(uname -m))" --notes \
"pacman repository for Jarch, rebuilt by the Package repo workflow. Don't edit by hand.

\`\`\`
[jarch]
Server = https://github.com/$GH_REPO/releases/download/repo-\$arch
\`\`\`"
fi

mkdir -p "$out"
if [[ -z "${REBUILD:-}" ]]; then
    gh release download "$tag" --dir "$out" --clobber \
        -p 'jarch.db.tar.gz' -p 'jarch.db.tar.gz.sig' -p 'jarch.files.tar.gz' -p 'jarch.files.tar.gz.sig' \
        || echo "No published database yet; building everything"
fi

JARCH_REQUIRE_HISTORY=1 .github/scripts/build-repo.sh "$out"

# Release assets can't be symlinks or have directories: stage real files,
# with pacman's names for the database (jarch.db, jarch.files)
stage="$(mktemp -d)"
for f in "$out"/*.pkg.tar.*; do
    [[ -f "$f" ]] && cp "$f" "$stage/"
done
dbs=()
for f in db files; do
    cp "$out/jarch.$f.tar.gz" "$stage/jarch.$f"
    dbs+=("$out/jarch.$f.tar.gz" "$stage/jarch.$f")
    if [[ -f "$out/jarch.$f.tar.gz.sig" ]]; then
        cp "$out/jarch.$f.tar.gz.sig" "$stage/jarch.$f.sig"
        dbs+=("$out/jarch.$f.tar.gz.sig" "$stage/jarch.$f.sig")
    fi
done

# Everything the database lists must be published, with its signature if signed
mapfile -t listed < <(bsdtar -xOf "$out/jarch.db.tar.gz" '*/desc' | awk '/^%FILENAME%$/ { getline; print }')
keep=()
for f in "${dbs[@]}"; do keep+=("$(basename "$f")"); done
for f in "${listed[@]}"; do keep+=("$f" "$f.sig"); done

in_list() { local x="$1"; shift; printf '%s\n' "$@" | grep -qxF "$x"; }
mapfile -t have < <(gh release view "$tag" --json assets -q '.assets[].name')

# Packages first, then the database, then old packages: clients never see a
# database that lists a file that isn't there
new=()
for f in "$stage"/*.pkg.tar.*; do
    [[ -f "$f" ]] || continue
    if [[ -n "${REBUILD:-}" ]] || ! in_list "$(basename "$f")" "${have[@]}"; then new+=("$f"); fi
done
if [[ ${#new[@]} -gt 0 ]]; then
    gh release upload "$tag" --clobber "${new[@]}"
fi
gh release upload "$tag" --clobber "${dbs[@]}"

for f in "${have[@]}"; do
    in_list "$f" "${keep[@]}" || { echo "Removing old asset $f"; gh release delete-asset "$tag" "$f" --yes; }
done

# GitHub renames assets with some characters (e.g. ':' from an epoch), which
# would break pacman downloads: fail loudly if any listed file isn't there
mapfile -t have < <(gh release view "$tag" --json assets -q '.assets[].name')
bad=0
for f in "${listed[@]}"; do
    in_list "$f" "${have[@]}" || { echo "Asset $f is missing or was renamed by GitHub" >&2; bad=1; }
    if [[ -f "$out/jarch.db.tar.gz.sig" ]] && ! in_list "$f.sig" "${have[@]}"; then
        echo "Signature $f.sig is missing" >&2; bad=1
    fi
done
[[ $bad == 0 ]] || exit 1
echo "[jarch] on $tag: ${#listed[@]} packages, ${#new[@]} uploaded this run"
