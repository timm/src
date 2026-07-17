# abc-doc.md — lecture notes for abc.lua

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

Companion to [abc.lua](abc.lua) (the code) and
[abc-eg.lua](abc-eg.lua) (the lessons: demos, tests,
exercises). Each lesson's stanza ends in **Core ideas**
whose links land on the glossary headings below (github
auto-anchors `## key` as `#key`). Glossary order = the
order the ideas first appear in the lessons.

## Contents

| lesson | section | run | core ideas |
|--------|---------|-----|------------|
|  0 | Lua     | `lua abc-eg.lua --lua`     | [truthy](#truthy) [onetable](#onetable) [closure](#closure) [patterns](#patterns) [bob](#bob) |
|  1 | Lst     | `lua abc-eg.lua --lst`     | [lists](#lists) [dsu](#dsu) [bisect](#bisect) |
|  2 | Rnd     | `lua abc-eg.lua --rnd`     | [seed](#seed) [shuffle](#shuffle) [gauss](#gauss) [roulette](#roulette) |
|  3 | Str     | `lua abc-eg.lua --str`     | [coerce](#coerce) [csv](#csv) [ssot](#ssot) |
|  4 | Num     | `lua abc-eg.lua --num`     | [welford](#welford) [stream](#stream) [minus](#minus) |
|  5 | Sym     | `lua abc-eg.lua --sym`     | [entropy](#entropy) [mode](#mode) [poly](#poly) [noir](#noir) |
|  6 | Cols    | `lua abc-eg.lua --cols`    | [schema](#schema) [goals](#goals) [xy](#xy) |
|  7 | Tbl     | `lua abc-eg.lua --tbl`     | [tables](#tables) [clone](#clone) |
|  8 | Dist    | `lua abc-eg.lua --dist`    | [norm](#norm) [minkowski](#minkowski) [missing](#missing) [heaven](#heaven) [knn](#knn) [anomaly](#anomaly) |
|  9 | Stats   | `lua abc-eg.lua --stats`   | [effect](#effect) [ks](#ks) [same](#same) |
| 10 | Acquire | `lua abc-eg.lua --acquire` | [budget](#budget) [active](#active) [poles](#poles) [explore](#explore) |
| 11 | Bins    | `lua abc-eg.lua --bins`    | [bins](#bins) [cost](#cost) [closure](#closure) |
| 12 | Tree    | `lua abc-eg.lua --tree`    | [tree](#tree) [predict](#predict) [explain](#explain) |
| 13 | Score   | `lua abc-eg.lua --score`   | [holdout](#holdout) [win](#win) [baseline](#baseline) [bets](#bets) [variability](#variability) |

## Glossary

## truthy

In lua only `nil` and `false` are falsy: 0 and "" are
TRUE. The `x and y or z` ternary and the `x = x or d`
default idiom both lean on this -- and both surprise
pythonistas (lesson 0).

## onetable

Lua's one data structure: the table is list, dict, object
and module at once. `ipairs` walks the list part 1,2,3..;
`pairs` walks everything, in no fixed order. Lesson 10's
`lab` (set and list in one table) is this idea at work
(lesson 0).

## patterns

Lua string patterns are not regexes: `%w %d %s` classes,
`^ $` anchors, no alternation. Small enough to learn in a
minute; enough to parse this whole system's csv, help and
schema texts (lessons 0, 3).

## bob

Uncle Bob's rule: keep functions small (5-10 lines).
Lesson 0's `--bob` demo audits abc.lua itself -- strip
comments, histogram paragraph sizes -- and the code
passes its own preaching. First of the SE design rules;
the rest live in the scope map below.

## lists

The only container in this system: Lua tables used as
lists, served by a dozen ten-line verbs that compose
(push returns its item, sort its list). A small
vocabulary covers thirteen lessons (lesson 1).


## dsu

Decorate-sort-undecorate: compute each item's sort key
once, sort the (key,item) pairs, strip the keys. Vital
when keys are expensive (a distance calc per row), as in
`keysort` (lessons 1, 8, 10).


## bisect

Binary search of a sorted list: the smallest index whose
item exceeds v, found in log time. So `bisect(t,v)-1`
counts items <= v — which is a CDF, which is why the
lesson 9 statistics ([ks](#ks), [effect](#effect)) run
fast off sorted lists.


## seed

Where a random number generator starts. A fixed seed
(here: a 16807 Lehmer generator, identical on any lua)
makes every stochastic experiment rerunnable — so results
are checkable by diff (lesson 2).


## shuffle

Fisher-Yates: walk the list backwards, swapping each item
with a random earlier one; every ordering equally likely,
in linear time (lesson 2).


## gauss

The bell curve. Box-Muller turns two uniform draws into
one normal draw with real (unclipped) tails; used to
sample plausible numeric values (lesson 2).


## roulette

Weighted random choice: pick a key with probability
proportional to its weight, by walking counts until a
random slice of the total is spent (lesson 2).


## coerce

Strings to things: "42" becomes a number, "true" a
boolean, anything else a trimmed string. The whole edge
of the system where files meet data is one tiny function
(lesson 3).


## csv

Comma-separated values, self-describing: the first line
is the [schema](#schema). Streamed one row at a time
(lesson 3), so file size never matters.


## ssot

Single source of truth: the option defaults live in the
help text and are parsed out of it, so the docs and the
program cannot disagree (lesson 3).


## welford

Incremental mean and variance in three slots (n, mu, m2),
one update per value, numerically stable — and reversible
(see [minus](#minus)) (lesson 4).


## stream

Process values one at a time, constant memory, no second
pass. [welford](#welford) streams; so do csv reads; so
does bin scoring via [minus](#minus) (lessons 3, 4).


## minus

The subtraction trick: Welford summaries un-fold, so
`i:without(j)` returns "i's data minus j's" in constant
time. This is why scoring every candidate [bin](#bins)
needs only one pass over the rows (lessons 4, 5, 11).


## entropy

The effort needed to describe what is in a bag of
symbols: -sum p log2 p. Low entropy = one symbol
dominates = easy to summarize. Sym's spread, and the
classification flavor of [cost](#cost) (lessons 5, 11).


## mode

The most common symbol in a bag: Sym's middle, and the
prediction at a classification leaf (lessons 5, 12).


## poly

Polymorphism: Num and Sym answer one interface (add, mid,
spread, without, dist, bins, holds), so distance, binning
and tree code never ask a column its type. Twenty lines
of metatables replace a design pattern (lesson 5).


## noir

Stevens' scale ladder: Nominal, Ordinal, Interval, Ratio.
This system keeps just the two ends -- symbols get
counted, numbers get averaged -- which is why two column
summaries suffice (lesson 5).


## schema

The csv header IS the schema: leading uppercase = number;
suffixes mark [goals](#goals) and columns to skip. Rename
a column and the system's whole view of the data changes;
no config files (lessons 3, 6).


## goals

The y columns: names ending "+" (maximize), "-"
(minimize), "!" (classify). Goals plus [norm](#norm)
define [heaven](#heaven) (lessons 6, 8).


## xy

The x columns describe a thing (cheap to read); the y
columns judge it (dear to measure). That asymmetry is the
economics behind the whole second half of the course
(lessons 6, 10, 13).


## tables

Rows plus typed column summaries: the first row builds
the [schema](#schema), later rows update per-column
stats as they are stored (lesson 7).


## clone

A fresh table wearing an existing header, given new rows.
Each subset then owns honest column summaries, keeping
train and test data uncontaminated (lessons 7, 13).


## norm

Map a raw number to 0..1 via a logistic over its z-score,
so a column of grams and a column of years contribute
fairly to one distance (lesson 8).


## minkowski

The p-norm: aggregate per-column gaps as
`(sum gap^p / n)^(1/p)`. p=1 city-block, p=2
euclidean-ish; one exponent tunes the geometry of both
`distx` and `disty` (lesson 8).


## missing

"?" cells. Distance treats them pessimistically — assume
the unknown value is far away — so missing data widens
gaps rather than hiding them (lesson 8).


## heaven

The ideal point where every goal is at its best value.
`disty` = a row's distance to heaven (0 = ideal, 1 =
worst), so optimization is just "find rows near heaven"
(lesson 8).


## knn

k-nearest-neighbors: sort everything by distance to a
query, let the closest few answer. No training step --
the data IS the model (lesson 8, `--near`).


## anomaly

A row far from even its own nearest neighbor. Once
distance exists, outlier detection is one argmax: find
who is loneliest (lesson 8, `--near`).


## effect

Effect size: how BIG a difference is, not merely whether
one exists. Here Cliff's delta: from sorted lists, how
often items of one sample out-rank the other's. Small
delta = who cares (lesson 9).


## ks

Kolmogorov-Smirnov: the biggest gap between two samples'
CDFs. Distribution-free, no normality assumed, and via
[bisect](#bisect) nearly free to compute (lesson 9).


## same

Conservative equality for result sets: [effect](#effect)
AND cohen AND [ks](#ks) must all agree before two samples
are called alike. Demanding all three means "different!"
is only shouted when it would be hard to argue otherwise
(lesson 9).


## budget

The number of y-labels we may buy. In real tables the x
values are cheap and the y values dear (a benchmark, a
build, a survey), so methods are judged by result per
label spent (lessons 10-13).


## active

Active learning: the learner chooses which rows to label
next, instead of labelling at random. Here (lesson 10),
choose by projecting the unlabelled pool onto a line
between two [poles](#poles) and keeping the good end.
Spend the [budget](#budget) where it teaches most.


## poles

Two far-apart rows. Projecting everything onto the line
joining them gives a cheap one-dimensional view of
n-dimensional data (after FastMap); walking toward the
good pole is lesson 10's whole tactic.


## explore

Explore vs exploit: spend labels learning the landscape,
or harvesting its best-known corner? Acquisition policies
(lesson 10) balance the two; pure exploit gets trapped,
pure explore wastes the [budget](#budget).


## bins

Chopping an x column into ranges that simplify y
(lesson 11). Numeric bins come from breaks in sorted
values, symbolic bins from each value seen; every
candidate is scored by [cost](#cost). One bin is a
readable test like `Volume <= 112`.


## cost

Split cost: the size-weighted spread of the two halves a
bin creates. Lower cost = y is simpler to describe after
the cut. The far half comes from [minus](#minus), so
scoring never re-reads the rows (lesson 11).


## closure

A function plus the variables it captured. Lesson 0's
`lst.items` is a closure remembering how far a sorted
walk has got (that is all a lua iterator is); lesson 11's
`bins.keep` is one holding the cheapest bin seen so far,
letting every column's candidates compete in one running
contest without any global state.


## tree

Recursive splitting on the cheapest [bin](#bins) while
rows and depth allow. Leaves keep their rows and a mid
prediction; branches read as English-ish tests
(lesson 12).


## predict

Route a row down the tree by its branch tests; report the
leaf's mid (mean or [mode](#mode)). Same tree, two uses:
predict and [explain](#explain) (lesson 12).


## explain

A model a human can argue with: branch tests in the
data's own vocabulary, leaves small enough to inspect.
This system prefers models that explain themselves over
models that merely score well (lesson 12).


## holdout

Judge on rows never seen in training: shuffle, train on
half under the [budget](#budget), let the tree rank the
other half, check only the top few (lesson 13).


## win

A grade for any row: 100 = as good as the best row in the
table, 0 = no better than the median, computed from the
distance-to-[heaven](#heaven) distribution (lesson 13).


## baseline

Before crediting a clever method, beat a dumb one under
the same rules. Ours: random labelling with the same
[budget](#budget). If [same](#same) can't tell them
apart, the cleverness is decoration (lessons 10, 13).


## bets

Every learner and optimizer is a falsifiable bet about
the shape of your data: in recent optimizer tournaments
the winner changed with the evaluation budget. So run the
cheap experiment; don't trust the brand name (lesson 13).


## variability

Learner variability: rerun with a new seed and the answer
moves. So report distributions, never single runs, and
judge gaps with [same](#same) (lesson 13, `--seeds`).

## Scope: the larger concept space

An audit (2026-07) of the ideas this course family wants
to explain, pooled from abc-doc.md, luamine/tut.md's
glossary, the seai26spr lectures and reviews, guru26spr's
rules.md, and the standing SE/AI rules-of-thumb lists.
**Bold** = covered by abc-eg.lua lessons (and defined
above). The rest live in the other courses, or await
future lessons.

1. Code craft:
   **lists**, **dsu**, **bisect**, **closure**,
   **poly**, **coerce**, **csv**, **ssot**, **schema**,
   little languages, **idioms** (lesson 0), **bob**
   (short functions),
   function-oriented over OO, streaming-over-loading,
   pipe-and-filter, no magic numbers, code needs doco,
   code needs tests, rogue globals, fail fast.
2. SE design rules and laws:
   SoC, SRP, DRY/WET, KISS, YAGNI, SOLID, GRASP, Law of
   Demeter, CQS, POLA, design by contract, composition
   over inheritance, mechanism vs policy, convention over
   configuration, tell don't ask, cohesion/coupling, boy
   scout rule, rule of three, Postel, Brooks, Conway,
   Occam, Chesterton's fence, Hyrum, Parkinson, 90-90,
   big ball of mud, Zawinski, Gall, premature
   optimization, coding for teams, PEP 8.
3. Data and statistics:
   **welford**, **stream**, **minus**, **entropy**,
   **mode**, **noir**, **norm**, **effect**, **ks**,
   cohen, **same**, **seed**, **gauss**, **shuffle**,
   **roulette**, **baseline**, **variability**,
   m-estimates, percentile spreads, cross-validation,
   temporal validation, overfitting, order effects,
   best/rest ranking, accuracy/FPR, sampling.
4. Distance, clustering, trees (XAI):
   **minkowski**, **heaven**, **missing**, **knn**,
   **anomaly**, **poles**, **bins**, **cost**, **tree**,
   **predict**, **explain**, kmeans/kmeans++, medoids,
   interpolation, synthesis, naive bayes, like/likes,
   black-box to small tree.
5. Search and optimization:
   **budget**, **bets**, **explore**, SBSE, GA, DE, SA,
   (1+1)/local search, GP, metropolis-hastings, pareto,
   zitzler, chebyshev/MOEA-D, IGD/spread/hypervolume,
   surrogates, multi-fidelity, racing, mutation and
   extrapolation, tournament-of-optimizers, no free
   lunch.
6. Labels and active learning:
   **active**, **xy**, **holdout**, **win**, acquisition
   functions, informativeness, representativeness,
   diversity, perversity, cold vs warm start, pool- vs
   stream-based, model-query synthesis, Thompson
   sampling, smart labeling, label-starved domains,
   semi-supervised labeling.
7. LLM-era SE and automation:
   AI agents, MCP, A2A, audit trails, reasoning traces,
   tools over agents, least privilege, automation layer
   cake, sync vs async AI, APR, fuzzing, differential
   oracles, oracle problem, evals, architecture beats
   scale, specification writing.

## References

- Welford (1962), Technometrics 4(3) — incremental
  variance.
- Park & Miller (1988), CACM 31(10) — the 16807 minimal
  standard generator.
- Box & Muller (1958) — normal deviates from uniforms.
- Cliff (1993), Psych. Bulletin 114 — dominance
  statistics.
- Cohen (1988) — statistical power and effect size.
- Massey (1951), JASA 46 — the Kolmogorov-Smirnov test.
- Faloutsos & Lin (1995), SIGMOD — FastMap (the poles
  trick).
- Breiman et al. (1984) — CART: classification and
  regression trees.
- Settles (2009) — Active Learning literature survey.
- Menzies (2026) — luamine/tut.md: ten lectures on
  data-lite AI, the long-form ancestor of these notes.
