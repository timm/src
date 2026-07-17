# glossary.md -- the shared concept dictionary

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

One entry per idea, shared by every course in this repo
(concepts are repo-level; courses just sample them). You
rarely read this file top to bottom: you arrive from a
lesson's **Core ideas** link, and the *taught in* line
under each heading points back to every lesson that uses
the term. Entries are grouped into coarse regions,
alphabetical within each; each region ends by naming
concepts still awaiting entries (and a course).


# coding

## bisect

*taught in:* [abc-eg, lesson 1](sandbox/abc-eg.lua)

Binary search of a sorted list: the smallest index whose
item exceeds v, found in log time. So `bisect(t,v)-1`
counts items <= v — which is a CDF, which is why the
lesson 9 statistics ([ks](#ks), [effect](#effect)) run
fast off sorted lists.

## closure

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua) · [abc-eg, lesson 11](sandbox/abc-eg.lua)

A function plus the variables it captured. Lesson 0's
`lst.items` is a closure remembering how far a sorted
walk has got (that is all a lua iterator is); lesson 11's
`bins.keep` is one holding the cheapest bin seen so far,
letting every column's candidates compete in one running
contest without any global state.

## coerce

*taught in:* [abc-eg, lesson 3](sandbox/abc-eg.lua)

Strings to things: "42" becomes a number, "true" a
boolean, anything else a trimmed string. The whole edge
of the system where files meet data is one tiny function
(lesson 3).

## csv

*taught in:* [abc-eg, lesson 3](sandbox/abc-eg.lua)

Comma-separated values, self-describing: the first line
is the [schema](#schema). Streamed one row at a time
(lesson 3), so file size never matters.

## dsu

*taught in:* [abc-eg, lesson 1](sandbox/abc-eg.lua)

Decorate-sort-undecorate: compute each item's sort key
once, sort the (key,item) pairs, strip the keys. Vital
when keys are expensive (a distance calc per row), as in
`keysort` (lessons 1, 8, 10).

## lists

*taught in:* [abc-eg, lesson 1](sandbox/abc-eg.lua)

The only container in this system: Lua tables used as
lists, served by a dozen ten-line verbs that compose
(push returns its item, sort its list). A small
vocabulary covers thirteen lessons (lesson 1).

## lua

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua)

For the impatient pythonista:

- only `nil` and `false` are falsy; 0 and "" are TRUE
- indexes start at 1; `for i=1,10` includes the 10
- one data structure: the table is your list, dict,
  object and module (see [onetable](#onetable))
- `pairs` walks keys in no fixed order; `ipairs` walks
  1,2,3.. and stops at the first gap
- for loops are customizable: any iterator function can
  drive one, and iterators are [closures](#closure)
- Lua's texet matching patterns are not quite standard regexes (see [patterns](#patterns))
- `x and y or z` is the ternary (breaks when y is false);
  `x = x or default` fills defaults
- `..` concatenates; `~=` is not-equals
- variables are global unless marked `local` (but see next point about function locals).
- house rule: params after the wide gap in a signature
  are locals, not arguments; callers never pass them
- comments: `-- line` and `--[[ block ]]` (this repo
  lifts block comments into tutorial prose)
- call sugar: parens are optional for a single string or
  table argument -- `s:find"-$"`, `Tbl.new{names}`
  (house style everywhere)
- `i:add(x)` is sugar for `Num.add(i, x)`: the colon
  passes the receiver as the first argument
- metatables are lua's magic methods (the full list:
  [metatable events](http://lua-users.org/wiki/MetatableEvents)
  -- __index, __call, __add, __tostring, ...). Setting
  `__index` on a shared table gives python-style method
  lookup -- see `new` in abc.lua: two lines make the
  whole class system. That buys [poly](#poly)morphism,
  not inheritance; for fuller OO see
  [PIL ch 16](https://www.lua.org/pil/16.html)
- functions are plain values that can be passed around like any other value; so higher-order style is
  everywhere: `table.sort(t)` sorts ascending;
  `table.sort(t, function(a,b) return a > b end)`
  descending; pass any comparator (must be a strict
  less-than)
- multiple return values: `("ab"):find"b"` returns start
  AND finish; unwanted extras vanish silently
- no exceptions: `error` throws, `pcall` catches --
  crash early by default
- proper tail calls: `return f(x)` reuses the current
  stack frame, so deep recursion cannot overflow
  (python has no TCO)

Lua: quick refs (quickest to read, shown first):

- Lua cheatsheet:            https://devhints.io/lua
- Learn X in Y minutes:      https://learnxinyminutes.com/docs/lua/
- Lua demo (run in browser): https://www.lua.org/demo.html
- lua-users wiki tutorials:  http://lua-users.org/wiki/TutorialDirectory
- Lua 5.4 Reference Manual:  https://www.lua.org/manual/5.4/
- PIL (Programming in Lua):  https://www.lua.org/pil/contents.html   (1st ed, free)

## onetable

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua)

Lua's one data structure: the table is list, dict, object
and module at once. `ipairs` walks the list part 1,2,3..;
`pairs` walks everything, in no fixed order. Lesson 10's
`lab` (set and list in one table) is this idea at work
(lesson 0).

## patterns

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua)

Lua string patterns are not regexes: `%w %d %s` classes,
`^ $` anchors, no alternation. Small enough to learn in a
minute; enough to parse this whole system's csv, help and
schema texts (lessons 0, 3).

## poly

*taught in:* [abc-eg, lesson 5](sandbox/abc-eg.lua)

Polymorphism: Num and Sym answer one interface (add, mid,
spread, without, dist, bins, holds), so distance, binning
and tree code never ask a column its type. Twenty lines
of metatables replace a design pattern (lesson 5).

## truthy

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua)

In lua only `nil` and `false` are falsy: 0 and "" are
TRUE. The `x and y or z` ternary and the `x = x or d`
default idiom both lean on this -- and both surprise
pythonistas (lesson 0).

*Awaiting entries:* little languages, short functions as style, streaming over loading, fail fast, rogue globals.


# se

## bob

*taught in:* [abc-eg, lesson 0](sandbox/abc-eg.lua)

Uncle Bob's rule: keep functions small (5-10 lines).
Lesson 0's `--bob` demo audits abc.lua itself -- strip
comments, histogram paragraph sizes -- and the code
passes its own preaching. First of the SE design rules;
the rest live in the scope map below.

## schema

*taught in:* [abc-eg, lesson 6](sandbox/abc-eg.lua)

The csv header IS the schema: leading uppercase = number;
suffixes mark [goals](#goals) and columns to skip. Rename
a column and the system's whole view of the data changes;
no config files (lessons 3, 6).

## ssot

*taught in:* [abc-eg, lesson 3](sandbox/abc-eg.lua)

Single source of truth: the option defaults live in the
help text and are parsed out of it, so the docs and the
program cannot disagree (lesson 3).

*Awaiting entries:* SoC, SRP, DRY, KISS, YAGNI, SOLID, GRASP, Demeter, CQS, POLA, design by contract, composition over inheritance, mechanism vs policy, convention over configuration, tell don't ask, cohesion/coupling, boy scout, rule of three, Postel, Brooks, Conway, Occam, Chesterton, Hyrum, Parkinson, 90-90, big ball of mud, Zawinski, Gall, premature optimization.


# data and stats

## baseline

*taught in:* [abc-eg, lesson 13](sandbox/abc-eg.lua)

Before crediting a clever method, beat a dumb one under
the same rules. Ours: random labelling with the same
[budget](#budget). If [same](#same) can't tell them
apart, the cleverness is decoration (lessons 10, 13).

## effect

*taught in:* [abc-eg, lesson 9](sandbox/abc-eg.lua)

Effect size: how BIG a difference is, not merely whether
one exists. Here Cliff's delta: from sorted lists, how
often items of one sample out-rank the other's. Small
delta = who cares (lesson 9).

## entropy

*taught in:* [abc-eg, lesson 5](sandbox/abc-eg.lua)

The effort needed to describe what is in a bag of
symbols: -sum p log2 p. Low entropy = one symbol
dominates = easy to summarize. Sym's spread, and the
classification flavor of [cost](#cost) (lessons 5, 11).

## gauss

*taught in:* [abc-eg, lesson 2](sandbox/abc-eg.lua)

The bell curve. Box-Muller turns two uniform draws into
one normal draw with real (unclipped) tails; used to
sample plausible numeric values (lesson 2).

## ks

*taught in:* [abc-eg, lesson 9](sandbox/abc-eg.lua)

Kolmogorov-Smirnov: the biggest gap between two samples'
CDFs. Distribution-free, no normality assumed, and via
[bisect](#bisect) nearly free to compute (lesson 9).

## minus

*taught in:* [abc-eg, lesson 4](sandbox/abc-eg.lua)

The subtraction trick: Welford summaries un-fold, so
`i:without(j)` returns "i's data minus j's" in constant
time. This is why scoring every candidate [bin](#bins)
needs only one pass over the rows (lessons 4, 5, 11).

## mode

*taught in:* [abc-eg, lesson 5](sandbox/abc-eg.lua)

The most common symbol in a bag: Sym's middle, and the
prediction at a classification leaf (lessons 5, 12).

## noir

*taught in:* [abc-eg, lesson 5](sandbox/abc-eg.lua)

Stevens' scale ladder: Nominal, Ordinal, Interval, Ratio.
This system keeps just the two ends -- symbols get
counted, numbers get averaged -- which is why two column
summaries suffice (lesson 5).

## roulette

*taught in:* [abc-eg, lesson 2](sandbox/abc-eg.lua)

Weighted random choice: pick a key with probability
proportional to its weight, by walking counts until a
random slice of the total is spent (lesson 2).

## same

*taught in:* [abc-eg, lesson 9](sandbox/abc-eg.lua)

Conservative equality for result sets: [effect](#effect)
AND cohen AND [ks](#ks) must all agree before two samples
are called alike. Demanding all three means "different!"
is only shouted when it would be hard to argue otherwise
(lesson 9).

## seed

*taught in:* [abc-eg, lesson 2](sandbox/abc-eg.lua)

Where a random number generator starts. A fixed seed
(here: a 16807 Lehmer generator, identical on any lua)
makes every stochastic experiment rerunnable — so results
are checkable by diff (lesson 2).

## shuffle

*taught in:* [abc-eg, lesson 2](sandbox/abc-eg.lua)

Fisher-Yates: walk the list backwards, swapping each item
with a random earlier one; every ordering equally likely,
in linear time (lesson 2).

## stream

*taught in:* [abc-eg, lesson 4](sandbox/abc-eg.lua)

Process values one at a time, constant memory, no second
pass. [welford](#welford) streams; so do csv reads; so
does bin scoring via [minus](#minus) (lessons 3, 4).

## variability

*taught in:* [abc-eg, lesson 13](sandbox/abc-eg.lua)

Learner variability: rerun with a new seed and the answer
moves. So report distributions, never single runs, and
judge gaps with [same](#same) (lesson 13, `--seeds`).

## welford

*taught in:* [abc-eg, lesson 4](sandbox/abc-eg.lua)

Incremental mean and variance in three slots (n, mu, m2),
one update per value, numerically stable — and reversible
(see [minus](#minus)) (lesson 4).

*Awaiting entries:* cohen, m-estimates, percentile spreads, cross-validation, temporal validation, overfitting, order effects, best/rest ranking, accuracy/FPR.


# distance

## anomaly

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

A row far from even its own nearest neighbor. Once
distance exists, outlier detection is one argmax: find
who is loneliest (lesson 8, `--near`).

## centroid

*taught in:* [abc-eg, lesson 7](sandbox/abc-eg.lua)

A table's middle: every column's mid, in column order.
Computed lazily and cached; any add wipes the cache,
since new rows move the middle. Compare a subset
[clone](#clone)'s centroid to the full table's to see
sampling error with your own eyes.

## clone

*taught in:* [abc-eg, lesson 7](sandbox/abc-eg.lua)

A fresh table wearing an existing header, given new rows.
Each subset then owns honest column summaries, keeping
train and test data uncontaminated (lessons 7, 13).

## heaven

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

The ideal point where every goal is at its best value.
`disty` = a row's distance to heaven (0 = ideal, 1 =
worst), so optimization is just "find rows near heaven"
(lesson 8).

## knn

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

k-nearest-neighbors: sort everything by distance to a
query, let the closest few answer. No training step --
the data IS the model (lesson 8, `--near`).

## minkowski

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

The p-norm: aggregate per-column gaps as
`(sum gap^p / n)^(1/p)`. p=1 city-block, p=2
euclidean-ish; one exponent tunes the geometry of both
`distx` and `disty` (lesson 8).

## missing

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

"?" cells. Distance treats them pessimistically — assume
the unknown value is far away — so missing data widens
gaps rather than hiding them (lesson 8).

## norm

*taught in:* [abc-eg, lesson 8](sandbox/abc-eg.lua)

Map a raw number to 0..1 via a logistic over its z-score,
so a column of grams and a column of years contribute
fairly to one distance (lesson 8).

## poles

*taught in:* [abc-eg, lesson 10](sandbox/abc-eg.lua)

Two far-apart rows. Projecting everything onto the line
joining them gives a cheap one-dimensional view of
n-dimensional data (after FastMap); walking toward the
good pole is lesson 10's whole tactic.

## tables

*taught in:* [abc-eg, lesson 7](sandbox/abc-eg.lua)

Rows plus typed column summaries: the first row builds
the [schema](#schema), later rows update per-column
stats as they are stored (lesson 7).

*Awaiting entries:* kmeans, kmeans++, medoids, interpolation, synthesis, naive bayes, black-box to small tree.


# search and optimize

## bets

*taught in:* [abc-eg, lesson 13](sandbox/abc-eg.lua)

Every learner and optimizer is a falsifiable bet about
the shape of your data: in recent optimizer tournaments
the winner changed with the evaluation budget. So run the
cheap experiment; don't trust the brand name (lesson 13).

## bins

*taught in:* [abc-eg, lesson 11](sandbox/abc-eg.lua)

Chopping an x column into ranges that simplify y
(lesson 11). Numeric bins come from breaks in sorted
values, symbolic bins from each value seen; every
candidate is scored by [cost](#cost). One bin is a
readable test like `Volume <= 112`.

## cost

*taught in:* [abc-eg, lesson 11](sandbox/abc-eg.lua)

Split cost: the size-weighted spread of the two halves a
bin creates. Lower cost = y is simpler to describe after
the cut. The far half comes from [minus](#minus), so
scoring never re-reads the rows (lesson 11).

## explain

*taught in:* [abc-eg, lesson 12](sandbox/abc-eg.lua)

A model a human can argue with: branch tests in the
data's own vocabulary, leaves small enough to inspect.
This system prefers models that explain themselves over
models that merely score well (lesson 12).

## explore

*taught in:* [abc-eg, lesson 10](sandbox/abc-eg.lua)

Explore vs exploit: spend labels learning the landscape,
or harvesting its best-known corner? Acquisition policies
(lesson 10) balance the two; pure exploit gets trapped,
pure explore wastes the [budget](#budget).

## predict

*taught in:* [abc-eg, lesson 12](sandbox/abc-eg.lua)

Route a row down the tree by its branch tests; report the
leaf's mid (mean or [mode](#mode)). Same tree, two uses:
predict and [explain](#explain) (lesson 12).

## tree

*taught in:* [abc-eg, lesson 12](sandbox/abc-eg.lua)

Recursive splitting on the cheapest [bin](#bins) while
rows and depth allow. Leaves keep their rows and a mid
prediction; branches read as English-ish tests
(lesson 12).

*Awaiting entries:* SBSE, GA, DE, SA, local search, GP, metropolis-hastings, pareto, zitzler, chebyshev, MOEA-D, IGD, hypervolume, surrogates, multi-fidelity, racing, no free lunch.


# labels

## active

*taught in:* [abc-eg, lesson 10](sandbox/abc-eg.lua)

Active learning: the learner chooses which rows to label
next, instead of labelling at random. Here (lesson 10),
choose by projecting the unlabelled pool onto a line
between two [poles](#poles) and keeping the good end.
Spend the [budget](#budget) where it teaches most.

## budget

*taught in:* [abc-eg, lesson 10](sandbox/abc-eg.lua)

The number of y-labels we may buy. In real tables the x
values are cheap and the y values dear (a benchmark, a
build, a survey), so methods are judged by result per
label spent (lessons 10-13).

## goals

*taught in:* [abc-eg, lesson 6](sandbox/abc-eg.lua)

The y columns: names ending "+" (maximize), "-"
(minimize), "!" (classify). Goals plus [norm](#norm)
define [heaven](#heaven) (lessons 6, 8).

## holdout

*taught in:* [abc-eg, lesson 13](sandbox/abc-eg.lua)

Judge on rows never seen in training: shuffle, train on
half under the [budget](#budget), let the tree rank the
other half, check only the top few (lesson 13).

## win

*taught in:* [abc-eg, lesson 13](sandbox/abc-eg.lua)

A grade for any row: 100 = as good as the best row in the
table, 0 = no better than the median, computed from the
distance-to-[heaven](#heaven) distribution (lesson 13).

## xy

*taught in:* [abc-eg, lesson 6](sandbox/abc-eg.lua)

The x columns describe a thing (cheap to read); the y
columns judge it (dear to measure). That asymmetry is the
economics behind the whole second half of the course
(lessons 6, 10, 13).

*Awaiting entries:* acquisition functions, informativeness, representativeness, diversity, cold vs warm start, pool- vs stream-based, Thompson sampling, smart labeling.


# llm-era se

*Awaiting entries:* AI agents, MCP, A2A, audit trails, reasoning traces, tools over agents, least privilege, automation layer cake, APR, fuzzing, differential oracles, evals.
