<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-Active%C2%B7Learning-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-129%C2%B7datasets-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-85%25%C2%B7gap%C2%B7closed%C2%B7with%C2%B750%C2%B7labels-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-~0.25%C2%B7CPU%C2%B7s%C2%B7per%C2%B7study-ff8c00?logo=speedtest&logoColor=white">

# How much labelling does landscape optimization need?

**tl;dr** How good? With ~50 labels the rig closes 85% of
the gap to the best row on the median dataset (RQ0). How
fast? 50 labels beat 20 on 67% of datasets, budgets past
~50 are unspendable, and a full 20-repeat study of one
dataset costs about a quarter of a CPU second (RQ1). How
simple? Random labelling ties active on 60% of datasets,
but where they differ active wins 2.4:1 - and that edge
lives in one bookkeeping detail: projection anchors must
be labels still in the pool (RQ2).

## Why active learning?

In many engineering problems the x values are cheap but the
y values are dear: running a benchmark, compiling a config,
polling a focus group, waiting weeks for a build to fail.
So the real question is not "how good is the model?" but
"how few labels buy a good answer?" Active learning attacks
this by letting the model-so-far choose which example to
label next, spending the budget where it expects to learn
the most.

The active method here is a landscape sampler in the
FASTMAP family: project the pool onto the line joining
the two most distant labelled rows *still in the pool*
(found via the x-distance `distx`), orient that line by
the labelled y values so one pole is "good", then cull
the third of the pool projecting nearest the bad pole -
labelled rows included, and a culled label stops
anchoring. Label a few more survivors, re-project, cull
again: the pool shrinks geometrically toward the good
region, and only labelled rows are ever scored. Random
sampling is the control.

## Method

**Data.** 129 CSV files from `../optimiz` (config spaces,
process models, HPO logs, misc tabular). Column names code
their role: leading uppercase = numeric; trailing `+`/`-` =
goal to maximize/minimize; trailing `X` = ignore. Cells
holding `?` are missing. Files larger than 1024 rows are
randomly sampled down (`--cap`).

**Task.** Multi-objective row selection: find rows near the
ideal point. A row's quality is `disty` - the p-norm (p=2)
distance from its normalized goal values to best
(0 = ideal, 1 = worst).

**Rig (`holdout`).** Per repeat: shuffle rows, split 50:50
into train and test. A labeller inspects at most
`--budget - --check` training rows. A regression tree
(min leaf 3, max depth 4) is fit to the labelled rows'
`disty`. The `--check = 5` test rows with the best predicted
leaves are "bought"; the rig returns the truly best of
those. Score = `wins`: percent of the gap to the dataset's
best row that the pick closes (100 = optimal, 0 = median,
clamped at +/-100).

**Comparisons.** Per dataset, 20 paired repeats per arm
(repeat k reseeds both arms with `seed + k`). Delta = 0 if
the two win-distributions are statistically
indistinguishable - Cohen (d <= 0.35) and Cliff's delta
(<= 0.195) and Kolmogorov-Smirnov (95%) must all agree -
else `mean(win(a)) - mean(win(b))`.

Everything is deterministic (own 16807 LCG) and reproduces
bit-identically on SBCL and CLISP. Rerun: `make holdouts`
(RQ0), `make budgets` (RQ1), `make deltas` (RQ2).

**Get the code and data.** One source file, one data repo:

    git clone https://github.com/aiez/tiny-xai
    git clone https://github.com/aiez/optimiz
    cd tiny-xai
    sbcl --script tiny-xai.lisp -h        # options, tests
    sbcl --script tiny-xai.lisp --all     # unit tests, ~0.1s
    sbcl --script tiny-xai.lisp --study   # the studies, ~1s

The data repo must sit beside `tiny-xai` (paths default to
`../optimiz/*.csv`); any CSV following the header
conventions above also works via `--file`.

## RQ0: how good are our optimizers?

Before comparing variants, check the rig finds anything at
all. `wins` calibrates each dataset: 100 = the pick equals
the best row in the data, 0 = no better than the median
row, negative = worse than median.

`mu(win)`, active labelling, budget 50, 20 repeats,
129 datasets (one `*` = 3 datasets):

```
[  0, 10)    1%  *
[ 10, 20)    1%  *
[ 20, 30)    0%
[ 30, 40)    4%  **
[ 40, 50)    5%  ***
[ 50, 60)    5%  **
[ 60, 70)   16%  *******
[ 70, 80)   12%  *****
[ 80, 90)   18%  ********
[ 90,100]   40%  *****************
```

Quartiles: min 4, q1 65, median 85, q3 96, max 100.

**Answer:** good. With only ~45 labels plus 5 checked test
rows, the median dataset closes 85% of the gap between its
median and best row; 40% of datasets close 90% or more.
No dataset scores below zero (never worse than guessing).
The stragglers (two datasets under 20) are rugged or noisy
landscapes worth separate study.

## RQ1: how fast? (budget and runtime)

Speed here has two currencies: labels spent (the dear
resource) and CPU spent (the cheap one).

### Labels

If labels did not matter, active learning would be a
solution looking for a problem.

`mu(win(budget=50)) - mu(win(budget=20))`, active labelling,
20 repeats, 129 datasets (one `*` = 3 datasets):

```
[-15,-10)    0%
[-10, -5)    0%
[ -5,  0)    2%  *
   ties=0   31%  **************
[  0,  5)   20%  *********
[  5, 10)   13%  ******
[ 10, 15)   15%  *******
[ 15, 20)   11%  *****
[ 20, 25)    8%  ****
[ 25, 30)    1%  *
```

Budget 50 beats budget 20 on 87/129 datasets (67%), by up
to +28 wins; it loses on 2 (worst -2.7). Labels buy real
performance - the problem is not trivial.

One caveat found while testing the other direction: budget
200 vs 50 ties on 129/129 datasets. The culling loop
(`keepf 0.66`, stop when pool < 2x leaf) self-terminates
after ~48 labels on a 1000-row pool, so budgets past ~50
are never spent. The interesting budget range for this
sampler is 10-50; beyond that, extra budget is unreachable
by construction.

### Runtime

Measured on one laptop core (SBCL): one holdout (label,
build tree, buy 5 test rows) costs ~10ms on a 1024-row
dataset. One full study cell - load a dataset, 20 repeated
holdouts - costs 0.3s on auto93, ~0.25 CPU-seconds
typical. The entire RQ2 sweep (129 datasets x 20 repeats
x 2 treatments) runs in under 2 minutes wall on 10 cores.
The only slow datasets are load-dominated: Scrum100k spends
~9s parsing 100k CSV rows before sampling its 1024.

**Answer:** in labels, budget matters strongly up to
~40-50, past which this sampler cannot spend more; in CPU,
the method is effectively free - milliseconds per
optimization, so runtime never limits the study design.

## RQ2: how simple? (compare with random)

`mu(win(active)) - mu(win(random))`, budget 50, 20 repeats,
129 datasets:

```
[-15,-10)    1%  *
[-10, -5)    5%  **
[ -5,  0)    6%  ***
   ties=0   60%  **************************
[  0,  5)   17%  ********
[  5, 10)    4%  **
[ 10, 15)    6%  ***
[ 15, 20)    0%
[ 20, 25)    1%  *
[ 25, 30)    0%
```

**Answer:** mostly, but the edge is real. Active and
random tie on 60% of datasets; the remainder splits 36
active to 15 random (2.4:1), with a longer active tail
(+21.7 vs -10.2). An earlier draft of this report found
a dead-even split (23-19, symmetric tails) and concluded
clever labelling buys nothing; see the aside below for
what changed. At this budget random remains a strong,
far simpler baseline - but the FASTMAP-style sampler now
wins where it matters and rarely loses big.

## Aside: which projection anchors?

A port ambiguity became an experiment - twice. ezr2
projects the pool onto poles chosen from labels *still in
the pool* (culled labels stop anchoring; labelled rows
stay in the pool and can themselves be culled); an
earlier lisp rewrite popped each labelled row *out* of
the pool and anchored on *all* labels, so a culled
bad-pole label kept orienting the line forever.

A first study toggled only the anchor list and found 73%
ties, so the code kept the simpler all-labels policy,
noting the divergence from ezr2. That was the wrong cut:
grading the DTLZ demo (`dtlz.lisp`, its `win` column)
then showed active barely beating random labelling on
smooth synthetic landscapes (dtlz2 mean win 64 vs 72).
Restoring the *full* ezr2 bookkeeping - labelled rows
stay in the pool, new labels come from the pool walk,
and only in-pool labels anchor - lifted dtlz2 to 76 and,
on the 129-csv corpus, flipped RQ2 from a dead heat
(23-19) to 36-15 in active's favor. The "2.4x active
edge" an earlier implementation reported, which two
rewrites then erased, was this bookkeeping all along.

Moral: in FASTMAP-style samplers the anchor list is not
a detail. Culled labels must stop steering, or the line
keeps pointing at regions the cull already rejected.

## Threats to validity

Single sampler (one FASTMAP-style method), single tree
learner, fixed knobs (leaf 3, depth 4, grow 4, keepf 0.66),
20 repeats, and the `same` gate is conservative (three
tests must all reject). Different budgets interact with the
cull schedule (see RQ1 caveat); results may differ for
samplers that can actually spend a larger budget.
