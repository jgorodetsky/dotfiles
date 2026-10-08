# dotfiles

My macOS setup: shell, git, Homebrew packages, Ghostty terminal themes, and AI agent skills
that work in Claude Code, Codex, Cursor, Gemini CLI, OpenCode and GitHub Copilot.

`./install.sh` runs a health check, shows what's already installed (and where), and lets you
fuzzy-pick what to add. It never replaces your existing files. See [Never overwrites](#never-overwrites).

## Install

```bash
git clone https://github.com/jgorodetsky/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

- `./install.sh` - health check, then fuzzy-pick what to install (ALL / by class / by feature)
- `./install.sh --all` - install everything missing, no prompt
- `./install.sh --check` - health check only, installs nothing
- `./install.sh --only shell,skills` - (re)apply just those features

Safe to re-run and safe to `git pull` over an existing setup.

## Never overwrites

| Feature | What it does to your machine |
|---------|------------------------------|
| `shell` | Appends one marked block to `~/.zprofile` and `~/.zshrc` that sources the repo files. Your own lines stay above it, and re-running never adds it twice. Older installs that symlinked these files get your original file back first. |
| `git` | Appends an `[include]` of `git/.gitconfig` to `~/.gitconfig`. Your identity and settings stay yours. |
| `ghostty-theme` | Appends a marked block to your Ghostty config. If you already have a different theme file or `gtheme` with the same name, yours is kept as `<file>.bak-<timestamp>`. |
| `skills` | Adds skill folders to `~/.agents/skills` and `~/.claude/skills`. If you already have a different skill with the same name, it's skipped. |
| `macos` | Changes four settings (key repeat, file extensions, screenshot folder). The first run saves your previous values to `~/.dotfiles-macos-defaults.bak`. |
| packages | `brew bundle` only adds. Nothing is uninstalled. |

To remove the shell layer, delete the `# >>> dotfiles >>>` block from `~/.zshrc` and `~/.zprofile`.

## What's in it

| Path | What |
|------|------|
| `Brewfile` | packages (cli, languages, terminal, editor); also the source for the health check |
| `install.sh` | health check + installer |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | completions, ghh, gtheme alias, git aliases |
| `git/.gitconfig` | git behavior only, no identity (see below) |
| `macos/defaults.sh` | key repeat, file extensions, screenshots (reloads Finder/SystemUIServer) |
| `ghostty/` | ChessKing + Cadillac themes and the `gtheme` picker (see `ghostty/README.md`) |
| `generator/` | re-renders the ChessKing board image |
| `agents/skills/` | AI agent skills (below) |

Shell and git config are sourced/included from the repo, so editing a file here takes effect
in the next terminal.

## Agent skills

Skills use the open [Agent Skills](https://agentskills.io) format (a folder with a `SKILL.md`),
so one copy works in every harness. `install.sh` copies them to:

- `~/.agents/skills` - Codex, Cursor, Gemini CLI, OpenCode, GitHub Copilot
- `~/.claude/skills` - Claude Code

| Skill | What it does |
|-------|--------------|
| `interactive-diagram` | Builds a self-contained interactive HTML diagram of any system: nested boundaries, status colors, numbered flows, pan/zoom, drill-down and a detail panel |
| `grill-me` | Interviews you one question at a time about a plan or design and saves every answer to `brainstorms/` |
| `laymans` | Explains a concept in plain language with small ASCII diagrams and comparison tables |

In Claude Code, run `/<skill> [what you want]`, e.g. `/interactive-diagram our ingest pipeline`.
With nothing after it, the skill works from the current conversation. Other harnesses pick a
skill up when you name it or when your request matches its description.

Edit skills in `agents/skills/`, then run `./install.sh --only skills`.

## Git identity

`install.sh` adds an `[include]` of this repo's `git/.gitconfig` to your real `~/.gitconfig`.
It never replaces or symlinks that file, so global git writes never land in the repo. Set
identity the normal way:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

Those write to `~/.gitconfig` (untracked, machine-specific); the repo stays identity-free.

## GitHub auth

Git talks to GitHub through `gh`: `git/.gitconfig` sets `gh auth git-credential` as the only
credential helper for github.com. Log in once and the token lives in the macOS Keychain:

```bash
gh auth login
```

No token goes in `~/.gitconfig`, `~/.git-credentials`, or a remote URL. Don't use
`credential.helper store` or a `url."https://<token>@github.com/".insteadOf` rewrite - both
keep the token in plain text.
