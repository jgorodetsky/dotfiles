---
name: grill-me
description: Interview the user relentlessly about a plan, design, or topic, checkpointing every answer to a brainstorm file so nothing is lost. Use when the user wants to stress-test a plan, get grilled on a design, run a brainstorm or discovery session, extract what's in their head into a doc, or says "grill me".
---

# Grill Me

Relentlessly interview the user about every aspect of the topic until you reach shared understanding. Walk down each branch of the decision tree, resolving dependencies one by one. The real goal is to **extract what's in their head into a durable, organized markdown file** so nothing is lost as context fills up.

## The capture file is the whole point

Long interviews fill up context. If you hold answers only in your head, you will eventually misremember, conflate, or drop something. So you **checkpoint to disk after every single answer**. The file, not your context, is the source of truth. Never make the user ask you to save progress.

## Setup (do this BEFORE the first question)

1. **Create the capture file** at `brainstorms/{YYYY-MM-DD}-{topic-slug}.md` (create the `brainstorms/` folder if it doesn't exist). Every brainstorm capture lives here. One predictable home, regardless of topic. Do NOT scatter captures into project folders. If a session later produces a polished deliverable (a plan, a map, a spec), that artifact can move into the relevant `projects/` folder, but the raw capture always stays in `brainstorms/`.
   - Get today's date with `date +%F` (Bash) if you don't already know it.
2. **Create the file immediately** with a header: title, date, the goal of the session, and an empty "Open flags" section.
3. **Tell the user where you're saving**, in one line. Then ask Q1.

## The checkpoint rule (non-negotiable)

After EVERY user answer, BEFORE you ask the next question:

- Append a structured entry to the capture file: the question topic, the key facts and decisions from their answer (in their words where the wording matters), and any flags (things they couldn't answer plus who should).
- Update or correct earlier entries if a later answer changes them.
- Only then ask the next question.

Never batch multiple answers into one write. Checkpoint one answer at a time. The point is that if context is lost at any moment, the file already holds everything said so far. Answers from a batch round (below) arrive together: write one entry per answer right away, before anything else.

## Interview method

- Ask **one question at a time**. For each, provide your **recommended answer** (your best inference from context) so the user can simply confirm, correct, or redirect.
- Resolve dependencies in order: settle the upstream decision before the ones that depend on it.
- If a question can be answered by **exploring the codebase or reading a file/doc**, do that instead of asking. If the user hands you a doc (e.g. a Google Doc), read it and only surface what's net-new.
- When the user **can't answer** something, capture it as a flag with the right owner and move on. Don't stall.
- Keep going until the user says you're done, or you've covered every branch. Offer a completeness backstop near the end ("anything we haven't touched?").

## Batch round (independent questions together)

When the questions left don't depend on each other (no answer would change another question), ask them together instead of one at a time. Keep asking one at a time while answers still shape the next question.

- Ask up to 4 questions per round with your harness's question tool (in Claude Code: AskUserQuestion). Put your recommended answer first in each. Without such a tool, send them as a numbered list, each with your recommended answer.
- Checkpoint one entry per answer right away, and mark the ones that differ from your recommendation.

### On a lavish page (only when the user asks)

Use a page only when the user asks for one or for lavish:

1. Write the questions to `.lavish/grill-{topic-slug}/questions.json` in the working folder:
   ```json
   {"title": "Topic: open questions", "intro": "one line on what these decide",
    "questions": [{"id": "q1", "q": "the question", "why": "one line of context",
      "options": [["label", "what it means"], ["label", "what it means"]],
      "recommended": ["label"], "multi": false}]}
   ```
   Every question gets your recommended answer, which starts out picked. Use short, stable IDs (`q1`, `q2`...) and 2 to 4 options. The user can always type their own answer.
2. Build the page: `python3 <this skill>/kit/batch.py .lavish/grill-{topic-slug}/questions.json .lavish/grill-{topic-slug}/questions.html`. It uses the terminal's colors when `lavish-theme` is on PATH.
3. Open it with `npx -y lavish-axi@0.1.93 <questions.html>`, then run `npx -y lavish-axi@0.1.93 poll <questions.html>` as a background job your harness tracks (in Claude Code: Bash with `run_in_background`). Never `nohup` or `&`. With no tracked background jobs, poll in the foreground.
4. Every change on the page re-queues the whole set under one key, so what the user sends is what the page shows. The answers come back tagged `grill-batch`, one line per ID. Check that every ID is there, then checkpoint one entry per answer and mark the ones that differ from your recommendation.
5. Without lavish (no Node, or the user isn't at a browser), the page's "Copy all answers" button copies the answers for them to paste into the chat. Or ask in the chat as above.

Never run `lavish-axi share`: it publishes the page on a public third-party site.

## Capture file structure

```
# {Topic}: Brainstorm / Discovery Notes
Date: {date} · Goal: {one line}

## Summary / key decisions
(running synthesis, updated as you go)

## Q&A log
### Q1 - {topic}
- Asked: {question}
- Captured: {facts, decisions, in their words where it matters}
- Flags: {open item -> owner}
...

## Open flags (pending input)
- {item} -> {who can answer}
```

## At the end

- Do a final read of the capture file for contradictions or gaps and reconcile them.
- Give the user a short recap: what's captured, what's still flagged, and the suggested next step.
