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

# [jarch] repo section, kept between BEGIN/END markers so re-runs can update it
_jarch_conf() {  # current pacman.conf with the [jarch] section as configured
    local block=""
    [[ "${JARCH_REPO:-1}" == 1 ]] && block="$(jarch_repo_block)"
    JARCH_BLOCK="$block" awk -v first="${JARCH_REPO_FIRST:-1}" '
        BEGIN { block = ENVIRON["JARCH_BLOCK"] }
        # the blank line before the old section goes with it, so re-runs are stable
        /^# BEGIN jarch/ { skip = 1; if (blank) blank--; next }
        skip { if (/^# END jarch/) skip = 0; next }
        /^$/ { blank++; next }
        first == 1 && block != "" && !done && /^\[core\]/ { flush(); print block; print ""; done = 1 }
        { flush(); print }
        END { flush(); if (block != "" && !done) { print ""; print block } }
        function flush() { while (blank > 0) { print ""; blank-- } }
    ' "$_pconf"
}
_want="$(_jarch_conf)"
if [[ "$_want" == "$(cat "$_pconf")" ]]; then
    [[ "${JARCH_REPO:-1}" == 1 ]] && ok "pacman: [jarch] repo already configured"
elif [[ "${JARCH_REPO:-1}" != 1 ]]; then
    run sudo install -m644 /dev/stdin "$_pconf" <<<"$_want" && ok "pacman: [jarch] repo removed"
elif [[ "$DRY_RUN" == 1 ]]; then
    info "Would add the [jarch] repo to $_pconf ($JARCH_REPO_SERVER)"
else
    _db="${JARCH_REPO_SERVER//\$arch/$(uname -m)}/jarch.db"
    if ! curl -fsSL --max-time 20 -o /dev/null "$_db"; then
        warn "Can't reach the [jarch] repo ($_db). Jarch's packages will be built from pkgbuilds/ instead."
        grep -q '^# BEGIN jarch' "$_pconf" && warn "Leaving the existing [jarch] section in $_pconf as it is."
    else
        if [[ "$(jarch_siglevel)" == Required* && -f "$JARCH_DIR/keys/jarch.asc" ]]; then
            _fpr="$(gpg --with-colons --import-options show-only --import "$JARCH_DIR/keys/jarch.asc" 2>/dev/null | awk -F: '/^fpr/ { print $10; exit }')"
            [[ -n "$_fpr" ]] || die "keys/jarch.asc isn't a valid GPG public key"
            if ! sudo pacman-key --list-keys "$_fpr" &>/dev/null; then
                sudo pacman-key --add "$JARCH_DIR/keys/jarch.asc"
                sudo pacman-key --lsign-key "$_fpr"
                ok "pacman: trusted the [jarch] signing key $_fpr"
            fi
        fi
        sudo install -m644 /dev/stdin "$_pconf" <<<"$_want"
        ok "pacman: [jarch] repo configured ($JARCH_REPO_SERVER)"
    fi
fi
unset _pconf _want _db _fpr
unset -f _jarch_conf
