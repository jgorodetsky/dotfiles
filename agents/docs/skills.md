# Skills and agent files

Read this before you create or change a skill, `AGENTS.md` or a file in `agents/docs/`.

## Skills

Every skill goes through the same four steps, in this order:

1. **Format:** the Agent Skills spec, https://agentskills.io/specification.
   - The folder name and `name` match: lowercase letters, digits and single hyphens, 64 characters at most.
   - `description` says what the skill does and when to use it, in 1024 characters at most.
   - The only top-level frontmatter fields are `name`, `description`, `license`, `compatibility`, `metadata` and `allowed-tools`. Put a field for one tool (like `argument-hint`) under `metadata`.
   - Keep `SKILL.md` under 500 lines. Put longer material in `references/`, `scripts/` or `assets/`.
2. **Write or change it** with Anthropic's skill-creator (the `skill-creator` skill in Claude Code).
3. **Validate:** `uvx --from skills-ref==0.1.1 agentskills validate <skill-folder>` has to pass.
4. **Install** only through `dot` (`dot fix`, then skills). It looks for edits in the installed copies, then runs `npx skills@1.7.4` with `DISABLE_TELEMETRY=1`. Do not run `npx skills add` for these skills yourself. Do not edit the copies in `~/.agents/skills` or `~/.claude/skills`. Change the source, then install again.

Public skills live in the dotfiles repo under `agents/skills/`. Private skills live in `~/engine/skills/` and never go in the public repo.

A skill from another author keeps its `LICENSE` and gets an `UPSTREAM` file. The file gives the author, the source, the date and each change that you made.

## Text that agents read

- Write new text for `AGENTS.md`, `agents/docs/` and `SKILL.md` files in STE-flavored English. The asd-ste100 skill has the rules.
- Then lint the file: `python3 -I ~/.agents/skills/asd-ste100/scripts/ste-lint.py <file>`
- A finding for a word that the file quotes on purpose, such as a banned word, is not an error.
