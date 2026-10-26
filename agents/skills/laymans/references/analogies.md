# Analogy engineering

An analogy is not an ornament. It is temporary scaffolding that holds an idea upright
until the real concept can stand on its own — and like scaffolding, it is dangerous
if you forget it is there. This file is how to build one that holds and take it down
cleanly.

---

## 1. Choosing the source

A good source domain is:

- **Physical and manipulable.** Notebooks, drawers, keys, queues, post, receipts,
  doormen, wall clocks, kitchen scales. Things with weight and moving parts. Feynman's
  entire toolkit is objects you could pick up.
- **Universally owned.** Not sport-specific, not culture-specific, not gendered. A
  queue at a bank works almost everywhere; a baseball infield does not.
- **Structurally similar, not superficially similar.** The test is whether the
  *relations* match, not whether the things look alike. A mutex is like a pen only
  because of the exclusivity rule, not because code resembles handwriting.
- **Richer than you need.** You will have to extend it three or four times as you
  climb. A source with only one moving part runs out at level 2.

Bad sources: anything requiring domain knowledge to understand ("it's like a Kalman
filter"), anything emotionally loaded, anything you have to explain first.

---

## 2. One analogy, extended

**One master analogy carries the whole answer.** A new metaphor every paragraph is
worse than none — the reader spends their attention on the metaphors instead of the
subject.

Extend by **complication**, not replacement. The model is Feynman's blocks. A mother
counts her son's 28 indestructible blocks each evening. Then, one at a time:

| Complication | Mechanism it teaches |
|---|---|
| One block under the rug | hidden state you must go looking for |
| Two blocks out the open window | leakage out of the system |
| Bruce visits, leaves blocks behind | uncounted input from outside |
| The toy box she may not open — so she weighs it | measuring indirectly through a proxy |
| The dirty bathwater — infer from the water level | a reservoir you can only reach by inference |

Five complications, five mechanisms, one story. Each earns its place. Nothing is
introduced for colour.

Then the dismantling: **"there are no blocks."** The analogy is destroyed at exactly
the moment it has finished its job, and the destruction is itself the lesson — energy
is not a substance, it is a number that stays put.

**To apply:** start the analogy at its simplest. Add one complication per level as you
climb. At the top, say what the analogy was hiding.

---

## 3. Declare where it breaks — always

This is not optional politeness. A reader who doesn't know the limit will reason past
it and be wrong, and that will be your fault.

Feynman does this compulsively. Presenting a diagram of water molecules he immediately
lists how the picture lies: the particles are drawn with sharp edges, "which is
inaccurate"; they are shown in two dimensions "for simplicity" when they move in three;
the drawing is static when the real thing is "continually jiggling and bouncing,
turning and twisting". Then, of the next figure: "This picture of steam fails in one
respect" — there would really be no molecules in a square that size.

Phrasings that work:

> "The drawer analogy holds up to here. Unlike a drawer, two programs can open this one
> at the same time — and that is the entire problem."

> "Careful: in the postal analogy the letter always arrives eventually. Here it may
> simply never arrive, and nothing tells you."

Put the break **at the level where a reader would first be misled by it**, not in a
footnote at the end.

---

## 4. When there is no honest analogy

Do not force one. Feynman's own solution is **negative definition** — enumerate the
analogies that fail:

> "They do not behave like waves, they do not behave like particles, they do not behave
> like clouds, or billiard balls, or weights on springs, or like anything that you have
> ever seen."

Four failed comparisons in one sentence, and the reader learns more from that than from
any single forced one. He follows it with an admission — even the experts don't
understand it the way they'd like to — and then simply describes the behaviour.

The fallback ladder, in order of preference:

1. A structurally honest analogy.
2. Negative definition — what it is *not* like, and why each comparison fails.
3. A small, complete, concrete example. One real case beats a crooked metaphor.
4. Plain description of the mechanism, step by step, in physical verbs.

Never reach past these into a metaphor that "sort of works". A crooked analogy is a
debt the reader pays later, with interest, at the moment they act on it.

---

## 5. Three other structures

### The zoom ladder
For anything about scale. Feynman magnifies a drop of water by 2,000 — now it's "as big
as a large room", and there are paramecia swimming in it. Another 2,000 — "about
fifteen miles across", looking "something like a crowd at a football game as seen from
a very great distance". Another 250 — atoms.

**A familiar object at every stop.** Never jump orders of magnitude bare. And note the
ratio trick he closes with: *"if an apple is magnified to the size of the earth, then
the atoms in the apple are approximately the size of the original apple."*

### The parallel experiment
To explain something strange, run the *identical* setup on two familiar things first.
Feynman teaches the double-slit experiment with bullets, then with water waves, then
with electrons. By the third run the reader has a template, and the strangeness shows
up as a *difference* — which is far easier to see than an absolute weirdness.

Use it whenever the thing is counterintuitive: establish the expected pattern twice,
then break it.

### Arithmetic in the open
Ground an abstraction with a number, computed in front of the reader.

> "Why cannot we write the entire 24 volumes of the Encyclopaedia Brittanica on the head
> of a pin? Let's see what would be involved. The head of a pin is a sixteenth of an
> inch across. If you magnify it by 25,000 diameters, the area of the head of the pin is
> then equal to the area of all the pages of the Encyclopaedia…"

Doing the division openly is the point. It converts "very small" into something the
reader can check — and being checkable is what separates an explanation from an
assertion.

---

## 6. Analogies do not cross borders on their own

The source domain has to exist in the reader's life. An analogy translated word-for-word,
with its objects intact, fails in a way that is *harder* to spot than a bad sentence —
every word is correct, and the image is simply dead on arrival.

### The failure, caught in this repository

Level 0 of the ladder is named **"Kitchen table"**. In English that is not furniture: it
is the idiom for the homely, unceremonious place where ordinary people talk something
over — *kitchen-table conversation*, *kitchen-table economics*. It carries informality,
family, no stakes.

Nine translations rendered it as a table:

| Language | What was written | What it now means |
|---|---|---|
| Portuguese | Mesa da cozinha | a table, in a kitchen |
| Spanish | Mesa de cocina | a table, in a kitchen |
| French | Table de cuisine | a table, in a kitchen |
| Russian | Кухонный стол | a table, in a kitchen |
| Chinese | 厨房餐桌 | a table, in a kitchen |
| Hindi | रसोई की मेज़ | a table, in a kitchen |

Each is a correct translation and none of them is the idea. The scene that does this job
in Brazil is the **churrasco** — the weekend gathering where you explain your work to an
uncle who does something else entirely. That is the level-0 reader, and that is the name
the Portuguese level should carry.

Note *how* the error survived: the level names live inside a frozen code block, and the
native reviewers had been instructed not to touch code blocks. An integrity rule written
to protect the install commands ended up protecting a calque. Freeze commands, not prose.

### The method

1. **Name the role, not the object.** Write down what the image is doing: *informal,
   domestic, shared, low-stakes, everybody has one*. That description travels; the noun
   does not.
2. **Find the local object that fills the role.** Not the closest translation — the
   closest *function*.
3. **Check it against a fifteen-year-old** in that culture. If they would have to be told
   what the source is, the analogy has a hole in its floor.

### What reliably fails to transfer

- **Sports.** Baseball (US), cricket (South Asia, UK, Australia), American football.
  A "home run" and a "sticky wicket" are noise almost everywhere else. Football/soccer
  travels further than any other, and still not everywhere.
- **Institutions.** The DMV, the NHS, the IRS, small claims court, 911. Every country has
  a bureaucracy people resent; it is never the same bureaucracy.
- **Comic and TV characters.** Dennis the Menace is a US newspaper strip. Use "a small
  child with indestructible blocks" and the analogy survives intact.
- **Holidays, seasons, school systems.** "Summer holidays" lands in July north of the
  equator and in January south of it. "Freshman", "GCSE", "sophomore" mean nothing
  outside their own country.
- **Brands and retail.** Yard sales, drive-thrus, the corner bodega, Tupperware.
- **Currency, units, paper sizes.** Miles, ounces, °F, Letter vs A4.
- **Food.** A sandwich, a cup of coffee, and a bowl of rice are near-universal. Almost
  nothing else is.

### What travels almost everywhere

Doors, keys, locks, queues, rope and knots, water, notebooks, envelopes and post,
switches, buckets, ladders, mirrors, shadows, weight, a market stall, a shared meal.
Physics and the body: pushing, pulling, dropping, spilling, waiting, forgetting.

When you cannot find a local equivalent you trust, **retreat to one of these**. A plain
physical object that everyone owns beats a culturally sharp image that half the readers
have to decode.

---

## 7. Stress test before shipping

Run the analogy against these five:

1. **Does it survive the climb?** Can it still carry weight at level 3, or does it quietly
   get abandoned after level 1? If it's abandoned, it was decoration.
2. **What does it wrongly imply?** List what a reader would incorrectly conclude if they
   trusted it completely. Anything on that list gets declared explicitly.
3. **Does the reader already own every part of the source?** If any part needs
   explaining, the analogy has a hole in its floor.
4. **Does it survive the reversal?** Explain the analogy to yourself starting from the
   real concept. If the mapping only works one way, it's a slogan.
5. **Is it doing work, or is it flattery?** An analogy that makes the reader feel clever
   without letting them predict anything new is a cargo cult analogy — perfect form,
   no planes land.
