# shellcheck shell=bash
# desc: install Jarch's own packages (from [jarch], or built from pkgbuilds/)

mapfile -t _jpkgs < <(profile_items jarch)

# What [jarch] offers, as "name version" lines (empty if it isn't configured)
_offer=""
if [[ "$DRY_RUN" == 0 ]] && grep -q '^\[jarch\]' /etc/pacman.conf; then
    _offer="$(pacman -Sl jarch 2>/dev/null | awk '{ print $2, $3 }' || true)"
fi

for _p in "${_jpkgs[@]}"; do
    _dir="$JARCH_DIR/pkgbuilds/$_p"
    if [[ "$DRY_RUN" == 1 ]]; then
        info "Would install $_p from [jarch], or build it from pkgbuilds/$_p"
        continue
    fi
    _have="$(pacman -Q "$_p" 2>/dev/null | awk '{ print $2 }' || true)"
    _repo="$(awk -v p="$_p" '$1 == p { print $2 }' <<<"$_offer")"
    if [[ -n "$_repo" ]]; then
        if [[ "$_have" == "$_repo" ]]; then
            ok "$_p $_have already installed"
        else
            # shellcheck disable=SC2046
            run sudo pacman -S --needed $(pacman_noconfirm) "jarch/$_p"
            ok "Installed $_p $_repo from [jarch]"
        fi
        continue
    fi
    [[ -f "$_dir/PKGBUILD" ]] || die "$_p is listed in a 'jarch' profile list but [jarch] doesn't have it and pkgbuilds/$_p doesn't exist"
    _want="$(pkgbuild_version "$_dir")"
    if [[ "$_have" == "$_want" ]]; then
        ok "$_p $_have already installed"
        continue
    fi
    info "Building $_p $_want from pkgbuilds/$_p"
    _build="$(mktemp -d)"
    # shellcheck disable=SC2046
    ( cd "$_dir" && PKGDEST="$_build" BUILDDIR="$_build" SRCDEST="$_build" \
        makepkg -si --needed --cleanbuild --clean $(pacman_noconfirm) )
    rm -rf "$_build"
    ok "Installed $_p $_want (built locally)"
done

# Before packaging, jarch-manager was copied to /usr/local/bin and jarch-install
# linked there; both would shadow the packaged /usr/bin versions
if [[ "$DRY_RUN" == 0 ]]; then
    if pacman -Qq jarch-manager &>/dev/null && [[ -f /usr/local/bin/jarch-manager ]] \
        && ! pacman -Qo /usr/local/bin/jarch-manager &>/dev/null; then
        run sudo rm -f /usr/local/bin/jarch-manager
        ok "Removed the old /usr/local/bin/jarch-manager"
    fi
    if pacman -Qq jarch-install &>/dev/null && [[ -L /usr/local/bin/jarch-install ]]; then
        run sudo rm -f /usr/local/bin/jarch-install
        ok "Removed the old /usr/local/bin/jarch-install link"
    fi
fi
unset _jpkgs _offer _p _dir _have _repo _want _build
