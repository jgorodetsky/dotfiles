# dotfiles

Reproducible macOS dev environment. `./install.sh` runs a health check, shows what's
already installed (and where), and lets you fuzzy-pick what to add from the diff.

## Install

```bash
git clone https://github.com/jgorodetsky/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

- `./install.sh` — health-check, then fuzzy-pick what to install (ALL / by class / by feature)
- `./install.sh --all` — install everything missing, no prompt
- `./install.sh --check` — health-check only, installs nothing

Safe to re-run and safe to `git pull` over an existing setup — it only touches what's missing.

## What it manages

| Path | What |
|------|------|
| `Brewfile` | packages (cli, languages, terminal, editor); also the source for the health-check |
| `install.sh` | health-check + fuzzy installer: Homebrew, packages, config, ghostty theme |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | completions, ghh, gtheme alias, git aliases |
| `git/.gitconfig` | behavior only — included from your real `~/.gitconfig` (see below) |
| `macos/defaults.sh` | key repeat, file extensions, screenshots (reloads Finder/SystemUIServer) |
| `ghostty/` | ChessKing theme + `gtheme` picker (see `ghostty/README.md`) |
| `claude/commands/` | Claude Code slash commands |

Config is symlinked with [GNU Stow](https://www.gnu.org/software/stow/) (shell only), so
editing a file in the repo takes effect immediately.

## Git identity

`install.sh` adds an `[include]` of this repo's `git/.gitconfig` to your **real** `~/.gitconfig`
— it never symlinks it, so global git writes never land in the repo. Set identity the normal way:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

Those write to `~/.gitconfig` (untracked, machine-specific); the repo stays identity-free.
