---
name: prose
description: Write the sentences: whiteboard voice, opening moves, banned LLM tells, LaTeX conventions, the abstract rule. Use at HOWTO steps 8, 9, 13.
---

# prose

## Short form

- Whiteboard voice; read aloud or rewrite.
- Pick one opening move on page 1; elevator speech in its quote block, 2-3 lines.
- The abstract carries the paper: everyone who judges it cheaply reads nothing else.
- Kill the LLM tells (full ban list below).
- Numbers with their arithmetic; claims gated by stats.

## Detail

## Opening moves (pick one, page 1)

- Cost hook with arithmetic shown: "one system we studied
  has 460 binary flags, a space of 2^460 options (more
  configurations than there are stars in the observable
  universe)". Numbers never round away the working.
- Field-disagreement hook: enumerate the contradictory
  verdicts ("Reports range from limited advantage, to
  useful only on small problems, to too slow to be
  practical"), then the turn: "We argue this disagreement
  reflects an evidence base too small to settle its own
  disputes."
- Ethics/duty hook (sparingly): "It is the ethical duty
  of software researchers..."
- Quote a truism from a big name, then push on it: Berk's
  "impossible to achieve fairness and high performance"
  followed by "we argue that assumption may not even be
  necessary."

## Argument habits (carried from proposal style, seen in
## papers too)

- Praise prior work, then storm out: "While these
  approaches were certainly useful... these methods are
  'dumb' in a way because they do not take advantage of
  domain knowledge."
- Digression flags: "Before beginning, we digress to
  clarify two points. Firstly... Secondly..."
- Inline enumeration (a) (b) (c) inside sentences,
  heavily. "Firstly/Secondly" for two-part bad news.
- Repetition flagged honestly: "Just to repeat a point
  made above..."
- Pre-empt reviewers in asides and FAQs; state success
  AND failure criteria for the experiments.
- Cite own prior work by result, not ceremony: "prior
  results [20, 24] show that..."

## Sentence mechanics (unchanged from proposal style.md)

- Mix lengths hard; 5-word sentence beside a 40-word one.
- Short declaratives as pivots: "But there is a catch."
  "Enter active learning." "We disagree."
- Rhetorical questions drive sections.
- One idea per sentence. Semicolons rare. Paragraphs may
  end flat.
- Connectives, in house frequency order: "Hence", "That
  said,", "Also,", "Further,", "Note that", "To say that
  another way,".

## LaTeX conventions

- List macros: \bi ... \ei (itemize), \be ... \ee
  (enumerate). Never mix a macro opener with a raw closer
  (\bi ... \end{itemize} does not compile).
- Cross-references via \tion{label}, \fig{label},
  \tbl{label}.
- Editorial markers: \need{...} renders red [TIMM: ...].
  These stay visible in working drafts; they are for the
  PI, not comments. Red flag symbol: {\redflag}.
- Captions carry a guided read for dense figures: name
  the parts, walk the example, land the point
  ("Everything else stays untouched").
- Wrapfigures: environment a touch wider than the image
  (2.6in around a 2.5in image); \centering inside; place
  at paragraph starts; two wrapfigures at least a page
  apart.

## Banned: LLM tells (the full law, from proposal
## style.md)

- Verbless sentence fragments used as punchy caps: "One
  substrate, again." "Speed, again." "The loop, closed."
  Too terse even for this house style. Rewrite as full
  clauses or delete. On any full-text pass, sweep for the
  shape noun-phrase-comma-adverb-period and kill it.
- Short sentences must still be sentences: complete
  clauses with verbs.
- No em-dash pairs ("---like this---"). No spaced
  en-dashes. The unspaced double hyphen as a single
  trailing interruptor is native ("runtime adaption--
  which is akin to fixing a problem after creating it")
  but at most once or twice per document.
- No "X is not Y, it is Z" mic-drop constructions.
- No triads for rhythm ("reproducible, teachable, and
  energy-frugal"). One list of three per page, only when
  the three things are real.
- No parallel-scaffold runs: three sentences in a row
  with identical "A does X but not Y" shape.
- No thesis-announcement filler: "This is timely and
  feasible", "This approach is significant because", "In
  today's rapidly evolving...".
- No consultant nouns: "defensible basis", "growing
  industrial risk", "actionable insights", "robust
  framework", "landscape" as metaphor (landscape as a
  technical term for loss/data topology is fine).
- No adjective-stacked noun phrases doing verb work
  ("lightweight learner-agnostic region-level
  monitors"). Use a verb.
- No "delve", "crucial", "pivotal", "seamless",
  "holistic", "leverage" (as a verb), "harness",
  "underscore", "foster".
- No perfectly uniform paragraph shapes. Vary: some
  paragraphs are two sentences.
- Do not end every paragraph with a summary sentence.
- Semicolons rare; prefer a period and a new sentence.
  Colons introduce lists and definitions, not dramatic
  reveals.
