#!/usr/bin/env bash
# shellcheck disable=SC2034  # out and menu_out are read inside check's eval
# Tests for jarch-manager (tools/jarch-manager/arch-manager.sh) with pacman,
# sudo, systemctl and friends stubbed: nothing on this machine is changed.
set -euo pipefail
cd "$(dirname "$0")/.."
jm="$PWD/tools/jarch-manager/arch-manager.sh"
t="$(mktemp -d)"
trap 'rm -rf "$t"' EXIT
mkdir -p "$t/bin" "$t/home/.config/jarch-manager" "$t/backups"
log="$t/log"
: >"$log"

# Stubs record their calls. pacman -S fails, like a package that doesn't exist.
stub() { printf '#!/usr/bin/env bash\necho "%s $*" >>"%s"\n%s\n' "$1" "$log" "${2:-exit 0}" >"$t/bin/$1"; chmod +x "$t/bin/$1"; }
# shellcheck disable=SC2016  # stub bodies expand when the stub runs
stub pacman 'case "$1" in -Qqe) printf "bash\nlinux\n" ;; -S) exit 1 ;; esac; exit 0'
stub sudo '"$@"'
stub checkupdates 'printf "linux 6.1-1 -> 6.2-1\nbash 5.1-1 -> 5.2-1\n"'
for c in systemctl paccache journalctl mkinitcpio yay; do stub "$c"; done

cat >"$t/home/.config/jarch-manager/config" <<CONF
BACKUP_DIR="$t/backups"
REPORT_DIR="$t/home"
CACHE_KEEP=5
AUR_HELPER=yay
CONF

jm() { env -i PATH="$t/bin:/usr/bin:/bin" HOME="$t/home" TERM=dumb bash "$jm" "$@"; }

fail=0
check() {
    if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}

check "help names the tool" "jm help | grep -q 'Jarch Manager'"
check "unknown command exits non-zero" "! jm frobnicate >/dev/null 2>&1"

out="$(jm config)"
check "config file is read" "grep -qx 'BACKUP_DIR=$t/backups' <<<\"\$out\" && grep -qx 'CACHE_KEEP=5' <<<\"\$out\""
check "AUR helper comes from the config" "grep -qx 'AUR_HELPER=yay' <<<\"\$out\""

jm backup-packages >/dev/null
check "package list backed up to BACKUP_DIR" "grep -qx linux $t/backups/packages-*.txt 2>/dev/null"

: >"$log"
echo 1 | jm clean-cache >/dev/null
check "cache cleanup keeps CACHE_KEEP versions" "grep -q 'paccache -rk5' $log"

: >"$log"
echo n | jm update >/dev/null || true
check "declined update changes nothing" "! grep -qE '^pacman -Sy' $log && grep -q '^checkupdates' $log"

: >"$log"
jm service restart foo.service >/dev/null
check "service command runs systemctl" "grep -q 'systemctl restart foo.service' $log"
if [[ $EUID -ne 0 ]]; then
    check "privileged steps go through sudo" "grep -q '^sudo systemctl restart foo.service' $log"
fi

# The menu survives a failed action: install a package that doesn't exist,
# then leave with 0. Before, set -e killed the menu on the first failure.
menu_out="$(printf '2\nno-such-package\n\n0\n' | jm menu 2>&1)" && rc=0 || rc=$?
check "menu survives a failed action" "[[ $rc == 0 ]] && grep -q \"didn't finish\" <<<\"\$menu_out\" && grep -q Exiting <<<\"\$menu_out\""
check "end of input leaves the menu cleanly" "jm menu </dev/null >/dev/null 2>&1"

exit $fail
