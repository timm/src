---
name: tut-exam-questions
description: Author two-part (Bloom define+debug) exam questions for the ezr-lua tut, with every planted bug verified live before it enters the text. Use when writing or reviewing "Exam questions" blocks in tut/lN.md.
---

# Two-part exam questions (Bloom: define, then debug)

Every question block sits at the END of its lecture file
(`tut/lN.md`), after the exercises. The lecture's glossary terms sit
at the TOP as "**Words to watch for:**"; the block's Q0 is always
"define any three of them, one sentence + one limit case."

## The Xa/Xb pattern

- **Xa — define** (Remember/Understand): concept in own words + its
  boundary condition. Keep gentle: "what mistakes can a novice
  make..." beats "state the two rules...".
- **Xb — debug** (Analyze/Evaluate): a fragment of the REAL source,
  minimally mutated so it still runs, returns right-shaped numbers,
  and often looks MORE careful than the original — but violates the
  Xa concept. Ask: what do the outputs have in common / what breaks,
  is it a bug, how found, how fixed.

Banned bugs: typos, off-by-ones, crashes, anything a linter catches.
Required: invisible without the concept. Fault species that worked:

- independence: srand(the.seed) INSIDE the repeat loop (20 runs
  collapse to twenty copies of one number — verified: twenty 24s)
- streaming: forget `i.n = i.n + inc` in Welford (first add divides
  by zero -> mu=inf, silent poison, never crashes)
- role/NOIR: `SYM.norm = v/2` ("1"/2 silently coerces to 0.5;
  "usa"/2 crashes — silent vs loud split is the question)
- boundary: entropy as log2(#keys) (1.58 vs true 1.46; agrees only
  on uniform distributions — "Why?" is the whole b-part)
- header: reorder Cols branches so `not s:find"X$"` precedes the
  goal test (ALL goals land in x, y empty, search optimizes a
  constant)

## Non-negotiable workflow

1. Write the mutated fragment.
2. RUN it (lua AND luajit) and capture the wrong output.
3. Only then paste into the lecture; quote the verified numbers in
   the question ("this prints 1.58; the true entropy is 1.46").
4. Answers go in `tut/ans/aN.md` (numbered to match), released via
   `make tut.md RELEASED=k`. Include the verified wrong output.

Style notes from Tim (2026-08-10): soften a-parts; b-parts use
plain rand()/count demos not the full holdout rig; call srand "set
random seed"; end short ("Why?" beats a compound question); pdf/cdf
questions need the 1.6 ascii-figure notes; keep "(gate N)" tags on
migrated questions.
