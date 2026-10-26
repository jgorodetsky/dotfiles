---
name: deepen
description: Turn a request into the version a top professional in the field would ask for, before doing any of it. Answers five questions (what an expert would do that wasn't asked, the rawest source material, the methods and tools, what outside evidence would show the result is right, and what decision the result feeds), then rewrites the prompt and stops. Use when the user says "go deep", "deep version", "deepen this", "what would an expert do here", "rewrite my prompt", or "/deepen". Not for explaining a concept (laymans) or attacking a plan (roast, steelman, grill-me).
---

Make the ask deeper, not bigger. The output is a better prompt plus the reasons for it, not the work itself.

## Focus

$ARGUMENTS

The focus is whatever the user wrote when invoking this skill. If the line above still shows a literal placeholder, read the focus from the user's invoking message instead. If no focus was given, use the most recent request in the conversation.

## Steps

1. **Look before answering.** If the subject is unfamiliar, read enough raw source (code, data, spec, the actual tool) to answer with specifics. Don't answer from the request's own framing.
2. **Answer five questions**, 2-6 bullets each, specific to this task:
   1. **What a top pro would do that wasn't asked.** Common moves: turn a reading into a measurement; add a control or baseline so only one variable changes; freeze the success criteria before seeing results; count what the method misses, not only what it finds; check the scope against the real risk.
   2. **Rawest material.** The primary source instead of what's been digested: source over README, transcripts over summaries, raw data over dashboards, git history over docs. Name exact files, commands or datasets.
   3. **Methods and tools.** Named techniques and tools the field uses, each with one line on what it does. Include the cheap deterministic baseline.
   4. **What, other than you or me, shows it's right.** Executed proof, known-answer tests, ground truth with a known denominator, independent tools agreeing, repeat runs agreeing, a different model family, a human expert blind-labeling a sample. Opinion, mine or the user's, doesn't count.
   5. **The decision.** What decision the result feeds, and what result would change it. State the threshold before the work starts.
3. **Rewrite the prompt** in a fenced block the user can paste: goal and decision rule, phases in order, guardrails (cost, private data, anything destructive or outward-facing), deliverable. Under a page. Deeper means sharper controls and evidence, not more phases.
4. **Say in one line what you cut** to keep it from getting bigger.
5. **Ask whether to run it.** Don't start the work in the same turn.

## Rules

- Specific beats generic: "seed 8 bugs by deleting existing checks", not "consider adding test cases".
- If the original ask is already what a pro would do, say so in one line and stop.
- If the honest answer to question 4 is "nothing outside our opinion is available", say so plainly; it caps how far the result can be trusted.
- Explain the five answers the way the laymans skill explains: read `~/.claude/skills/laymans/SKILL.md` and follow its explain-mode rules (mechanism before name, every new term defined at first use, compare to something the user already knows). The rewritten prompt itself stays plain and paste-ready.
- In interview or meeting context, end with a "how to say this" one-liner.
- No em dashes. No filler words (robust, comprehensive, seamless, leverage, streamline, utilize).
