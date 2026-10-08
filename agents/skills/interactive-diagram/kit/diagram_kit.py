import base64
import html
import json
import os
import re

KIT = os.path.dirname(os.path.abspath(__file__))
COL = {"built": "#1d8a4a", "todo": "#d42a2a", "ext": "#7a8491"}
INK, MUTED, LINE = "#18212b", "#5b6672", "#9aa5b1"
FONT = "'Segoe UI', 'Helvetica Neue', Arial, sans-serif"
DASH = {
    "solid": "",
    "dashed": ' stroke-dasharray="8 5"',
    "dotted": ' stroke-dasharray="2 5" stroke-linecap="round"',
    "dash-dot": ' stroke-dasharray="10 4 2 4"',
    "long-dash": ' stroke-dasharray="6 4"',
}
MIME = {".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}


def esc(s):
    return html.escape(str(s), quote=True)


def _pieces(word, maxc):
    if len(word) <= maxc or "-" not in word:
        return [word]
    out, cur = [], ""
    for p in re.findall(r"[^-]+-?", word):
        if len(cur + p) <= maxc or not cur:
            cur += p
        else:
            out.append(cur)
            cur = p
    return out + ([cur] if cur else [])


def wrap(text, maxw, fs):
    text = str(text).replace(" · ", " · ")
    maxc = max(4, int(maxw / (fs * 0.56)))
    toks = []
    for w in text.split(" "):
        ps = _pieces(w, maxc)
        toks.extend((p, i < len(ps) - 1) for i, p in enumerate(ps))
    lines, cur, glue = [], "", False
    for t, joined in toks:
        cand = (cur + t) if glue else (cur + " " + t).strip()
        if len(cand) <= maxc or not cur:
            cur = cand
        else:
            lines.append(cur)
            cur = t
        glue = joined
    return lines + ([cur] if cur else [])


def _lines(x, y, lines, fs, weight, fill, anchor):
    out = "".join(
        f'<text x="{x}" y="{y + i * (fs + 3)}" font-size="{fs}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{esc(ln)}</text>'
        for i, ln in enumerate(lines)
    )
    return out, len(lines) * (fs + 3)


def _initials(label):
    words = re.findall(r"[A-Za-z0-9]+", label)
    return ("".join(w[0] for w in words[:2]) or "?").upper()


class Diagram:
    def __init__(self, title, width, height, subtitle="", statuses=None):
        self.title, self.subtitle, self.W, self.H = title, subtitle, width, height
        self.statuses = statuses or {"built": "Built", "todo": "Not built", "ext": "Existing"}
        self.icons, self.rects, self.items, self.arrows, self.titles = {}, [], [], [], []
        self.nodes, self.flows = {}, []

    def icon(self, key, source):
        if source.lstrip().startswith("<svg"):
            uri = "data:image/svg+xml;base64," + base64.b64encode(source.encode()).decode()
        else:
            ext = os.path.splitext(source)[1].lower()
            with open(os.path.expanduser(source), "rb") as fh:
                uri = f"data:{MIME.get(ext, 'image/svg+xml')};base64," + base64.b64encode(fh.read()).decode()
        self.icons[key] = uri

    def _reg(self, id, label, st, kind, parent, bbox, **kw):
        if id in self.nodes:
            raise ValueError(f"duplicate id {id}")
        if parent and parent not in self.nodes:
            raise ValueError(f"{id}: parent {parent} must be declared first")
        d = {"id": id, "label": label, "st": st, "kind": kind, "p": parent, "bbox": [round(v, 1) for v in bbox]}
        d.update({k: v for k, v in kw.items() if v})
        self.nodes[id] = d

    def _tile(self, cx, cy, st, icon, label):
        c = COL[st]
        sw, fo = (2.6, 0.16) if st == "todo" else (1.6, 0.12)
        body = (f'<use href="#i-{icon}" x="{cx-20}" y="{cy-20}" width="40" height="40"/>' if icon in self.icons else
                f'<text x="{cx}" y="{cy+7}" font-size="19" font-weight="700" fill="{c}" text-anchor="middle">{esc(_initials(label))}</text>')
        return (f'<rect class="tl" x="{cx-28}" y="{cy-28}" width="56" height="56" rx="10" fill="{c}" '
                f'fill-opacity="{fo}" stroke="{c}" stroke-width="{sw}"/>{body}')

    def boundary(self, id, parent, x, y, w, h, title, icon=None, st="zone", sub=None, dash=None, fill="none", fop=0, sw=1.4, **detail):
        stroke = {"zone": LINE, **COL}[st]
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.rects.append(f'<rect class="bdr st-{st}" x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="{fill}" '
                          f'fill-opacity="{fop}" stroke="{stroke}" stroke-width="{sw}"{d}/>')
        tx, head = x + 12, []
        if icon in self.icons:
            head.append(f'<use href="#i-{icon}" x="{x+10}" y="{y+8}" width="20" height="20"/>')
            tx = x + 36
        tc = "#b42323" if st == "todo" else INK
        head.append(f'<text x="{tx}" y="{y+23}" font-size="13" font-weight="700" fill="{tc}">{esc(title)}</text>')
        tw = len(title) * 7.4
        if sub:
            head.append(f'<text x="{tx + tw + 10}" y="{y+23}" font-size="11" fill="{MUTED}">{esc(sub)}</text>')
            tw += 10 + len(sub) * 5.9
        self.titles.append(f'<g class="bd st-{st}" data-id="{esc(id)}" tabindex="0" role="button" aria-label="{esc(title)}">'
                           f'<rect class="hit" x="{x+4}" y="{y+5}" width="{tx - x + tw + 8}" height="26" rx="6" fill="transparent"/>{"".join(head)}</g>')
        self._reg(id, title, st, "boundary", parent, [x, y, w, h], sub=sub, icon=icon if icon in self.icons else None, **detail)

    def item(self, id, parent, cx, cy, label, sub="", st="built", icon=None, lw=118, pos="below", **detail):
        lc = "#b42323" if st == "todo" else INK
        parts = [self._tile(cx, cy, st, icon, label)]
        if pos == "below":
            s, h = _lines(cx, cy + 44, wrap(label, lw, 12), 12, 600, lc, "middle")
            parts.append(s)
            if sub:
                s2, h2 = _lines(cx, cy + 44 + h, wrap(sub, lw, 10.5), 10.5, 400, MUTED, "middle")
                parts.append(s2)
                h += h2
            bbox = [cx - max(30, lw / 2), cy - 30, max(60, lw), 60 + h + 8]
        else:
            ll, sl = wrap(label, lw, 12), (wrap(sub, lw, 10.5) if sub else [])
            total = len(ll) * 15 + len(sl) * 13.5
            y0 = cy - total / 2 + 11
            s, h = _lines(cx + 36, y0, ll, 12, 600, lc, "start")
            parts.append(s)
            if sl:
                parts.append(_lines(cx + 36, y0 + h, sl, 10.5, 400, MUTED, "start")[0])
            bbox = [cx - 30, cy - max(30, total / 2 + 4), 66 + lw, max(60, total + 8)]
        self.items.append(f'<g class="it st-{st}" data-id="{esc(id)}" tabindex="0" role="button" aria-label="{esc(label)}">{"".join(parts)}</g>')
        self._reg(id, label, st, "item", parent, bbox, sub=sub, icon=icon if icon in self.icons else None, **detail)

    def cloud(self, id, parent, cx, cy, label, sub="", st="ext", lw=170, **detail):
        c = COL[st]
        s, h = _lines(cx, cy + 44, wrap(label, lw, 12), 12, 600, INK, "middle")
        s2, h2 = _lines(cx, cy + 44 + h, wrap(sub, lw, 10.5), 10.5, 400, MUTED, "middle") if sub else ("", 0)
        self.items.append(
            f'<g class="it st-{st}" data-id="{esc(id)}" tabindex="0" role="button" aria-label="{esc(label)}">'
            f'<rect class="tl" x="{cx-28}" y="{cy-28}" width="56" height="56" rx="10" fill="{c}" fill-opacity="0.12" stroke="{c}" stroke-width="1.6"/>'
            f'<path transform="translate({cx-17},{cy-11})" d="M9 22 a7 7 0 0 1 0-14 a9 9 0 0 1 17-2 a6.5 6.5 0 0 1 2 13 z" fill="#ffffff" stroke="{c}" stroke-width="2"/>'
            f'{s}{s2}</g>')
        self._reg(id, label, st, "item", parent, [cx - lw / 2, cy - 30, lw, 60 + h + h2 + 8], sub=sub, **detail)

    def chip(self, id, parent, x, y, w, text, st="built", **detail):
        c = COL[st]
        fc, sw = ("#b42323", 2) if st == "todo" else (INK, 1.4)
        self.items.append(
            f'<g class="it st-{st}" data-id="{esc(id)}" tabindex="0" role="button" aria-label="{esc(text)}">'
            f'<rect class="tl" x="{x}" y="{y}" width="{w}" height="26" rx="6" fill="{c}" fill-opacity="0.13" stroke="{c}" stroke-width="{sw}"/>'
            f'<text x="{x+w/2}" y="{y+17}" font-size="11" font-weight="600" fill="{fc}" text-anchor="middle">{esc(text)}</text></g>')
        self._reg(id, text, st, "item", parent, [x, y, w, 26], **detail)

    def arrow(self, flow, points, blocked=False):
        style = next((f["style"] for f in self.flows if f["id"] == flow), "solid")
        pts = " ".join(f"{a},{b}" for a, b in points)
        color, marker = (COL["todo"], "ahr") if blocked else (INK, "ah")
        self.arrows.append(f'<polyline class="fa fa-{flow}{" blk" if blocked else ""}" points="{pts}" fill="none" '
                           f'stroke="{color}" stroke-width="2"{DASH[style]} marker-end="url(#{marker})"/>')

    def badge(self, flow, x, y):
        n = next(f["n"] for f in self.flows if f["id"] == flow)
        self.arrows.append(f'<g class="fb fb-{flow}" data-flow="{flow}" role="button" tabindex="0"><circle cx="{x}" cy="{y}" r="11" fill="{INK}"/>'
                           f'<text x="{x}" y="{y+4}" font-size="12" font-weight="700" fill="#fff" text-anchor="middle">{n}</text></g>')

    def blocked_mark(self, flow, x, y):
        r = COL["todo"]
        self.arrows.append(f'<g class="fa fa-{flow} blk"><circle cx="{x}" cy="{y}" r="8" fill="#fff" stroke="{r}" stroke-width="2"/>'
                           f'<path d="M{x-3.5},{y-3.5} L{x+3.5},{y+3.5} M{x+3.5},{y-3.5} L{x-3.5},{y+3.5}" stroke="{r}" stroke-width="2" stroke-linecap="round"/></g>')

    def flow(self, id, name, blurb, style, steps):
        if style not in DASH:
            raise ValueError(f"flow style must be one of {list(DASH)}")
        self.flows.append({"id": id, "n": len(self.flows) + 1, "name": name, "blurb": blurb, "style": style, "steps": steps})

    def check(self):
        problems = [f"flow {f['id']} step {s[0]} is not a node" for f in self.flows for s in f["steps"] if s[0] not in self.nodes]
        ids = [n for n in self.nodes.values() if n["kind"] == "item"]
        for i, a in enumerate(ids):
            ax, ay, aw, ah = a["bbox"]
            for b in ids[i + 1:]:
                bx, by, bw, bh = b["bbox"]
                if ax < bx + bw - 2 and bx < ax + aw - 2 and ay < by + bh - 2 and by < ay + ah - 2:
                    problems.append(f"overlap: {a['id']} and {b['id']}")
        for n in self.nodes.values():
            p = self.nodes.get(n["p"]) if n["p"] else None
            if p:
                x, y, w, h = n["bbox"]
                px, py, pw, ph = p["bbox"]
                if x < px - 1 or y < py - 1 or x + w > px + pw + 1 or y + h > py + ph + 1:
                    problems.append(f"outside parent: {n['id']} in {p['id']}")
        return problems

    def render(self, path):
        defs = "".join(f'<symbol id="i-{k}" viewBox="0 0 40 40"><image href="{v}" width="40" height="40"/></symbol>' for k, v in self.icons.items())
        marker = '<marker id="{0}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{1}"/></marker>'
        svg = (f'<svg id="dg" viewBox="0 0 {self.W} {self.H}" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="{esc(self.title)}" font-family="{FONT}">'
               f'<defs>{defs}{marker.format("ah", INK)}{marker.format("ahr", COL["todo"])}</defs>'
               f'<rect width="{self.W}" height="{self.H}" fill="#ffffff"/>'
               f'<g id="layer">{"".join(self.rects)}{"".join(self.items)}</g><g id="arrows">{"".join(self.arrows)}</g>'
               f'<g id="titles">{"".join(self.titles)}</g></svg>')
        items = [n for n in self.nodes.values() if n["kind"] == "item"]
        legend = "".join(f'<span class="lg {k}" data-st="{k}"><i></i>{esc(v)} <b>{sum(1 for n in items if n["st"] == k)}</b></span>'
                         for k, v in self.statuses.items() if any(n["st"] == k for n in items))
        data = json.dumps({"nodes": self.nodes, "flows": self.flows, "W": self.W, "H": self.H,
                           "statuses": self.statuses, "subtitle": self.subtitle}, separators=(",", ":")).replace("</", "<\\/")
        with open(os.path.join(KIT, "template.html")) as fh:
            page = fh.read()
        page = page.replace("__TITLE__", esc(self.title)).replace("__LEGEND__", legend).replace("__SVG__", svg).replace("__DATA__", data)
        with open(os.path.expanduser(path), "w") as fh:
            fh.write(page)
        return {s: sum(1 for n in items if n["st"] == s) for s in self.statuses}
