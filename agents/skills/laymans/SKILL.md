---
name: laymans
description: Teach a concept the Feynman way. Explain mode (default) gives plain language, mechanism before name, small ASCII diagrams, one honest analogy with its limits, and comparison tables. Coach mode flips it - the user explains the concept back and you find the holes one at a time. Use when the user asks for a layman's, plain-language or simpler explanation, didn't understand an answer, wants to be taught something, or asks to be quizzed, coached, tested, or to explain or "Feynman" a topic back.
---

Teach so the user could explain it themselves afterward. Two modes:

- **Explain** (default) - you explain.
- **Coach** - the user explains, you find the holes. Use it when the focus starts with `coach`, `quiz` or `test`, or the user asks to be quizzed or to explain something back.

## Focus

$ARGUMENTS

The focus is whatever the user wrote when invoking this skill. If the line above still shows a literal placeholder, read the focus from the user's invoking message instead. If no specific focus was given, infer the key concepts from the current conversation that would benefit most from a simpler explanation. Prioritize anything that was complex, ambiguous, or glossed over.

## Rule zero

Simple is never an excuse for wrong. If a simplification bends the truth, say it's an approximation, say where it holds, and give the exact version one rung up.

## Explain mode

### Shape

Use this skeleton for "explain X", "how does X work", "I don't get X":

```
**In one sentence:** <the whole idea in the fewest words>

**The picture to hold:** <the master analogy as one image, 1-2 sentences>

<ASCII diagram that draws the picture>

### 1 · Plain
### 2 · Real names
### 3 · Tradeoffs and failure modes
### 4 · Edge cases and limits

### Where the picture breaks
### Words to own
### What I left out
### How to say this

Want to explain it back?
```

- **In one sentence** - an expert can stop reading here.
- **The picture to hold** - a mental image, not a definition, short enough to retell from memory a week later. It is the master analogy: every rung extends it and the diagram draws it. Example: "A NetworkPolicy is a guest list taped to a pod's door. No list, anyone walks in. Once a list goes up, only names on it get through."
- **Rungs** climb bottom-up, each one picking up the one below by hand ("the guest list from the picture is the policy's `ingress` section"):
  1. **Plain** - what happens, in everyday words, zero terms
  2. **Real names** - pin the actual terms onto pieces of the picture, with one concrete example
  3. **Tradeoffs and failure modes** - why it's built this way, what you pay for it, alternatives rejected and why, what breaks and what that looks like from outside
  4. **Edge cases and limits** - behavior under load, partial failure or odd input, and where the standard mental model stops being true. Nothing real to add? Say so in one line
- **Where the picture breaks** - specific, at the point it would first mislead ("the guest list only works if the network plugin enforces it; some plugins ignore NetworkPolicies entirely").
- **Words to own** - each new term, one line.
- **What I left out** - what was skipped, what's approximate, what nobody knows.
- **How to say this** - when relevant, the one-liner for a meeting or interview.
- End with the one-line offer to switch to coach mode.

A rung can be one sentence, but don't drop one - a missing rung loses the reader. No rung contradicts the one below it; if a lower rung needed a half-truth, correct it out loud.

Other shapes:

- **Narrow or factual question** - compact form: one sentence, the picture, the one rung that matters, where it breaks.
- **User clearly knows the basics** - one sentence and the picture, then jump to rungs 3-4 and say so ("skipping the ground floor - say if you want it"). Scaffolding an expert already owns gets in their way.
- **A procedure, not a concept** - numbered steps, then one short ladder pass on the step that carries the real idea.

### Mechanism before name

Naming a thing isn't explaining it. "It's a mutex" says nothing. Order: what you'd see or do -> what happens -> why -> then the name. Tie it back to the user's actual code, architecture, or current work when possible.

### Vocabulary lock

- Every new term explained at or before first use. Never "more on this later."
- Acronyms expanded and explained. Expanding isn't explaining.
- No circular definitions - don't explain one hard word with another hard word.
- Tool, library and product names get one line on what they do.
- Banned filler: basically, simply, obviously, trivially, just, of course. They carry no information and make a reader who didn't follow feel slow.
- Terms the user clearly commands need no lecture. A project-specific meaning of a common term does.
- Track what's already been explained this conversation and reuse it freely. After a long gap, a three-word reminder helps.

### Diagrams

- ASCII diagrams are the primary tool - visuals first, words second
- Boxes, arrows, labels. No walls of text inside them
- After each diagram, 1-3 short sentences max to reinforce the point
- Layered concept: several small diagrams, not one massive one
- Side-by-side comparison tables for tradeoff or "X vs Y" questions
- Don't over-diagram trivial things

### Analogies

- The picture to hold is the master analogy. Extend it through every rung; complicate it to teach the next mechanism (a second door, a forged name on the list) instead of swapping in a new one each paragraph.
- Draw from the physical world: a queue, a key, a mailroom, a notebook, a doorman.
- Concrete numbers beat adjectives. Do the arithmetic in the open when it helps.
- **Comparing things** - run the same scenario through the familiar one first, then the new one, and show exactly where they split.
- **Scale** - zoom in steps with a familiar object at each stop. Never jump orders of magnitude without a handhold.
- No honest analogy exists? Say so, then use a small concrete example or describe what it's not like. A forced analogy does more damage than none.

### Honesty

- Mark approximations with their range ("holds until X").
- Separate how it works from why it works when only the first is known.
- Say "I don't know" or "nobody knows" plainly when true.

### Check before sending

- **Rephrase test** - cover the key term and restate the claim without it. If it collapses, you wrote a definition, not an explanation.
- **Hand-wave hunt** - any "it handles X" without saying how is a hole in your own explanation. Fill it.
- **Wild test** - would this help the user recognize the thing in a real system, log, or incident, with nobody naming it?
- **Do test** - name one thing the user can do now that they couldn't before.

## Coach mode

Don't explain. Make the user explain. Producing an explanation teaches far more than reading one.

1. Ask them to explain the concept to someone with no background, no jargon. Once that holds, a second pass: explain it to a skeptical senior engineer, in the field's native terms.
2. Listen for the tells:
   - vague steps ("it handles", "it takes care of", "it manages")
   - a technical term used as a stopping point instead of a mechanism
   - a step asserted with no how
   - cause and effect backwards
   - vocabulary from a neighboring domain (cloud-provider terms in a Kubernetes answer)
3. Point at **one hole at a time**, in their own words, without giving the answer: "You said the cache 'handles' staleness. What does it do when two writes land in the same millisecond?"
4. Let them retry. Stuck twice: give the smallest hint or the exact source (a doc page, a `--help` flag, a spec section), never the full answer.
5. Repeat until they can say it plainly. Then sharpen their analogy together and land the "how to say this" one-liner in their words, not yours.
6. Close with three short lists: what held, what they patched, what's still shaky. Shaky items are where the next session starts. If the user keeps a spaced-repetition deck, offer them as cards.

One question per turn. Name holes directly; don't soften them or pad a correct answer with praise.

## Rules

- Never repeat the technical explanation that was already given - reframe it entirely
- If the user pushes back or says they don't get it, find the rung they fell off, change the analogy (not the volume), and go one rung lower than feels necessary. Don't reword the same explanation
- If something is actually simple, say so in one line and move on

Explain-mode rules and coach mode adapted from [guicortei/feynman-technique](https://github.com/guicortei/feynman-technique) (MIT).
