# Answering in a language other than English

Everything in [voice.md](voice.md) was measured on English prose. This file is how the
method survives the border. Three failures happen here, in rising order of subtlety:
translated syntax, borrowed imagery, and dropped connective tissue.

---

## 1. Compose. Do not translate.

Prose that has been translated has a smell a native reader catches in one paragraph:
English word order preserved, English idioms rendered word-for-word, abstract nouns where
the language wants a verb. Every word is correct and it still reads foreign — which costs
you exactly the trust the explanation depends on.

**The trap is your own draft.** If you have already formed the sentence in English
internally, do not translate it. Set it aside and write what you would have written had
the English never existed. Translating your own draft produces the same calque as
translating anyone else's, and it is by far the most common way this rule breaks —
*including for writers who know the rule*. Knowing is not enough. You have to start over.

The tell: an idiom vivid in English and inert in the target.

| Written (calque) | English behind it | Why it dies |
|---|---|---|
| "às vezes você vê a página de ontem" | "you sometimes see yesterday's page" | Portuguese has no such expression |
| "uma frase em que você balançou a cabeça" | "a sentence you nodded at" | not Portuguese; *balançar a cabeça* can read as **no** |
| "Agora é seu" | "Now it's yours" | fine English, inert in Portuguese |

What fixed it was not more warnings — it was changing the process. Given the
*specification* rather than the sentence, native writers reached things translation cannot:
for "agreed to without reading", Portuguese quoted the checkbox itself (**LI E CONCORDO**),
Russian named the button (**ПРИНЯЛИ НЕ ЧИТАЯ**), Chinese described the gesture
(**你顺手点了同意**). None is a translation of the others.

---

## 2. The analogy has to come from the reader's world

Keeping an image and translating only the words around it is calque one level up, and it
is harder to catch because every word is right. Covered in full in
[analogies.md §6](analogies.md), including the kitchen-table failure this project shipped
in nine languages at once.

Short version: **name the role the image plays, then find the local object that fills it.**
"Kitchen table" is not furniture — it is the idiom for the homely, unceremonious place
where ordinary people talk something over. In Brazil that scene is the *churrasco*.

---

## 3. English can leave out what other languages must say

This is the failure that survives even careful composition, because the sentence sounds
fine when read quickly.

English stacks nouns and drops connectives freely. Most other languages cannot, and the
connective is not decoration — it is what tells the reader which word attaches to which.
Drop it and the sentence is not terse, it is **ambiguous**.

| English does this | Portuguese must say |
|---|---|
| browser security policy | política de segurança **do** navegador |
| connection pooling strategy | estratégia **de** reaproveitamento **de** conexões |
| the answer the site sent | a resposta **que** o site mandou |
| he said he would | ele disse **que** ia |
| browser blocked it | **o** navegador bloqueou |
| the error message meaning | **o** significado **da** mensagem **de** erro |

**Articulate the joints.** Put in the conjunctions, prepositions, relative pronouns and
articles the language requires. Then check every pronoun actually resolves: if *ele* could
point at two nouns in the sentence, name the noun instead. English gets away with loose
reference because rigid word order disambiguates; inflected and pro-drop languages do not
have that safety net, so precision has to be carried explicitly.

---

## 4. Register: articulate speech, written well

Aim for someone who **speaks articulately, writing it down**. Two ditches on either side.

**Do not fall into the solemn one.** No archaic constructions, no inversions for their own
sake, no bureaucratic stacking:

- Portuguese: mesoclisis (*dar-se-á*), *outrossim*, *no que tange a*, ladders of *o qual*,
  hyperbaton for effect, participial pile-ups.
- Spanish: *cabe señalar que*, *el mismo* as a pronoun, chained *cuyo*.
- French: *il convient de*, *dans le cadre de*, stacked *-tion* nominalisations.
- Russian: отглагольные существительные stacked into officialese; *в целях осуществления*.
- Arabic: ornate classical constructions where plain modern technical Arabic is wanted.
- Hindi / Bengali / Urdu: over-Sanskritised or over-Persianised coinages for things people
  name in English.

**Do not fall into the other one either.** This is still written text, and it has to hold
up on a page:

- No filler or verbal tics — *tipo, né, cara, meio que*; *o sea, en plan*; *du coup* as
  punctuation; 就是说 as a comma.
- No text-speak, no emoji, no performed casualness.
- Slang dates fast and travels badly. A reader three years from now, or two countries
  over, should still be inside the sentence.

The target is the sentence a well-read person would actually *say* out loud in a normal
conversation — and would be content to see printed.

---

## 5. Per-language notes

**Portuguese, Spanish.** Pro-drop: an explicit subject pronoun in every sentence is the
loudest tell of translated English. Prefer verbs to nominalisations. Build *de/da/do*
chains rather than stacking nouns. Keep the relative *que*; English drops it, you cannot.

**French.** Same *de* chains. Resist the administrative register and the anglicism when a
real French term exists. Non-breaking space before `: ; ! ?`, « » for quotations.

**Russian.** No articles, so the cases carry the disambiguation — get them right, then use
free word order to put the new information last, where Russian expects it. Drop the
possessive pronouns English insists on. « » for quotes, spaced em dashes.

**Chinese.** Short clauses; break the long English sentence rather than stacking
attributives before 的. Avoid gratuitous 被. Keep measure words. Full-width punctuation,
and a space between Chinese characters and Latin runs.

**Hindi, Urdu, Bengali.** SOV, verb last. The postpositions (को / ने / से, کو / نے / سے,
কে / দিয়ে) are obligatory and do the work English word order does. Code-mixing is the
honest register for a technical audience — `browser`, `request`, `commit`, `token` stay in
Latin script; inventing a pure-native coinage loses the reader on the first line.

**Arabic.** Verbal sentences, not the nominal calque of English. Correct iḍāfa chains. The
definite article carries much of what English handles by position. Keep tool names in
Latin script.

**Right-to-left, in Markdown.** Wrap prose in `<div dir="rtl">` but leave fenced code
blocks *outside* it, so shell commands stay left-to-right and copy correctly. Arabic-Indic
and Devanagari numerals are not valid Markdown list markers — `١.` and `১.` render as
run-together paragraphs. Use ASCII digits for list markers.

---

## 6. The check

Read a paragraph back as a monolingual native of that language who has never seen English.

- Would they believe a compatriot wrote it?
- Does every pronoun resolve to exactly one noun?
- Is there a preposition or relative missing that they would have said out loud?
- Is any image borrowed from a country they have not lived in?

"It reads like a good translation" is a failure, not a pass.
