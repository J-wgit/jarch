# shellcheck shell=bash
# desc: apply KDE settings listed in profiles/<profile>/kconfig

mapfile -t _kc < <(profile_items kconfig)
if [[ ${#_kc[@]} -eq 0 ]]; then
    info "No KDE settings listed"
else
    have kwriteconfig6 || [[ "$DRY_RUN" == 1 ]] || die "kwriteconfig6 is missing (it comes with KDE's kconfig package)."
    _set=0 _same=0
    declare -A _sys=()   # system file -> its entries, "group<US>key=value" per line
    for _line in "${_kc[@]}"; do
        kconfig_parse "$_line" || die "Bad kconfig entry (want 'file | group | key | value'): $_line"

        # Absolute paths are small system files Jarch owns outright (e.g. an
        # sddm.conf.d drop-in): collected here and written whole below
        if [[ "$KC_FILE" == /* ]]; then
            _sys[$KC_FILE]+="${KC_GROUPS[*]}"$'\x1f'"$KC_KEY=$KC_VALUE"$'\n'
            continue
        fi

        mapfile -t _args < <(kconfig_args)
        _cur=""
        have kreadconfig6 && _cur="$(kreadconfig6 "${_args[@]}" 2>/dev/null || true)"
        if [[ "$_cur" == "$KC_VALUE" ]]; then
            _same=$((_same + 1))
            continue
        fi
        run kwriteconfig6 "${_args[@]}" "$KC_VALUE"
        info "Set $KC_FILE [${KC_GROUPS[*]}] $KC_KEY"
        _set=$((_set + 1))
    done

    for _file in "${!_sys[@]}"; do
        # one INI section header each time the group changes, in list order
        _want="# Written by jarch-install from profiles/*/kconfig. Edit it there."$'\n'
        _want+="$(awk -F '\x1f' 'NF { if ($1 != g) { print "[" $1 "]"; g = $1 } print $2 }' <<<"${_sys[$_file]}")"
        if [[ -f "$_file" && "$(cat "$_file")" == "$_want" ]]; then
            _same=$((_same + 1))
            continue
        fi
        if [[ "$DRY_RUN" == 1 ]]; then
            echo "  would write: $_file"
        else
            printf '%s\n' "$_want" | sudo install -Dm644 /dev/stdin "$_file"
        fi
        info "Wrote $_file"
        _set=$((_set + 1))
    done
    ok "KDE settings: $_set changed, $_same already set"
    unset _set _same _line _args _cur _sys _file _want
fi
unset _kc
