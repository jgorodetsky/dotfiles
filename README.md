# dotfiles

My macOS setup: shell, git, Homebrew packages, Ghostty terminal themes and tabs, Neovim, and AI agent skills
that work in Claude Code, Codex, Cursor, Gemini CLI, OpenCode and GitHub Copilot.

`./install.sh` (later: `dot fix`) checks what's already set up, sorts the lines your shell files
already have, and installs what's missing. It never replaces your existing files. See
[Never overwrites](#never-overwrites).

## Install

```bash
git clone https://github.com/jgorodetsky/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`./install.sh` runs on its own screen (like vim) in four steps, one decision per screen, and
leaves a short receipt in your terminal when it's done:

```
 ✓ check ━━ ● shell ━━ ○ pick ━━ ○ install
```

1. **check** - what needs you (why, and what to do), with everything that's fine folded into one
   line per group
2. **shell** - the lines in `~/.zshrc` / `~/.zprofile` besides the loader, in three boxes:
   delete (the repo has them), move (only yours, to `~/.zshrc.local`), you pick (same job under
   another name, a clash, or something destructive). Then merge / keep / overwrite, a question for
   each line in the third box, a check that your shell behaves the same, and a yes before writing
3. **pick** - fix what needs it (already selected), choose items from the full list, upgrade, or nothing
4. **install** - one line per item with a spinner; the full output goes to `~/.cache/dotfiles/`

Arrow keys and enter answer everything; `q` stops at any step.

- `./install.sh --all` - fix everything that needs it, no questions (shell lines merged with the
  safe choices)
- `./install.sh --check` - the check screen only, changes nothing
- `./install.sh --only shell,skills` - (re)apply just those features

Safe to re-run and safe to `git pull` over an existing setup.

## Never overwrites

| Feature | What it does to your machine |
|---------|------------------------------|
| `shell` | Appends one marked block to `~/.zprofile` and `~/.zshrc` that sources the repo files, and never adds it twice. Lines you already had are shown grouped by where they'd go, and you pick: **merge** (ones the repo already does are deleted, yours move to `~/.zshrc.local`, an alias the repo has under another name or a clash asks you), **keep** the file as it is, or **overwrite** (loader only; your lines stay in the backup). Before writing it loads your shell both ways and shows anything that would behave differently. Backups are `.bak-<timestamp>`. Re-running from another checkout (a worktree, say) points the block at that checkout. Older installs that symlinked these files get your original file back first. |
| `git` | Appends an `[include]` of `git/.gitconfig` to `~/.gitconfig`. Your identity and settings stay yours. |
| `ghostty-theme` | Appends a marked block to your Ghostty config. If you already have a different theme file or `gtheme` with the same name, yours is kept as `<file>.bak-<timestamp>`. |
| `ghostty-tabs` | Appends a marked block to your Ghostty config that loads `ghostty/tabs.conf`. Same re-pointing rule as `shell`. |
| `nvim` | Links `~/.config/nvim` to `nvim/`. An existing `~/.config/nvim` of your own is kept as `~/.config/nvim.bak-<timestamp>`. |
| `skills` | Adds skill folders to `~/.agents/skills` and `~/.claude/skills`. A copy you've changed (or one that came from another checkout) is only replaced if you say so: keep all of yours, overwrite all, or choose each one. Replaced copies are saved in `~/.cache/dotfiles/`, outside the skill folders so they don't load as a second skill. |
| `macos` | Changes eight settings: key repeat delay and speed, file extensions, screenshot folder, Cmd+1 opens the apps launcher, and Ctrl+Option+←/→ tiles a window to the left/right half. The first run saves your previous values to `~/.dotfiles-macos-defaults.bak`. |
| `claude` | Installs Claude Code with the native installer only if `claude` isn't on your PATH. An existing install (native or Homebrew) is left alone. |
| `aws` | Runs `awssetup`, which writes only inside a marked block in `~/.aws/config`. See [AWS SSO](#aws-sso). |
| packages | `brew bundle` only adds. Nothing is uninstalled. |
| tap trust | Every run trusts the Brewfile entries marked `trusted: true` (Homebrew 6+ refuses third-party formulae until they're trusted). Only those exact formulae, not the whole tap. |

To remove the shell layer, delete the `# >>> dotfiles >>>` block from `~/.zshrc` and `~/.zprofile`.

## Machine-specific config

Anything that belongs to one machine or one job (work aliases, internal tools, secrets wiring)
goes in `~/.zshrc.local` (login settings: `~/.zprofile.local`). They're never committed, and the
repo files load them last so they win over anything defined here.

```
~/.zshrc                              this Mac's file: only the loader
  # >>> dotfiles >>>
    source ~/dotfiles/shell/.zshrc    every machine (commit changes here)
      ... source ~/.zshrc.local       this Mac only, loads last, wins
  # <<< dotfiles <<<
```

Lines that show up in `~/.zshrc` later (an installer appending `export PATH=...`) are fine; the
next `./install.sh` shows them under `shell` and sorts them the same way.

`dot` is the front door once it's installed:

- `dot` - the check screen, then what's wired to the repo (`→` follows the repo on every pull,
  `(copied)` only changes when `dot fix` runs), then a "what now?" menu with the likely next step
  selected: fix, upgrade, add or remove an alias, open a file
- `dot fix` - the installer above
- `dot upgrade` - newer versions of what you installed, as tick boxes. Your Brewfile packages
  come first. A new major version, or a minor bump of terraform or kubectl (where versions
  have to match your state files or clusters), starts unticked with the reason next to it.
  If Xcode's command line tools are too old for brew to install with, it says so first and can
  update just the tools (Homebrew's own method: no macOS update, no restart, asks for your
  password) or open Software Update. It uses brew's own version info (refreshed about daily) unless you pick
  refresh
- `dot alias NAME 'COMMAND'` - add an alias. It tells you if the name is taken or the command
  already has a name, then asks: every machine (the repo's `shell/.zshrc`, an optional note for
  `mine`, then offers to commit) or this Mac only (`~/.zshrc.local`)
- `dot alias -d NAME` - remove an alias. It finds every file that sets it and asks where: one of
  those files, all of them, or (for one the repo sets) only on this Mac, which adds an `unalias`
  line to `~/.zshrc.local` and leaves the repo alone
- `dot edit [shell|local|profile|git|brew|mine|nvim|ghostty]` - open the file you'd change
- `dot update` - `git pull --ff-only`, then `dot fix`

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
| `ff` | fuzzy-pick a file with a preview, enter opens it in `$EDITOR` (nvim when installed, else vim) |
| `fif <text>` | live search inside files as you type, enter opens the match at that line |
| `z <dir>` / `zi` | jump to a frequent folder / pick one with fzf and a tree preview (zoxide) |
| `alt-c` (or `esc` then `c`) | fuzzy-cd into any folder below here, with a tree preview |
| `ls` `ll` `la` / `cat` | eza (git status per file) / bat, plain ls/cat if they aren't installed |
| `k` `kcur` `kctx` | kubectl, current context, fzf-pick a context (`kctx -u` clears it) |
| `ccupdate` | update Claude Code now, however it was installed |
| `tn <name>` | name this Ghostty tab; it keeps showing what runs in it (`api · nvim`). `tn` alone goes back to automatic |
| `nv <file>` | Neovim with the LazyVim setup (see [Neovim](#neovim)) |
| `trials` | the list of tools being tried (`trials.tsv`) as an editable table in Neovim, rows colored by status (keep green, later yellow, dropped red). `trials --plain` prints it |

The prompt (starship) shows the folder, git branch and status, AWS profile and region, and kube
context. Contexts with `prod` in the name turn red. Native Claude Code installs auto-update on their own;
`CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` makes Homebrew installs do the same.

## Neovim

`nv file` (short for `nvim`) opens [LazyVim](https://www.lazyvim.org), a ready-made setup: file search, a file tree,
code checks for Go, Python, Bash, Terraform, YAML, Docker, JSON, Markdown and Helm, and lazygit.
It's also `$EDITOR`, so `ff`, `fif` and `git commit` open it.

- New to vim: `:Tutor` (30-minute lesson), `space` then `C` (cheat sheet, `nvim/cheat.md`), and
  press `space` and wait to see what every key does.
- Colors come from your active Ghostty theme (`:colorscheme ghostty`, built in `nvim/lua/dotfiles/ghostty.lua`),
  so switching themes with `gtheme` recolors Neovim too. `space` `u` `C` picks another theme with a live
  preview; `:Transparent` toggles the see-through background.
- `.csv` and `.tsv` files open as a table: aligned columns, header pinned, tab / shift+tab between
  columns, `cif` to change a cell.
- `cmd+s` or `ctrl+s` saves. The mouse and the Mac clipboard work.

The first start installs plugins (pinned in `nvim/lazy-lock.json`) and language tools, about a minute.
Your additions go in `nvim/lua/plugins/` and `nvim/lua/config/`; LazyVim's own files stay untouched.

## Git diffs

Every diff you read on screen is drawn by [delta](https://dandavison.github.io/delta/): syntax colors,
line numbers, `n` / `N` to jump between files. Nothing to type, it sits under the aliases and under
lazygit. Output piped to a script or an agent stays a plain patch, and without delta installed git
falls back to plain `less`. Set in `git/.gitconfig`.

| Alias | Runs |
|-------|------|
| `gd` / `gds` | `git diff` (not yet added) / `git diff --staged` (what the next commit contains) |
| `gdh` / `gdw` | `git diff HEAD` (everything since the last commit) / `git diff --word-diff` |
| `gdm` | what this branch changed vs main, the same diff the pull request shows (`gdm --stat` for a summary) |
| `gsh` / `glp` | `git show` (last commit and its diff) / `git log -p` (history with diffs) |
| `gap` / `gbl` | `git add -p` (stage chunk by chunk) / `git blame` |
| `gcm` / `gpf` | `git commit -m` / `git push --force-with-lease --force-if-includes` (won't overwrite someone else's push) |
| `sbs <alias>` | side by side for one command: `sbs gds`, `sbs gdm` |
| `lg` | lazygit: files on the left, diff on the right, stage single lines, commit, push. `\|` switches the diff to side by side |

`lg` and Neovim's `space g g` use `lazygit/config.yml`, plus your own lazygit `config.yml` if you
have one (yours wins).

## Ghostty tabs

Each tab's title shows a status dot, an icon for what's running, and a name:

| Dot | When |
|-----|------|
| 🟢 | at the prompt: folder name (🌿 inside a git repo, 🏠 at home) |
| 🟡 | a command is running: its name (`k get pods` shows ☸️ kubectl) |
| 🔵 | an agent is running (claude, codex, opencode, pi): the folder it runs in, so several agents can be told apart |
| 🔴 | ssh/mosh (shows the host), or the AWS profile or kube context looks like prod |

In a prod context the tab also turns blue. `TABS_PROD_PATTERN` (default `*prod*`) decides what counts
as prod and `TABS_PROD_TINT` sets the color (empty turns the tint off); set them in `~/.zshrc.local`.
`tn <name>` renames a tab and keeps the program in the title; Ghostty's own rename (`ctrl+n` here)
pins a fixed title instead. Lives in `shell/tabs.zsh` and `ghostty/tabs.conf`, and does nothing outside Ghostty.

## What's in it

| Path | What |
|------|------|
| `Brewfile` | packages (cli, prompt, cloud, languages, terminal, editor); also the source for the health check |
| `install.sh` | health check + installer |
| `shell/adopt.zsh` | sorts the lines a machine already has in `~/.zshrc` / `~/.zprofile` (used by install.sh) |
| `bin/dot` | the front door: check + what's wired up, `dot fix`, `dot alias`, `dot edit`, `dot update` |
| `lib/ui.sh` | the installer's screens: its own screen, step bar, arrow-key menus, spinner rows |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | completions, aliases, fzf/zoxide/eza/bat, aws + kube helpers, prompt, plugins |
| `shell/starship.toml` | prompt layout |
| `shell/tabs.zsh`, `ghostty/tabs.conf` | Ghostty tab titles by rule (above) |
| `nvim/` | Neovim config: the LazyVim starter plus `lua/plugins/dotfiles.lua` and `lua/dotfiles/` |
| `bin/trials`, `trials.tsv` | the tools-being-tried list and the command that opens it |
| `bin/awssetup` | AWS SSO profile generator (on PATH via `.zprofile`) |
| `bin/mine-table`, `shell/mine.tsv` | the engine behind `mine`, and the tools/keys/notes it adds to your aliases and functions |
| `bin/boxtable` | draws tab-separated text as a boxed table (used by mine and alias) |
| `git/.gitconfig` | git behavior only, no identity (see below); delta draws diffs |
| `lazygit/config.yml` | lazygit settings: delta diffs, side by side on `\|` |
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
