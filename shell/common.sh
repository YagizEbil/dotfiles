# Shared shell config for bash and zsh on macOS, Ubuntu/Debian and Rocky/RHEL.
# Sourced from ~/.bashrc and ~/.zshrc by a line install.sh adds.
# This is the light-mode base; full mode adds shell/full.sh on top.
# Keep it POSIX-ish so both shells can read it.

# --- OS detection ---------------------------------------------------------
case "$(uname -s)" in
  Darwin) DOTFILES_OS=mac ;;
  Linux)
    if [ -r /etc/os-release ]; then
      DOTFILES_OS=$(. /etc/os-release; echo "${ID:-linux}")   # ubuntu, debian, rocky, rhel, fedora...
    else
      DOTFILES_OS=linux
    fi ;;
  *) DOTFILES_OS=other ;;
esac
export DOTFILES_OS

# --- PATH -----------------------------------------------------------------
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
if [ "$DOTFILES_OS" = mac ]; then
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
  [ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"      # Intel
fi
export PATH

# --- Env --------------------------------------------------------------------
export EDITOR=vim VISUAL=vim

# --- Aliases (GNU vs BSD tools differ) ------------------------------------
if ls --color=auto / >/dev/null 2>&1; then
  alias ls='ls --color=auto'      # GNU (Linux)
else
  alias ls='ls -G'                # BSD (macOS)
fi
alias ll='ls -lAh'
alias grep='grep --color=auto'

# --- Mode (light/full), set by install.sh ---------------------------------
DOTFILES_MODE=$(cat "$HOME/.dotfiles_mode" 2>/dev/null || echo light)
export DOTFILES_MODE
[ "$DOTFILES_MODE" = full ] && [ -f "$HOME/.dotfiles/shell/full.sh" ] && . "$HOME/.dotfiles/shell/full.sh"

# --- Secrets & per-machine overrides (both untracked) ---------------------
[ -f "$HOME/.secrets" ] && . "$HOME/.secrets"
[ -f "$HOME/.shell.local" ] && . "$HOME/.shell.local"
