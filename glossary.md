# glossary.md -- the shared concept dictionary

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

One entry per idea, shared by every course in this repo
(concepts are repo-level; courses just sample them). You
rarely read this file top to bottom: you arrive from a
lesson's **Core ideas** link, and the *taught in* line
under each heading points back to every lesson that uses
the term. Where an idea rests on a paper, a *see:* `[^key]`
footnote cites it (peer-reviewed, MLA, with a verify link;
all defined in `# references` at the end). Entries are
grouped into coarse regions, alphabetical within each; each
region ends by naming concepts still awaiting entries (and
a course).


# coding

## bisect

*taught in:* [xai-eg, lesson 1](ezr-lua/xai-eg.lua)

Binary search of a sorted list: the smallest index whose
item exceeds v, found in log time. So `bisect(t,v)-1`
counts items <= v — which is a CDF, which is why the
lesson 9 statistics ([ks](#ks), [effect](#effect)) run
fast off sorted lists.

## closure

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua) · [xai-eg, lesson 11](ezr-lua/xai-eg.lua)

A function plus the variables it captured. Lesson 0's
`lst.items` is a closure remembering how far a sorted
walk has got (that is all a lua iterator is); lesson 11's
`bins.keep` is one holding the cheapest bin seen so far,
letting every column's candidates compete in one running
contest without any global state.

## coerce

*taught in:* [xai-eg, lesson 3](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 1](ezr-lisp/xai-eg.lisp)

Strings to things: "42" becomes a number, "true" a
boolean, anything else a trimmed string. The whole edge
of the system where files meet data is one tiny function
(lesson 3).

## csv

*taught in:* [xai-eg, lesson 3](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 1](ezr-lisp/xai-eg.lisp)

Comma-separated values, self-describing: the first line
is the [schema](#schema). Streamed one row at a time
(lesson 3), so file size never matters.

## dsu

*taught in:* [xai-eg, lesson 1](ezr-lua/xai-eg.lua)

Decorate-sort-undecorate: compute each item's sort key
once, sort the (key,item) pairs, strip the keys. Vital
when keys are expensive (a distance calc per row), as in
`keysort` (lessons 1, 8, 10).

## lists

*taught in:* [xai-eg, lesson 1](ezr-lua/xai-eg.lua)

The only container in this system: Lua tables used as
lists, served by a dozen ten-line verbs that compose
(push returns its item, sort its list). A small
vocabulary covers thirteen lessons (lesson 1).

## lisp

*taught in:* [xai-eg (lisp), lesson 0](ezr-lisp/xai-eg.lisp)

For the impatient pythonista:

- `nil` is the only false, and it IS the empty list;
  0 and "" are TRUE
- five spellings of equal: `eq` (same object), `eql`
  (same object, or same-type same-value number), `equal`
  (same structure), `equalp` (case- and type-blind), `=`
  (same numeric value)
- functions live in their own namespace: quote them with
  `#'`, call function values with `funcall` or `apply`
- integer math stays exact: `(/ 1 3)` is the rational
  `1/3`, not 0.333; `(float x)` when you must round
- many returns: `(floor 7 2)` yields 3 AND 1; the extras
  drop silently unless caught by `multiple-value-bind`
- `format` is its own tiny language: `~a` display, `~s`
  readable, `~,2f` two decimals, `~&` fresh line

## lua

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua)

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
  lookup -- see `new` in xai.lua: two lines make the
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

## macros

*taught in:* [xai-eg (lisp), lesson 2](ezr-lisp/xai-eg.lisp)

Code that writes code, at compile time. Used sparingly
here: one accessor family (`ats` reads hash keys and
struct slots alike; `?` nests it; `ats!` fills a missing
key on first touch) plus `aif`, which remembers its test
as `it`. Rule of thumb: a macro must buy shorter call
sites at every use, else write a function.

## onetable

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua)

Lua's one data structure: the table is list, dict, object
and module at once. `ipairs` walks the list part 1,2,3..;
`pairs` walks everything, in no fixed order. Lesson 10's
`lab` (set and list in one table) is this idea at work
(lesson 0).

## patterns

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua)

Lua string patterns are not regexes: `%w %d %s` classes,
`^ $` anchors, no alternation. Small enough to learn in a
minute; enough to parse this whole system's csv, help and
schema texts (lessons 0, 3).

## poly

*taught in:* [xai-eg, lesson 5](ezr-lua/xai-eg.lua)

Polymorphism: Num and Sym answer one interface (add, mid,
spread, without, dist, bins, holds), so distance, binning
and tree code never ask a column its type. Twenty lines
of metatables replace a design pattern (lesson 5).

## truthy

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 0](ezr-lisp/xai-eg.lisp)

In lua only `nil` and `false` are falsy: 0 and "" are
TRUE. The `x and y or z` ternary and the `x = x or d`
default idiom both lean on this -- and both surprise
pythonistas (lesson 0).

*Awaiting entries:* little languages, short functions as style, streaming over loading, fail fast, rogue globals.


# se

## bob

*taught in:* [xai-eg, lesson 0](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 0](ezr-lisp/xai-eg.lisp)

Uncle Bob's rule: keep functions small (5-10 lines).
Lesson 0's `--bob` demo audits xai.lua itself -- strip
comments, histogram paragraph sizes -- and the code
passes its own preaching. First of the SE design rules;
the rest live in the scope map below.

## schema

*taught in:* [xai-eg, lesson 6](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 6](ezr-lisp/xai-eg.lisp)

The csv header IS the schema: leading uppercase = number;
suffixes mark [goals](#goals) and columns to skip. Rename
a column and the system's whole view of the data changes;
no config files (lessons 3, 6).

## ssot

*taught in:* [xai-eg, lesson 3](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 2](ezr-lisp/xai-eg.lisp)

Single source of truth: the option defaults live in the
help text and are parsed out of it, so the docs and the
program cannot disagree (lesson 3).

*Awaiting entries:* SoC, SRP, DRY, KISS, YAGNI, SOLID, GRASP, Demeter, CQS, POLA, design by contract, composition over inheritance, mechanism vs policy, convention over configuration, tell don't ask, cohesion/coupling, boy scout, rule of three, Postel, Brooks, Conway, Occam, Chesterton, Hyrum, Parkinson, 90-90, big ball of mud, Zawinski, Gall, premature optimization.


# data and stats

## baseline

*taught in:* [xai-eg, lesson 13](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 12](ezr-lisp/xai-eg.lisp)

Before crediting a clever method, beat a dumb one under
the same rules. Ours: random labelling with the same
[budget](#budget). If [same](#same) can't tell them
apart, the cleverness is decoration (lessons 10, 13).

## bayes

*taught in:* [xaiplus, lesson 4](ezr-lua/xaiplus-eg.lua) · [xaiplus, lesson 5](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 4](ezr-lisp/xaiplus-eg.lisp)

Naive Bayes: score a row under a klass by multiplying its
columns' likelihoods -- a [gauss](#gauss)ian pdf for
numbers, a smoothed frequency for symbols (log-summed, so
underflow never bites). "Naive" = assumes the columns
independent; cheap, incremental, a strong baseline.

## confusion

*taught in:* [xaiplus, lesson 5](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 5](ezr-lisp/xaiplus-eg.lisp)

A confusion matrix counts predictions by (actual, guessed)
klass. Its diagonal is the hits; accuracy is the diagonal
over the total. Off-diagonal cells show which klasses a
learner keeps mixing up.

## effect

*taught in:* [xai-eg, lesson 9](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 8](ezr-lisp/xai-eg.lisp)

*see:* [^cliff]

Effect size: how BIG a difference is, not merely whether
one exists. Here Cliff's delta: from sorted lists, how
often items of one sample out-rank the other's. Small
delta = who cares (lesson 9).

## entropy

*taught in:* [xai-eg, lesson 5](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 3](ezr-lisp/xai-eg.lisp)

The effort needed to describe what is in a bag of
symbols: -sum p log2 p. Low entropy = one symbol
dominates = easy to summarize. Sym's spread, and the
classification flavor of [cost](#cost) (lessons 5, 11).

## gauss

*taught in:* [xai-eg, lesson 2](ezr-lua/xai-eg.lua) · [xaiplus-eg (lisp), lesson 4](ezr-lisp/xaiplus-eg.lisp)

*see:* [^boxmuller]

The bell curve. Box-Muller turns two uniform draws into
one normal draw with real (unclipped) tails; used to
sample plausible numeric values (lesson 2).

## ks

*taught in:* [xai-eg, lesson 9](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 8](ezr-lisp/xai-eg.lisp)

*see:* [^massey]

Kolmogorov-Smirnov: the biggest gap between two samples'
CDFs. Distribution-free, no normality assumed, and via
[bisect](#bisect) nearly free to compute (lesson 9).

## minus

*taught in:* [xai-eg, lesson 4](ezr-lua/xai-eg.lua)

The subtraction trick: Welford summaries un-fold, so
`i:without(j)` returns "i's data minus j's" in constant
time. This is why scoring every candidate [bin](#bins)
needs only one pass over the rows (lessons 4, 5, 11).

## mode

*taught in:* [xai-eg, lesson 5](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 3](ezr-lisp/xai-eg.lisp) · [xaiplus-eg (lisp), lesson 1](ezr-lisp/xaiplus-eg.lisp)

The most common symbol in a bag: Sym's middle, and the
prediction at a classification leaf (lessons 5, 12).

## noir

*taught in:* [xai-eg, lesson 5](ezr-lua/xai-eg.lua)

Stevens' scale ladder: Nominal, Ordinal, Interval, Ratio.
This system keeps just the two ends -- symbols get
counted, numbers get averaged -- which is why two column
summaries suffice (lesson 5).

## roulette

*taught in:* [xai-eg, lesson 2](ezr-lua/xai-eg.lua)

Weighted random choice: pick a key with probability
proportional to its weight, by walking counts until a
random slice of the total is spent (lesson 2).

## same

*taught in:* [xai-eg, lesson 9](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 8](ezr-lisp/xai-eg.lisp)

*see:* [^cohen]

Conservative equality for result sets: [effect](#effect)
AND cohen AND [ks](#ks) must all agree before two samples
are called alike. Demanding all three means "different!"
is only shouted when it would be hard to argue otherwise
(lesson 9).

## seed

*taught in:* [xai-eg, lesson 2](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 5](ezr-lisp/xai-eg.lisp)

*see:* [^parkmiller]

Where a random number generator starts. A fixed seed
(here: a 16807 Lehmer generator, identical on any lua)
makes every stochastic experiment rerunnable — so results
are checkable by diff (lesson 2).

## shuffle

*taught in:* [xai-eg, lesson 2](ezr-lua/xai-eg.lua)

Fisher-Yates: walk the list backwards, swapping each item
with a random earlier one; every ordering equally likely,
in linear time (lesson 2).

## stream

*taught in:* [xai-eg, lesson 4](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 4](ezr-lisp/xai-eg.lisp)

Process values one at a time, constant memory, no second
pass. [welford](#welford) streams; so do csv reads; so
does bin scoring via [minus](#minus) (lessons 3, 4).

## variability

*taught in:* [xai-eg, lesson 13](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 12](ezr-lisp/xai-eg.lisp)

Learner variability: rerun with a new seed and the answer
moves. So report distributions, never single runs, and
judge gaps with [same](#same) (lesson 13, `--seeds`).

## welford

*taught in:* [xai-eg, lesson 4](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 4](ezr-lisp/xai-eg.lisp)

*see:* [^welford]

Incremental mean and variance in three slots (n, mu, m2),
one update per value, numerically stable — and reversible
(see [minus](#minus)) (lesson 4).

*Awaiting entries:* cohen, m-estimates, percentile spreads, cross-validation, temporal validation, overfitting, order effects, best/rest ranking, accuracy/FPR.


# distance

## anomaly

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xaiplus, lesson 14](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 14](ezr-lisp/xaiplus-eg.lisp)

A row far from even its own nearest neighbor. Once
distance exists, outlier detection is one argmax: find
who is loneliest (lesson 8, `--near`; a calibrated
nearest-gap CDF in xaiplus lesson 14).

## centroid

*taught in:* [xai-eg, lesson 7](ezr-lua/xai-eg.lua) · [xaiplus-eg (lisp), lesson 2](ezr-lisp/xaiplus-eg.lisp)

A table's middle: every column's mid, in column order.
Computed lazily and cached; any add wipes the cache,
since new rows move the middle. Compare a subset
[clone](#clone)'s centroid to the full table's to see
sampling error with your own eyes.

## clone

*taught in:* [xai-eg, lesson 7](ezr-lua/xai-eg.lua)

A fresh table wearing an existing header, given new rows.
Each subset then owns honest column summaries, keeping
train and test data uncontaminated (lessons 7, 13).

## heaven

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 7](ezr-lisp/xai-eg.lisp)

The ideal point where every goal is at its best value.
`disty` = a row's distance to heaven (0 = ideal, 1 =
worst), so optimization is just "find rows near heaven"
(lesson 8).

## kmeans

*taught in:* [xaiplus, lesson 2](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 2](ezr-lisp/xaiplus-eg.lisp)

k clusters found by repetition: drop each row into its
nearest centroid, move every centroid to its members'
[centroid](#centroid), repeat. Cheap, but a random start
scatters the result -- which is why [kmeanspp](#kmeanspp)
seeds smarter.

## kmeanspp

*taught in:* [xaiplus, lesson 3](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 3](ezr-lisp/xaiplus-eg.lisp)

kmeans++ seeding: draw each new centroid from a small pool
with probability proportional to its squared distance to
the nearest centroid so far, so far-apart rows win. A better
start than random, so [kmeans](#kmeans) settles faster.

## knn

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xaiplus, lesson 1](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 1](ezr-lisp/xaiplus-eg.lisp)

k-nearest-neighbors: sort everything by distance to a
query, let the closest few answer. No training step --
the data IS the model (lesson 8, `--near`; a klass-voting
classifier in xaiplus lesson 1).

## minkowski

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 7](ezr-lisp/xai-eg.lisp)

The p-norm: aggregate per-column gaps as
`(sum gap^p / n)^(1/p)`. p=1 city-block, p=2
euclidean-ish; one exponent tunes the geometry of both
`distx` and `disty` (lesson 8).

## missing

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 7](ezr-lisp/xai-eg.lisp)

"?" cells. Distance treats them pessimistically — assume
the unknown value is far away — so missing data widens
gaps rather than hiding them (lesson 8).

## norm

*taught in:* [xai-eg, lesson 8](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 7](ezr-lisp/xai-eg.lisp)

Map a raw number to 0..1 via a logistic over its z-score,
so a column of grams and a column of years contribute
fairly to one distance (lesson 8).

## poles

*taught in:* [xai-eg, lesson 10](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 9](ezr-lisp/xai-eg.lisp)

*see:* [^fastmap]

Two far-apart rows. Projecting everything onto the line
joining them gives a cheap one-dimensional view of
n-dimensional data (after FastMap); walking toward the
good pole is lesson 10's whole tactic.

## tables

*taught in:* [xai-eg, lesson 7](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 6](ezr-lisp/xai-eg.lisp)

Rows plus typed column summaries: the first row builds
the [schema](#schema), later rows update per-column
stats as they are stored (lesson 7).

*Awaiting entries:* medoids, interpolation, black-box to small tree.


# search and optimize

## bets

*taught in:* [xai-eg, lesson 13](ezr-lua/xai-eg.lua) · [xaiplus-eg (lisp), lesson 11](ezr-lisp/xaiplus-eg.lisp)

Every learner and optimizer is a falsifiable bet about
the shape of your data: in recent optimizer tournaments
the winner changed with the evaluation budget. So run the
cheap experiment; don't trust the brand name (lesson 13).

## bins

*taught in:* [xai-eg, lesson 11](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 10](ezr-lisp/xai-eg.lisp)

Chopping an x column into ranges that simplify y
(lesson 11). Numeric bins come from breaks in sorted
values, symbolic bins from each value seen; every
candidate is scored by [cost](#cost). One bin is a
readable test like `Volume <= 112`.

## cost

*taught in:* [xai-eg, lesson 11](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 10](ezr-lisp/xai-eg.lisp)

Split cost: the size-weighted spread of the two halves a
bin creates. Lower cost = y is simpler to describe after
the cut. The far half comes from [minus](#minus), so
scoring never re-reads the rows (lesson 11).

## de

*taught in:* [xaiplus, lesson 7](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 7](ezr-lisp/xaiplus-eg.lisp)

Differential evolution: evolve a population of rows; each
child is three others blended as a + F*(b - c), kept only
if it scores better. Few knobs, strong results -- the
default workhorse optimizer here.

## explain

*taught in:* [xai-eg, lesson 12](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 11](ezr-lisp/xai-eg.lisp)

A model a human can argue with: branch tests in the
data's own vocabulary, leaves small enough to inspect.
This system prefers models that explain themselves over
models that merely score well (lesson 12).

## explore

*taught in:* [xai-eg, lesson 10](ezr-lua/xai-eg.lua)

Explore vs exploit: spend labels learning the landscape,
or harvesting its best-known corner? Acquisition policies
(lesson 10) balance the two; pure exploit gets trapped,
pure explore wastes the [budget](#budget).

## ga

*taught in:* [xaiplus, lesson 8](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 8](ezr-lisp/xaiplus-eg.lisp)

Genetic algorithm: each generation mutates the population,
then refills it by crossover of tournament-selected
parents. Mutation explores, crossover recombines,
tournaments apply the selection pressure.

## ls

*taught in:* [xaiplus, lesson 10](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 10](ezr-lisp/xaiplus-eg.lisp)

Local search: greedy hill climbing that jumps to a fresh
random start whenever it stalls, so one bad basin cannot
trap the whole run. A baseline fancier search must beat.

## mutate

*taught in:* [xaiplus, lesson 6](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 6](ezr-lisp/xaiplus-eg.lisp)

Making new rows from old: nudge one cell (a [gauss](#gauss)
for numbers, a frequency draw for symbols), or blend three
rows the differential-evolution way (a + F*(b - c), one
column always kept from the base). The raw material every
optimizer searches over.

## predict

*taught in:* [xai-eg, lesson 12](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 11](ezr-lisp/xai-eg.lisp)

Route a row down the tree by its branch tests; report the
leaf's mid (mean or [mode](#mode)). Same tree, two uses:
predict and [explain](#explain) (lesson 12).

## race

*taught in:* [xaiplus, lesson 11](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 11](ezr-lisp/xaiplus-eg.lisp)

Run several optimizers on the same data and rank them by
result. There is no universal winner (no free lunch), so a
cheap race beats trusting any one method's reputation.

## sa

*taught in:* [xaiplus, lesson 9](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 9](ezr-lisp/xaiplus-eg.lisp)

Simulated annealing: a one-solution search that always
takes better moves and sometimes worse ones, the tolerance
cooling as the budget spends -- wander early, greedy late.

## synthesis

*taught in:* [xaiplus, lesson 12](ezr-lua/xaiplus-eg.lua) · [xaiplus-eg (lisp), lesson 12](ezr-lisp/xaiplus-eg.lisp)

Inventing new rows: grow a [tree](#tree), then blend rows
within a single leaf, so each synthetic row stays inside a
real, coherent region rather than a void between clusters.

## tree

*taught in:* [xai-eg, lesson 12](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 11](ezr-lisp/xai-eg.lisp) · [xaiplus-eg (lisp), lesson 12](ezr-lisp/xaiplus-eg.lisp)

*see:* [^cart]

Recursive splitting on the cheapest [bin](#bins) while
rows and depth allow. Leaves keep their rows and a mid
prediction; branches read as English-ish tests
(lesson 12).

*Awaiting entries:* SBSE, GP, metropolis-hastings, pareto, zitzler, chebyshev, MOEA-D, IGD, hypervolume, surrogates, multi-fidelity, no free lunch.


# labels

## active

*taught in:* [xai-eg, lesson 10](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 9](ezr-lisp/xai-eg.lisp) · [xaiplus-eg (lisp), lesson 13](ezr-lisp/xaiplus-eg.lisp)

*see:* [^settles]

Active learning: the learner chooses which rows to label
next, instead of labelling at random. Here (lesson 10),
choose by projecting the unlabelled pool onto a line
between two [poles](#poles) and keeping the good end.
Spend the [budget](#budget) where it teaches most.

## budget

*taught in:* [xai-eg, lesson 10](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 9](ezr-lisp/xai-eg.lisp) · [xaiplus-eg (lisp), lesson 13](ezr-lisp/xaiplus-eg.lisp)

The number of y-labels we may buy. In real tables the x
values are cheap and the y values dear (a benchmark, a
build, a survey), so methods are judged by result per
label spent (lessons 10-13).

## goals

*taught in:* [xai-eg, lesson 6](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 6](ezr-lisp/xai-eg.lisp)

The y columns: names ending "+" (maximize), "-"
(minimize), "!" (classify). Goals plus [norm](#norm)
define [heaven](#heaven) (lessons 6, 8).

## holdout

*taught in:* [xai-eg, lesson 13](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 12](ezr-lisp/xai-eg.lisp)

Judge on rows never seen in training: shuffle, train on
half under the [budget](#budget), let the tree rank the
other half, check only the top few (lesson 13).

## win

*taught in:* [xai-eg, lesson 13](ezr-lua/xai-eg.lua) · [xai-eg (lisp), lesson 12](ezr-lisp/xai-eg.lisp)

A grade for any row: 100 = as good as the best row in the
table, 0 = no better than the median, computed from the
distance-to-[heaven](#heaven) distribution (lesson 13).

## xy

*taught in:* [xai-eg, lesson 6](ezr-lua/xai-eg.lua)

The x columns describe a thing (cheap to read); the y
columns judge it (dear to measure). That asymmetry is the
economics behind the whole second half of the course
(lessons 6, 10, 13).

*Awaiting entries:* acquisition functions, informativeness, representativeness, diversity, cold vs warm start, pool- vs stream-based, Thompson sampling, smart labeling.


# llm-era se

*Awaiting entries:* AI agents, MCP, A2A, audit trails, reasoning traces, tools over agents, least privilege, automation layer cake, APR, fuzzing, differential oracles, evals.


# references

Papers cited above via GFM footnotes (`[^key]` on an
entry's *see:* line), MLA style, each ending in a link so a
reader can verify the work is real. Concept-level, so shared
across every course. (DOIs written by hand -- spot-check
before relying.)

[^welford]: Welford, B. P. "Note on a Method for Calculating Corrected Sums of Squares and Products." *Technometrics*, vol. 4, no. 3, 1962, pp. 419-420. <https://doi.org/10.1080/00401706.1962.10490022>
[^parkmiller]: Park, Stephen K., and Keith W. Miller. "Random Number Generators: Good Ones Are Hard to Find." *Communications of the ACM*, vol. 31, no. 10, 1988, pp. 1192-1201. <https://doi.org/10.1145/63039.63042>
[^boxmuller]: Box, G. E. P., and Mervin E. Muller. "A Note on the Generation of Random Normal Deviates." *The Annals of Mathematical Statistics*, vol. 29, no. 2, 1958, pp. 610-611. <https://doi.org/10.1214/aoms/1177706645>
[^cliff]: Cliff, Norman. "Dominance Statistics: Ordinal Analyses to Answer Ordinal Questions." *Psychological Bulletin*, vol. 114, no. 3, 1993, pp. 494-509. <https://doi.org/10.1037/0033-2909.114.3.494>
[^cohen]: Cohen, Jacob. *Statistical Power Analysis for the Behavioral Sciences*. 2nd ed., Lawrence Erlbaum Associates, 1988. <https://doi.org/10.4324/9780203771587>
[^massey]: Massey, Frank J. "The Kolmogorov-Smirnov Test for Goodness of Fit." *Journal of the American Statistical Association*, vol. 46, no. 253, 1951, pp. 68-78. <https://doi.org/10.1080/01621459.1951.10500769>
[^fastmap]: Faloutsos, Christos, and King-Ip Lin. "FastMap: A Fast Algorithm for Indexing, Data-Mining and Visualization of Traditional and Multimedia Datasets." *Proc. 1995 ACM SIGMOD Int. Conf. on Management of Data*, 1995, pp. 163-174. <https://doi.org/10.1145/223784.223812>
[^cart]: Breiman, Leo, et al. *Classification and Regression Trees*. Wadsworth, 1984. <https://doi.org/10.1201/9781315139470>
[^settles]: Settles, Burr. "Active Learning Literature Survey." Computer Sciences Technical Report 1648, University of Wisconsin-Madison, 2009. <https://minds.wisconsin.edu/handle/1793/60660>

General (the long-form ancestor of the xai course, not a
single paper): Menzies, Tim. *luamine/tut.md: Ten Lectures
on Data-Lite AI.* timm/src, 2026.
<https://github.com/timm/src/blob/main/luamine/tut.md>
