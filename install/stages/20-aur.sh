# shellcheck shell=bash
# desc: bootstrap the AUR helper and install AUR packages

case "$AUR_HELPER" in
    paru|yay) ;;
    *) die "AUR_HELPER must be paru or yay (got '$AUR_HELPER')" ;;
esac

# A helper that exists but can't run (e.g. a -bin build linked against an
# older libalpm after a pacman update) counts as missing.
_helper_works() { "$AUR_HELPER" --version &>/dev/null; }

# _aur_build <aur-pkgname> — clone and makepkg -si one AUR package
_aur_build() {
    local dir
    dir="$(mktemp -d)"
    run git clone --depth 1 "https://aur.archlinux.org/$1.git" "$dir/$1"
    if [[ "$DRY_RUN" == 1 ]]; then
        run makepkg -si --needed
    else
        # shellcheck disable=SC2046
        ( cd "$dir/$1" && makepkg -si --needed $(pacman_noconfirm) )
    fi
    rm -rf "$dir"
}

if _helper_works; then
    ok "$AUR_HELPER already installed"
elif [[ "$DRY_RUN" == 1 ]]; then
    info "Would build $AUR_HELPER from the AUR"
    _aur_build "${AUR_HELPER}-bin"
else
    # The prebuilt -bin package is quick; if it can't run against this
    # system's pacman, build from source instead (slower, always matches).
    info "Installing ${AUR_HELPER}-bin from the AUR"
    _aur_build "${AUR_HELPER}-bin" || true
    if ! _helper_works; then
        warn "${AUR_HELPER}-bin doesn't run on this system; building $AUR_HELPER from source"
        if pacman -Qq "${AUR_HELPER}-bin" &>/dev/null; then
            # shellcheck disable=SC2046
            sudo pacman -Rns $(pacman_noconfirm) "${AUR_HELPER}-bin"
        fi
        _aur_build "$AUR_HELPER"
    fi
    _helper_works || die "$AUR_HELPER failed to install"
    ok "$AUR_HELPER installed"
fi

mapfile -t _aur < <(profile_items aur)
if [[ ${#_aur[@]} -eq 0 ]]; then
    info "No AUR packages listed"
else
    info "${#_aur[@]} AUR packages: ${_aur[*]}"
    _flags=(-S --needed)
    [[ "$ASSUME_YES" == 1 ]] && _flags+=(--noconfirm)
    [[ "$AUR_HELPER" == paru && "$ASSUME_YES" == 1 ]] && _flags+=(--skipreview)
    run "$AUR_HELPER" "${_flags[@]}" "${_aur[@]}"
    ok "AUR packages installed"
    unset _flags
fi
unset _aur
unset -f _helper_works _aur_build
