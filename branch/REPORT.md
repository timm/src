<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-Model%C2%B7Multiplicity-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-6%C2%B7fairness%C2%B7datasets-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-fairness%C2%B7for%C2%B7free-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-%3C3%C2%B7CPU%C2%B7s%C2%B7per%C2%B7dataset-ff8c00?logo=speedtest&logoColor=white">

# One tree is many models: prunings, sweeps, and fairness for free

**tl;dr** One classification tree, pruned every possible
way, is a free model zoo: 416-676 trees and 3,000-6,000
ROC operating points per dataset in under 3 CPU seconds
(RQ1). That zoo reaches operating points a single tree
never offers: 7-25 significance cells vs 1 (RQ2). But the
elaborate methods discover no new territory -- every cell
the simpler methods reach lies inside the forest+sweep
footprint, on all six datasets; more machinery just
samples the same shape at finer grain (RQ3). The surprise
is fairness: models inside ONE cell (statistically
identical pf, pd at the 0.35-sd level) differ in group
unfairness by up to 0.31 on a 0-0.4 scale -- red and green
share cells, so picking the fairest model in a cell costs
no measurable performance (RQ4). A three-goal d2h over
(pf, 1-pd, unfairness) auto-picks a fair knee model, and
the zoo lands 30-45% closer to heaven than the lone tree
(RQ5). Small pruned trees do all this; growing bigger
trees (cf. sandbox/ezr2.py) buys size, not reach (RQ6).
And small means SMALL: over 20 repeats per dataset, the
lowest-d2h winner uses a median of 4 variables (37% use
at most 3, 85% at most 5, never more than 8 -- of up to
24 on offer) (RQ7).

## Why

Labels are dear, trees are cheap (see README.md). branch's
`walk` yields every pruning of one tree -- up to 4 shapes
per cut, all sharing structure, scored lazily. Here we
point that machinery at classification and ask what a
forest of prunings buys: coverage of ROC space, and (on
datasets with protected attributes) a view of the
accuracy-fairness trade.

## Method

**Data.** Six `$MOOT/classify` datasets with protected
columns: COMPAS53 (sex, race), german (sex, age), credit.g
(personal_status, foreign_worker, age), heart.statlog
(sex, age), heart.c (sex, age), diabetes (age). COMPAS53
keeps only pre-trial columns (charge, priors, juvenile
counts, demographics); post-hoc leak columns are X'd out.
Rows capped at 2048; positive class = minority class.

**Models.** One 50:50 split. One classification tree
(branch's `Tree`, accum=Sym, Y=klass, maxd 4) on the train
half. Four method rungs, simple to elaborate:

    one tree        the full tree, leaf-mode prediction
    one tree+sweep  same tree; predict pos iff leaf's
                    pos-fraction >= theta, theta swept
                    over the distinct leaf fractions
    forest          every walk() pruning, mode prediction
    forest+sweep    every pruning x its theta sweep

Each (model, theta) is one (pf, pd) point on the test
half.

**Unfairness.** Worst per-group error gap: max over
protected cols c of max(|pd_priv - pd_rest|,
|pf_priv - pf_rest|), privileged = column mode (symbolic)
or >= median (numeric). Same 0-0.4 scale everywhere.

**Significance grid.** Per dataset, from the forest+sweep
cloud: cell = 0.35*sd(pf) x 0.35*sd(pd) -- Cohen's
small-effect eps, the same 0.35 that `cohen()` in
branch-eg.py uses. Two points in one cell are "the same".

**Selection (RQ5).** d2h = sqrt((pf^2 + (1-pd)^2 +
gap^2)/3): distance to heaven (pf 0, pd 1, gap 0); each
rung's pick is its min-d2h point.

Everything is seeded (seed 1). The study scripts (fair4.py
draws the figure below; fair5stats.py, fewvars.py and
fewvars2.py print the tables) are session prototypes, not
in this dir; this report
is hand-written from their output, per ../etc/style.md.

## The picture

![4x6 grid: four method rungs x six datasets, pd vs pf,
gray = reachable cells, color = unfairness, arrow = d2h
pick](fair4.png)

One figure carries the whole study. Columns are datasets;
rows descend the method ladder, forest+sweep down to one
tree, so reading DOWN a column watches resolution drain
away: a dense cloud thins to a curve, then to clusters,
then to a single dot -- while the gray footprint (cells
some model reaches, at the 0.35-sd grid the faint lines
mark) shrinks inside the top row's, never outside it
(RQ3). Color is worst-group unfairness, and the trouble is
visible before any table: german's tight 0.5-pd cluster
holds deep red beside green at the same (pf, pd), and
heart.statlog's cloud is red-flecked throughout -- the
within-cell spreads of RQ4. The blue arrow drops from
heaven (pf 0, pd 1) to each rung's min-d2h pick, labelled
with its d2h; arrows visibly lengthen down the german and
credit.g columns (0.27 to 0.48, 0.30 to 0.41) and the pick
visibly sidesteps red clusters -- RQ5 at a glance. What
the picture cannot show is price, which is the point:
every panel above the bottom row cost essentially nothing
beyond its bottom-row fit (RQ1).

## RQ1: how fast is many-models?

    dataset        trees  points  secs
    COMPAS53         416   2,948   2.3
    german           676   5,812   2.1
    credit.g         676   5,872   2.9
    heart.statlog    416   2,708   0.3
    heart.c          676   5,270   0.6
    diabetes         676   5,864   1.1

**Answer:** surprisingly fast. Prunings share structure
(no refitting; `walk` re-scores sunk leaf statistics), and
the theta sweep reuses each pruning's leaf fractions.
Hundreds of trees, thousands of operating points,
single-digit seconds, one core. Model multiplicity is not
an expense here; it is a by-product.

## RQ2: do many models reach points one tree cannot?

Significance cells covered (grid from forest+sweep):

    dataset        f+sweep  forest  1+sweep  1
    COMPAS53             7       3        6  1
    german              12       2        7  1
    credit.g            13       4        8  1
    heart.statlog       25       5        5  1
    heart.c             20       8        7  1
    diabetes            18       8        8  1

**Answer:** yes. A single tree is one point; its theta
sweep already buys 5-8 cells (most of the frontier); the
pruning forest grows that to 7-25. The two ladders differ:
sweeping theta moves ALONG the ROC frontier, pruning moves
the frontier (new split structure = new reachable
trade-offs). heart.statlog is the extreme: forest+sweep
holds 25 cells, 5x the swept single tree.

## RQ3: new territory, or the same shape, finer?

Fraction of each simpler method's cells inside the
forest+sweep footprint: **100%, every method, every
dataset.**

**Answer:** the same shape. Elaboration never contradicts
the simple methods -- it interpolates and extends the
curve they sketch. It is as if each dataset has one
reachable (pf, pd) shape and the rungs differ only in
sampling grain: one dot, a coarse curve, a dense cloud.
Practical reading: if a swept single tree's cell already
sits where you want to operate, the forest buys nothing
but resolution.

## RQ4: does performance pin down fairness?

Within-cell unfairness spread (max - min over models
sharing a cell, forest+sweep):

    dataset        median  max
    COMPAS53         0.01  0.07
    german           0.08  0.27
    credit.g         0.05  0.24
    heart.statlog    0.05  0.23
    heart.c          0.07  0.31
    diabetes         0.06  0.12

**Answer:** no -- and this is the headline. Models
statistically indistinguishable on (pf, pd) differ in
worst-group gap by up to 0.31 of the 0.4 scale (heart.c);
german's dense 0.5-pd cluster mixes deep red (0.35+) with
green (<0.1) at the same accuracy. Two consequences.
First, fairness for free: within any target cell, choose
the fairest member -- no measurable performance cost, no
fairness-aware learner needed, just generate-and-pick from
the free zoo of RQ1. Second, fragility: one pruning or a
small theta nudge can flip a fair model unfair, so
reporting one tree's fairness number without its
neighborhood is close to meaningless. (COMPAS is the
caution: its within-cell spread collapsed to ~0.01-0.07
only after X-ing the leak columns; with leaks the study
told a rosier story.)

## RQ5: can one number pick the deployment model?

Min d2h(pf, 1-pd, unfairness) per rung:

    dataset          1   1+swp  forest  f+swp
    COMPAS53       0.31   0.31    0.31   0.31
    german         0.48   0.27    0.48   0.27
    credit.g       0.41   0.31    0.40   0.30
    heart.statlog  0.29   0.27    0.22   0.20
    heart.c        0.18   0.18    0.18   0.18
    diabetes       0.38   0.26    0.26   0.26

**Answer:** yes. d2h picks a knee model -- never the
max-pd corner (its pf and unfairness cost too much), and
never the red clusters (german's pick skips the unfair
0.5-pd cluster for the fair 0.8-pd one). The zoo pays:
forest+sweep lands 0.18-0.31 from heaven vs 0.18-0.48 for
the lone tree -- 30-45% closer on german, credit.g,
diabetes -- from the same single fit. And again the sweep
does most of the work: one tree+sweep nearly matches
forest+sweep everywhere; mode-only forests can be poor
(german 0.48). Caveat: the gap term enters raw (in
practice <= ~0.4) beside full-range pf and 1-pd, so
unfairness pulls de-facto lighter; rescaling it is a
one-line change and untested.

## RQ6: do bigger trees help?

A parallel line of work (sandbox/ezr2.py) grows much
larger trees on these tasks. Observation, not yet a
measured comparison: those trees are unnecessarily large.
The maxd-4 tree here, pruned and swept, already covers the
reachable (pf, pd) shape (RQ2, RQ3) and reaches the same
knees (RQ5) at ~no CPU cost beyond the one fit (RQ1).
Depth buys leaf purity on train; it does not buy new test
operating points that the pruning zoo lacks.

**Answer** (provisional): no. Prefer one small tree plus
its free zoo over one big tree. Making this a real RQ
needs ezr2 run under this rig -- same splits, same grid --
and a cells-covered / d2h table beside it.

## RQ7: how many variables do these problems really need?

Distinct split attributes: in the full maxd-4 tree, and in
the smallest pruning matching its score (same rig; the SE
optimize sets are binary-ized best-10%-by-d2h, so their
klass encodes a multi-objective target):

    dataset                 x cols  full  best pruning
    COMPAS53                    11     8     3
    german                      20    11     4
    credit.g                    20     8     4
    heart.statlog               12     8     3
    heart.c                     13    11     3
    diabetes                     8     6     3
    Apache_AllMeasurements       9     8     1
    SS-N                        17     8     2
    xomo_flight                 24     8     2
    Health-Commits0000           5     5     1
    auto93                       4     3     1

How often the zoo builds a k-variable tree (% of all
prunings using k distinct split attributes; "." = 0%):

    k =                 1  2  3  4  5  6  7  8  9 10 11
    COMPAS53            .  2  5 14 21 29 23  6
    german              .  .  1  2  6 12 19 24 22 11  2
    credit.g            .  .  1  3  8 20 45 24
    heart.statlog       .  1  2  7 17 29 30 13
    heart.c             .  .  1  3  5 12 21 25 21 10  2
    diabetes            .  1  9 23 41 26
    Apache              .  .  1  9 18 30 28 12
    SS-N                .  1  4 10 20 35 25  6
    xomo_flight         .  1  5 15 26 29 19  5
    Health-Commits0000  .  1  9 27 63
    auto93              1 40 59

The zoo's bulk sits at 5-7 variables, so few-variable
trees are the tail, not the norm. But selection lives in
that tail. Repeating the whole rig 20 times per dataset
(fresh shuffle and split each time) and keeping only each
run's WINNER -- the pruning-x-theta with lowest d2h --
gives (count of winners using k variables):

    dataset             k of the 20 d2h winners
    COMPAS53            2:6  3:7  4:5  5:2
    german              3:2  4:9  5:5  7:2  8:2
    credit.g            1:2  2:1  3:3  4:7  5:3  6:1  7:3
    heart.statlog       3:3  4:3  5:6  6:5  7:2  8:1
    heart.c             3:1  4:1  5:11 6:2  7:4  8:1
    diabetes            1:5  2:3  3:6  4:3  5:3
    Apache              2:5  3:3  4:8  5:4
    SS-N                3:1  4:7  5:4  6:5  7:3
    xomo_flight         2:1  3:3  4:7  5:6  6:3
    Health-Commits0000  1:2  2:1  3:7  4:8  5:2
    auto93              1:9  2:7  3:4

Winner tree TYPES, coded as each attribute's split count,
sorted and joined (so "1111" = four variables split once
each; "112" = three variables, one split twice; "3" = one
variable split three times). `sort | uniq -c | sort -n`
over the 220 winners:

      2  1222 1113 123 11111111 11222 111222   (each)
      3  111111 111122 1123                    (each)
      5  1111112
      6  1122 122 1111111                      (each)
      7  11122 111112                          (each)
     10  12
     11  11
     13  112
     14  111 11111                             (each)
     16  1 1112                                (each)
     20  11112
     27  1111
    + 16 types seen once (113, 13, 3, 1234, ...)

**Answer:** very few. Over all 220 winner-trees: 37% use
at most 3 variables, 64% at most 4, 85% at most 5; the
median winner uses 4. The modal type is `1111`, and the
all-ones family (`1`, `11`, ..., `11111111`: every chosen
variable split exactly once) covers 42% of winners;
splitting any single attribute three or more times happens
in ~6%. So the surviving trees are frugal twice over: few
variables, and each variable interrogated once. On auto93, diabetes, COMPAS and
Health-Commits, 3-or-fewer wins half the time or more. No
winner ever needed more than 8 of the available columns
(german and heart.c offer 20 and 13; xomo_flight offers
24 and its winners want 2-6). The full tree touches most
columns -- greedy splitting spends depth somewhere -- but
what survives selection is small: seemingly complex MOO
landscapes collapse to a handful of load-bearing
variables once you ask only "reach the best leaf", not
"explain every row". This is the same story at a different altitude: RQ3 said
the model SPACE is a small shape finely sampled; RQ7 says
each model in it is small too. It also explains RQ1's
speed -- trees this shallow over this few variables cost
nothing to enumerate -- and it is the practical case for
fft-style tools: a 2-3 variable tree is auditable by
reading it aloud.

## Discussion: why doesn't this explode?

Rashomon-set enumerators (TreeFARMS and kin) blow up on
exactly these small datasets: they search the space of ALL
sparse trees within epsilon of optimal, so they must
construct and certify trees that share nothing, and the
count of near-optimal trees grows combinatorially with
features and depth. This fft*-style walk runs in seconds
-- faster even than building one fast-and-frugal tree per
variant -- because it never searches. It fits ONE greedy
tree, then enumerates its prunings: at each of the ~15
internal cuts, each side either stays or collapses, so the
candidate count is bounded by shapes-per-cut ^ cuts, all
variants share subtrees and sunk leaf statistics, `walk`
is a lazy generator, and each emitted tree costs one
re-route of the test rows. The price is coverage: we
sample only the Rashomon subset reachable by pruning one
tree, with no optimality certificate. RQ3 is the empirical
defense that this subset is enough here -- the simpler
rungs' cells all sit inside the pruning zoo's footprint,
and the zoo's d2h knees (RQ5) are as good as anything the
bigger machinery found. Open question: on what data does
the prune-one-tree Rashomon sample MISS cells that true
enumeration finds?

## Threats to validity

RQ1-RQ5 use one seed, one 50:50 split per dataset --
those spreads are existence proofs, not distributions
(fix: repeat as RQ7 does; only RQ7's winner counts run
20 repeats). The grid comes from the forest+sweep
cloud's own sd, so RQ2/RQ3 cell counts depend on that
choice; stats use dot centers, the plot grays cells
touched by marker discs, so plot and table can disagree at
boundaries. Privileged = mode / >= median is a heuristic;
real protected-group definitions are legal, not
statistical. Six datasets, all small, all binary-ized to
minority-vs-rest; maxd 4 caps the zoo. RQ6 is an
observation awaiting numbers.
