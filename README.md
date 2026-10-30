# dotfiles

This repository keeps the configuration files for my softwares that I use between computers. Vim, the shell, and tmux.
You can use the same configuration on macOS, Ubuntu, and Rocky Linux.

## Modes

The repository has two modes:

| Mode    | Contents                                                                |
|---------|-------------------------------------------------------------------------|
| `light` | The base settings and four small Vim plugins. No other tools are necessary. |
| `full`  | The light mode, plus more Vim plugins, shell aliases, and tmux settings. |

Each computer keeps its mode in the file `~/.dotfiles_mode`.

## Install

To install on a new computer, type one of these commands:

```sh
# Light mode
curl -fsSL https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --light

# Full mode, with the tools for full mode
curl -fsSL https://raw.githubusercontent.com/YagizEbil/dotfiles/main/bootstrap.sh | bash -s -- --full --deps
```

The command does these steps:

1. It copies the repository to `~/dotfiles`.
2. It links the configuration files into your home directory.
3. It installs the Vim plugins for the mode.

The `--deps` option also installs `git`, `vim`, `curl`, and `gitleaks`.
In full mode, it also installs `tmux`, `fzf`, and `ripgrep`.

NOTE: Do not type `sudo` before `install.sh` or `bootstrap.sh`. If you use `sudo`, the script installs the files for the root user, not for you. The script asks for your password when it must install packages.

When the installation is complete, open a new terminal.

## Change the mode

To change the mode on a computer, type one of these commands:

```sh
~/dotfiles/install.sh --light        # Change to light mode
~/dotfiles/install.sh --full --deps  # Change to full mode
```

When you change to light mode, the script removes the Vim plugins that only full mode uses.

## Repository structure

```
dotfiles/
├── vimrc                  Vim base settings and plugin loader (both modes)
├── vim/
│   ├── plugins.light.vim  Vim plugins for both modes
│   ├── plugins.full.vim   Vim plugins for full mode only
│   └── full.vim           Vim settings and key mappings for full mode only
├── shell/
│   ├── common.sh          Shell base settings: PATH, aliases, OS detection (both modes)
│   └── full.sh            Shell aliases and functions for full mode only
├── tmux.conf              tmux base settings (both modes)
├── tmux/full.conf         tmux settings for full mode only
├── install.sh             Links the files, installs the plugins, and keeps the mode
├── bootstrap.sh           Copies the repository and starts install.sh
├── sync.sh                Gets the latest changes and starts install.sh
└── hooks/pre-commit       Stops a commit that contains a secret
```

The files in your home directory point to the files in the repository:

| File in your home directory | Points to                        |
|-----------------------------|----------------------------------|
| `~/.vimrc`                  | `vimrc` (symbolic link)          |
| `~/.tmux.conf`              | `tmux.conf` (symbolic link)      |
| `~/.dotfiles`               | The repository (symbolic link)   |
| `~/.bashrc` and `~/.zshrc`  | `shell/common.sh` (one line at the end of the file) |

Thus, when you edit a file in the repository, the change applies immediately on that computer.

The install script does not replace your `~/.bashrc` or `~/.zshrc`. It adds one line at the end of the file.

## Where to make a change

Use this table to find the file to edit:

| Change                                   | File to edit               |
|------------------------------------------|----------------------------|
| Vim setting for all computers            | `vimrc`                    |
| Vim setting for full mode only           | `vim/full.vim`             |
| Vim plugin for all computers             | `vim/plugins.light.vim`    |
| Vim plugin for full mode only            | `vim/plugins.full.vim`     |
| Shell alias or function for all computers | `shell/common.sh`         |
| Shell alias or function for full mode only | `shell/full.sh`          |
| tmux setting for all computers           | `tmux.conf`                |
| tmux setting for full mode only          | `tmux/full.conf`           |

### Add a Vim plugin

1. Open `vim/plugins.light.vim` or `vim/plugins.full.vim`.
2. Add one line for the plugin, for example `Plug 'preservim/nerdtree'`.
3. Type `./install.sh` to install the plugin.

### Add a new configuration file

This example adds a Git configuration file.

1. Put the file in the repository with the name `gitconfig`.
2. Open `install.sh`.
3. Find the `LINKS` list.
4. Add this line to the list: `gitconfig:.gitconfig`
5. Type `./install.sh`. The script links `~/.gitconfig` to the file in the repository.

## Send a change to the other computers

Do these steps on the computer where you made the change:

```sh
cd ~/dotfiles                          # Go to the repository
./install.sh                           # Apply the change on this computer
git add -A                             # Add all changes to the next commit
git commit -m "Describe the change"    # gitleaks examines the files for secrets
git push                               # Send the change to GitHub
```

Do this step on each of the other computers:

```sh
~/dotfiles/sync.sh
```

The `sync.sh` script gets the latest changes and starts `install.sh`. Each computer keeps its own mode.

NOTE: If you have changes on a computer that you did not commit, `sync.sh` stops. Commit the changes first.

## Settings for one computer only

These files are not in the repository. Use them for settings that apply to one computer only.

| File                 | Contents                                    |
|----------------------|---------------------------------------------|
| `~/.secrets`         | API keys and tokens                         |
| `~/.shell.local`     | Shell aliases and PATH for this computer    |
| `~/.vimrc.local`     | Vim settings for this computer              |
| `~/.tmux.local.conf` | tmux settings for this computer             |

CAUTION: DO NOT PUT API KEYS OR PASSWORDS IN THE REPOSITORY. PUT THEM IN `~/.secrets`.

In the shell files, you can use these variables to make a setting for one system or one mode:

- `$DOTFILES_OS`: `mac`, `ubuntu`, `rocky`, or the name of a different Linux system.
- `$DOTFILES_MODE`: `light` or `full`.

## Full mode key mappings in Vim

The leader key is Space.

| Keys        | Action                         |
|-------------|--------------------------------|
| `Space f`   | Find a file                    |
| `Space b`   | Find an open buffer            |
| `Space g`   | Find text in all files (ripgrep) |
| `Space h`   | Remove the search highlight    |
| `Space w`   | Save the file                  |
