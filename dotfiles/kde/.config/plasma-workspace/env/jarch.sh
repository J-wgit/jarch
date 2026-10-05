# Sourced by Plasma at login, before any app starts. Managed by Jarch (dotfiles/kde).

# ~/.local/bin for apps and autostart, not just terminals
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# GUI passphrase prompts for ssh/git when there's no terminal (stored in KWallet)
export SSH_ASKPASS=/usr/bin/ksshaskpass

export EDITOR=nvim
export VISUAL=nvim
