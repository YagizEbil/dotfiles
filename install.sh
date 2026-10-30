#!/usr/bin/env bash
# Portable dotfiles installer: macOS, Ubuntu/Debian, Rocky/RHEL/Fedora.
# Safe to re-run. Usage:  ./install.sh          link configs + hooks
#                         ./install.sh --deps   also install git, vim, curl, gitleaks
# Written for bash 3.2 (macOS default): no mapfile, no associative arrays.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITLEAKS_VERSION="8.21.2"
BIN="$HOME/.local/bin"

info() { printf '  %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Detect OS / package manager ------------------------------------------
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS" in
  Darwin) PLATFORM=mac; PM=brew ;;
  Linux)
    PLATFORM=linux
    if   have apt-get; then PM=apt
    elif have dnf;     then PM=dnf
    elif have yum;     then PM=yum
    else PM=none; fi ;;
  *) warn "Unsupported OS: $OS"; exit 1 ;;
esac
SUDO=""; [ "$(id -u)" -ne 0 ] && have sudo && SUDO="sudo"
echo "dotfiles: $DOTFILES  ($PLATFORM/$ARCH, pkg: $PM)"

# --- Optional dependency install ------------------------------------------
pkg_install() {
  case "$PM" in
    brew) have brew || { warn "Homebrew missing: https://brew.sh"; return 1; }; brew install "$@" ;;
    apt)  $SUDO apt-get update -qq && $SUDO apt-get install -y "$@" ;;
    dnf)  $SUDO dnf install -y "$@" ;;
    yum)  $SUDO yum install -y "$@" ;;
    *)    warn "No package manager found; install manually: $*"; return 1 ;;
  esac
}

fetch() {  # fetch URL DEST
  if have curl; then curl -fsSL "$1" -o "$2"
  elif have wget; then wget -qO "$2" "$1"
  else warn "need curl or wget"; return 1; fi
}

install_gitleaks() {
  have gitleaks && { info "gitleaks present ($(gitleaks version 2>/dev/null))"; return; }
  if [ "$PLATFORM" = mac ]; then pkg_install gitleaks; return; fi
  # Linux: distro packages are missing or old -> use the official release binary (no sudo)
  local a
  case "$ARCH" in
    x86_64|amd64)  a=x64 ;;
    aarch64|arm64) a=arm64 ;;
    *) warn "No gitleaks binary for $ARCH; install manually"; return 1 ;;
  esac
  local tmp; tmp="$(mktemp -d)"
  fetch "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${a}.tar.gz" "$tmp/gl.tgz"
  tar -xzf "$tmp/gl.tgz" -C "$tmp" gitleaks
  mkdir -p "$BIN" && mv "$tmp/gitleaks" "$BIN/gitleaks" && chmod +x "$BIN/gitleaks"
  rm -rf "$tmp"
  info "installed gitleaks -> $BIN/gitleaks"
}

if [ "${1:-}" = "--deps" ]; then
  echo "Installing dependencies..."
  for p in git vim curl; do have "$p" || pkg_install "$p"; done
  install_gitleaks
fi

# --- Symlinks: "repo_path:target_in_HOME" ---------------------------------
LINKS="
vimrc:.vimrc
tmux.conf:.tmux.conf
"

link() {
  local src="$DOTFILES/$1" dst="$HOME/$2"
  [ -e "$src" ] || { info "skip   $1 (not in repo)"; return 0; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then info "ok     ~/$2"; return 0; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak; bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"; info "backup ~/$2 -> $bak"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"; info "link   ~/$2"
}

echo "Linking configs..."
for pair in $LINKS; do link "${pair%%:*}" "${pair#*:}"; done

# --- Shell rc: append one source line instead of replacing distro defaults --
MARK="# dotfiles"
LINE="[ -f \"$DOTFILES/shell/common.sh\" ] && . \"$DOTFILES/shell/common.sh\"  $MARK"
hook_rc() {
  local rc="$HOME/$1"
  [ -e "$rc" ] || [ "$2" = always ] || return 0
  if [ -f "$rc" ] && grep -qxF "$LINE" "$rc"; then info "ok     ~/$1"; return 0; fi
  if [ -f "$rc" ] && grep -qF "$MARK" "$rc"; then
    # update path in case the repo moved
    local tmp; tmp="$(mktemp)"; grep -vF "$MARK" "$rc" > "$tmp"; cat "$tmp" > "$rc"; rm -f "$tmp"
  fi
  printf '\n%s\n' "$LINE" >> "$rc"; info "hooked ~/$1"
}
echo "Hooking shell..."
hook_rc .bashrc always                       # Linux default shell
hook_rc .zshrc  "$([ "$PLATFORM" = mac ] && echo always || echo ifexists)"   # macOS default shell
# macOS login bash reads .bash_profile, not .bashrc
if [ "$PLATFORM" = mac ] && ! grep -qs '\.bashrc' "$HOME/.bash_profile"; then
  printf '\n[ -f ~/.bashrc ] && . ~/.bashrc\n' >> "$HOME/.bash_profile"; info "hooked ~/.bash_profile"
fi

# --- Git hooks -------------------------------------------------------------
chmod +x "$DOTFILES/hooks/"* "$DOTFILES/"*.sh 2>/dev/null || true
git -C "$DOTFILES" config core.hooksPath hooks
info "git hooks enabled"
have gitleaks || have "$BIN/gitleaks" || warn "gitleaks not installed - commits will be blocked. Run: ./install.sh --deps"

# --- Secrets template ------------------------------------------------------
if [ ! -f "$HOME/.secrets" ]; then
  cp "$DOTFILES/secrets.example" "$HOME/.secrets"; chmod 600 "$HOME/.secrets"
  info "created ~/.secrets (600) - fill in your keys"
fi

# --- vim-plug (plugins themselves are not committed) -----------------------
PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$PLUG" ]; then
  mkdir -p "$(dirname "$PLUG")"
  fetch https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim "$PLUG" \
    && info "installed vim-plug - run :PlugInstall in vim" || warn "vim-plug download failed"
fi

echo "Done. Open a new shell (or: source ~/.bashrc / ~/.zshrc)."
