# Rules for every agent

Every agent tool on this machine reads this file. Claude Code imports it from `~/.claude/CLAUDE.md`;
Codex, pi and Copilot read a link to it. The source is `agents/AGENTS.md` in the dotfiles repo,
which is public: nothing private goes in here.

## Skills

Every skill goes through the same four steps, in this order:

1. **Format:** the Agent Skills spec, https://agentskills.io/specification.
   - The folder name and `name` match: lowercase letters, digits and single hyphens, 64 characters at most.
   - `description` says what the skill does and when to use it, in 1024 characters at most.
   - The only top-level frontmatter fields are `name`, `description`, `license`, `compatibility`, `metadata` and `allowed-tools`. Anything for one tool (like `argument-hint`) goes under `metadata`.
   - Keep `SKILL.md` under 500 lines. Longer material goes in `references/`, `scripts/` or `assets/`.
2. **Write or change it** with Anthropic's skill-creator (the `skill-creator` skill in Claude Code).
3. **Validate:** `uvx --from skills-ref==0.1.1 agentskills validate <skill-folder>` has to pass.
4. **Install** only through `dot` (`dot fix`, then skills). It checks the installed copies for edits, then runs `npx skills@1.7.4` with `DISABLE_TELEMETRY=1`. Don't run `npx skills add` for these yourself, and don't edit the copies in `~/.agents/skills` or `~/.claude/skills`. Change the source, then install again.

Public skills live in the dotfiles repo under `agents/skills/`. Private ones live in `~/engine/skills/` and never go in the public repo.

## Review pages

When a plan, diagram, table or set of choices reads better as a page, use lavish:
`npx -y lavish-axi@0.1.93 <page.html>`, then `npx -y lavish-axi@0.1.93 poll <page.html>` for the answers.

- Pages go in `.lavish/` in the working folder. Git ignores that folder everywhere.
- `lavish-theme` prints the `<head>` lines for a page in the terminal's colors.
- Never run `lavish-axi share`. It publishes the page on a third-party site.

## Private rules

If `~/engine/RULES.md` exists, read it too. It holds the rules that stay out of the public repo.
