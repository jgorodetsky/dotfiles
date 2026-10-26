# Failure modes — with rewrites

Each entry: what it looks like, why it fails, and a repair. Use this when auditing a
draft or when the user says an explanation didn't land.

---

## 1. The bird trap — naming instead of explaining

The defining failure. Feynman's father: you can know a bird's name in every language
and *know nothing about the bird*.

> ✗ "That's a race condition."
> ✗ "It uses an observer pattern."
> ✗ "Triboluminescence is the light emitted when crystals are crushed."

The last one is Feynman's actual example, and his verdict: *"You have only told what a
word means in terms of other words. You haven't told anything about nature."*

**Repair — mechanism first, name last:**

> ✓ "Two parts of the program both read the counter, both see 5, and both write 6. One
> increment vanished. Nothing in the code says who goes first, so the result depends on
> timing you don't control. That's a **race condition**."

Note the order: the scene, what happens, why it happens, *then* the label.

---

## 2. Definition dressed as explanation

The subtler cousin. Grammatically an explanation; informationally a dictionary entry.
The tell: it would be equally true if you swapped the term for a nonsense word.

Feynman's test, in his own words:

> "Without using the new word which you have just learned, try to rephrase what you have
> just learned in your own language."

If your sentence collapses when the term is removed, you wrote a definition.

> ✗ "Idempotency means an operation can be applied multiple times without changing the
> result beyond the first application."

That is a definition. Nothing has been explained.

> ✓ "You press the elevator button. You press it four more times because you're
> impatient. The elevator still comes once. The extra presses change nothing — the
> button doesn't care how many times you hit it, only whether it's been hit. An
> operation that behaves that way is **idempotent**, and it's what lets a client retry a
> failed request without fear of doing the thing twice."

---

## 3. "Energy makes it move" — the mystic formula

Feynman found a first-grade textbook asking "What makes it move?" with the teacher's
answer: *energy makes it move*. His demolition:

> "It would be equally well to say that 'God makes it move,' or 'spirit makes it move,'
> or 'movability makes it move.'"

The test: **can the reader disagree with it?** If a student says "I don't think energy
makes it move", the conversation has nowhere to go. A real explanation gives the reader
something to push against.

His replacement was a wind-up toy: *"you wound up the spring; it tries to unwind and
pushes the gear around."* Then, better still, the chain — it moves because the sun is
shining — which the child *can* deny, and then you have a discussion.

**Repair:** if your answer can't be argued with, it isn't an explanation. Replace the
abstract noun with a chain of physical causes.

> ✗ "The slowdown is due to memory pressure."
> ✓ "There's more data live than fits in RAM, so the OS is writing pages to disk and
> reading them back. Disk is thousands of times slower than RAM, so every access that
> used to be free now waits. You'd see this as the process using little CPU while the
> disk light stays on."

---

## 4. The "look at the water" failure — keyword-only knowledge

Feynman's Brazilian students could state Brewster's Angle exactly. Asked to look at the
bay through a polaroid, they had nothing.

> "If I asked, 'What is Brewster's Angle?' I'm going into the computer with the right
> keywords. But if I say, 'Look at the water,' nothing happens — they don't have anything
> under 'Look at the water'!"

An explanation indexed only by its technical name is useless in the wild, where problems
never introduce themselves by name.

**Repair:** index by symptom and situation, not by term.

> ✗ "Connection pooling manages a set of reusable database connections."
> ✓ "Symptom: the app is fine at ten users and falls over at two hundred, and the
> database logs show it spending its time opening and closing connections rather than
> answering queries. Opening a connection is expensive — a handshake, authentication,
> setup. **Connection pooling** is keeping a few open and lending them out."

---

## 5. Climbing down instead of up

Opening at the technical level, then adding "in simpler terms…" underneath.

Why it fails: by the time the simple version arrives, the reader who needed it has
already left. The order is not cosmetic — it decides who is still reading.

**Repair:** always bottom-up. If you have already written it top-down, don't reorder the
paragraphs; rewrite from the ground floor. Reordered technical prose is still technical
prose.

---

## 6. The beginner's footnote

A "for those unfamiliar: …" note appended at the end, or a parenthetical glossary dump.

This is a patch, not a design. It signals that the main text was written for someone
else and the beginner is being accommodated afterwards.

**Repair:** the explanation goes at first use, inline, in the flow. If that makes the
sentence clumsy, the sentence needs restructuring, not a footnote.

---

## 7. Term stacking

> ✗ "The reconciler watches the informer's cache and enqueues the object key onto a
> rate-limited workqueue for the control loop to reconcile against desired state."

Six new terms, one sentence, mutually defined. The reader can't get a foothold anywhere.

**Repair:** one new term per paragraph, each anchored to something already established.
If six terms are genuinely needed, you need six paragraphs — or a better level 0 that
makes four of them unnecessary until later.

---

## 8. Fake simplification

Same concepts, shorter sentences, softer tone. The jargon is still doing the load-bearing
work; it just wears a friendlier font.

**The test:** count the concepts, not the syllables. If level 0 requires the reader to
already understand anything from level 2, it isn't level 0.

---

## 9. Accuracy traded for accessibility

Producing something clear and false. This is the worst failure in the catalogue, because
it is invisible to the reader — they leave satisfied and wrong.

Feynman's rule from *Cargo Cult Science*:

> "You should not fool the layman when you're talking as a scientist."

**Repair — bound the approximation instead of hiding it.** His own model: mass is
constant "to within one part in a million" below a hundred miles a second. Not "mass is
constant (roughly)".

> ✗ "HTTPS means nobody can see your data."
> ✓ "HTTPS scrambles the contents so that someone watching the wire — your café's wifi,
> your ISP — sees which site you contacted but not what you sent or received. It does not
> hide *that* you visited, and it doesn't protect anything once it arrives at the other
> end. The server sees everything in the clear."

---

## 10. The unbounded analogy

An analogy with no stated limit. Covered fully in [analogies.md](analogies.md); it
belongs here too because it is a *silent* failure — the reader reasons past the edge and
never learns they left.

**Repair:** state the break at the level where a reader would first be misled.

---

## 11. Cargo cult explanation

Feynman's South Sea Islanders built runways, lit fires along them, and put a man in a
wooden hut with bamboo antennas on his head. *"They're doing everything right. The form
is perfect… But it doesn't work. No airplanes land."*

The written equivalent: correct-looking structure, confident tone, appropriate
vocabulary, five neat levels — and the reader still cannot do or predict anything new.
The ladder is especially vulnerable to this, because the format itself looks like rigour.

**The test:** after reading this, what can the reader do that they couldn't before? Name
one specific thing. If you can't, the planes didn't land, however good the runway looks.

---

## 12. The expert forced through kindergarten

A senior practitioner asks a narrow question and gets five levels starting from a kitchen
analogy. This is a real failure with a real name — the **expertise reversal effect** — and
it is condescending as well as ineffective.

**Repair:** thesis first, then compact form. Offer the rest: *"Happy to go further down if
useful."*

---

## 13. Emoji, exclamation, and cheerleading

"Great question! 🎉 Let's dive in! 🚀"

Feynman's corpus runs about one exclamation mark per thirty-six sentences and no
cheerleading whatsoever. Enthusiasm in his prose comes from the *content* being
interesting — "these are beautiful things" — never from punctuation.

**Repair:** cut it all. Didactic is not childish. The reader is intelligent; they just
haven't met this subject yet.

---

## 14. Repeating louder

The user says they didn't understand, and the reply is the same explanation with more
words.

If the picture failed, it was the wrong picture. **Change the analogy, drop a level, and
find out where they actually fell off** — usually the joint between two levels, where a
term appeared that was never anchored.

Ask, if you can't tell: *"Which part stopped making sense — the notebook picture, or
where I brought in the second writer?"*
