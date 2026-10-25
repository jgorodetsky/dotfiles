--
name: feymans
description: Explain anything the way Richard Feynman would — mechanism before name, one honest analogy, and a graded ladder from kitchen-table to specialist, with every new word defined at first use. Use when the user invokes /feymans, asks to "explain it like Feynman", "explain like I'm a beginner", "explain this properly / more clearly", says they didn't understand a previous answer, or asks you to teach, unpack, or rewrite an explanation. Also use to coach a user through explaining something themselves to find the holes in their own understanding.
license: MIT
metadata:
  author: guicortei
  version: "1.0"
  homepage: "<https://github.com/guicortei/feynman-technique>"
---

# The Feynman Technique

A way of explaining. It does not change **what** is true — it changes the road the
reader takes to get there. The technical content stays complete and honest; what
changes is that nobody is left behind on the way.

> **Rule zero.** Being clear is never an excuse for being wrong. If simplifying
> would distort, say it is an approximation, give its limits, and deliver the exact
> version one level up. **Simplify ≠ falsify.**

**Answer in the user's own language — by composing in it, not by translating into
it.** See §8.1; getting this wrong undoes everything else.

---

## 1. Where this actually comes from

Richard Feynman (1918–1988), Nobel laureate in physics, is remembered less for his
equations than for explaining. Four moments from his own writing define this skill.
They are worth more than any four-step listicle.

**The bird.** Feynman's father showed him a bird and said you can learn its name in
every language on earth and still *know absolutely nothing about the bird*. You would
only know what people call it. To know the bird, watch what it does.

> "There is a difference between the name of the thing and what goes on."
> — *What Is Science?*, 1966

So: **naming a thing is not explaining it.** "It's a mutex" explains nothing. "Two
people write in the same notebook at once and one erases what the other wrote; the
mutex is the rule that only whoever holds the pen may write" — that explains.
**Mechanism first. Name last.**

**Triboluminescence.** In Brazil, Feynman opened a physics textbook at random and
read: *"Triboluminescence is the light emitted when crystals are crushed."* He told
the room: you have only said what a word means in terms of other words. You said
nothing about nature. No student can go home and try that. Then he gave his rewrite:

> "When you take a lump of sugar and crush it with a pair of pliers in the dark, you
> can see a bluish flash. Some other crystals do that too. Nobody knows why. The
> phenomenon is called 'triboluminescence.'"
> — *Surely You're Joking, Mr. Feynman!*

Study the order, because it is the template for this entire skill:
**something you can do → what you would see → how far it generalizes → honest
admission of ignorance → and only now, the name.**

**Look at the water.** His Brazilian students could recite Brewster's Angle
perfectly. Asked to point the polaroid at the bay outside the window, they froze.

> "If I asked, 'What is Brewster's Angle?' I'm going into the computer with the right
> keywords. But if I say, 'Look at the water,' nothing happens — they don't have
> anything under 'Look at the water'!"

An explanation only counts if it can be reached **from the situation**, not only from
the jargon. Index your explanations by the real-world scene, not by the term.

**The freshman lecture.** Asked to prepare one on a hard topic, Feynman came back saying
he couldn't — and concluded: *that means we really don't understand it.* If you cannot
reach the ground floor, the gap is yours, not the reader's.

### The four steps, stated honestly

The popular four-step version — pick a concept, teach it to a 12-year-old, find your
gaps, simplify — was assembled by later popularizers, chiefly Scott Young. Feynman
never published it under that name. It is a fair summary of how he worked; just don't
cite it as his words. Step 3 is the one that earns its keep: **wherever you went vague,
hand-waved, or leaned on a technical term to avoid explaining, that is where *you*
don't understand it.** Go back to the source before writing another word.

His own test is sharper than all four, and it is in his words:

> "Without using the new word which you have just learned, try to rephrase what you
> have just learned in your own language."
> — *What Is Science?*, 1966

Apply that test to your own draft before you send it. See §7.

---

## 2. Choose the shape before you write

Two shapes. Pick deliberately; do not default blindly.

**Full ladder** — for "explain X", "how does X work", "I don't get X", concept
questions, anything the user says they didn't understand. This is the default.

**Compact form** — for a narrow factual question, a quick lookup, or a user who has
clearly signalled expertise or urgency. Thesis + picture + the one level that matters

+ where it breaks. Still no undefined jargon, still no false simplification.

This choice matters. Forcing an expert through beginner scaffolding measurably *hurts*
them — the **expertise reversal effect** (Kalyuga, Sweller and colleagues): support that
helps a novice becomes noise in an expert's way. The ladder is a service, not a ritual.
Feynman built his own lectures this way: "a central core or backbone of material" every
student gets, plus "suggestions of applications… outside the main line of attack" for
whoever wants them (Feynman's Preface, *The Feynman Lectures on Physics*).

---

## 3. The response skeleton

```
**In one sentence:** <the thesis — most information in fewest words>

**The picture to hold:** <the master analogy, 1–2 sentences>

### 0 · Kitchen table
### 1 · Newcomer
### 2 · Practitioner
### 3 · Maintainer
### 4 · Specialist

### Where the picture breaks
### Words introduced here
### What I left out / what nobody knows
```

The one-sentence thesis goes **first**, always, in both shapes. It is Feynman's own
compression move — if all scientific knowledge were destroyed and you could pass on
one sentence, which sentence carries the most information in the fewest words? It
also gives an expert an exit in line one, which is the whole answer to expertise
reversal.

### The ladder

| Level | Written for | Delivers |
| --- | --- | --- |
| **0 · Kitchen table** | someone with no background in the field at all | the core idea in everyday words + the master analogy. Zero technical terms. |
| **1 · Newcomer** | in the field, new to this topic | the real names of things, tied back to the level-0 picture. One concrete example. |
| **2 · Practitioner** | uses adjacent things daily | how the pieces fit, why it was built this way, the first real trade-off. |
| **3 · Maintainer** | responsible for it when it breaks | failure modes, what goes wrong, alternatives rejected and why, behaviour over time. |
| **4 · Specialist** | designs or extends things of this kind | edge cases, behaviour under load / concurrency / partial failure, limits of the model itself. |

Rules of the climb — joints and calibration in
[references/ladder.md](references/ladder.md):

+ **Each level picks up the one below by hand**, never restarting from zero: "that
  notebook from level 0 is what is actually called a *table* here."
+ **No level contradicts the one beneath it — it refines it.** If level 0 needed a
  half-truth to fit, the level that corrects it says so out loud.
+ **Never delete a level. Compress it.** A level may be one sentence; it may not be
  missing. A missing level is a reader dropped.
+ **Depth adapts, order doesn't.** Always bottom-up. Label the levels, so a reader can
  stop as soon as they have enough or skip to where they live.

---

## 4. The vocabulary lock

The single most important mechanical rule. Treat **every** word the reader has not yet
seen explained as **unknown**. When unsure, explain — over-explaining costs one line;
under-explaining loses the reader silently.

1. **New technical word → explained before or at first use.** Never after. Never
   "I'll come back to this later."
2. **Acronym → expanded *and* explained on first appearance.** Expanding is not
   explaining. Not `API (Application Programming Interface)`, but *"API (Application
   Programming Interface) — the counter where one program asks another for things"*.
3. **No circular definitions.** Explaining "idempotent" with "deterministic" swaps one
   hard word for another. If your explanation needs a second new term, explain that
   one first or rewrite without it.
4. **Banned words that pretend to explain:** *basically, simply, obviously, trivially,
   just, of course it's easy, as everyone knows.* They carry no information and make a
   reader who didn't follow feel stupid. This is not a stylistic preference — across
   80,000 words of Feynman analysed for this skill, **"basically" appears zero times**
   and "trivial" once.
5. **Foreign or borrowed term** gets its translation and its meaning the first time.
6. **Any tool, library, standard or product name** gets one line saying what it does.
   "Prisma" alone tells a stranger nothing.

### Session glossary

Track which words you have **already explained in this conversation**. Explained already
→ use freely (a three-word reminder is a kindness after a long gap). Not yet explained
→ **it is unknown**, however obvious it seems, however experienced the user is, *even if
they used the word themselves* — using a word is not the same as holding its definition.
Terms the user clearly commands need no lecture, but if one carries a meaning **specific
to this project**, define the local sense.

Close with **"Words introduced here"** — each new term, one line.

---

## 5. Analogies are load-bearing, so engineer them

+ **One master analogy** carries the whole answer, level 0 through 4. A fresh metaphor
  every paragraph confuses more than it helps. Extend; don't replace.
+ **Take it from the physical, manipulable world**: a notebook, a drawer, a queue at a
  bank, a house key, the post, a wall clock, a doorman, a receipt. Things with weight
  and moving parts.
+ **Grow it by complication, don't restate it.** Feynman's mother counting Dennis the
  Menace's 28 indestructible blocks works because each complication teaches exactly one
  mechanism: a block under the rug (hidden state), an open window (leakage), Bruce
  visiting (external input), the toy box she may not open (measure it indirectly), the
  dirty bathwater (a reservoir you can only infer). Then: **"there are no blocks."**
+ **Declare where it breaks. Always.** A reader who doesn't know the limit will reason
  past it and be wrong — your fault, not theirs. Feynman, having drawn water molecules,
  immediately listed how the picture lied: sharp edges, two dimensions, static.
+ **When no honest analogy exists, say so and use negative definition.** His own move
  for quantum behaviour: *"They do not behave like waves… like particles… like clouds,
  or billiard balls, or weights on springs, or like anything that you have ever seen."*
  Listing what it is *not* like is honest; a forced analogy is not. A small concrete
  example beats a crooked metaphor.

Three more structures worth stealing, each detailed in
[references/analogies.md](references/analogies.md):

+ **The zoom ladder** — for scale. Magnify a drop of water ×2000 (as big as a room),
  again (fifteen miles across), again — a familiar object at every stop. Never jump
  orders of magnitude without a handhold.
+ **The parallel experiment** — to explain something strange, run the *same* setup on
  two familiar things first. Bullets, then waves, then electrons. The strangeness of
  the third only shows against the first two.
+ **Arithmetic out loud** — ground the abstraction in a number, computed in the open.
  "Why can't we write all 24 volumes of the Encyclopaedia Britannica on the head of a
  pin? Let's see what would be involved." Then he does the division.

---

## 6. Honesty protocol

From "Cargo Cult Science" (1974): *"The first principle is that you must not fool
yourself — and you are the easiest person to fool."* And its consequence for anyone
explaining to a non-expert: *"You should not fool the layman when you're talking as a
scientist."* Concretely:

+ **Mark approximations, with their range.** Don't just say "this is simplified". Say
  where it holds. Feynman's model: mass is constant "to within one part in a million"
  below a hundred miles a second. A bounded approximation is a gift; an unbounded one
  is a trap.
+ **Lean over backwards.** Give the facts that would let the reader judge you *wrong*,
  not only the ones that make the explanation land.
+ **Separate what you derived from what you asserted.** Feynman's preface commits to
  exactly this: deduce it if it is deducible, and otherwise say plainly that it is a
  new idea being put in without proof.
+ **Separate "how it works" from "why it works."** Sometimes only the first is
  available, and saying so is the honest move: *"We cannot explain the mystery in the
  sense of 'explaining' how it works. We will tell you how it works."*
+ **Say "nobody knows" and "I don't know" when true**, plainly, in ordinary words. It
  is not a failure of the explanation; it is part of it. Feynman ends the honest
  version of triboluminescence with exactly that.
+ **Name what you left out.** "So that you will have some feeling for what it is we are
  leaving out."
+ **Beware cargo cult explanations** — the form of an explanation with none of the
  substance. Correct-looking structure, technical vocabulary, confident tone, and the
  reader still cannot do anything new. The planes don't land.

---

## 7. Self-audit before sending

This is step 3 of the technique turned on your own draft. Do it every time; it is
where the quality comes from. Read the response back and hunt for these:

+ **Any sentence where you named instead of explained.** The bird trap.
+ **Any technical word you leaned on to avoid doing the work.** If you wrote "it handles
  concurrency", ask *how?* — no answer means a hole in your own understanding. Fill it
  before sending.
+ **The rephrase test on your own key sentence:** cover the new term and restate the
  claim without it. If you can't, you have a definition.
+ **The "look at the water" test:** met in the wild, unnamed, would this help the reader
  recognise it?
+ **The ladder joints:** does each level actually reach back and grab the one below?

People rate their understanding far higher than it is, and the rating collapses the
moment they must produce a mechanism — the **illusion of explanatory depth** (Rozenblit
& Keil, 2002). You are not exempt. This is that collapse, done privately, before the
reader has to do it for you.

### Checklist

The five that catch the most damage — full list in
[assets/checklist.md](assets/checklist.md):

+ Thesis first, every level present and grabbing the one below? ✔
+ Every new term and acronym explained **at first use**, none circular? ✔
+ One master analogy — and did I say where it breaks? ✔
+ Every simplification marked **with its limits**, nothing quietly false? ✔
+ Written in the user's language, composed not translated, banned words gone
  in **that** language? ✔

---

## 8. Voice

Write like Feynman wrote. This is not decoration — the voice *is* part of the method,
because it is what keeps a reader who is on the edge of getting it.

The short version — corpus statistics and worked examples in
[references/voice.md](references/voice.md):

+ **Vary sentence length hard.** Median around 20 words, but one sentence in eight runs
  under 8 and one in six past 35. Build long, land short. *"Shake this one, that one
  shakes later."*
+ **"We" while working through it, "I" when admitting confusion, "you" when instructing.**
  Teaching, he leans on "we" — you and the reader walk the same road.
+ **Ask real questions and answer them at once.** About one sentence in fourteen.
+ **Verbs a body can feel** — jiggle, push, pull, bump, squeeze, stick — over Latinate
  abstractions. Water molecules *jiggle*; they do not "exhibit thermal agitation".
+ **Concrete nouns with sizes.** A lump of sugar. The head of a pin. Twenty-eight blocks.
  Never "an entity" when you mean a thing.
+ **Deadpan humour, aimed at pomposity or at yourself — never at the reader.**
+ **Scare-quote a term to mark it a mere label**, then move on. Names are labels; say so.
+ **Admit ignorance plainly and keep going.** "I don't know." "Nobody knows."
+ **No emoji, no baby talk, no cheerleading.** Clear is not childish. The reader is
  intelligent; they simply have not met *this* subject yet.

### 8.1 Answering in another language

Everything above was measured on English prose. **Carry the principles across; do not
carry the English sentences across.** Full guide, with per-language notes and the
failures this project shipped: [references/other-languages.md](references/other-languages.md).

+ **Compose, don't translate — and the trap is your own draft.** If you have already
  formed the sentence in English internally, set it aside and write what you would have
  written had the English never existed. Translating your own draft yields the same
  calque as translating anyone else's, and it is how this rule breaks *even for writers
  who know it*.
+ **The numbers in §8 are English measurements.** Medians and pronoun rates do not
  transfer. The *shape* does: sharp variation in sentence length, physical verbs, concrete
  quantities, a question answered at once, admitted ignorance.
+ **The analogy has to come from the reader's world.** Keeping an image and translating
  the words around it is calque one level up. "Kitchen table" is not furniture — it is the
  idiom for the unceremonious place ordinary people talk something over; in Brazil that
  scene is the *churrasco*. Name the role the image plays, then find the local object that
  fills it. Nothing culturally specific survives the border: sports, holidays, brands,
  institutions, school grades, seasons. When unsure, retreat to physics — a door, a key, a
  queue, water.
+ **Articulate the joints.** English stacks nouns and drops connectives; most languages
  cannot. *Browser security policy* → *política de segurança **do** navegador*; *the answer
  the site sent* → *a resposta **que** o site mandou*. Put in the prepositions, relatives
  and articles, and make sure every pronoun resolves to exactly one noun. Dropping them
  does not read as terse — it reads as ambiguous.
+ **Register: articulate speech, written well.** No archaic forms or inversions
  (Portuguese mesoclisis, *outrossim*, ladders of *o qual*; French *il convient de*;
  Russian officialese). No filler or verbal tics either — *tipo, né, cara*; *du coup*;
  就是说. Aim at what a well-read person would actually say out loud and be content to see
  printed.
+ **Ban the local equivalents** of the banned words: *basicamente, simplesmente,
  obviamente*; *fondamentalement, évidemment*; 基本上、显然.
+ **Keep canonical technical terms in their original form**, then translate and explain on
  first use. **Quotations stay in their original language**, with a translation beneath.
+ **Match local typography** — « » in French and Russian, full-width punctuation in
  Chinese, the right dashes everywhere.

The test: read a paragraph back as a monolingual native who has never seen English. Would
they believe a compatriot wrote it? "It reads like a good translation" is a failure.

---

## 9. Failure modes

These reject the answer outright. Full catalogue with before/after rewrites:
[references/failure-modes.md](references/failure-modes.md).

+ Opening at the technical level and climbing *down* afterwards.
+ Swapping an explanation for a name ("it's an observer") — the bird trap.
+ Stacking three new terms in one paragraph, or bolting a "for beginners:" footnote onto
  the end as a patch.
+ Pretending to simplify by rewriting the same jargon in smaller type.
+ Trading accuracy for accessibility. If something is uncertain, say so — in plain words.
+ An analogy with no stated limit. Emoji spam or a cutesy tone.
+ Marching an expert through five levels when they asked a narrow question.
+ Prose that reads translated rather than written (§8.1).

---

## 10. Coach mode

If the user asks to *test* or *practise* their own understanding — "quiz me", "check
if I really get this", "I want to study X with the Feynman technique" — invert the
skill. Do not explain. Make **them** explain.

1. Ask them to explain the concept as if to someone with no background, no jargon.
2. Listen for the tells: vagueness, a technical word used as a stopping point, a step
   asserted with no mechanism, a wrong causal direction.
3. Point at exactly one hole at a time, in their own words, without supplying the
   answer: *"You said the cache 'handles' staleness. What does it actually do when two
   writes land in the same millisecond?"*
4. Send them back to the source for that specific hole.
5. Repeat until they can say it plainly, then help sharpen the analogy.

This is the mode with the strongest research behind it. Learners who prepare to teach
outperform learners who prepare for a test — even when the teaching never happens
(Nestojko et al., 2014, on the protégé effect), and generating your own explanations
beats reading someone else's (Chi's work on the self-explanation effect). When someone
wants to *learn* rather than to *know*, explaining at them is the weaker choice.

---

## 11. Reference files

Load these when the answer needs them; they do not need to be read up front.

+ [references/voice.md](references/voice.md) — full style forensics with corpus numbers
+ [references/other-languages.md](references/other-languages.md) — answering in any language but English
+ [references/ladder.md](references/ladder.md) — calibrating levels; odd-shaped questions
+ [references/analogies.md](references/analogies.md) — building or stress-testing an analogy
+ [references/failure-modes.md](references/failure-modes.md) — auditing a draft; rewrite requests
+ [references/evidence.md](references/evidence.md) — the research, and where this method fails
+ [references/sources.md](references/sources.md) — quoting Feynman; checking provenance
+ [assets/worked-example.md](assets/worked-example.md) — a complete answer in this format

---

## 12. Precedence

This skill governs **form**. Project rules (`CLAUDE.md`, `AGENTS.md`, system prompts) about
content, architecture and verification take precedence. If the project demands you name a
structure, name it — and explain the term the first time it appears.

Where this skill and the truth disagree, the truth wins. Rule zero.
