<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-Active%C2%B7Learning-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-127%C2%B7datasets-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-87%25%C2%B7gap%C2%B7closed%C2%B7with%C2%B750%C2%B7labels-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-~18%C2%B7CPU%C2%B7s%C2%B7per%C2%B7study-ff8c00?logo=speedtest&logoColor=white">

# How much labelling does landscape optimization need?

**tl;dr** How good? With ~50 labels the rig closes 87% of
the gap to the best row on the median dataset (RQ0). How
fast? 50 labels beat 20 on 72% of datasets and NEVER lose
to 20; thanks to the redo loop bigger budgets are now
spendable, and 200 beats 50 on 43% of datasets (RQ1). How
simple? Random labelling ties active on 60% of datasets,
but where they differ active wins 5.4:1 - and that edge
depends on one bookkeeping detail: projection anchors must
be labels still in the pool (RQ2). Given 4x the labels,
though, random beats active@50 46:10 - active learning
pays when the label budget is a hard wall (RQ2b).

## Why active learning?

In many engineering problems the x values are cheap but the
y values are dear: running a benchmark, compiling a config,
polling a focus group, waiting weeks for a build to fail.
So the real question is not "how good is the model?" but
"how few labels buy a good answer?" Active learning attacks
this by letting the model-so-far choose which example to
label next, spending the budget where it expects to learn
the most.

The active method here (`sway3`) is a landscape sampler in
the FASTMAP family: project the pool onto the line joining
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
rows are ever scored. When the pool hits its floor with
budget unspent, the sampler REDOES: it restarts on a fresh
shuffle of all rows, anchoring every later projection at
the best and worst labelled rows seen so far; labels
accumulate across passes until the budget is gone. Random
sampling is the control.

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
(the library default is 8) to match the ezr-lisp rig.

**Comparisons.** Per dataset, 20 paired repeats per arm
(repeat k reseeds both arms with `seed + k`) of five
arms -- active@50, active@20, active@200, random@50,
random@200. Delta = 0 if the two win-distributions are
statistically indistinguishable - Cohen (d <= 0.35) and
Cliff's delta (<= 0.195) and Kolmogorov-Smirnov (95%) must
all agree - else `mean(win(a)) - mean(win(b))`.

Everything is seeded (Python's Mersenne Twister via
`random.seed`), so runs reproduce exactly on one Python
version. Rerun: `python3 report.py` (writes per-dataset
results to `report.jsonl`, then prints the histograms
below).

**Get the code and data.** One curl for the code, one
clone for the data:

    REPO=https://raw.githubusercontent.com/timm/src/main/xai
    curl -fL $REPO/INSTALL.md | sh
    git clone https://github.com/timm/moot ~/gits/moot
    python3 xai-eg.py -h          # options, tests
    python3 xai-eg.py all         # unit tests, ~10s
    python3 report.py              # this study, ~8min

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
[ 20, 30)   1%
[ 30, 40)   1%
[ 40, 50)   5% **
[ 50, 60)   8% ***
[ 60, 70)  17% *******
[ 70, 80)   9% ****
[ 80, 90)  16% *******
[ 90,100]  43% ******************
```

Quartiles: min 2, q1 67, median 87, q3 97, max 100.

**Answer:** good. With only ~45 labels plus 5 checked test
rows, the median dataset closes 87% of the gap between its
median and best row; 43% of datasets close 90% or more.
No dataset scores below zero (never worse than guessing).
The stragglers (two datasets under 20:
`Health-ClosedPRs0008` at 2, `accessories` at 8) are
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
   ties=0   28% ************
[  0,  5)  10% ****
[  5, 10)  21% *********
[ 10, 15)  20% ********
[ 15, 20)  13% ******
[ 20, 25)   6% **
[ 25, 30]   2% *
```

Budget 50 beats budget 20 on 92/127 datasets (72%), by up
to +25.6 wins (`Health-Commits0003`) - and loses on NONE.
Labels buy real performance, and the extra budget never
backfires.

### More labels: budget 200

Earlier versions of this sampler could not spend past ~45
labels: the cull schedule (`keepf 0.66`, stop when pool <
2x leaf) self-terminated first, so 200 vs 50 tied on every
dataset by construction. The redo loop removed that wall.
`mu(win(active@200)) - mu(win(active@50))`, 20 repeats,
127 datasets:

```
[-15,-10)   1%
[-10, -5)   2% *
[ -5,  0)   4% **
   ties=0   50% *********************
[  0,  5)  16% *******
[  5, 10)  17% *******
[ 10, 15)   7% ***
[ 20, 25)   2% *
[ 25, 30]   1%
```

Budget 200 beats 50 on 55/127 datasets (43%, mean +8.2,
best +34.6 on `Health-ClosedPRs0010`), loses on 8 (mean
-4.6). Bigger budgets are now genuinely spendable - and
half the corpus is already saturated at 50.

### Runtime

Measured on one laptop (CPython 3.13): one full study cell
- load a dataset, 5 arms x 20 repeated holdouts - costs
17.7s mean; the whole sweep (127 datasets x 100 holdouts)
runs in ~8 minutes wall on 10 cores. The slow tail is
distance-dominated, not load-dominated: the wide binary
`FFM/FM` SAT configuration spaces (hundreds of x columns)
dominate the tail.

**Answer:** in labels, budget matters strongly up to ~50
and (post-redo) keeps paying on 43% of datasets up to 200;
in CPU the method is cheap - fractions of a second per
optimization, so runtime never limits the study design.

## RQ2: how simple? (compare with random)

`mu(win(active)) - mu(win(random))`, budget 50, 20 repeats,
127 datasets:

```
[-15,-10)   1%
[-10, -5)   1%
[ -5,  0)   5% **
   ties=0   60% *************************
[  0,  5)  19% ********
[  5, 10)   9% ****
[ 10, 15)   4% **
[ 15, 20)   2% *
[ 20, 25)   0%
[ 25, 30]   0%
```

**Answer:** mostly, but the edge is real and grew with the
redo. Active and random tie on 60% of datasets; the
remainder splits 43 active to 8 random (5.4:1). The
winning tail runs to +18.8 (`Health-Commits0002`, mean
+5.3); the losing tail is thin (mean -5.0, worst `pom3d`
at -14.9). At this budget random remains a strong, far
simpler baseline - but the FASTMAP-style sampler wins
where it matters and rarely loses.

## RQ2b: what if random gets a bigger budget?

RQ2 compared equals: 50 labels each. The harder street
fight: smart-and-few vs dumb-and-many.
`mu(win(active@50)) - mu(win(random@200))`, 20 repeats,
127 datasets:

```
[-30,-25)   1%
[-25,-20)   1%
[-20,-15)   3% *
[-15,-10)   9% ****
[-10, -5)  10% ****
[ -5,  0)  12% *****
   ties=0   56% ************************
[  0,  5)   6% **
[  5, 10)   1%
[ 10, 15)   1%
[ 25, 30]   1%
```

**Answer:** brute labels still win, though less than they
used to. Given 4x the budget, random beats active@50 on 46
datasets to 10 (ties 71); losses average -8.2 and run to
-27.1 (`Health-ClosedPRs0006`); the rare wins (mean +6.9,
best +30.0 on `Medical_Data_and_Hospital_Readmissions`)
mark landscapes where smart labelling survives any budget.
So active learning here is a story about label COST: if a
label costs the same at n=200 as at n=50, buy more labels
(or better: spend them actively - see RQ1's 200-arm);
active@50 earns its keep when the budget is a hard wall.

## Aside: which projection anchors?

This code is the reference for that bookkeeping. In
`sway3` (xai.py) labelled rows stay in the pool, new
labels come from the pool walk, and only in-pool labels
anchor the projection - so a culled label stops steering
(until a redo pass deliberately re-anchors at the best and
worst labels so far). A Common Lisp port of this code
(`../ezr-lisp`) twice lost that detail by anchoring on
*all* labels ever picked, and each time the
active-vs-random edge quietly collapsed to a dead heat
(23-19 there, vs 36-15 once restored). Moral: in
FASTMAP-style samplers the anchor list is not a detail.
Culled labels must stop steering, or the line keeps
pointing at regions the cull already rejected. (A pinned
regression test guarding this seam would be cheap
insurance; see `test_acquire`.)

## History

2026-07-12 (b): sway3 gains the redo loop: when the cull
schedule exhausts the pool with budget unspent, restart on
a fresh shuffle, anchoring projections at the best and
worst labels so far; labels accumulate until the budget is
spent. Effects vs (a): RQ0 median 84 -> 87; RQ1 wins
89 -> 92 (still no losses); budgets past 50 became
spendable, killing the old "unspendable" caveat (now 55
wins for 200 vs 50); RQ2 active:random 36:15 -> 43:8;
RQ2b random@200's rout softened 62:10 -> 46:10.

2026-07-12 (a): regenerated after the corpus moved from
`../optimiz` (129 files) to the moot repo (127 files), and
the sampler switched to exploit-first ordering (surviving
pool sorted good-pole-first; previously bad-frontier
first). RQ0 median 84 unchanged; RQ1 losses 5 -> 0; RQ2
edge narrowed 3.9:1 -> 2.4:1.

## Threats to validity

Single sampler (one FASTMAP-style method), single tree
learner, fixed knobs (leaf 3, depth 4, more 4, keepf 0.66),
20 repeats, and the `same` gate is conservative (three
tests must all reject). Numbers here come from Python's
Mersenne Twister; the lisp port uses its own 16807 LCG, so
cross-implementation agreement is statistical, not
bit-identical.
