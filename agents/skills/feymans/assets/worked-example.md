# Worked example

A complete answer in the skill's format, so the shape is unambiguous. The question:

> **"What is a database index and why is my query slow without one?"**

Read it once for content, then again for the machinery — the annotations after it point
at what each part is doing and why.

---

## The answer

**In one sentence:** An index is a second, pre-sorted copy of one column that the
database can search by halving, so it stops reading every row to find a few.

**The picture to hold:** the index at the back of a book. The book is in whatever order
the author wrote it; the index is a thin extra section, alphabetical, where every entry
points at a page number.

---

### 0 · Kitchen table

Imagine a filing cabinet with a million receipts, dumped in the order they arrived. You
want every receipt from one shop. You have no choice: you take out the first receipt,
look at it, put it back, take out the second. A million times. Even if only three of them
match, you cannot know that until you have looked at all million.

Now suppose that when each receipt arrived, you also wrote the shop name on a small card
and kept those cards in a box, in alphabetical order, each card noting which drawer the
receipt is in. Finding your three receipts now means flipping to the right letter in the
card box — a few seconds — and then going straight to three drawers.

You did extra work every time a receipt arrived. You got it all back on the first search.

That card box is an index.

### 1 · Newcomer

The filing cabinet is the **table** — your rows, sitting on disk roughly in the order
they were written. Reading every one of them is a **full table scan**, and it is what the
database does when it has no better option.

The card box is the **index**: a separate structure holding the values of one column,
kept in sorted order, each paired with a pointer to the row it came from.

Sorted is the whole trick. In a sorted set you can open at the middle, see whether your
value is above or below, and throw away half. Then half of what remains. A million
receipts is twenty of those halvings. That is the difference between a million looks and
twenty.

```sql
-- before: full table scan, every row read
SELECT * FROM receipts WHERE shop = 'Copacabana';

CREATE INDEX idx_receipts_shop ON receipts (shop);
-- after: the database finds 'Copacabana' in the index, then fetches only those rows
```

### 2 · Practitioner

The card box is not really one sorted list — it's a **B-tree**, a card box of card boxes.
The top card says "A–F over here, G–M over there". Follow that, and the next level splits
again. Three or four hops from the top and you are at the value. That structure is what
keeps lookup cheap even as the table grows, and it is why an index stays fast at a
hundred million rows.

Now the trade-off, and there is always one. **Every write pays.** Insert a receipt and
you must also file its card — find the right place in the sorted structure, put it in,
sometimes rearrange. Five indexes on a table means an insert does one write plus five
index maintenances. Indexes also occupy real disk and real memory. An index nobody uses
is a pure tax, charged on every write, forever.

Which means the interesting question is never "should I index this table" but "**which
queries am I willing to pay for**".

### 3 · Maintainer

The failure modes, in the order you will actually meet them.

**The index exists and the database ignores it.** The planner estimates cost, and
sometimes the scan genuinely wins. If your column is `status` and 90% of rows are
`active`, looking up `active` in the index gives you 900,000 pointers, and then 900,000
scattered jumps into the table — each one a separate disk seek. Reading the whole table
in order is *faster*. This is **low cardinality** (few distinct values), and it is the
most common reason a new index changes nothing. `EXPLAIN` tells you which path was chosen.

**Composite indexes and the leftmost rule.** An index on `(shop, date)` is sorted by shop
first, then by date within each shop. So it serves `WHERE shop = ?`, and it serves
`WHERE shop = ? AND date > ?`. It does *not* serve `WHERE date > ?` alone — that is like
asking the alphabetical card box for everything filed on a Tuesday. Column order is a
design decision, not a formality.

**Wrapping the column kills the index.** `WHERE lower(email) = 'a@b.com'` cannot use an
index on `email`, because the index stores the original values and the database will not
evaluate a function against every card. Index the expression instead, or store the
normalised value.

**Drift over time.** The planner decides using statistics that were accurate when they
were last gathered. A table that grew tenfold since the last `ANALYZE` may be planned
against a picture of itself from months ago — a query that was instant becomes a scan and
nothing in your code changed.

**Building one on a live table can lock it.** Postgres has `CREATE INDEX CONCURRENTLY`;
it is slower and can leave an invalid index behind if it fails. Know your engine's
behaviour before running this on production at a busy hour.

### 4 · Specialist

**The pointer indirection is often the real cost.** Finding the value in the index is
cheap; following each pointer into the table is a random read. Once matches run past a
few percent of the table, sequential scanning beats random access — modern storage is
still much better at reading in order. This is why the planner's *selectivity estimate*
matters more than the index's existence, and why a **covering index** (one that includes
every column the query needs) is such a large win: the second lookup disappears
entirely. Postgres calls this an index-only scan, and it only works if the visibility map
is current — which depends on vacuum having run.

**Write amplification compounds.** Under sustained insert load, index maintenance
dominates. B-trees split pages; random-order inserts (UUIDv4 primary keys are the classic
case) fragment the tree and blow up write volume compared with time-ordered keys. This is
where LSM-tree engines make the opposite trade: cheap writes, deferred merge cost, and
read amplification you manage with bloom filters.

**Under concurrency, an index is a contention surface.** Every insert into a
monotonically increasing index touches the same rightmost page, and that page becomes a
hot spot — latch contention that no amount of read optimisation will fix.

**And the limit of the model itself:** "sorted list plus pointers" is an accurate picture
of a B-tree and a poor one for everything else. Hash indexes have no order and cannot
serve range queries. Inverted indexes map a term to the documents containing it. Vector
indexes are *approximate* by construction — they trade guaranteed correctness for speed,
which the book-index picture has no room for at all. When you leave B-trees, expect the
picture to stop paying rent.

---

### Where the picture breaks

The card box holds up well, but three ways it lies:

- **The book index is written once; a database index is maintained continuously.** That
  continuous cost is the entire trade-off, and the book analogy hides it completely.
- **A book index costs you nothing to consult; here, following each pointer is a real
  disk seek.** Once you are following enough pointers, reading the book cover to cover
  wins — which is nonsense for books and routine for databases.
- **A book has one index. A table can have many, and they compete** for memory and for
  the planner's attention.

### Words introduced here

- **Table** — where the rows actually live, roughly in insertion order.
- **Full table scan** — reading every row because there's no faster route.
- **Index** — a sorted copy of one or more columns, each value paired with a pointer to
  its row.
- **B-tree** — the tree-of-sorted-blocks an index is really made of; a few hops from top
  to any value.
- **Cardinality** — how many distinct values a column has. Low cardinality makes indexes
  ineffective.
- **Composite index** — one index over several columns, sorted by the first, then the
  second within it.
- **Covering index** — includes every column the query needs, so the table is never
  touched.
- **Selectivity** — the fraction of rows a condition matches. Drives the planner's choice.
- **`EXPLAIN`** — the command that shows which plan the database picked.
- **Write amplification** — one logical write causing several physical ones.

### What I left out

Partial and filtered indexes; index types beyond B-tree (GiST, GIN, BRIN) and when each
earns its place; how the optimiser actually costs a plan, which is engine-specific and
where most real surprises live. All of it sits on top of the picture above rather than
replacing it.

---
---

## What the machinery is doing

Now the annotations. Each corresponds to a rule in the main skill.

**The thesis sentence exists so an expert can leave.** A DBA reads line one, confirms
there is nothing new, and stops. That is the answer to the expertise reversal effect
(see [evidence.md](../references/evidence.md)) — the ladder costs a knowledgeable reader
one sentence, not five sections.

**Mechanism arrives before the name, everywhere.** Level 0 has no jargon at all — no
"index", no "table", no "query". The reader watches someone open a million drawers and
then watches the card box fix it. The word "index" appears in the *last line of the
level*, as a label for something already understood. That is the triboluminescence
order: something you can do → what you'd see → then the name.

**One analogy, extended by complication, never replaced.** The card box carries all five
levels. It grows: a box → a box of boxes (B-tree) → a box that costs you on every filing
(write amplification) → a box whose pointers are expensive to follow (indirection). This
is the Dennis-the-Menace pattern from [analogies.md](../references/analogies.md) — one
new mechanism per complication, and the picture is never swapped out mid-climb.

**Every level grabs the one below by hand.** "The filing cabinet is the **table**." "The
card box is the **index**." "The card box is not really one sorted list — it's a
B-tree." No level restarts.

**The half-truth gets corrected out loud.** Level 1 says an index is a sorted list.
Level 2 opens by saying it isn't, quite, and explains what it really is. The correction
is explicit rather than silent — no level contradicts the one beneath it without saying so.

**The trade-off appears exactly at level 2, and it is a real one.** Not "indexes use some
space", but: every write pays, five indexes means five maintenances, an unused index is a
tax charged forever. Level 2 must leave the reader able to make a decision.

**Level 3 is failure modes only, in the order they are actually met.** Not a features
tour. Every item is something that will one day be someone's bad afternoon, and each
carries the observable symptom, not just the cause.

**Level 4 ends on the limits of the model itself** — the single most-skipped obligation
in the ladder. "Sorted list plus pointers" is *false* for hash, inverted and vector
indexes, and saying so is what stops a reader carrying the picture somewhere it will
mislead them.

**The break is declared, and it is specific.** Not "all analogies are imperfect" — three
named failures, each with a consequence. The reader now knows exactly how far the card
box travels.

**"What I left out" is named** rather than quietly omitted — *"so that you will have some
feeling for what it is we are leaving out."*

**Voice checks.** Sentence lengths vary hard: "A million times." after a long build-up.
Physical verbs — *take out, put it back, flipping, dumped, jumps, wrapping*. Concrete
quantities — a million receipts, twenty halvings, three drawers, 90%. Second person for
instructions, "you" throughout, no cheerleading, no emoji, zero instances of *basically*,
*simply*, *obviously* or *just*.
