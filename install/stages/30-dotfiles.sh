# shellcheck shell=bash
# desc: link dotfiles into your home with GNU stow (existing files are backed up)

have stow || [[ "$DRY_RUN" == 1 ]] || die "stow is not installed (it's in the base profile's package list)."

_dots="$JARCH_DIR/dotfiles"
_backup="$STATE_DIR/backup/$(date +%Y%m%d_%H%M%S)"
_moved=0

mapfile -t _stow_pkgs < <(profile_items dotfiles)
for _p in "${_stow_pkgs[@]}"; do
    [[ -d "$_dots/$_p" ]] || die "Dotfile package '$_p' listed but $_dots/$_p doesn't exist"

    # Move aside anything in $HOME that would block stow, unless it's already our link
    while IFS= read -r -d '' _f; do
        _rel="${_f#"$_dots/$_p/"}"
        _target="$HOME/$_rel"
        if [[ -L "$_target" && "$(readlink -f "$_target")" == "$(readlink -f "$_f")" ]]; then
            continue
        fi
        if [[ -e "$_target" || -L "$_target" ]]; then
            info "Backing up ~/$_rel"
            run mkdir -p "$(dirname "$_backup/$_rel")"
            run mv "$_target" "$_backup/$_rel"
            _moved=$((_moved + 1))
        fi
    done < <(find "$_dots/$_p" -mindepth 1 \( -type f -o -type l \) -print0)

    run stow --no-folding --restow --dir="$_dots" --target="$HOME" "$_p"
    ok "Linked $_p"
done
[[ $_moved -gt 0 ]] && info "$_moved existing file(s) saved under $_backup"

# Hyprland sources this for per-machine monitors/keyboard; it must exist
if has_profile desktop && [[ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/local.conf" ]]; then
    run touch "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/local.conf"
    ok "Created ~/.config/hypr/local.conf for machine-specific Hyprland settings"
fi

# Tell the shell where the repo lives (used by .bashrc for DOTFILES_DIR etc.)
_envfile="${XDG_CONFIG_HOME:-$HOME/.config}/jarch/env"
if [[ "$DRY_RUN" == 1 ]]; then
    echo "  would write: $_envfile"
else
    mkdir -p "$(dirname "$_envfile")"
    printf 'export JARCH_DIR=%q\n' "$JARCH_DIR" >"$_envfile"
fi
ok "Wrote $_envfile"
unset _dots _backup _moved _stow_pkgs _p _f _rel _target _envfile
