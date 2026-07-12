<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-Active%C2%B7Learning-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-127%C2%B7datasets-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-84%25%C2%B7gap%C2%B7closed%C2%B7with%C2%B750%C2%B7labels-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-~5%C2%B7CPU%C2%B7s%C2%B7per%C2%B7study-ff8c00?logo=speedtest&logoColor=white">

# How much labelling does landscape optimization need?

**tl;dr** How good? With ~50 labels the rig closes 84% of
the gap to the best row on the median dataset (RQ0). How
fast? 50 labels beat 20 on 65% of datasets and NEVER lose
to 20; budgets past ~50 are unspendable; a full 20-repeat,
4-arm study of one dataset costs about five CPU seconds
(RQ1). How simple? Random labelling ties active on 60% of
datasets, but where they differ active wins 2.4:1 - and
that edge depends on one bookkeeping detail: projection
anchors must be labels still in the pool (RQ2).

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
the labelled y values so one pole is "good", then keep
only the `keepf` fraction of the pool projecting nearest
the good pole - labelled rows included, and a culled label
stops anchoring. The surviving pool stays sorted
good-pole-first, so the next round's labels come from the
most promising end (exploit-first). Label a few more
survivors, re-project, cull again: the pool shrinks
geometrically toward the good region, and only labelled
rows are ever scored. Random sampling is the control.

## Method

**Data.** 127 CSV files from the moot repo
(`$MOOT/optimize/*/*.csv`: config spaces, process models,
HPO logs, misc tabular). Column names code their role:
leading uppercase = numeric; trailing `+`/`-` = goal to
maximize/minimize; trailing `X` = ignore. Cells holding `?`
are missing. Files larger than 1024 rows are randomly
sampled down (`--cap`).

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
clamped at +/-100). Note: this study sets `--maxd 4`
(the library default is 8) to match the tiny-xai rig.

**Comparisons.** Per dataset, 20 paired repeats per arm
(repeat k reseeds both arms with `seed + k`). Delta = 0 if
the two win-distributions are statistically
indistinguishable - Cohen (d <= 0.35) and Cliff's delta
(<= 0.195) and Kolmogorov-Smirnov (95%) must all agree -
else `mean(win(a)) - mean(win(b))`.

Everything is seeded (Python's Mersenne Twister via
`random.seed`), so runs reproduce exactly on one Python
version. Rerun: `python3 report.py` (writes per-dataset
results to `report.jsonl`, then prints the histograms
below).

**Get the code and data.** One curl for the code, one
clone for the data:

    REPO=https://raw.githubusercontent.com/timm/src/main/ezr2
    curl -fL $REPO/INSTALL.md | sh
    git clone https://github.com/timm/moot ~/gits/moot
    python3 ezr2-eg.py -h          # options, tests
    python3 ezr2-eg.py all         # unit tests, ~10s
    python3 report.py              # this study, ~2.5min

Data paths default to `$MOOT` (env var, else
`~/gits/moot`); any CSV following the header conventions
above also works via `--file`.

## RQ0: how good are our optimizers?

Before comparing variants, check the rig finds anything at
all. `wins` calibrates each dataset: 100 = the pick equals
the best row in the data, 0 = no better than the median
row, negative = worse than median.

`mu(win)`, active labelling, budget 50, 20 repeats,
127 datasets (one `*` = 3 datasets):

```
[  0, 10)   2% *
[ 10, 20)   0%
[ 20, 30)   2% *
[ 30, 40)   1%
[ 40, 50)   6% **
[ 50, 60)   6% ***
[ 60, 70)  17% *******
[ 70, 80)  13% ******
[ 80, 90)  16% *******
[ 90,100]  39% ****************
```

Quartiles: min 2, q1 64, median 84, q3 95, max 100.

**Answer:** good. With only ~45 labels plus 5 checked test
rows, the median dataset closes 84% of the gap between its
median and best row; 39% of datasets close 90% or more.
No dataset scores below zero (never worse than guessing).
The stragglers (two datasets under 20:
`Health-ClosedPRs0008` at 2, `accessories` at 9) are
rugged or noisy landscapes worth separate study.

## RQ1: how fast? (budget and runtime)

Speed here has two currencies: labels spent (the dear
resource) and CPU spent (the cheap one).

### Labels

If labels did not matter, active learning would be a
solution looking for a problem.

`mu(win(budget=50)) - mu(win(budget=20))`, active labelling,
20 repeats, 127 datasets (one `*` = 3 datasets):

```
[-15,-10)   0%
[-10, -5)   0%
[ -5,  0)   0%
   ties=0   35% ***************
[  0,  5)  12% *****
[  5, 10)  20% ********
[ 10, 15)  23% **********
[ 15, 20)   6% **
[ 20, 25)   2% *
[ 25, 30]   2% *
```

Budget 50 beats budget 20 on 82/127 datasets (65%), by up
to +27.2 wins (`Health-ClosedIssues0003`) - and loses on
NONE. Labels buy real performance, and under the
exploit-first sampler the extra budget never backfires.

One caveat found while testing the other direction: budget
200 vs 50 ties on 127/127 datasets. The culling loop
(`keepf 0.66`, stop when pool < 2x leaf) self-terminates
after ~48 labels on a 1000-row pool, so budgets past ~50
are never spent. The interesting budget range for this
sampler is 10-50; beyond that, extra budget is unreachable
by construction.

### Runtime

Measured on one laptop (CPython 3.13): one full study cell
- load a dataset, 4 arms x 20 repeated holdouts - costs
5.1s mean; the whole sweep (127 datasets x 80 holdouts)
runs in ~2.5 minutes wall on 10 cores. The slow tail is
distance-dominated, not load-dominated: the wide binary
`FFM/FM` SAT configuration spaces (hundreds of x columns)
cost up to 83s per cell.

**Answer:** in labels, budget matters strongly up to
~40-50, past which this sampler cannot spend more; in CPU,
the method is cheap - tens of milliseconds per
optimization, so runtime never limits the study design.

## RQ2: how simple? (compare with random)

`mu(win(active)) - mu(win(random))`, budget 50, 20 repeats,
127 datasets:

```
[-15,-10)   4% **
[-10, -5)   2% *
[ -5,  0)   5% **
   ties=0   60% *************************
[  0,  5)  20% ********
[  5, 10)   6% ***
[ 10, 15)   2% *
[ 15, 20)   0%
[ 20, 25)   0%
[ 25, 30]   0%
```

**Answer:** mostly, but the edge is real. Active and
random tie on 60% of datasets; the remainder splits 36
active to 15 random (2.4:1). The winning tail runs to
+14.5 (`Marketing_Analytics`, mean +4.6); the losing tail
is thinner in count but heavier per loss (mean -7.4, worst
`Health-ClosedPRs0007` at -15.6). At this budget random
remains a strong, far simpler baseline - but the
FASTMAP-style sampler wins where it matters and rarely
loses.

## Aside: which projection anchors?

This code is the reference for that bookkeeping. In
`acquire` (acquire.py) labelled rows stay in the pool, new
labels come from the pool walk, and only in-pool labels
anchor the projection - so a culled label stops steering.
A Common Lisp port of this code (`../tiny-xai`) twice
lost that detail by anchoring on *all* labels ever
picked, and each time the active-vs-random edge quietly
collapsed to a dead heat (23-19 there, vs 36-15 once
restored). Moral: in FASTMAP-style samplers the anchor
list is not a detail. Culled labels must stop steering,
or the line keeps pointing at regions the cull already
rejected. (A pinned regression test guarding this seam
would be cheap insurance; see `test_acquire`.)

## History

2026-07-12: regenerated after two changes. (1) The corpus
moved from `../optimiz` (129 files) to the moot repo (127
files). (2) The sampler now keeps the surviving pool
sorted good-pole-first, so each round's new labels come
from the promising end (exploit-first; previously the pool
sat bad-pole-first and new labels came from the bad
frontier). Effects vs the prior report: RQ0 unchanged
(median 84); RQ1 strengthened (was 5 losses vs budget 20,
now none); RQ2 edge narrowed (3.9:1 over 58% ties, now
2.4:1 over 60% ties). Better rows for fewer labels, at
the cost of a slimmer margin over random through the tree
pipeline.

## Threats to validity

Single sampler (one FASTMAP-style method), single tree
learner, fixed knobs (leaf 3, depth 4, grow 4, keepf 0.66),
20 repeats, and the `same` gate is conservative (three
tests must all reject). Different budgets interact with the
cull schedule (see RQ1 caveat); results may differ for
samplers that can actually spend a larger budget. Numbers
here come from Python's Mersenne Twister; the lisp port
uses its own 16807 LCG, so cross-implementation agreement
is statistical, not bit-identical.
