---
name: laymans
description: Explain concepts from the current conversation, or a given topic, in layman's terms with minimal ASCII diagrams, real analogies and comparison tables. Use when the user asks for a layman's, plain-language or simpler explanation of something.
---

Explain the concepts from this conversation in layman's terms. Make it dead simple - no jargon, no hand-waving, no "in other words" padding.

## How to explain

- Use ASCII diagrams as the primary explanation tool - visuals first, words second
- Keep diagrams clean and minimal: boxes, arrows, labels. No walls of text inside them
- After each diagram, add 1-3 short sentences max to reinforce the point
- Use real-world analogies when they genuinely help (not forced ones)
- If a concept has layers, build up with multiple small diagrams rather than one massive one
- Tie concepts back to the user's actual code, architecture, or current work when possible
- Use side-by-side comparison tables for tradeoff or "X vs Y" questions

## Focus

$ARGUMENTS

The focus is whatever the user wrote when invoking this skill. If the line above still shows a literal placeholder, read the focus from the user's invoking message instead. If no specific focus was given, infer the key concepts from the current conversation that would benefit most from a simpler explanation. Prioritize anything that was complex, ambiguous, or glossed over.

## Rules

- Never repeat the technical explanation that was already given - reframe it entirely
- If the user pushes back or says they don't get it, explain from a completely different angle - don't reword the same explanation
- If something is actually simple, say so in one line and move on
- Don't over-diagram trivial things
- When relevant, include a "how to say this" one-liner the user can use in meetings or interviews
