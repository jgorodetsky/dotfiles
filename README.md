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
- `./install.sh --all` - install everything missing, no prompt (the `MISSING` row in the picker does the same)
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
| `macos` | Changes eight settings: key repeat delay and speed, file extensions, screenshot folder, Cmd+1 opens the apps launcher, and Ctrl+Option+←/→ tiles a window to the left/right half. The first run saves your previous values to `~/.dotfiles-macos-defaults.bak`. |
| `claude` | Installs Claude Code with the native installer only if `claude` isn't on your PATH. An existing install (native or Homebrew) is left alone. |
| `aws` | Runs `awssetup`, which writes only inside a marked block in `~/.aws/config`. See [AWS SSO](#aws-sso). |
| packages | `brew bundle` only adds. Nothing is uninstalled. |
| tap trust | Every run trusts the Brewfile entries marked `trusted: true` (Homebrew 6+ refuses third-party formulae until they're trusted). Only those exact formulae, not the whole tap. |

To remove the shell layer, delete the `# >>> dotfiles >>>` block from `~/.zshrc` and `~/.zprofile`.

## Machine-specific config

Anything that belongs to one machine or one job (work aliases, internal tools, secrets wiring)
goes in `~/.zshrc.local`. It's never committed, and the repo `.zshrc` loads it near the end so
it wins over anything defined here. Lines you add to `~/.zshrc` below the dotfiles block win too.

```
~/.zshrc
  your / IT's existing lines        <- untouched
  # >>> dotfiles >>>
    source ~/dotfiles/shell/.zshrc  <- generic config
      ... source ~/.zshrc.local     <- machine-specific, wins
  # <<< dotfiles <<<
  lines you add later               <- also win
```

If the machine already has an oh-my-zsh theme or powerlevel10k, the starship prompt is skipped,
and a `~/.config/starship.toml` of your own is used instead of the repo's.

## AWS SSO

One browser login, a profile for every AWS account and role you're allowed into, no access keys.

```bash
awssetup    # asks for your start url, logs in once, writes a profile per account + role
awslogin    # fzf-pick a profile for this shell (logs in again only when the session expired)
awsme       # who am I actually authenticated as
```

`awssetup` walks you through finding the start URL: sign in to AWS the way you normally do, then
paste the address bar from the page that lists your accounts. Profiles are named
`<account>-<role>` and it can set a low-risk `[default]` for plain `aws` calls.

It writes only inside a `# >>> awssetup >>>` block in `~/.aws/config` and backs the file up
first. Profiles your company's tooling created stay as they are, and a name that already exists
outside the block is skipped. If the config already has an `sso-session`, it tells you that
`awslogin` already works and asks before adding anything. Re-run it to pick up new accounts.

## Shell helpers

Two ways to look things up:

- `mine` - everything on your setup in one A-Z table: tools (eza, bat, zoxide...), keys (ctrl-r...),
  and every alias and function, with what it replaces and an example. `mine aws` shows every aws
  thing, `mine bat eza` just those, `mine cd` whatever replaced cd. Aliases and functions are read
  live from `.zshrc` and `.zshrc.local`, so new ones show up on their own; tools and keys live in
  `shell/mine.tsv` (`mine --edit`). Piped (`mine | grep aws`) it prints plain tab-separated rows.
- `tldr <command>` - 5-8 real examples for any public command, e.g. `tldr tar`.

Plain `alias` shows your aliases as a table too (piped, like `alias | grep git`, it's the normal list).

Both draw through `boxtable`, which turns any tab-separated text into a boxed table: rows always
sorted A-Z by the first column, columns that are empty everywhere dropped, at most 110 characters
wide (`BOXTABLE_MAX_WIDTH`), long text wrapped at spaces. `printf 'name\tsize\nfoo\t12\n' | boxtable`.

A table taller than your screen opens searchable: type words to filter the rows (they can be in any
column, all must match, `'word` for loose matching), Enter leaves the matching rows printed in your
terminal (Enter with nothing typed prints the whole table), Esc closes. Short tables just print,
and piped output is always plain. `boxtable --plain` never opens the search.

| Command | What |
|---------|------|
| `ctrl-r` / `ctrl-t` | fuzzy history search / file picker with a bat preview (fzf) |
| `ff` | fuzzy-pick a file with a preview, enter opens it in `$EDITOR` (vim by default) |
| `fif <text>` | live search inside files as you type, enter opens the match at that line |
| `z <dir>` / `zi` | jump to a frequent folder / pick one with fzf and a tree preview (zoxide) |
| `alt-c` (or `esc` then `c`) | fuzzy-cd into any folder below here, with a tree preview |
| `ls` `ll` `la` / `cat` | eza (git status per file) / bat, plain ls/cat if they aren't installed |
| `k` `kcur` `kctx` | kubectl, current context, fzf-pick a context (`kctx -u` clears it) |
| `ccupdate` | update Claude Code now, however it was installed |

The prompt (starship) shows the folder, git branch and status, AWS profile and region, and kube
context. Contexts with `prod` in the name turn red. Native Claude Code installs auto-update on their own;
`CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` makes Homebrew installs do the same.

## What's in it

| Path | What |
|------|------|
| `Brewfile` | packages (cli, prompt, cloud, languages, terminal, editor); also the source for the health check |
| `install.sh` | health check + installer |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | completions, aliases, fzf/zoxide/eza/bat, aws + kube helpers, prompt, plugins |
| `shell/starship.toml` | prompt layout |
| `bin/awssetup` | AWS SSO profile generator (on PATH via `.zprofile`) |
| `bin/mine-table`, `shell/mine.tsv` | the engine behind `mine`, and the tools/keys/notes it adds to your aliases and functions |
| `bin/boxtable` | draws tab-separated text as a boxed table (used by mine and alias) |
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
