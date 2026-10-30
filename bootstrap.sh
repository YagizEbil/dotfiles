#!/usr/bin/env bash
# One-command setup on a fresh machine - no SSH keys or GitHub login needed.
#
#   Public repo:
#     curl -fsSL https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --light
#
#   Private repo (read-only token, see README):
#     export GITHUB_TOKEN=github_pat_xxx
#     curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
#       https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --light
#
# Arguments after `--` go to install.sh (--light / --full / --deps).
# Install location: $DOTFILES_DIR (default ~/dotfiles).
set -euo pipefail

REPO="${DOTFILES_REPO:-YagizEbil/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"
DEST="${DOTFILES_DIR:-$HOME/dotfiles}"
URL="https://github.com/$REPO.git"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

say()  { printf '==> %s\n' "$*"; }
warn() { printf '!   %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
export GIT_TERMINAL_PROMPT=0   # never hang on a hidden password prompt

ask_token() {   # read a token from the keyboard even when piped through `curl | bash`
  [ -n "$TOKEN" ] && return 0
  { : < /dev/tty; } 2>/dev/null || return 1   # no keyboard (CI, Codespaces)
  printf 'Repo is private. Paste a read-only GitHub token (input hidden, empty = abort): ' > /dev/tty
  stty -echo < /dev/tty 2>/dev/null || true
  IFS= read -r TOKEN < /dev/tty || true
  stty echo < /dev/tty 2>/dev/null || true
  printf '\n' > /dev/tty
  [ -n "$TOKEN" ]
}

clone_git() {
  say "Cloning $REPO -> $DEST"
  if git clone -q --branch "$BRANCH" "$URL" "$DEST" 2>/dev/null; then return 0; fi
  ask_token || { warn "Clone failed and no token given."; return 1; }
  # Token is only passed for this one command - never written to .git/config
  git -c "http.extraHeader=Authorization: Basic $(printf 'x-access-token:%s' "$TOKEN" | base64 | tr -d '\n')" \
      clone -q --branch "$BRANCH" "$URL" "$DEST"
}

download_tarball() {   # fallback when git is not installed
  say "git not found - downloading a snapshot instead (./sync.sh needs git later)"
  local tmp; tmp="$(mktemp -d)"
  local api="https://api.github.com/repos/$REPO/tarball/$BRANCH"
  if ! curl -fsSL "$api" -o "$tmp/repo.tgz" 2>/dev/null; then
    ask_token || { warn "Download failed and no token given."; return 1; }
    curl -fsSL -H "Authorization: Bearer $TOKEN" "$api" -o "$tmp/repo.tgz"
  fi
  mkdir -p "$DEST"
  tar -xzf "$tmp/repo.tgz" -C "$DEST" --strip-components=1
  rm -rf "$tmp"
}

if [ -d "$DEST/.git" ]; then
  say "Already cloned at $DEST - pulling"
  git -C "$DEST" pull -q --rebase || warn "pull failed (offline or private repo?) - using local copy"
elif [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  warn "$DEST exists and is not a git repo. Set DOTFILES_DIR=... or move it."; exit 1
elif have git; then
  clone_git
else
  download_tarball
fi

chmod +x "$DEST/install.sh" "$DEST/sync.sh" "$DEST/hooks/"* 2>/dev/null || true
say "Running install.sh $*"
exec "$DEST/install.sh" "$@"
