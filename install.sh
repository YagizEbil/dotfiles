#!/usr/bin/env bash
# Portable dotfiles installer: macOS, Ubuntu/Debian, Rocky/RHEL/Fedora.
# Safe to re-run.
#
# Usage: ./install.sh [--light | --full] [--deps]
#   --light   minimal setup (default on new machines / Codespaces)
#   --full    light + extra plugins, tools and custom config
#   --deps    also install system packages (git, vim, curl, gitleaks; +tmux, fzf, ripgrep in full)
# The chosen mode is saved in ~/.dotfiles_mode and reused by later runs and ./sync.sh.
# Override without a flag: DOTFILES_MODE=full ./install.sh
#
# Written for bash 3.2 (macOS default): no mapfile, no associative arrays.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITLEAKS_VERSION="8.21.2"
BIN="$HOME/.local/bin"
MODE_FILE="$HOME/.dotfiles_mode"

info() { printf '  %s\n' "$*"; }
warn() { printf '! %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Arguments --------------------------------------------------------------
DEPS=0; MODE=""
for arg in "$@"; do
  case "$arg" in
    --deps)  DEPS=1 ;;
    --light) MODE=light ;;
    --full)  MODE=full ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) warn "unknown option: $arg"; exit 1 ;;
  esac
done

# --- Mode: flag > $DOTFILES_MODE > saved file > ask (if interactive) > light --
if [ -z "$MODE" ] && [ -n "${DOTFILES_MODE:-}" ]; then MODE="$DOTFILES_MODE"; fi
if [ -z "$MODE" ] && [ -f "$MODE_FILE" ]; then MODE="$(tr -d '[:space:]' < "$MODE_FILE")"; fi
if [ -z "$MODE" ] && [ -t 0 ] && [ -t 1 ]; then
  read -r -p "Install mode? [l]ight / [f]ull (default light): " ans || true
  case "$ans" in f|F|full) MODE=full ;; esac
fi
case "${MODE:-light}" in full) MODE=full ;; *) MODE=light ;; esac
printf '%s\n' "$MODE" > "$MODE_FILE"

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
echo "dotfiles: $DOTFILES  ($PLATFORM/$ARCH, pkg: $PM, mode: $MODE)"

# --- Dependency install ------------------------------------------------------
APT_UPDATED=0
pkg_install() {
  case "$PM" in
    brew) have brew || { warn "Homebrew missing: https://brew.sh"; return 1; }; brew install "$@" ;;
    apt)  [ "$APT_UPDATED" = 1 ] || { $SUDO apt-get update -qq; APT_UPDATED=1; }
          $SUDO apt-get install -y "$@" ;;
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
  if have gitleaks || [ -x "$BIN/gitleaks" ]; then info "gitleaks present"; return 0; fi
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

if [ "$DEPS" = 1 ]; then
  echo "Installing dependencies..."
  for p in git vim curl; do have "$p" || pkg_install "$p" || warn "failed: $p"; done
  install_gitleaks || warn "gitleaks install failed"
  if [ "$MODE" = full ]; then
    # fzf / ripgrep live in EPEL on Rocky/RHEL
    if [ "$PM" = dnf ] || [ "$PM" = yum ]; then
      rpm -q epel-release >/dev/null 2>&1 || pkg_install epel-release || warn "could not enable EPEL"
    fi
    for p in tmux fzf ripgrep; do
      bin="$p"; [ "$p" = ripgrep ] && bin=rg
      have "$bin" || pkg_install "$p" || warn "failed: $p (install manually)"
    done
  fi
fi

# --- ~/.dotfiles -> repo (lets configs find the repo wherever it is cloned) --
if [ "$DOTFILES" != "$HOME/.dotfiles" ]; then
  if [ -L "$HOME/.dotfiles" ] || [ ! -e "$HOME/.dotfiles" ]; then
    ln -sfn "$DOTFILES" "$HOME/.dotfiles"
  else
    warn "~/.dotfiles exists and is not a symlink - configs may not find the repo"
  fi
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
# shellcheck disable=SC2016  # $HOME is expanded by the shell rc, not here
LINE='[ -f "$HOME/.dotfiles/shell/common.sh" ] && . "$HOME/.dotfiles/shell/common.sh"  '"$MARK"
hook_rc() {
  local rc="$HOME/$1"
  [ -e "$rc" ] || [ "$2" = always ] || return 0
  if [ -f "$rc" ] && grep -qxF "$LINE" "$rc"; then info "ok     ~/$1"; return 0; fi
  if [ -f "$rc" ] && grep -qF "$MARK" "$rc"; then   # replace an older dotfiles line
    local tmp; tmp="$(mktemp)"; grep -vF "$MARK" "$rc" > "$tmp"; cat "$tmp" > "$rc"; rm -f "$tmp"
  fi
  printf '\n%s\n' "$LINE" >> "$rc"; info "hooked ~/$1"
}
echo "Hooking shell..."
hook_rc .bashrc always                                                        # Linux default shell
hook_rc .zshrc  "$([ "$PLATFORM" = mac ] && echo always || echo ifexists)"   # macOS default shell
# macOS login bash reads .bash_profile, not .bashrc
if [ "$PLATFORM" = mac ] && ! grep -qs '\.bashrc' "$HOME/.bash_profile"; then
  printf '\n[ -f ~/.bashrc ] && . ~/.bashrc\n' >> "$HOME/.bash_profile"; info "hooked ~/.bash_profile"
fi

# --- Git hooks -------------------------------------------------------------
chmod +x "$DOTFILES/hooks/"* "$DOTFILES/"*.sh 2>/dev/null || true
git -C "$DOTFILES" config core.hooksPath hooks 2>/dev/null || warn "not a git checkout - hooks not enabled"
info "git hooks enabled"
have gitleaks || [ -x "$BIN/gitleaks" ] || warn "gitleaks not installed - commits will be blocked. Run: ./install.sh --deps"

# --- Secrets template ------------------------------------------------------
if [ ! -f "$HOME/.secrets" ]; then
  cp "$DOTFILES/secrets.example" "$HOME/.secrets"; chmod 600 "$HOME/.secrets"
  info "created ~/.secrets (600) - fill in your keys"
fi

# --- Vim: vim-plug + plugins for the current mode --------------------------
echo "Vim plugins ($MODE)..."
PLUG="$HOME/.vim/autoload/plug.vim"
if [ ! -f "$PLUG" ]; then
  mkdir -p "$(dirname "$PLUG")"
  fetch https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim "$PLUG" \
    && info "installed vim-plug" || warn "vim-plug download failed"
fi
if have vim && have git && [ -f "$PLUG" ]; then
  # Install missing plugins and remove ones the current mode no longer uses
  if vim -E -s -u "$HOME/.vimrc" +'PlugInstall --sync' +'PlugClean!' +qall </dev/null >/dev/null 2>&1; then
    info "plugins synced"
  else
    warn "plugin install had errors - open vim and run :PlugInstall"
  fi
fi

echo "Done ($MODE mode). Open a new shell (or: source ~/.bashrc / ~/.zshrc)."
[ "$MODE" = light ] && echo "Switch to full anytime: ./install.sh --full --deps"
exit 0
