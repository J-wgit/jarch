#!/usr/bin/env bash
# shellcheck disable=SC2088  # "~" in check labels is display text
# Assertions run after an install (inside the test container, as the user).
set -euo pipefail
JARCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IFS=',' read -ra PROFILES <<<"${1:-base}"
expect="${2:-any}"   # repo: Jarch's packages must have come from [jarch]
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
while read -r p; do
    check "$p installed at its pkgbuilds/ version" "[[ \$(pacman -Q $p | cut -d' ' -f2) == \$(pkgbuild_version $JARCH_DIR/pkgbuilds/$p) ]]"
    if [[ "$expect" == repo ]]; then
        check "$p installed from [jarch]" "pacman -Sl jarch | grep -q '^jarch $p .*\[installed\]'"
    fi
done < <(profile_items jarch)
if [[ "$expect" == repo ]]; then
    if [[ -f "$JARCH_DIR/keys/jarch.asc" ]]; then
        check "[jarch] listed above [core]" "[[ \$(grep -nx '\\[jarch\\]' /etc/pacman.conf | cut -d: -f1) -lt \$(grep -nx '\\[core\\]' /etc/pacman.conf | cut -d: -f1) ]]"
        check "[jarch] requires signatures" "grep -qx 'SigLevel = Required DatabaseOptional' /etc/pacman.conf"
    else
        # unsigned: never allowed to shadow official packages
        check "[jarch] listed below [core]" "[[ \$(grep -nx '\\[jarch\\]' /etc/pacman.conf | cut -d: -f1) -gt \$(grep -nx '\\[core\\]' /etc/pacman.conf | cut -d: -f1) ]]"
    fi
fi
# outputs are captured first: grep -q closing a pipe early would trip pipefail
check "jarch-manager runs as a user" "[[ \$(command -v jarch-manager) == /usr/bin/jarch-manager && \$(jarch-manager version) == *v1.0.0* ]]"
check "jarch-install launcher finds the checkout" "[[ \$(command -v jarch-install) == /usr/bin/jarch-install && \$(jarch-install --list) == *50-tools* ]]"
# (the archlinux image's NoExtract skips docs on disk, so ask the package)
check "jarch-manager ships its docs" "[[ \$(pacman -Qlq jarch-manager) == */usr/share/doc/jarch-manager/README.md* ]]"
check "pacman Color on" "grep -q '^Color' /etc/pacman.conf"
check "install state recorded" "[[ -f ~/.local/state/jarch/installed ]]"
exit $fail
