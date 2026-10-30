# dotfiles

Personal configs shared across machines. Tested on Ubuntu; written for macOS (bash 3.2 / zsh) and Rocky/RHEL (dnf) too.

## Layout

| File               | Purpose                                                         |
|--------------------|-----------------------------------------------------------------|
| `vimrc`            | → `~/.vimrc` (symlink)                                          |
| `tmux.conf`        | → `~/.tmux.conf` (symlink, optional)                            |
| `shell/common.sh`  | Shared bash/zsh config with OS detection; sourced from `~/.bashrc` / `~/.zshrc` |
| `install.sh`       | Links files, hooks shell rc, enables gitleaks hook. Safe to re-run |
| `sync.sh`          | `git pull --rebase` + re-run install (`./sync.sh push` to also push) |
| `hooks/pre-commit` | Blocks commits containing secrets (gitleaks)                    |
| `secrets.example`  | Template for `~/.secrets` (untracked)                           |

Distro default `~/.bashrc`/`~/.zshrc` files are **not replaced**. `install.sh` appends one `source` line, so OS-specific defaults keep working.

## First machine (this Mac)

```sh
mv ~/.vimrc ~/Developer/dotfiles/vimrc
cd ~/Developer/dotfiles
./install.sh --deps          # installs git, vim, curl, gitleaks + links everything
git add -A && git commit -m "Initial dotfiles"
gh repo create dotfiles --private --source . --push   # or add remote manually
```

## Any other machine (Mac / Ubuntu / Rocky)

```sh
# GitHub auth first: `gh auth login` or an SSH key
git clone git@github.com:<you>/dotfiles.git ~/dotfiles   # any path works
cd ~/dotfiles && ./install.sh --deps
```

`--deps` uses brew (mac), apt (Ubuntu/Debian) or dnf/yum (Rocky/RHEL). On Linux, gitleaks is installed as a release binary into `~/.local/bin` (no sudo needed).

## Keeping machines in sync

```sh
./sync.sh          # pull + re-apply
./sync.sh push     # pull + re-apply + push your local commits
```

## Per-machine settings (never committed)

- `~/.secrets` — API keys (`chmod 600`), sourced automatically.
- `~/.shell.local` — machine-specific aliases/PATH (e.g. CUDA paths on the GPU server).
- In shell config, branch on `$DOTFILES_OS` (`mac`, `ubuntu`, `rocky`, ...).

## Before making the repo public

```sh
gitleaks git -v      # full history (older gitleaks: gitleaks detect -v)
```
Rotate any key that was ever committed — removing it from history is not enough.
