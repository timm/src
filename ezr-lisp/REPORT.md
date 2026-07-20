<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-Active%C2%B7Learning-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-127%C2%B7datasets-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-86%25%C2%B7gap%C2%B7closed%C2%B7with%C2%B750%C2%B7labels-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-~4.5%C2%B7CPU%C2%B7s%C2%B7per%C2%B7study-ff8c00?logo=speedtest&logoColor=white">

# How much labelling does landscape optimization need?

**tl;dr** How good? With ~50 labels the rig closes 86% of
the gap to the best row on the median dataset (RQ0). How
fast? 50 labels beat 20 on 75% of datasets (2 losses);
thanks to the redo loop bigger budgets are spendable, and
200 beats 50 on 44% of datasets (RQ1). How simple? Random
labelling ties active on 59% of datasets; where they
differ, active wins 41:11 (RQ2). Given 4x the labels,
random beats active@50 56:12 - active learning pays when
the label budget is a hard wall (RQ2b). These lisp numbers
agree, question for question, with the python reference
(`../ezr-py/REPORT.md`): RQ1b there 55:8, here 56:6; RQ2
there 43:8, here 41:11.

## The sampler

`sway3` (xai.lisp) is a landscape sampler in the
FASTMAP family: project the pool onto the line joining two
poles (initially the two most distant rows; on redo
passes, the best and worst labels seen so far), orient the
line by labelled y values so one pole is "good", keep only
the `keepf` fraction of the pool nearest the good pole -
labelled rows included, and a culled label stops
anchoring. The survivors stay sorted good-pole-first, so
each round's new labels come from the promising end
(exploit-first). When the pool hits its floor with budget
unspent, redo: restart on a fresh shuffle with labels
accumulating until the budget is gone. Random sampling is
the control.

## Method

Same rig as the python reference (`../ezr-py/REPORT.md`),
ported: 127 CSVs from `$MOOT/optimize/*/*.csv`, capped at
1024 rows; per repeat, shuffle and split 50:50; label at
most `--budget - --check` training rows; fit a regression
tree (leaf 3, depth 4) to the labels' `disty`; buy the
`--check = 5` best-leaf test rows; return the truly best.
Score = `wins`: percent of the median-to-best gap closed.
Per dataset, five arms (active@50, active@20, active@200,
random@50, random@200), 20 paired repeats each (repeat k
reseeds with `seed + k`); deltas are 0 unless Cohen AND
Cliff's delta AND Kolmogorov-Smirnov all call the two
win-distributions different.

Randomness is a hand-rolled 16807 Lehmer generator, so
runs reproduce on sbcl and clisp alike (but not
bit-identically vs python's Mersenne Twister; agreement
across languages is statistical).

**Rerun.**

    ls $MOOT/optimize/*/*.csv | xargs -P 10 -I{} \
      sbcl --script report.lisp {} > report.csv
    sbcl --script report.lisp --hist report.csv

One dataset (5 arms x 20 repeats) costs ~4.5 CPU seconds;
the sweep runs in a few minutes on 10 cores.

## RQ0: how good are our optimizers?

`mu(win)`, active labelling, budget 50, 20 repeats,
127 datasets (one `*` = 3 datasets):

```
[  0, 10)   0%
[ 10, 20)   0%
[ 20, 30)   4% **
[ 30, 40)   2% *
[ 40, 50)   6% **
[ 50, 60)   9% ****
[ 60, 70)  12% *****
[ 70, 80)   9% ****
[ 80, 90)  17% *******
[ 90,100]  43% ******************
```

Quartiles: min 22, q1 66, median 86, q3 97, max 100.

**Answer:** good. With ~45 labels plus 5 checked test
rows, the median dataset closes 86% of the gap between its
median and best row; 43% of datasets close 90% or more; no
dataset drops below +22 (the python floor was 2 - the lisp
rig never gets that lost). Stragglers under 30:
`Health-ClosedPRs0008` (22), `accessories` (25),
`Health-Commits0004` (26).

## RQ1: how fast?

`mu(win(budget=50)) - mu(win(budget=20))`, active, 20
repeats, 127 datasets:

```
[-15,-10)   0%
[-10, -5)   1%
[ -5,  0)   0%
   ties=0   24% **********
[  0,  5)  15% ******
[  5, 10)  23% **********
[ 10, 15)  19% ********
[ 15, 20)  10% ****
[ 20, 25)   6% ***
[ 25, 30]   0%
```

Budget 50 beats 20 on 95/127 datasets (75%), by up to
+35.0 (`Health-ClosedIssues0003`); it loses on 2 (worst
-15.3, `SQL_AllMeasurements`). Labels buy real
performance.

### More labels: budget 200

Earlier samplers could not spend past ~45 labels (the cull
schedule self-terminated); the redo loop removed that
wall. `mu(win(active@200)) - mu(win(active@50))`:

```
[-15,-10)   1%
[-10, -5)   2% *
[ -5,  0)   2% *
   ties=0   51% **********************
[  0,  5)  17% *******
[  5, 10)  14% ******
[ 10, 15)   7% ***
[ 15, 20)   3% *
[ 20, 25)   2% *
[ 25, 30]   0%
```

Budget 200 beats 50 on 56/127 (44%, max +30.0), loses on
6 (worst -10.6, `A2C_CartPole`). Half the corpus is
saturated at 50; the other half keeps paying.

## RQ2: how simple? (compare with random)

`mu(win(active)) - mu(win(random))`, budget 50:

```
[-15,-10)   1%
[-10, -5)   2% *
[ -5,  0)   5% **
   ties=0   59% *************************
[  0,  5)  17% *******
[  5, 10)   7% ***
[ 10, 15)   5% **
[ 15, 20)   3% *
[ 20, 25)   0%
[ 25, 30]   0%
```

**Answer:** mostly, but the edge is real: ties on 59%,
remainder splits 41 active to 11 random (3.7:1), winning
tail to +18.7, losing tail to -17.5 (`Health-Commits0004`).
Random is a strong, far simpler baseline; the sampler wins
where it matters.

## RQ2b: what if random gets a bigger budget?

`mu(win(active@50)) - mu(win(random@200))`:

```
[-20,-15)   3% *
[-15,-10)  10% ****
[-10, -5)  13% ******
[ -5,  0)  17% *******
   ties=0   46% ********************
[  0,  5)   6% ***
[  5, 10)   2% *
[ 10, 15)   1%
[ 15, 20)   0%
```

**Answer:** brute labels win: 56 random to 12 active
(ties 59), losses to -19.9 (`coc1000`), rare wins to +10.6
(`A2C_CartPole`). As in the python study: active learning
is a story about label COST - it earns its keep when the
budget is a hard wall (and RQ1's 200-arm shows the smarter
way to spend a loose budget).

## History

2026-07-12: ported the python reference's two algorithm
steps (exploit-first ordering; sway3 redo with best/worst
anchors), renamed --landscape to --acquire and --grow to
--more, and regenerated over $MOOT (127 files; previously
../optimiz, 129). Cross-language agreement with
`../ezr-py/REPORT.md` is close everywhere: RQ0 median 86 vs
87; RQ1b 56:6 vs 55:8; RQ2 41:11 vs 43:8; RQ2b 12:56 vs
10:46.

## Threats to validity

Single sampler, single tree learner, fixed knobs (leaf 3,
depth 4, more 4, keepf 0.66), 20 repeats, conservative
`same` gate. Lisp's 16807 LCG vs python's Mersenne Twister
means agreement across implementations is statistical, not
bit-identical; that the two reports land within a few
datasets of each other on every RQ is itself a useful
regression check.
