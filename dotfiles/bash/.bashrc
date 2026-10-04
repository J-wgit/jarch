# ~/.bashrc — Jarch
# Managed by Jarch (dotfiles/bash). Put machine-specific bits in ~/.bashrc.local.

# Non-interactive shells stop here
[[ $- != *i* ]] && return

# Where the Jarch repo lives (written by jarch-install)
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/jarch/env" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/jarch/env"
export JARCH_DIR="${JARCH_DIR:-$HOME/.jarch}"
# dots_stow_* functions in ~/.bash-functions use this
export DOTFILES_DIR="$JARCH_DIR/dotfiles"

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less

# PATH
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
export PATH

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize autocd cdspell globstar

# Completion
[[ -r /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion

# Colours
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ip='ip -color=auto'

# Aliases and functions
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
[[ -f ~/.bash-functions ]] && source ~/.bash-functions

# Local overrides
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local

# Prompt
command -v starship &>/dev/null && eval "$(starship init bash)"
