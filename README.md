# dotfiles

Reproducible macOS dev environment. One command on a fresh machine installs the
toolchain, shell config, and terminal setup.

## Install

```bash
git clone https://github.com/jgorodetsky/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run; it skips whatever is already installed.

## What it sets up

| Path | What |
|------|------|
| `Brewfile` | packages (cli, iac, terminal, editor) installed via `brew bundle` |
| `install.sh` | Xcode CLT, Homebrew, packages, config symlinks, macos defaults, ghostty theme |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | ghh + git aliases |
| `git/.gitconfig` | behavior only — identity is per-machine (see below) |
| `macos/defaults.sh` | minimal system defaults (key repeat, file extensions, screenshots) |
| `ghostty/` | ChessKing terminal theme + `gtheme` picker (see `ghostty/README.md`) |
| `claude/commands/` | Claude Code slash commands |

Config is symlinked with [GNU Stow](https://www.gnu.org/software/stow/), so editing a
file in the repo takes effect immediately.

## Git identity (per machine)

`git/.gitconfig` carries no name, email, or signing key — set them per machine in an
untracked `~/.gitconfig.local`:

```bash
cp git/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```
