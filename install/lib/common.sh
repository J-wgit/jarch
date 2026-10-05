# shellcheck shell=bash
# Shared helpers for jarch-install and its stages.
# Sourced, never executed. Expects JARCH_DIR, DRY_RUN, ASSUME_YES, LOG_FILE.

_c_reset='\033[0m'
_c_bold='\033[1m'
_c_red='\033[0;31m'
_c_green='\033[0;32m'
_c_yellow='\033[0;33m'
_c_blue='\033[0;34m'
_c_magenta='\033[0;35m'

_log() { [[ -n "${LOG_FILE:-}" ]] && printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE"; return 0; }

info()  { echo -e "${_c_blue}[INFO]${_c_reset}  $*"; _log "INFO  $*"; }
ok()    { echo -e "${_c_green}[OK]${_c_reset}    $*"; _log "OK    $*"; }
warn()  { echo -e "${_c_yellow}[WARN]${_c_reset}  $*"; _log "WARN  $*"; }
err()   { echo -e "${_c_red}[ERR]${_c_reset}   $*" >&2; _log "ERR   $*"; }
die()   { err "$*"; exit 1; }
stage() { echo -e "\n${_c_bold}${_c_magenta}══ $* ══${_c_reset}"; _log "STAGE $*"; }

# run <cmd> [args...] — execute, or just print it under --dry-run
run() {
    if [[ "${DRY_RUN:-0}" == 1 ]]; then
        echo -e "  ${_c_yellow}would run:${_c_reset} $*"
        _log "DRY   $*"
        return 0
    fi
    _log "RUN   $*"
    "$@"
}

have() { command -v "$1" &>/dev/null; }

confirm() {
    [[ "${ASSUME_YES:-0}" == 1 ]] && return 0
    local reply
    read -r -p "$(echo -e "${_c_yellow}${1:-Continue?} [y/N] ${_c_reset}")" reply
    [[ "${reply,,}" =~ ^y(es)?$ ]]
}

# read_list <file> — print package names, skipping comments and blank lines
read_list() {
    [[ -f "$1" ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]\+$//' -e 's/^[[:space:]]\+//' "$1" | grep -v '^$' || true
}

# profile_items <list> — merged entries of profiles/<profile>/<list> for every
# active profile, in profile order, duplicates removed
profile_items() {
    local p
    for p in "${PROFILES[@]}"; do
        read_list "$JARCH_DIR/profiles/$p/$1"
    done | awk '!seen[$0]++'
}

# has_profile <name>
has_profile() {
    local p
    for p in "${PROFILES[@]}"; do [[ "$p" == "$1" ]] && return 0; done
    return 1
}

pacman_noconfirm() { if [[ "${ASSUME_YES:-0}" == 1 ]]; then echo --noconfirm; fi; }

# kconfig_parse <line> — split a profiles/<p>/kconfig entry
# ("file | group > subgroup | key | value") into KC_FILE, KC_GROUPS (array),
# KC_KEY and KC_VALUE. A literal \t in the value becomes a tab.
kconfig_parse() {
    local line="$1" groups part
    _kc_trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; printf '%s' "${s%"${s##*[![:space:]]}"}"; }
    IFS='|' read -r KC_FILE groups KC_KEY KC_VALUE <<<"$line"
    KC_FILE="$(_kc_trim "$KC_FILE")"
    KC_KEY="$(_kc_trim "$KC_KEY")"
    KC_VALUE="$(_kc_trim "$KC_VALUE")"
    KC_VALUE="${KC_VALUE//\\t/$'\t'}"
    KC_GROUPS=()
    while IFS= read -r part; do
        part="$(_kc_trim "$part")"
        [[ -n "$part" ]] && KC_GROUPS+=("$part")
    done <<<"${groups// > /$'\n'}"
    [[ -n "$KC_FILE" && ${#KC_GROUPS[@]} -gt 0 && -n "$KC_KEY" ]]
}

# kconfig_args — kreadconfig6/kwriteconfig6 arguments for the last kconfig_parse
kconfig_args() {
    local g
    printf '%s\n' --file "$KC_FILE"
    for g in "${KC_GROUPS[@]}"; do printf '%s\n' --group "$g"; done
    printf '%s\n' --key "$KC_KEY"
}
