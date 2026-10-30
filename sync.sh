#!/usr/bin/env bash
# Pull latest dotfiles and re-apply with this machine's saved mode.
# Usage: ./sync.sh          pull + re-apply
#        ./sync.sh push     pull + re-apply + push local commits
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "! Uncommitted changes - commit or stash first:"; git status --short; exit 1
fi
git pull --rebase
./install.sh
if [ "${1:-}" = push ]; then git push; fi
