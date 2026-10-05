#!/usr/bin/env bash
# shellcheck disable=SC2088  # "~" in check labels is display text
# Assertions run after an install (inside the test container, as the user).
set -euo pipefail
JARCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IFS=',' read -ra PROFILES <<<"${1:-base}"
[[ "${PROFILES[0]}" == base ]] || PROFILES=(base "${PROFILES[@]}")
source "$JARCH_DIR/install/lib/common.sh"
fail=0
check() { if eval "$2"; then ok "$1"; else err "$1"; fail=1; fi; }

while read -r p; do check "package $p installed" "pacman -Qq $p &>/dev/null || pacman -Qg $p &>/dev/null"; done < <(profile_items pacman)
while read -r p; do check "AUR package $p installed" "pacman -Qq $p &>/dev/null"; done < <(profile_items aur)
check "AUR helper on PATH" "command -v paru >/dev/null"
for f in .bashrc .bash_aliases .bash-functions .config/starship.toml; do
    check "~/$f linked into repo" "[[ -L ~/$f && \$(readlink -f ~/$f) == $JARCH_DIR/dotfiles/* ]]"
done
check "~/.config is a real dir (no stow folding)" "[[ -d ~/.config && ! -L ~/.config ]]"
check "old .bashrc backed up" "grep -rqx 'old bashrc' ~/.local/state/jarch/backup"
check "env file points at repo" "grep -q '$JARCH_DIR' ~/.config/jarch/env"
check "bashrc loads functions and aliases" "bash -ic 'type -t pkg_install && alias please' >/dev/null 2>&1"
check "starship config is valid TOML" "python3 -c 'import tomllib;tomllib.load(open(\"$HOME/.config/starship.toml\",\"rb\"))'"
while read -r s; do check "$s enabled" "systemctl is-enabled --quiet $s"; done < <(profile_items services)
while read -r line; do
    kconfig_parse "$line"
    # shellcheck disable=SC2034  # used inside check's eval
    mapfile -t args < <(kconfig_args)
    if [[ "$KC_FILE" == /* ]]; then
        check "$KC_FILE has $KC_KEY=$KC_VALUE" "grep -qxF \"\$KC_KEY=\$KC_VALUE\" \"\$KC_FILE\""
        continue
    fi
    check "kconfig $KC_FILE $KC_KEY = ${KC_VALUE//$'\t'/\\t}" "[[ \"\$(kreadconfig6 \"\${args[@]}\")\" == \"\$KC_VALUE\" ]]"
done < <(profile_items kconfig)
if has_profile kde; then
    check "konsole profile linked" "[[ -L ~/.local/share/konsole/Jarch.profile ]]"
    check "first-login script on PATH for Plasma" "bash -c 'source ~/.config/plasma-workspace/env/jarch.sh && command -v jarch-kde-firstrun' >/dev/null"
    check "look-and-feel package exists" "[[ -d /usr/share/plasma/look-and-feel/org.kde.breezedark.desktop ]]"
fi
check "jarch-manager installed" "[[ -x /usr/local/bin/jarch-manager ]] && bash -n /usr/local/bin/jarch-manager"
check "pacman Color on" "grep -q '^Color' /etc/pacman.conf"
check "install state recorded" "[[ -f ~/.local/state/jarch/installed ]]"
exit $fail
