#!/usr/bin/env bash
# Pull latest dotfiles and re-apply. Usage: ./sync.sh   (add "push" to also push local commits)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "! Uncommitted changes - commit or stash first:"; git status --short; exit 1
fi
git pull --rebase
./install.sh
[ "${1:-}" = push ] && git push
