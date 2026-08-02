# dotfiles

Personal Linux (Ubuntu/Debian) development environment: zsh, tmux, Neovim,
and a provisioning script that sets up a full C++/Python/Rust/Yocto
toolchain from a fresh install.

## Install

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
export DOTFILES="$HOME/dotfiles" XDG_CONFIG_HOME="$HOME/.config" \
       XDG_DATA_HOME="$HOME/.local/share"   # only needed before first run
./install.sh          # full setup (packages, toolchains, symlinks, ...)
./install.sh qt       # additionally build QtBase from source
./install.sh --help   # usage
```

`install.sh` is safe to re-run: package installs and symlink/clone steps
skip work that's already done. It symlinks `zsh/.zshenv`, `zsh/.zshrc`, and
`.bashrc` into `$HOME`, sets zsh as the login shell, links tmux/nvim
configs under `$XDG_CONFIG_HOME`, and activates the git hooks below.

## Layout

| path | purpose |
|---|---|
| `install.sh` | machine provisioning, one function per concern (see `main()`) |
| `versions.sh` | shared version/prefix constants (Qt, ccache size) sourced by both `install.sh` and `.zshenv` |
| `zsh/.zshenv` | environment/PATH — always sourced, even by non-interactive shells |
| `zsh/.zshrc` | interactive shell: prompt (Powerlevel10k), plugins (antigen), completion, keybindings |
| `zsh/aliases` | shared aliases/functions (`lower_snake_case` convention) |
| `zsh/yocto` | `bb*` helper functions for the Yocto/RPi cross-compile workflow |
| `zsh/history` | **git-tracked, shared zsh history** (see below) |
| `tmux/` | tmux config + popup session script (F11/F12) |
| `nvim/` | Neovim config (lazy.nvim, mason, per-server LSP configs) |
| `scripts/Bash/`, `scripts/Python/` | personal utility scripts, on `PATH` via `.zshenv` |
| `.githooks/` | tracked git hooks, activated via `core.hooksPath` |

## Shared history across machines

`~/.zsh_history` stays local and untracked; `zsh/history` is the tracked,
deduplicated union of every machine's history:

- `pre-commit` hook: folds this machine's new history into `zsh/history` so
  it rides along in each commit.
- `post-merge` hook: after `git pull`, folds other machines' new entries
  into the local history.
- Fresh install: `install.sh` seeds `~/.zsh_history` from the repo copy.

The merge engine is `scripts/Bash/history-sync` (`export`/`import`), safe
to run manually and idempotent.

## Machine-local extension points (gitignored on purpose)

- `zsh/aliases2` — aliases specific to one machine, sourced if present.
