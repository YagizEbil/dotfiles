# Full mode shell config - put your custom aliases/functions here.
# Sourced by shell/common.sh when ~/.dotfiles_mode is 'full'. Works in bash and zsh.

# --- Git shortcuts ----------------------------------------------------------
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'

# --- Navigation -------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
mkcd() { mkdir -p "$1" && cd "$1"; }

# --- Dotfiles ---------------------------------------------------------------
alias dots='cd "$HOME/.dotfiles"'
alias dsync='"$HOME/.dotfiles/sync.sh"'

# --- fzf / ripgrep (only if installed) ---------------------------------------
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
fi
if command -v fzf >/dev/null 2>&1; then
  if [ -n "${ZSH_VERSION:-}" ]; then
    # fzf >= 0.48 has built-in shell integration; older versions ship key-binding files
    if fzf --zsh >/dev/null 2>&1; then eval "$(fzf --zsh)"; else
      for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/fzf/shell/key-bindings.zsh; do
        [ -f "$f" ] && . "$f" && break; done; fi
  elif [ -n "${BASH_VERSION:-}" ]; then
    if fzf --bash >/dev/null 2>&1; then eval "$(fzf --bash)"; else
      for f in /usr/share/doc/fzf/examples/key-bindings.bash /usr/share/fzf/shell/key-bindings.bash; do
        [ -f "$f" ] && . "$f" && break; done; fi
  fi
fi

# --- Prompt with git branch (bash only; zsh users can add their own) ---------
if [ -n "${BASH_VERSION:-}" ]; then
  __git_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/ (&)/'; }
  PS1='\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[33m\]$(__git_branch)\[\e[0m\]\$ '
fi
