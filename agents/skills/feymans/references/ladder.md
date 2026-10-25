# The Ladder — calibration and adaptation

The five levels are a service to the reader, not a ritual to perform. This file is for
when the default shape doesn't fit.

---

## What each level owes the reader

### 0 · Kitchen table
**Reader:** no background in the field whatsoever. A relative at dinner.
**Owes:** the core idea in everyday words, plus the master analogy.
**Forbidden:** every technical term, including ones that "everyone knows".
**Test:** could someone who has never worked in this field repeat the gist back?

The hardest level to write and the one most often faked. Faking it looks like using
simpler *sentences* while keeping the same *concepts*. Level 0 is not shorter words —
it is a different set of ideas, drawn from things the reader already owns.

### 1 · Newcomer
**Reader:** in the field, new to this topic.
**Owes:** the real names for the things introduced in level 0, explicitly tied back to
the picture. One concrete, complete example — small enough to hold in the head.
**This is where the vocabulary lock does the most work.** Every name that lands here
must attach to something the reader already saw at level 0.

### 2 · Practitioner
**Reader:** works with adjacent things daily; will use this next week.
**Owes:** how the pieces fit together, why it was built this way rather than the
obvious alternative, and the first genuine trade-off — what you gain, what you pay.
**Test:** could the reader now make a decision they couldn't make before?

### 3 · Maintainer
**Reader:** responsible for this when it goes wrong.
**Owes:** failure modes, what breaks and what that looks like from outside,
alternatives that were rejected and why, behaviour over time — what degrades, what
accumulates, what surprises you in month six.
**Test:** would this help someone debug it at an unpleasant hour?

### 4 · Specialist
**Reader:** designs or extends things of this class.
**Owes:** edge cases, behaviour under concurrency, load, or partial failure, and — the
part usually missing — **the limits of the model itself**. Where does the standard way
of thinking about this stop being true?
**Test:** does it say something a well-read practitioner wouldn't already assume?

Level 4 is the one most often padded with jargon to look deep. If you have nothing
genuine to add, say so in one line: *"Beyond this the interesting questions are
empirical, not conceptual."* An honest short level beats an inflated one.

---

## Adapting

### The question is narrow and factual
Use **compact form**: thesis, picture, the one level that matters, where it breaks.
A three-sentence answer with no undefined jargon is a complete success. The technique
is not a word count.

### The user is clearly an expert
Lead with the thesis, then go straight to levels 3–4, and say what you're doing:
*"Skipping the ground floor since you're already there — shout if you want it."*
This is the expertise reversal effect handled properly (see [evidence.md](evidence.md)).

### The user said they didn't understand the last answer
Do **not** repeat the same explanation more slowly. That is the single most common
failure. Instead:
1. Find which level they fell off. Usually you started too high.
2. Change the analogy, not the volume. If the picture failed, it was the wrong picture.
3. Go one level *lower* than feels necessary.

### The topic is genuinely a procedure, not a concept
Ladders explain *why*; procedures need *order*. Give the numbered steps, then use one
short ladder pass on the single step that carries the real idea. Do not stretch a
five-command sequence over five levels.

### The topic is contested or unsettled
Add the disagreement at level 3, where a reader can weigh it, and name who holds which
position. Do not present one camp's view at level 0 as settled fact.

### The topic is mathematical
Level 0 gets the *shape* of the relationship in words — what grows, what shrinks, what
stays put. Notation arrives at level 1 or 2 with every symbol named as a quantity you
can point at. Feynman's habit: derive the thing in front of the reader and tell them
that watching the derivation is the point, not the result.

### The question is about a specific codebase or document
The ladder applies to the *concept*; the specifics stay concrete. Quote the real names,
paths, and lines. Then use the ladder for the idea those names implement.

---

## Joints between levels

The joint is where readers fall off. Every level opens by reaching back:

> "That notebook from level 0 — the one only the pen-holder may write in — is what's
> actually called a **mutex**."

> "The doorman we met a moment ago doesn't only check the guest list. He also…"

Three joint failures to watch for:

1. **The restart.** The level begins as if the reader arrived cold. It should begin by
   picking something up.
2. **The silent swap.** The analogy quietly changes — the notebook becomes a ledger,
   then a queue. Pick one and extend it.
3. **The contradiction.** A level says something that makes the level below false, and
   doesn't flag it. If level 0 needed a half-truth, the level that corrects it must say
   so: *"I simplified there. What actually happens is…"*

---

## Depth budget

A rough guide, not a rule. For a normal conceptual question:

| Level | Typical share |
|---|---|
| 0 | 10–15% |
| 1 | 20% |
| 2 | 25% |
| 3 | 25% |
| 4 | 15–20% |

If level 0 is running longer than level 2, the analogy is doing too much work and has
probably stopped being simple. If level 4 is longest, you are writing for yourself.
