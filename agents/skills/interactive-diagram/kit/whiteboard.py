# builds a whiteboard page for lavish: a mermaid diagram that lavish turns into an excalidraw
# board the user can edit. mermaid is pinned at the version lavish-axi 0.1.93 ships.
#   python3 whiteboard.py OUT.html SOURCE.mmd --title "..." [--answer "..."] [--draw]
# --draw: the user draws and you coach, so the hint says so. colors come from lavish-theme
# (the terminal's theme) when it's on PATH, else lavish's default theme
import argparse
import html
import os
import shutil
import subprocess

KIT = os.path.dirname(os.path.abspath(__file__))
CDN = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/daisyui@5.5.19/daisyui.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/daisyui@5.5.19/themes.css">
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4.2.4/dist/index.global.js"></script>"""
HINTS = {
    "sketch": "Click the diagram to edit it: move, add or delete shapes and arrows, rename anything. Queue feedback when it looks right.",
    "draw": "Draw it yourself: click the board to start, add boxes and arrows for what you know. Queue feedback when you want a check.",
}


def head():
    lt = shutil.which("lavish-theme")
    if lt:
        out = subprocess.run([lt], capture_output=True, text=True).stdout
        if out.strip():
            return out, "ghostty" if 'data-theme="ghostty"' in out and "<style>" in out else "luxury"
    return CDN, "luxury"


def build(out, source, title, answer="", draw=False):
    h, theme = head()
    with open(os.path.join(KIT, "whiteboard.html")) as fh:
        page = fh.read()
    with open(os.path.expanduser(source)) as fh:
        mmd = fh.read().strip()
    page = (page.replace("__HEAD__", h.strip()).replace("__THEME__", theme).replace("__TITLE__", html.escape(title))
            .replace("__ANSWER__", html.escape(answer)).replace("__HINT__", HINTS["draw" if draw else "sketch"])
            .replace("__MERMAID__", html.escape(mmd, quote=False)))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w") as fh:
        fh.write(page)


if __name__ == "__main__":
    a = argparse.ArgumentParser()
    a.add_argument("out")
    a.add_argument("source")
    a.add_argument("--title", required=True)
    a.add_argument("--answer", default="")
    a.add_argument("--draw", action="store_true")
    o = a.parse_args()
    build(o.out, o.source, o.title, o.answer, o.draw)
    print(o.out)
