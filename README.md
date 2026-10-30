# dotfiles

My macOS setup: shell, git, Homebrew packages, Ghostty terminal themes and tabs, Neovim, and AI agent skills
that work in Claude Code, Codex, Cursor, Gemini CLI, OpenCode, GitHub Copilot and pi.

[dott](https://github.com/jgorodetsky/dott) checks what's already set up, sorts the lines your
shell files already have, and installs what's missing. It never replaces a file of yours without
asking. See [Never overwrites](#never-overwrites).

## Setup and updates

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jgorodetsky/dotfiles/main/install.sh)"
```

```
install.sh                                   every day after
  1  Homebrew, if it is missing                dott
     (it asks for your Mac password once)        the header says when GitHub has new commits:
  2  dott, from its Homebrew tap                 ↑ origin/main has new commits: pick refresh
  3  dott --init jgorodetsky/dotfiles              │
     clones this repo to ~/dotfiles                ▼
  4  dott asks once about the optional parts   refresh
     (AWS, kube, the macOS settings, the         the new commits, the items they touch and
     ChessKing theme)                            the diff of every changed script
        │                                          │ Pull? [Y/n]
        ▼                                          ▼
     fix everything                            git pull --ff-only, then the fix plan
                                                 and its own Run it? [Y/n/copy]
```

In a clone, `./install.sh` does the same with that folder.

`fix everything` sets up what's missing: it shows the plan, asks once, backs up what it changes
and checks each item after. Things of your own (your own `~/.config/nvim`, a rules file of a
tool's own) stay as they are until you pick `resolve` for them. Without a terminal,
`dott fix everything --yes` does the same and never replaces yours.

The update check asks GitHub with `git ls-remote`: it fetches nothing, never asks for a password,
and gives up after 5 seconds, so offline there is no notice and no wait. dott itself updates with
Homebrew (the `upgrade` row, or `brew upgrade dott`).

Safe to re-run and safe to `git pull` over an existing setup.

## Never overwrites

| Item | What it does to your machine |
|---------|------------------------------|
| `shell-zprofile`, `shell-zshrc` | Appends one marked block to `~/.zprofile` and `~/.zshrc` that sources the repo files, and never adds it twice. A block from another checkout (a worktree, say) is pointed at this one. |
| `shell-sort` | The lines you already had besides the loader: the ones the repo already does are deleted, yours move to `~/.zshrc.local` / `~/.zprofile.local`, and a line that clashes with the repo stays there commented out (the repo's wins). The plan lists the counts first; a `.bak-<timestamp>` of each file goes next to it. |
| `git-include`, `git-ignore` | Appends an `[include]` of `git/.gitconfig` to `~/.gitconfig`. Your identity and settings stay yours. Adds the lines in `git/ignore` (`.lavish/`, `.playwright-mcp/`) that your global ignore file (`~/.config/git/ignore`, or your `core.excludesFile`) doesn't have yet, and keeps the rest. |
| `ghostty-tabs` | Appends a marked block to your Ghostty config that loads `ghostty/tabs.conf`. |
| `ghostty-themes`, `gtheme` | Copies the themes to `~/.config/ghostty/themes` and links `~/.local/bin/gtheme` to `ghostty/gtheme`. A theme file you changed is yours: it is left alone until you pick `resolve`. |
| `ghostty-theme` (optional) | Adds the ChessKing block to your Ghostty config once, and only when your config has no `theme =` line of its own. |
| `nvim` | Links `~/.config/nvim` to `nvim/`. An `~/.config/nvim` of your own is left alone: `resolve nvim` keeps it (the item turns off), replaces it (yours goes to the backup first), or compares the two. |
| `skills` | Installs the skills with `npx skills@1.7.4` (telemetry off): one copy in `~/.agents/skills` and a link to it in `~/.claude/skills`. npx skills overwrites without asking, so dott checks first: each install is recorded in `~/.local/state/dott` (it still reads the old `~/.cache/dotfiles/skills.sync`), so it can tell a repo update (installed with fix) from your edits to an installed copy (yours until you pick `resolve`). Skills that fail the spec check aren't installed. `~/.claude/skills/synced` is never touched. |
| `rules` | Appends a marked block with `@<repo>/agents/AGENTS.md` to `~/.claude/CLAUDE.md` (your own lines stay), and links `~/.codex/AGENTS.md`, `~/.pi/agent/AGENTS.md`, `~/.copilot/copilot-instructions.md`, `~/.config/opencode/AGENTS.md` and `~/.gemini/GEMINI.md` to `agents/AGENTS.md`, for the tools that are installed. A tool with a file of its own keeps it until you pick `resolve`. |
| `macos` (optional) | Changes eight settings: key repeat delay and speed, file extensions, screenshot folder, Cmd+1 opens the apps launcher, and Ctrl+Option+←/→ tiles a window to the left/right half. The first run saves your previous values to `~/.dotfiles-macos-defaults.bak`. |
| `claude` | Installs Claude Code with the native installer only if `claude` isn't on your PATH. An existing install (native or Homebrew) is left alone. |
| `aws` (optional) | Runs `awssetup`, which asks its own questions and writes only inside a marked block in `~/.aws/config`. See [AWS SSO](#aws-sso). |
| `clipfmt` (each link rule is off until you turn it on in `dott clipfmt`) | The first rule you turn on builds `~/.local/bin/clipfmt` with `swiftc` (Xcode's command line tools), runs `clipfmt/test.sh`, and starts it at login (`~/Library/LaunchAgents/io.github.jgorodetsky.clipfmt.plist`). Each rule that is on is a line in `~/.config/clipfmt/enabled`. Turning the last one off stops clipfmt and removes the program and the agent; your rules stay. See [clipfmt](#clipfmt). |
| `brew` | Installs the Brewfile's packages that are missing. Nothing is uninstalled or upgraded. Entries marked `trusted: true` are trusted first (Homebrew 6+ refuses third-party formulae until they are): only those exact formulae, not the whole tap. awscli, kubectl and helm are in the optional groups. |

Every fix backs up what it changes to `~/.local/state/dott/backups`; `restore a backup` puts it back.
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
next `dott` shows them as `shell-sort` and sorts them the same way.

`dott` is the front door. Type any words after it to filter, like `dott aws` or `dott drift`:

- `dott` - what needs you, then every item and its state, then the tools. Enter on an item opens
  it: where it lives here and in the repo (a file opens in your editor), its parts, its fix, its
  entry in `dott.toml`, and turn off. Esc goes back one screen, ctrl-c quits
- `optional parts` - turn AWS, kube, the macOS settings or the ChessKing theme on or off
- `fix everything` - what drifted; your own things and the items that ask questions are left to you
- `upgrade` - newer versions of what you installed. Your Brewfile packages come first. A new
  major version, or a minor bump of terraform or kubectl (where versions have to match your state
  files or clusters), needs a typed yes, with the reason next to it. If Xcode's command line tools
  are too old for brew to build with, it says so and prints the commands (dott never runs sudo).
  It uses brew's own version info (refreshed about daily) unless you pick refresh
- `add alias` (under `add`, with `add skill`) - it tells you if the name is taken or the command already has a name, then asks:
  every machine (the repo's `shell/.zshrc`, an optional note for `mine`, then offers to commit
  only that line) or this Mac only (`~/.zshrc.local`)
- `remove alias` - it finds every file that sets it and asks where: one of those files, all of
  them, or (for one the repo sets) only on this Mac, which adds an `unalias` line to
  `~/.zshrc.local` and leaves the repo alone
- `edit shell` (also `local`, `profile`, `git`, `brew`, `mine`, `nvim`, `ghostty`, `rules`, `clipfmt`, `skills`, `dott`) - open the file you'd change
- `refresh` - fetches, shows the incoming commits, the items they touch and the diff of every
  changed script, asks `Pull?`, then shows the fix plan and asks again
- `permissions claude` (also codex, opencode, pi) - what each agent may do without asking, risky rules flagged; read-only

The header has the counts. The optional clean-ups are notes in an item's view: git settings you
also set in the repo (`git-include`), and packages the Brewfile doesn't list (`brew`).

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
| `s` + alias | side by side: `sgd`, `sgds`, `sgdm`, `sgsh`, `sglp`. Not for `gap` (`git add -p` needs the plain layout) or `gbl` (blame isn't a diff) |
| `lg` | lazygit: files on the left, diff on the right, stage single lines, commit, push. `\|` switches the diff to side by side |

`lg` and Neovim's `space g g` use `lazygit/config.yml`, plus your own lazygit `config.yml` if you
have one (yours wins).

## clipfmt

Copy a link, and Slack shows a short link instead of the whole URL. A terminal still gets the
full URL. Every rule is off until you turn it on.

| Rule | You copy | Slack shows (a link to the full URL) |
|---|---|---|
| `pr` | `https://github.com/owner/dott/pull/1234` | PR#1234-dott |
| `issue` | `https://github.com/owner/dott/issues/56` | #56-dott |
| `gitlab-mr` | `https://gitlab.com/acme/web/-/merge_requests/7` | !7-web |
| `jira` | `https://<your site>/browse/DEV-1900`, or a board with `?selectedIssue=DEV-1900` | DEV-1900 |
| `confluence` | `https://<your site>/wiki/spaces/OPS/pages/123/Deploy+runbook` | OPS: Deploy runbook |
| `linear` | `https://linear.app/acme/issue/ENG-123/fix-login` | ENG-123: fix login |

```
copy a link ──▶ clipfmt (4 checks a second, at login)
                  │ is it one https link? macOS says so without clipfmt reading it
                  │ does a rule that is on match it?
                  ▼
clipboard = rich text  <a href="full URL">PR#1234-dott</a>  ──▶ Slack, Mail, Notes: the short link
          + plain text  the full URL                         ──▶ Ghostty, any terminal: the URL
```

`dott clipfmt` shows each rule as a row, and `dott clipfmt linear` opens one:

```
clipfmt ›
  · pr                off   github.com/…/pull/1234 → PR#1234-dott · preset
  · linear            off   linear.app/…/ENG-123/fix-login → ENG-123: fix login · preset
  ▸ add a link rule         any site, from one example link: this Mac only or every machine
  ▸ test a link             what a copied link pastes as, as you type it
```

- A rule's own view turns it on or off, changes its format with a live preview, or removes it.
- `add a link rule` starts from one example link, and needs no regex. clipfmt numbers the link's
  parts, you pick the parts that change from link to link, and you write the format with those
  numbers: `{3}: {4:words}` makes ENG-123: fix login. `{N:words}` turns `-`, `_` or `+` into
  spaces, and `{host}` is the link's host.
- A new rule goes to this Mac only (`~/.config/clipfmt/local.tsv`, the default) or to every
  machine (`clipfmt/rules.tsv` in this repo, which is public). A Jira or Confluence address can
  name an employer, so a rule for every machine shows its exact line first, and a host other than
  github.com, gitlab.com or linear.app needs a typed yes.
- A new format for a preset is this Mac's own copy. Remove it, and the preset comes back.
- clipfmt reloads both rules files by itself. `bash clipfmt/clipfmt.sh test` builds it in a temp
  folder and checks each rule's example, `clipfmt/cases.tsv` and the flows. After a change to
  `clipfmt.swift`, run `bash clipfmt/clipfmt.sh rebuild`.
- It leaves alone: a copy from a password manager, a copy that already has its own formatting,
  anything that isn't exactly one https link, and every other kind of link. It never logs what
  you copy and never uses the network. The Jira and Confluence rules match the link's path on any
  site, so no company address is in this repo.
- The first time it shortens a link, macOS asks whether clipfmt may paste from other apps. Pick
  allow. After a rebuild macOS can ask once more.
- Apps that read rich text all get the short link: Slack, but also Mail, Notes and Google Docs.

## Ghostty tabs

Each tab's title shows a status dot, an icon for what's running, and a name:

| Dot | When |
|-----|------|
| 🟢 | at the prompt: folder name (🌿 inside a git repo, 🏠 at home) |
| 🟡 | a command is running: its name (`k get pods` shows ☸️ kubectl) |
| 🔵 | an agent is running: its name and the folder it runs in (`🔵 🤖 opencode - api`), so several agents can be told apart. pi sets its own title (`π - api`) and has no switch to turn that off |
| 🔴 | ssh/mosh (shows the host), or the AWS profile or kube context looks like prod |

In a prod context the tab also turns blue. `TABS_PROD_PATTERN` (default `*prod*`) decides what counts
as prod and `TABS_PROD_TINT` sets the color (empty turns the tint off); set them in `~/.zshrc.local`.
`tn <name>` renames a tab and keeps the program in the title; Ghostty's own rename (`ctrl+n` here)
pins a fixed title instead. Claude Code's and OpenCode's own titles are turned off so these show.
Lives in `shell/tabs.zsh` and `ghostty/tabs.conf`, and does nothing outside Ghostty.

## What's in it

| Path | What |
|------|------|
| `dott.toml` | every item [dott](https://github.com/jgorodetsky/dott) sets up, and how it checks each one |
| `install.sh` | the one-line bootstrap: Homebrew, dott, then `dott --init` |
| `Brewfile` | packages (cli, prompt, cloud, languages, terminal, editor); dott's `brew` item reads it |
| `shell/adopt.zsh` | sorts the lines a machine already has in `~/.zshrc` / `~/.zprofile` |
| `shell/sort.zsh` | the `shell-sort` item: adopt.zsh as a check, a plan and a merge |
| `shell/.zprofile` | login env: Homebrew + PATH (kept unique) |
| `shell/.zshrc` | completions, aliases, fzf/zoxide/eza/bat, aws + kube helpers, prompt, plugins |
| `shell/starship.toml` | prompt layout |
| `shell/tabs.zsh`, `ghostty/tabs.conf` | Ghostty tab titles by rule (above) |
| `nvim/` | Neovim config: the LazyVim starter plus `lua/plugins/dotfiles.lua` and `lua/dotfiles/` |
| `bin/trials`, `trials.tsv` | the tools-being-tried list and the command that opens it |
| `bin/awssetup` | AWS SSO profile generator (on PATH via `.zprofile`) |
| `bin/mine-table`, `shell/mine.tsv` | the engine behind `mine`, and the tools/keys/notes it adds to your aliases and functions |
| `bin/boxtable` | draws tab-separated text as a boxed table (used by mine and alias) |
| `bin/lavish-theme` | prints the `<head>` lines for a lavish page in Ghostty's colors (a DaisyUI theme) |
| `git/ignore` | lines added to your global git ignore file |
| `git/.gitconfig` | git behavior only, no identity (see below); delta draws diffs |
| `lazygit/config.yml` | lazygit settings: delta diffs, side by side on `\|` |
| `clipfmt/` | clipfmt (above): `clipfmt.swift`, the presets (`rules.tsv`), `cases.tsv`, `clipfmt.sh` (builds, installs and checks it for dott), `flows.sh` (the add, format and test questions) and `test.sh` |
| `macos/defaults.sh` | key repeat, file extensions, screenshots (reloads Finder/SystemUIServer); `--check` and `--plan` for dott |
| `ghostty/` | ChessKing + Cadillac themes and the `gtheme` picker (see `ghostty/README.md`) |
| `generator/` | re-renders the ChessKing board image |
| `agents/skills/` | AI agent skills (below) |
| `agents/AGENTS.md` | the rules every agent tool reads (below) |
| `agents/docs/` | rules an agent reads only for some tasks: git, Terraform, tools, skills, long answers |

Shell and git config are sourced/included from the repo, so editing a file here takes effect
in the next terminal.

## Agent skills

Skills use the open [Agent Skills](https://agentskills.io/specification) format (a folder with a
`SKILL.md`), so one copy works in every harness. `dott` installs them with `npx skills`:

- `~/.agents/skills` - the one real copy. Codex, OpenCode, GitHub Copilot, pi, Cursor and Gemini CLI read it here
- `~/.claude/skills/<name>` - a link to it, for Claude Code

Public skills live in `agents/skills/`. Skills that belong to one Mac live outside this repo:
that Mac's `~/.config/dott/config.toml` names the folder (`[local] skills = [...]`), and dott
installs them the same way, marked local.

| Skill | What it does |
|-------|--------------|
| `interactive-diagram` | Builds a self-contained interactive HTML diagram of any system: nested boundaries, status colors, numbered flows, pan/zoom, drill-down and a detail panel. Add `review` to go over it in lavish, `sketch` for an editable whiteboard, `draw` to draw it yourself with coaching |
| `grill-me` | Interviews you one question at a time about a plan or design and saves every answer to `brainstorms/`. Questions that don't depend on each other come together in one round, recommended answers first; on a lavish page only if you ask |
| `laymans` | Teaches a concept the Feynman way: plain language, ASCII diagrams, one honest analogy, a ladder from plain words to edge cases, or a coach mode where you explain it back and it finds the holes. Reference files on the ladder, analogies and failure modes load only when needed (MIT parts from guicortei/feynman-technique) |
| `deepen` | Rewrites a request into the version a top professional would ask for, then stops |
| `icm-architect` | Designs a process or body of knowledge as an ICM workspace, folder structure as agent architecture (MIT, by Jake Van Clief) |
| `asd-ste100` | Rewrites text an agent reads (rules files, skills, tool descriptions, error messages) into Simplified Technical English, with a linter for the structural rules (MIT, from danyuchn/asd-ste100-skill) |

In Claude Code, run `/<skill> [what you want]`, e.g. `/interactive-diagram our ingest pipeline`.
With nothing after it, the skill works from the current conversation. Other harnesses pick a
skill up when you name it or when your request matches its description.

Every skill follows the spec, is written with Anthropic's skill-creator, and passes
`uvx --from skills-ref==0.1.1 agentskills validate <folder>`. Edit them in `agents/skills/`
(`dott edit skills`), then pick `fix skills`.

## Agent rules

`agents/AGENTS.md` is a short router that every agent tool loads in every session: how to
answer, how to work, and a "Read when" table that points to `agents/docs/` for rules that only
some tasks need (git, Terraform, tools, skills, long answers). Tone stays in AGENTS.md itself,
since an agent opens a routed file only when it decides to.

dott (the `rules` item) connects it: an `@import` line in `~/.claude/CLAUDE.md` for Claude
Code, and links for Codex, pi, Copilot, OpenCode and Gemini CLI. Change it with `dott edit rules`; every tool
sees the change in its next session. Agent-facing text is written in STE-flavored English and
checked with the `asd-ste100` skill's linter.

## Git identity

dott adds an `[include]` of this repo's `git/.gitconfig` to your real `~/.gitconfig`.
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
