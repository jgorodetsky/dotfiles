---
name: interactive-diagram
description: Build a self-contained interactive HTML diagram of any system (cloud, software, data, process or org) with nested boundaries, status colors, numbered flows, pan and zoom, drill-down and a detail panel. Use when asked for an interactive diagram, architecture map, system overview, or to diagram what was discussed.
---

# Interactive diagram

## What to diagram

Request: $ARGUMENTS

The subject is whatever the user wrote when invoking this skill. If the line above still shows a literal placeholder, read the subject from the user's invoking message instead. If no subject was given, diagram the system discussed in the current conversation, using the components, names, statuses and flows already established there.

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
6. Deliver the HTML as a local file and give its path. Don't publish or upload it unless asked.

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
d.check()      # list of layout problems
d.render(path) # writes the page, returns status counts
```

`detail` keys shown in the side panel: `type`, `what`, `cfg=[[key, value], ...]`, `by` (source file or resource), `next` (what it takes to build it). Declare parents before children.

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
