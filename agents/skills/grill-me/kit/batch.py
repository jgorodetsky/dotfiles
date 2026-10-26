# builds the batch-round page for grill-me: every independent question on one page, the
# recommended answer already picked. the answers come back through lavish as one prompt.
#   python3 batch.py QUESTIONS.json OUT.html
# QUESTIONS.json:
#   {"title": "...", "intro": "...", "questions": [
#     {"id": "q1", "q": "the question", "why": "one line of context",
#      "options": [["label", "what it means"], ...], "recommended": ["label"], "multi": false}]}
# colors come from lavish-theme (the terminal's theme) when it's on PATH, else lavish's default
import html
import json
import os
import shutil
import subprocess
import sys

KIT = os.path.dirname(os.path.abspath(__file__))
CDN = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/daisyui@5.5.19/daisyui.css">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/daisyui@5.5.19/themes.css">
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4.2.4/dist/index.global.js"></script>"""
e = lambda s: html.escape(str(s), quote=True)


def head():
    lt = shutil.which("lavish-theme")
    if lt:
        out = subprocess.run([lt], capture_output=True, text=True).stdout
        if "<style>" in out:
            return out, "ghostty"
        if out.strip():
            return out, "luxury"
    return CDN, "luxury"


def question(q):
    qid, multi, rec = q["id"], q.get("multi", False), q.get("recommended", [])
    kind, cls = ("checkbox", "checkbox checkbox-primary") if multi else ("radio", "radio radio-primary")
    opts = []
    for label, detail in q["options"]:
        on = label in rec
        badge = ' <span class="badge badge-soft badge-primary badge-sm">recommended</span>' if on else ""
        more = '<br><span class="text-sm opacity-70">' + e(detail) + "</span>" if detail else ""
        opts.append(
            f'    <label class="flex gap-3 items-start p-2 rounded-field border border-base-300 cursor-pointer has-[:checked]:border-primary">\n'
            f'      <input type="{kind}" class="{cls} mt-0.5" name="{e(qid)}" value="{e(label)}"{" checked" if on else ""}>\n'
            f'      <span><span class="font-medium">{e(label)}</span>{badge}{more}</span>\n    </label>')
    why = f'\n    <p class="text-sm opacity-70">{e(q["why"])}</p>' if q.get("why") else ""
    return (f'  <fieldset class="card bg-base-200 border border-base-300" data-lavish-question="{e(qid)}" data-label="{e(q["q"])}" data-recommended="{e(json.dumps(rec))}">\n'
            f'   <div class="card-body gap-3">\n'
            f'    <div class="flex flex-wrap items-baseline gap-2"><span class="badge badge-neutral font-mono">{e(qid)}</span>'
            f'<h2 class="card-title text-base">{e(q["q"])}</h2><span class="badge badge-warning badge-sm" data-changed hidden>changed</span></div>{why}\n'
            + "\n".join(opts) +
            f'\n    <textarea class="textarea w-full" name="{e(qid)}-note" rows="1" placeholder="Your own answer, or a note (optional)"></textarea>\n'
            f'   </div>\n  </fieldset>')


def build(spec_path, out):
    with open(os.path.expanduser(spec_path)) as fh:
        spec = json.load(fh)
    ids = [q["id"] for q in spec["questions"]]
    if len(ids) != len(set(ids)):
        sys.exit("batch.py: question ids repeat")
    for q in spec["questions"]:
        labels = [o[0] for o in q["options"]]
        bad = [r for r in q.get("recommended", []) if r not in labels]
        if bad:
            sys.exit(f"batch.py: {q['id']} recommends {bad}, which isn't one of its options")
    h, theme = head()
    with open(os.path.join(KIT, "batch.html")) as fh:
        page = fh.read()
    page = (page.replace("__HEAD__", h.strip()).replace("__THEME__", theme).replace("__TITLE__", e(spec["title"]))
            .replace("__INTRO__", e(spec.get("intro", ""))).replace("__QUESTIONS__", "\n".join(question(q) for q in spec["questions"])))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    with open(out, "w") as fh:
        fh.write(page)
    return len(ids)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: python3 batch.py QUESTIONS.json OUT.html")
    print(build(sys.argv[1], sys.argv[2]), "questions ->", sys.argv[2])
