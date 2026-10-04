# shellcheck shell=bash
# desc: enable services, add groups, set login shell

mapfile -t _svcs < <(profile_items services)
for _s in "${_svcs[@]}"; do
    if systemctl is-enabled --quiet "$_s" 2>/dev/null; then
        ok "$_s already enabled"
    else
        # enable only; services start on next boot so nothing grabs this TTY mid-install
        run sudo systemctl enable "$_s"
        ok "Enabled $_s"
    fi
done

mapfile -t _usvcs < <(profile_items user-services)
for _s in "${_usvcs[@]}"; do
    run systemctl --user enable "$_s" || warn "Couldn't enable user unit $_s (no user session?). It's safe to re-run later."
done

mapfile -t _groups < <(profile_items groups)
for _g in "${_groups[@]}"; do
    if id -nG "$USER" | tr ' ' '\n' | grep -qx "$_g"; then
        ok "$USER already in $_g"
    elif getent group "$_g" >/dev/null || [[ "$DRY_RUN" == 1 ]]; then
        run sudo usermod -aG "$_g" "$USER"
        ok "Added $USER to $_g (takes effect at next login)"
    else
        warn "Group $_g doesn't exist; skipping"
    fi
done

if [[ -n "${LOGIN_SHELL:-}" && "$(getent passwd "$USER" | cut -d: -f7)" != "$LOGIN_SHELL" ]]; then
    if [[ -x "$LOGIN_SHELL" ]] || [[ "$DRY_RUN" == 1 ]]; then
        run sudo chsh -s "$LOGIN_SHELL" "$USER"
        ok "Login shell set to $LOGIN_SHELL"
    else
        warn "LOGIN_SHELL $LOGIN_SHELL isn't installed; leaving shell unchanged"
    fi
fi
unset _svcs _usvcs _groups _s _g
