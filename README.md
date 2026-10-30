# dotfiles

Personal configs shared across machines (macOS, Ubuntu/Debian, Rocky/RHEL, Codespaces), with two modes:

- **light**: base settings + a few small Vim plugins. No extra tools needed. Default on new machines.
- **full**: light + extra Vim plugins, shell aliases, tmux tweaks and your custom stuff.

## Install on a new machine (no SSH key or GitHub login needed)

```sh
curl -fsSL https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --light
# or: ... | bash -s -- --full --deps
```

This works without login only while the repo is **public**. If it is private, see [Private repo](#private-repo).
`bootstrap.sh` clones to `~/dotfiles` (change with `DOTFILES_DIR=...`), falls back to a tarball if git is missing, then runs `install.sh`.

Already have git access? Then just:

```sh
git clone https://github.com/YagizEbil/dotfiles.git ~/dotfiles
~/dotfiles/install.sh --light      # or --full; add --deps to install packages
```

## Modes

```sh
./install.sh --light        # switch to light (removes full-only Vim plugins)
./install.sh --full --deps  # switch to full and install tmux, fzf, ripgrep
./install.sh                # re-apply the saved mode (~/.dotfiles_mode)
```

| What  | Light (everywhere)                         | Full only (add your custom stuff here) |
|-------|--------------------------------------------|----------------------------------------|
| Vim   | `vimrc`, `vim/plugins.light.vim`           | `vim/plugins.full.vim`, `vim/full.vim` |
| Shell | `shell/common.sh`                          | `shell/full.sh`                        |
| tmux  | `tmux.conf`                                | `tmux/full.conf`                       |

Light Vim plugins: sensible, commentary, surround, repeat.
Full Vim plugins: fzf, fugitive, gitgutter, polyglot (incl. Verilog/SystemVerilog), lightline, gruvbox.
Full mappings (leader = Space): `<Space>f` files, `<Space>b` buffers, `<Space>g` ripgrep, `<Space>h` clear highlight.

After editing a plugin list, run `./install.sh` (or `:PlugInstall` in Vim).

## Other files

| File               | Purpose                                                         |
|--------------------|-----------------------------------------------------------------|
| `bootstrap.sh`     | One-command install on a fresh machine                          |
| `install.sh`       | Links files, hooks shell rc, enables gitleaks hook, syncs plugins. Safe to re-run |
| `sync.sh`          | `git pull --rebase` + re-apply (`./sync.sh push` to also push)  |
| `hooks/pre-commit` | Blocks commits containing secrets (gitleaks)                    |
| `secrets.example`  | Template for `~/.secrets` (untracked)                           |

`install.sh` also links `~/.dotfiles` → the repo, so configs find it wherever you cloned it.
Your distro's `~/.bashrc` / `~/.zshrc` are not replaced; one `source` line is appended.

## Per-machine settings (never committed)

| File                 | For                              |
|----------------------|----------------------------------|
| `~/.secrets`         | API keys (`chmod 600`)           |
| `~/.shell.local`     | Machine-specific aliases / PATH  |
| `~/.vimrc.local`     | Machine-specific Vim settings    |
| `~/.tmux.local.conf` | Machine-specific tmux settings   |

In shell config you can branch on `$DOTFILES_OS` (`mac`, `ubuntu`, `rocky`, ...) and `$DOTFILES_MODE`.

## Pushing changes from another machine

Pulling works without login (public repo). To push, log in once with a browser code, no SSH key:

```sh
gh auth login          # choose HTTPS + "Login with a web browser"
```

## Private repo

Create a fine-grained token at GitHub → Settings → Developer settings → Fine-grained tokens:
only this repo, **Contents: Read-only**, short expiry. Then:

```sh
export GITHUB_TOKEN=github_pat_xxx
curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --light
```

The token is used only for the clone and is not saved. `./sync.sh` will need `gh auth login` on that machine.

## Codespaces

GitHub → Settings → Codespaces → "Automatically install dotfiles" → pick this repo.
It runs `install.sh` (light mode). For full mode, run `~/.dotfiles/install.sh --full` inside the codespace,
or try a Codespaces secret `DOTFILES_MODE=full`.

## Before making the repo public

```sh
gitleaks git -v      # scan full history (older gitleaks: gitleaks detect -v)
```
Rotate any key that was ever committed. Removing it from history is not enough.
