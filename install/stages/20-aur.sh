# shellcheck shell=bash
# desc: bootstrap the AUR helper and install AUR packages

case "$AUR_HELPER" in
    paru|yay) ;;
    *) die "AUR_HELPER must be paru or yay (got '$AUR_HELPER')" ;;
esac

if have "$AUR_HELPER"; then
    ok "$AUR_HELPER already installed"
else
    info "Building $AUR_HELPER from the AUR"
    _build="$(mktemp -d)"
    run git clone --depth 1 "https://aur.archlinux.org/${AUR_HELPER}-bin.git" "$_build/$AUR_HELPER"
    if [[ "$DRY_RUN" == 1 ]]; then
        run makepkg -si --needed
    else
        # shellcheck disable=SC2046
        ( cd "$_build/$AUR_HELPER" && makepkg -si --needed $(pacman_noconfirm) )
    fi
    rm -rf "$_build"
    unset _build
    [[ "$DRY_RUN" == 1 ]] || have "$AUR_HELPER" || die "$AUR_HELPER failed to install"
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
