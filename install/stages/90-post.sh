# shellcheck shell=bash
# desc: refresh caches and record what was installed

have xdg-user-dirs-update && run xdg-user-dirs-update
have fc-cache && run fc-cache -f >/dev/null
if [[ "$DRY_RUN" == 0 ]]; then
    {
        echo "installed_at=$(date -Is)"
        echo "commit=$(git -C "$JARCH_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
        echo "profiles=${PROFILES[*]}"
    } >"$STATE_DIR/installed"
fi
ok "Recorded install state in $STATE_DIR/installed"
