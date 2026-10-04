# shellcheck shell=bash
# desc: check the system and tune pacman.conf

[[ -f /etc/arch-release ]] || die "This doesn't look like Arch Linux (/etc/arch-release missing)."
[[ $EUID -ne 0 ]] || die "Run jarch-install as your normal user, not root. It uses sudo when needed."
have sudo || die "sudo is not installed. As root: pacman -S sudo, then add your user to wheel."

if [[ "$DRY_RUN" == 1 ]]; then
    info "Dry run: skipping sudo and network checks"
else
    info "Checking sudo access (you may be asked for your password)"
    sudo -v || die "Your user can't use sudo."
    # keep the sudo timestamp fresh for long package installs
    ( while kill -0 "$$" 2>/dev/null; do sudo -n true; sleep 50; done ) 2>/dev/null &
    if ! curl -fsS --max-time 10 -o /dev/null https://archlinux.org; then
        die "No internet connection (couldn't reach archlinux.org)."
    fi
    ok "sudo and network OK"
fi

if [[ -e /var/lib/pacman/db.lck ]]; then
    die "pacman is locked (/var/lib/pacman/db.lck). Close other package managers, or remove the lock if none is running."
fi

# pacman.conf tweaks; each is idempotent
_pconf=/etc/pacman.conf
if [[ "$PACMAN_COLOR" == 1 ]] && ! grep -q '^Color' "$_pconf"; then
    run sudo sed -i 's/^#Color/Color/' "$_pconf" && ok "pacman: Color on"
fi
if [[ -n "$PACMAN_PARALLEL_DOWNLOADS" ]] && ! grep -q "^ParallelDownloads = $PACMAN_PARALLEL_DOWNLOADS\$" "$_pconf"; then
    run sudo sed -i "s/^#\?ParallelDownloads.*/ParallelDownloads = $PACMAN_PARALLEL_DOWNLOADS/" "$_pconf" \
        && ok "pacman: ParallelDownloads = $PACMAN_PARALLEL_DOWNLOADS"
fi
if [[ "$PACMAN_ILOVECANDY" == 1 ]] && ! grep -q '^ILoveCandy' "$_pconf"; then
    run sudo sed -i '/^ParallelDownloads/a ILoveCandy' "$_pconf" && ok "pacman: ILoveCandy on"
fi
if [[ "$ENABLE_MULTILIB" == 1 ]] && ! grep -q '^\[multilib\]' "$_pconf"; then
    run sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' "$_pconf" && ok "pacman: multilib enabled"
fi
unset _pconf
