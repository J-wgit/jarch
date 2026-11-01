# shellcheck shell=bash disable=SC2034,SC2154  # makepkg reads these; $startdir and $_profile come from it and the PKGBUILD
# Shared body of the jarch-meta-<profile> PKGBUILDs. Each one sets _profile
# and sources this file.
#
# jarch-meta-<profile> is an empty package that depends on everything the
# profile's pacman and jarch lists name (profiles/<profile>/{pacman,jarch}),
# plus jarch-meta-base. The lists stay the source of truth: when one changes,
# the meta-package's version goes up, CI publishes it, and the next
# `pacman -Syu` installs whatever the profile gained. AUR packages are left
# out (pacman can't resolve them); serve one from [jarch] and list it in the
# profile's jarch file to have it pulled in too.
_jarch="$(realpath "$startdir/../..")"
pkgname="jarch-meta-$_profile"
_basever=1.0.0
_paths=("profiles/$_profile/pacman" "profiles/$_profile/jarch" "pkgbuilds/jarch-meta-$_profile" pkgbuilds/jarch-meta.sh)
pkgver=$_basever.r$(git -C "$_jarch" rev-list --count HEAD -- "${_paths[@]}" 2>/dev/null || echo 0)
pkgrel=1
pkgdesc="Jarch $_profile profile: depends on every package the profile lists"
arch=(any)
url="https://github.com/J-wgit/jarch"
license=(unknown)

# _jarch_meta_list <file> — entries of a profile list, comments and blanks dropped
_jarch_meta_list() {
    [[ -f "$1" ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]//g' "$1" | grep -v '^$' || true
}

# The dependencies are worked out here rather than at the top: pacman groups
# (allowed in profile lists) can't be dependencies, so they're expanded to
# their members, which needs the sync databases. Sourcing the PKGBUILD stays
# cheap, and makepkg --syncdeps doesn't try to install them before building.
package() {
    local _list _p _groups _deps=()
    # makepkg runs this with errexit: plain ifs, no '&&' shortcuts
    if [[ "$_profile" != base ]]; then _deps+=(jarch-meta-base); fi
    _groups="$(pacman -Sg 2>/dev/null | awk '{ print $1 }' | sort -u)"
    for _list in pacman jarch; do
        while read -r _p; do
            if [[ "$_p" == "$pkgname" ]]; then continue; fi
            if grep -qxF "$_p" <<<"$_groups" && ! pacman -Si "$_p" &>/dev/null; then
                mapfile -t -O "${#_deps[@]}" _deps < <(pacman -Sgq "$_p")
            else
                _deps+=("$_p")
            fi
        done < <(_jarch_meta_list "$_jarch/profiles/$_profile/$_list")
    done
    depends=("${_deps[@]}")
}
