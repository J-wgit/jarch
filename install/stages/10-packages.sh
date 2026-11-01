# shellcheck shell=bash
# desc: install official packages for the active profiles

# multilib packages too: the preflight stage turned [multilib] on for them
mapfile -t _pkgs < <(profile_items pacman; profile_items multilib)
if [[ ${#_pkgs[@]} -eq 0 ]]; then
    info "No packages listed"
else
    info "${#_pkgs[@]} packages from: ${PROFILES[*]}"
    # shellcheck disable=SC2046
    run sudo pacman -Syu --needed $(pacman_noconfirm) "${_pkgs[@]}"
    ok "Official packages installed"
fi
unset _pkgs
