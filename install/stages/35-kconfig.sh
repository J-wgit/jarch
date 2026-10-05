# shellcheck shell=bash
# desc: apply KDE settings listed in profiles/<profile>/kconfig

mapfile -t _kc < <(profile_items kconfig)
if [[ ${#_kc[@]} -eq 0 ]]; then
    info "No KDE settings listed"
else
    have kwriteconfig6 || [[ "$DRY_RUN" == 1 ]] || die "kwriteconfig6 is missing (it comes with KDE's kconfig package)."
    _set=0 _same=0
    for _line in "${_kc[@]}"; do
        kconfig_parse "$_line" || die "Bad kconfig entry (want 'file | group | key | value'): $_line"
        mapfile -t _args < <(kconfig_args)
        _cur=""
        have kreadconfig6 && _cur="$(kreadconfig6 "${_args[@]}" 2>/dev/null || true)"
        if [[ "$_cur" == "$KC_VALUE" ]]; then
            _same=$((_same + 1))
            continue
        fi
        if [[ "$KC_FILE" == /* ]]; then
            [[ -d "$(dirname "$KC_FILE")" ]] || run sudo mkdir -p "$(dirname "$KC_FILE")"
            run sudo kwriteconfig6 "${_args[@]}" "$KC_VALUE"
        else
            run kwriteconfig6 "${_args[@]}" "$KC_VALUE"
        fi
        info "Set $KC_FILE [${KC_GROUPS[*]}] $KC_KEY"
        _set=$((_set + 1))
    done
    ok "KDE settings: $_set changed, $_same already set"
    unset _set _same _line _args _cur
fi
unset _kc
