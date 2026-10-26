---
name: interactive-diagram
description: Build a self-contained interactive HTML diagram of any system (cloud, software, data, process or org) with nested boundaries, status colors, numbered flows, pan and zoom, drill-down and a detail panel. Use when asked for an interactive diagram, architecture map, system overview, or to diagram what was discussed. Add "review" to open it in lavish for feedback rounds, "sketch" for an editable Excalidraw whiteboard, or "draw" to have the user draw it with coaching.
---

# Interactive diagram

## What to diagram

Request: $ARGUMENTS

The subject is whatever the user wrote when invoking this skill. If the line above still shows a literal placeholder, read the subject from the user's invoking message instead. If no subject was given, diagram the system discussed in the current conversation, using the components, names, statuses and flows already established there.

## Mode

A last word of `review`, `sketch` or `draw` picks the mode. Drop that word from the subject.

| Mode | What you make | What the user does |
|---|---|---|
| (none) | the interactive diagram, below | opens the file you give them |
| `review` | the same diagram, opened in lavish | clicks and annotates it; you revise each round |
| `sketch` | a Mermaid draft that lavish turns into an Excalidraw whiteboard | moves, adds and renames shapes; you fold the edits in |
| `draw` | a near-blank whiteboard | draws it themselves; you coach |

`review`, `sketch` and `draw` use lavish (see "Lavish modes" below). Without Node or npx, say so and fall back to the plain file.

## Target

Build a single self-contained interactive HTML diagram as nested boundary boxes holding icon tiles (icon in a rounded square, bold real name, one muted detail line), color-coded by status, with numbered flows drawn in distinct line styles, using exact names from the source of truth in a terse architect tone with a minimal legend that shows counts. Make it explorable like a map, with everything driven from one embedded JSON node list: drag to pan, pinch or ⌘-scroll to zoom, click a boundary title to zoom in with a breadcrumb trail, click a tile to open a side panel with its type, config table, source and next step, click a flow to dim everything else and number its steps, and include a status filter and search.

## Steps

1. Gather facts from the real source: code, config, live state, docs, or this conversation. Never invent names, IDs or values. Leave a field out when unsure.
2. Model it: boundaries (what contains what), items, a status per item, and 2 to 6 flows with ordered steps.
   - Three status colors: `built` green, `todo` red, `ext` gray. Rename the labels to fit the subject, e.g. `{"built": "Done", "todo": "Blocked", "ext": "External"}`.
   - Mark `todo` only for agreed work with an owner, never for your own suggestions.
3. Write a generator script with `kit/diagram_kit.py` from this skill's directory. Copy `kit/example.py` as the starting point. Python 3, stdlib only. Keep the script next to the output so the diagram can be rebuilt after edits.
4. Run it and fix everything `d.check()` reports (overlaps, children outside parents, flow steps that are not nodes).
5. Look at it in a real browser. Serve the folder over localhost (`python3 -m http.server`), since automation browsers block `file://`. Screenshot the full view and each major boundary zoomed in, and fix any overlap or arrow crossing a label. Click a tile, a flow, the status filter, a boundary title and search, and confirm the console has no errors. Check at 400px wide.
6. Deliver the HTML as a local file and give its path. Don't publish or upload it unless asked. In `review` mode, open it in lavish instead (below).

## Kit API

```python
d = Diagram(title, width, height, subtitle="", statuses={"built": "Built", "todo": "Not built", "ext": "Existing"})
d.icon(key, path_or_svg)              # .svg/.png file or raw "<svg ..." string; tiles without an icon show initials
d.flow(id, name, blurb, style, steps)  # declare flows before arrows; style: solid | dashed | dotted | dash-dot | long-dash
                                       # steps: [[node_id, "what happens here"], ...]
d.boundary(id, parent, x, y, w, h, title, icon=None, st="zone", sub=None, dash=None, fill="none", fop=0, **detail)
d.item(id, parent, cx, cy, label, sub="", st="built", icon=None, lw=118, pos="below", **detail)  # pos: below | right
d.chip(id, parent, x, y, w, text, st="built", **detail)          # small pill: rules, settings, sub-parts
d.cloud(id, parent, cx, cy, label, sub="", st="ext", **detail)   # external endpoint
d.arrow(flow_id, [(x, y), ...], blocked=False)                 # right-angle polyline
d.badge(flow_id, x, y)                                         # numbered circle on an arrow
d.blocked_mark(flow_id, x, y)                                  # red X on a blocked path
d.revision(id, label, summary)                                 # one review round, e.g. ("r1", "Round 1", "split the API tier")
d.check()      # list of layout problems
d.render(path) # writes the page, returns status counts
```

`detail` keys shown in the side panel: `type`, `what`, `cfg=[[key, value], ...]`, `by` (source file or resource), `next` (what it takes to build it). Declare parents before children.

`rev="r1"` on `boundary`, `item`, `chip`, `cloud`, `flow` or `arrow` marks it as changed in that round. lavish shows a Revisions legend from these. Mark only what a round actually changed, never on a first draft.

## Layout rules

- Pick a grid first: column x and row y values about 160px apart for tiles with labels below. Use `pos="right"` for long names or dense columns.
- Tiles are 56px. A label below a tile takes roughly cy+30 to cy+80. Keep tiles at least 58px below their boundary's top edge so they clear the title.
- Route arrows through the gaps between boxes with right angles. Start and end them at tile edges (cx ± 28, cy ± 28) and never run them through label text.
- Place flow badges on an arrow segment, away from tiles.
- Use the official icon set when one exists and is available locally (Azure, AWS or GCP architecture icons, a product's own icons). Otherwise initials are fine.
- Wide canvases (2000 to 2500px) are fine, since the viewer pans and zooms.
- Don't rewrite the viewer. Change `kit/template.html` only for a real gap, and keep it generic.

## Style

- Architect tone: names and facts only. No commentary, no source tags, no marketing words.
- Minimal legend: status counts only. The header hint line comes from the template.
- Lead with the answer: put the one-sentence takeaway in `subtitle` (the Overview panel shows it first).
- Verified or inferred: when you confirmed an item in the source, put that source in `by`. When you inferred it, add a `cfg` row `["evidence", "inferred: <why>"]`.
- A link you couldn't confirm gets a `?` at the end of its step text, e.g. `"pushes to the queue ?"`, and a `dotted` flow if the whole flow is unconfirmed.

## Lavish modes

lavish opens the page in the browser, where the user can click, annotate and send feedback. Run it pinned, from the folder you're working in:

```
npx -y lavish-axi@0.1.93 <page.html>          # opens it (or resumes the session)
npx -y lavish-axi@0.1.93 poll <page.html>     # waits for the user's feedback
```

- Pages go in `.lavish/<slug>/` in the working folder, with the generator script next to them.
- Run `poll` as a background job your harness tracks and tells you about when it finishes (in Claude Code: Bash with `run_in_background`). Never `nohup`, `&` or `disown`. With no tracked background jobs, poll in the foreground. Don't tell the user you're watching until the poll is running.
- When feedback arrives, read all of it, change the generator, rebuild, then poll again with a short note of what you changed: `poll <page.html> --agent-reply "<what changed>"`.
- Mark each round: `d.revision("rN", "Round N", "<what changed>")` plus `rev="rN"` on what you changed (sketch and draw pages have no revisions).
- Fix layout problems only when the user queues them. If the poll says `browser_disconnected`, ask whether to reopen or end. If the user ends the session, stop and never reopen it uninvited.
- Never run `lavish-axi share`: it publishes the page on a public third-party site.

### review

Build the diagram as in Steps, render it to `.lavish/<slug>/<slug>.html`, open it, poll, and revise each round as above.

### sketch

1. Write the system as a Mermaid `flowchart` in `.lavish/<slug>/<slug>.mmd`: boundaries as `subgraph`s, the real names from Steps 1-2 as nodes, and flows as labeled arrows. Mark unconfirmed arrows with `?` in the label.
2. Optional icons from installed Excalidraw libraries: run `npx -y lavish-axi@0.1.93 libraries` (and `libraries --search <text>` for exact names), then add `%% lavish-icon <node-id> <library-id>/<item name>` lines. Skip this when none are installed. Libraries live in `~/.lavish-axi/excalidraw-libraries/`.
3. Build the page: `python3 <this skill>/kit/whiteboard.py .lavish/<slug>/<slug>.html .lavish/<slug>/<slug>.mmd --title "<name>" --answer "<one-sentence takeaway>"`. It pins Mermaid at 11.15.0, the version lavish 0.1.93 ships.
4. Open it and poll. Whiteboard feedback comes back tagged `whiteboard`, with an edit summary plus a scene file (`.excalidraw`) and a PNG. Read the summary first and open the files only when you need to. Apply the edits to the `.mmd`, rebuild, and poll again. Never write the scene back.
5. When the user is happy, offer to build the full interactive diagram from the final Mermaid (Steps 2-5).

### draw

The user draws and you coach, so they learn the system by building it.

1. Write a near-blank `.mmd`: only what they asked to start from, or the outer boundaries if the subject has known zones, e.g. `flowchart LR` then `start([Start drawing here])`.
2. Build it with `--draw` and open it, then poll.
3. For each round, read the edit summary and the PNG, then reply through `poll --agent-reply` with what's right, the one most important thing missing or wrong, and one question that leads to it. Don't redraw it for them and don't change the `.mmd` (that would ask them to throw away their drawing).
4. When they're done, offer to turn their drawing into the interactive diagram, using their names and layout.
