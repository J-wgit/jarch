# shellcheck shell=bash
# desc: install Jarch's own tools (jarch-manager)

run sudo install -Dm755 "$JARCH_DIR/tools/jarch-manager/arch-manager.sh" /usr/local/bin/jarch-manager
ok "Installed jarch-manager to /usr/local/bin"
# keep a re-run entry point on PATH too
run sudo ln -sfn "$JARCH_DIR/install/jarch-install" /usr/local/bin/jarch-install
ok "Linked jarch-install to /usr/local/bin"
