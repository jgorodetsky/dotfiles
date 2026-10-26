# Tools

Read this when you make a review page, use GitHub or add a new tool. Each section says when to use the tool and gives the exact command.

## lavish: review pages

Use lavish when a plan, a diagram, a table or a set of choices reads better as a page.

- Open the page: `npx -y lavish-axi@0.1.93 <page.html>`
- Get my answers: `npx -y lavish-axi@0.1.93 poll <page.html>`
- Put pages in `.lavish/` in the working folder. Git ignores that folder everywhere.
- `lavish-theme` prints the `<head>` lines for a page in the colors of the terminal.
- Never run `lavish-axi share`. It publishes the page on a third-party site.

## GitHub

- Use `gh` for issues, pull requests and API calls.

## Package runners

- Pin the version in each `npx` and `uvx` command, for example `npx -y lavish-axi@0.1.93`.
- Set `DISABLE_TELEMETRY=1` when you run `npx skills`.

## Add a tool

1. Add a section to this file. Write what the tool does, when to use it, the pinned command and the commands that are not permitted.
2. If the tool has its own skill, copy the skill into `agents/skills/` and follow `docs/skills.md`.
3. Add a row to the "Read when" table in `AGENTS.md` only if agents miss the tool without it. Example: "When I say 'qa this', run no-mistakes."
