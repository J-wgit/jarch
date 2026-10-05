#!/usr/bin/env bash
# Assertions for tests/offline-install.sh (run as the test user)
# shellcheck disable=SC2088  # "~" in check labels is display text
set -euo pipefail
JARCH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IFS=',' read -ra PROFILES <<<"${1:-base}"
[[ "${PROFILES[0]}" == base ]] || PROFILES=(base "${PROFILES[@]}")
source "$JARCH_DIR/install/lib/common.sh"
fail=0
check() { if eval "$2"; then ok "$1"; else err "$1"; fail=1; fi; }

while read -r p; do
    while IFS= read -r -d '' f; do
        rel="${f#"$JARCH_DIR/dotfiles/$p/"}"
        check "~/$rel linked" "[[ -L ~/$rel && \$(readlink -f ~/$rel) == $f ]]"
    done < <(find "$JARCH_DIR/dotfiles/$p" -type f -print0)
done < <(profile_items dotfiles)
check "~/.config not folded into a symlink" "[[ -d ~/.config && ! -L ~/.config ]]"
check "old .bashrc backed up exactly once" "[[ \$(grep -rlx 'old bashrc' ~/.local/state/jarch/backup | wc -l) == 1 ]]"
check "env file points at repo" "grep -q '$JARCH_DIR' ~/.config/jarch/env"
check "bashrc loads functions + aliases" "bash -ic 'type -t pkg_install >/dev/null && alias please >/dev/null' 2>/dev/null"
check "DOTFILES_DIR points at repo dotfiles" "[[ \$(bash -ic 'echo \$DOTFILES_DIR' 2>/dev/null) == $JARCH_DIR/dotfiles ]]"
check "pacman.conf tuned" "grep -q '^Color' /etc/pacman.conf && grep -q '^ParallelDownloads = 10' /etc/pacman.conf && [[ \$(grep -c '^ILoveCandy' /etc/pacman.conf) == 1 ]]"
check "all pacman packages requested" "grep -q 'pacman -Syu --needed --noconfirm' /stub/log.first"
check "paru-bin tried first" "grep -q 'git clone --depth 1 https://aur.archlinux.org/paru-bin.git' /stub/log.first"
check "broken paru-bin falls back to source build" "grep -q 'git clone --depth 1 https://aur.archlinux.org/paru.git' /stub/log.first"
check "paru-bin and paru-bin-debug removed before source build" "grep -q 'pacman -Rns --noconfirm paru-bin paru-bin-debug' /stub/log.first && ! grep -q '^paru-bin' /stub/db"
check "AUR packages installed with paru" "grep -q '^paru -S --needed --noconfirm --skipreview downgrade' /stub/log.first"
check "second run doesn't rebuild paru" "! grep -q 'makepkg' /stub/log"
check "second run doesn't re-enable services" "! grep -q 'systemctl enable' /stub/log"
check "second run doesn't change shell again" "! grep -q '^chsh' /stub/log"
check "no new backups on second run" "[[ \$(ls ~/.local/state/jarch/backup | wc -l) == 1 ]]"
while read -r s; do check "$s enabled" "grep -qx 'enabled $s' /stub/db"; done < <(profile_items services)
if has_profile desktop; then check "hypr local.conf created" "[[ -f ~/.config/hypr/local.conf ]]"; fi
while read -r line; do
    kconfig_parse "$line"
    # shellcheck disable=SC2034  # used inside check's eval
    mapfile -t args < <(kconfig_args)
    if [[ "$KC_FILE" == /* ]]; then
        check "$KC_FILE has $KC_KEY=$KC_VALUE" "grep -qxF \"\$KC_KEY=\$KC_VALUE\" \"\$KC_FILE\""
        continue
    fi
    check "kconfig $KC_FILE $KC_KEY" "[[ \"\$(STUB_DB=/stub/db /stub/bin/kreadconfig6 \"\${args[@]}\")\" == \"\$KC_VALUE\" ]]"
done < <(profile_items kconfig)
if has_profile kde; then
    check "kconfig shortcut keeps its tab" "grep -qP 'Alt\\+F4\\tMeta\\+Q,' /stub/db"
    check "SDDM drop-in written as a whole file" "[[ \$(stat -c %U:%a /etc/sddm.conf.d/jarch.conf) == root:644 ]] && grep -qx '\\[Theme\\]' /etc/sddm.conf.d/jarch.conf"
    check "second run doesn't rewrite KDE settings" "! grep -q kwriteconfig6 /stub/log"
fi
check "jarch-manager installed" "[[ -x /usr/local/bin/jarch-manager ]] && bash -n /usr/local/bin/jarch-manager"
check "jarch-install on PATH" "[[ -L /usr/local/bin/jarch-install ]]"
check "starship config is valid TOML" "python3 -c 'import tomllib;tomllib.load(open(\"$HOME/.config/starship.toml\",\"rb\"))'"
check "install state recorded" "grep -q 'profiles=${PROFILES[*]}' ~/.local/state/jarch/installed"
exit $fail
