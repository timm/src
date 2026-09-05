{% raw %}
# shortr2 vs NSGA-II vs SMAC-style vs ASP

Ran overnight 2026-08-30/31 on the eight SHORT models + small.
Every rival consumes the SAME models (loaded from models/*.py) and,
where it needs an evaluator, the SAME python engine (infer.py).
Scripts: softgoals/rivals_asp.py, rivals_nsga2.py, rivals_optuna.py
(in this directory; shortr1_table.py drives the SHORT repo).

Versions: clingo 5.8.2 (brew), pymoo 0.6.2, optuna 4.9.0, smac
2.4.0.  SMAC3 refused the brew python (pynisher build) but runs in
a dedicated venv (~/tmp/smacenv: fresh setuptools +
scikit-learn==1.6.1 pin -- SMAC imports symbols sklearn 1.7
removed).  Optuna TPE numbers are kept alongside: same paradigm
(model-based, single incumbent), cheaper surrogate.

## The common language

Every method answers five questions:

1. CANDIDATE  what is one solution?
2. GENERATE   how is the next candidate produced?
3. JUDGE      objectives and constraints; what dies, what scores?
4. GUARANTEE  what does the final answer promise?
5. EXPLAIN    what lands on the stakeholder's desk, and how small?

|           | shortr2            | NSGA-II          | Optuna/SMAC       | ASP (clingo) |
|-----------|--------------------|------------------|-------------------|--------------|
| candidate | partial labelling  | leaf bit-vector  | leaf configuration| stable model |
| generate  | forward random walk (42us) | population + crossover | surrogate suggests next | CDCL, complete |
| judge     | demands kill; d2h  | Pareto dominance | one scalar (d2h)  | hard rules native; #minimize exact |
| guarantee | statistical (n=1000 + replay variance) | none | none | PROOF of optimum / UNSAT |
| explain   | 1-12 keys, ddmin-minimal, replay-tested | front of full vectors | one full config | one full model |

## Results

shortr2 reference (rig6, seed 1): best sampled worlds, raw
benefit/cost --

    Counselling  25/27 @ 40 leaves   CnslMgmt  19/19 @ 38
    FDandMkting  17/18 @ 43          ITDept    15/15 @ 10
    SAProgram    10/11 @ 2           Services  14/16 @ 22
    Kids         3/3   @ 15          Modernize 4/4   @ 2
    whole-corpus pipeline: ~0.4s

ASP certified lexicographic optima (max benefit @2, min cost @1;
hard goals demoted to priority 3 so infeasible hards are COUNTED,
not fatal):

    model         status   hard    benefit  cost    ms
    Counselling   OPTIMUM  28/29   23/27    16/74   12
    CnslMgmt      OPTIMUM  33/36   17/19    18/53    9
    FDandMkting   OPTIMUM  32/32   18/18    16/83   14
    ITDepartment  OPTIMUM  18/23   11/15     6/22    7
    SAProgram     OPTIMUM   6/6    11/11     1/5     6
    Services      OPTIMUM  23/23   14/16    11/55   10
    KidsandYouth  OPTIMUM   5/5     2/3      2/25    6
    Modernize     OPTIMUM   1/1     4/4     10/26    5
    small         OPTIMUM   2/2     1/3      1/3     5

Optuna TPE (500 trials x 3 worlds, leaves as t/f categoricals,
objective = mean d2h of replayed worlds):

    model         lo(b4)  mu(b4)   incumbent  worlds  ms
    Counselling   6       56 (16)  200*       1500    18415
    CnslMgmt      0       43 (20)  200*       1500     9226
    FDandMkting   7       50 (13)  12         1500    17175
    ITDepartment  0       58 (23)  12         1500     4130
    SAProgram     8       47 (16)  5          1500     1151
    Services      10      49 (12)  7          1500    11857
    KidsandYouth  35      70 (18)  35         1500     3852
    Modernize     0       37 (28)  0          1500     4013
    small         35      52 (11)  38         1500      493
    * 200 = the dead-world sentinel: EVERY one of 1500 worlds died.

SMAC3 (HyperparameterOptimizationFacade = random-forest surrogate,
500 trials x 3 worlds, same space and objective as Optuna):

    model         lo(b4)  mu(b4)   incumbent  worlds  ms
    Counselling   6       56 (16)  35         1500    413587
    CnslMgmt      0       43 (20)  200*       1500    376757
    FDandMkting   7       50 (13)  18         1500    406156
    ITDepartment  0       58 (23)  27         1500    262092
    SAProgram     -       -        ERR        -       -
    Services      10      49 (12)  20         1500    338977
    KidsandYouth  35      70 (18)  79         1500    275479
    Modernize     0       37 (28)  6          1500    281287
    small         -       -        ERR        -       -
    * dead-world sentinel.  ERR = ConfigurationSpaceExhausted:
      SMAC refuses 500 trials on spaces of 32 (2^5) and 8 (2^3)
      configurations; Optuna just repeats.

SMAC vs TPE, same budget: SMAC wins exactly once -- Counselling 35
where TPE died at 200 (the random forest found the feasible
region).  TPE wins everywhere else (FDM 12 vs 18, ITDept 12 vs 27,
Services 7 vs 20, Modernize 0 vs 6, Kids 35 vs 79 -- SMAC's Kids
incumbent replays WORSE than the random mean).  And SMAC pays
~280-410 SECONDS per model vs TPE's 1-18s: the RF surrogate costs
~0.2s per trial against a 42us evaluation.  Both agree on the
paradigm verdict: CnslMgmt stays 100% dead worlds under total
assignments.

NSGA-II (pymoo, pop 50 x 40 gen, binary leaves, 3 worlds/eval,
dead worlds = worst objectives; off-the-shelf config, not tuned):

    model         bestFront  medFront  front  worlds  ms
    Counselling   425        884       5      6000    34424
    CnslMgmt      1141       1141      50     6000    18498
    FDandMkting   170        177       3      6000    29275
    ITDepartment  354        495       6      6000    11586
    SAProgram     16         38        5      96      435
    Services      47         76        5      6000    20241
    KidsandYouth  35         35        3      6000    363
    Modernize     7          27        2      6000    228
    small         39         72        2      24      46

## Parameter settings (complete)

Common to all rivals: same models (models/*.py + small.py); random
seed 1 everywhere; evaluator = infer.py sample() with leaf beliefs
adopted, replay=True; scoring yardstick = min/max benefit and
footprint over 1000 untreated worlds, seed 1 (identical to run.py);
d2h x100.  Every candidate was scored by RUNNING the model -- no
surrogate ever substitutes for evaluation and nothing is labelled
by nearest neighbor.  Optuna's TPE fits density models over
already-scored trials to PROPOSE the next candidate; the proposal
is then evaluated for real.  NSGA-II has no model at all.

- clingo 5.8.2: single-threaded, default branch-and-bound
  (--opt-mode=opt), --quiet=1 --time-limit=120 (no run came near
  the limit; all solved in 5-14ms).  Encoding: tseitin aux atoms
  per and/or; (= x f) as stratified "not x"; links collapsed to
  q :- sup_q, not att_q (helps/makes -> sup, hurts/breaks -> att);
  choice rule {l} per leaf; weak constraints: hard goals 1@3,
  missed qualities 1@2, bought leaves 1@1 (lexicographic).
- pymoo 0.6.2 NSGA-II: pop_size=50, n_gen=40 (2000 evals),
  BinaryRandomSampling, TwoPointCrossover (prob 0.9, pymoo
  default), BitflipMutation (prob 1.0 per individual, pymoo
  default per-gene rate), eliminate_duplicates=True, seed=1.
  3 worlds averaged per eval (6000 worlds/model); an eval where
  all 3 worlds die scores (benefit 0, footprint = |leaves|+1).
- Optuna 4.9.0 TPESampler(seed=1), library defaults otherwise
  (n_startup_trials=10 random, n_ei_candidates=24); 500 trials,
  one t/f categorical per leaf; 3 worlds averaged per trial
  (1500 worlds/model); all-dead trial scored d2h=2.0 (the "200"
  sentinel in the table).
- SMAC3 2.4.0: HyperparameterOptimizationFacade (random-forest
  surrogate), Scenario(deterministic=True, n_trials=500, seed=1),
  facade defaults otherwise; one t/f categorical per leaf; 3 worlds
  averaged per trial; dead-trial sentinel d2h=2.0.  Runs under
  ~/tmp/smacenv (python 3.14 venv, scikit-learn==1.6.1 pinned;
  brew-python pip cannot build its pynisher dependency).

## Minimization and ASP

The shortr2 minimization trick is: sample n worlds, drop what is
unanimous across all of them, delta-debug (ddmin) the rest.  That
needs a non-determinate generator: n samples must offer up to n
different assumption sets.  Head count first -- DISTINCT worlds in
100 samples, both generators, same models:

    model            nfr6.lisp   clingo(rnd)   clingo optima total
    Counselling        100          44            48
    CnslMgmt           100           4             4
    FDandMarketing     100          85           540
    ITDepartment       100           8             8
    SAProgram          100           1             4*
    Services           100           3             3
    KidsandYouth       100          23            24
    Modernize           46          32            36
    small               17           1             4*
    * those optima differ only in internal aux atoms; identical
      once projected onto decisions.

The default-settings trap: out of the box clingo is DETERMINATE --
same heuristic, same seed, one solve returns the same optimum every
time, and enumeration (--opt-mode=optN) walks neighbors in CDCL
order, so the first n models differ by an atom or two: unanimity
over them is fake.  Fixed with command-line flags:
--sign-def=rnd --seed=K --rand-freq=1, one solve per seed K.  That
buys real spread (the clingo(rnd) column: near-saturation of every
model's available optima) at a price on the hardest model:
FDandMarketing drops from 14ms to 2.3s per solve (160x) under
rand-freq.  Two structural limits remain, and no flag fixes them:
where few strict optima EXIST (Services 3, CnslMgmt 4) or where all
optima project to one decision set (SAProgram, small), 100 draws
still yield 1-4 distinct worlds.  The unanimity filter then divides
by ~zero.  The eps-band is the rescue there -- Services within (one
extra missed quality, +3 cost) of optimum holds > 1.1e8 answer sets
(--opt-mode=enum with a relaxed bound draws from it).

Discussion.  nfr6's sampler saturates (100/100 on every full-size
model) because it samples the whole score distribution; clingo's
draws sit only on the optimal shelf, and the shelf can be tiny.
For minimization that difference cuts both ways: our diversity
feeds the unanimity filter everywhere, but every world needs its
score checked; clingo's worlds are all pre-certified optimal, so a
ddmin oracle is one 10ms solve ("assert these labels as facts --
optimum still reachable?") with no variance to argue about.  The
natural hybrid: nfr6 generates and filters, clingo certifies the
ddmin steps.  Untried; all raw numbers above are measured.

### asp-min: the hybrid, built and run

rivals_aspmin.py runs ASP inside the SAME minimization loop as the
nfr6 pipeline: 1000 randomized-sign clingo draws (10-way parallel;
only proven "OPTIMUM FOUND" draws kept), pool = the first optimum's
full leaf labelling, shared = leaves unanimous across all draws,
ddmin the rest with clingo itself as the pass/fail oracle (assert
candidate labels as facts / prohibitions; pass iff the certified
optimum vector is unchanged).  Results:

    model         distinct  pool  shared  cands  keys  tries  sample-ms  ddmin-ms
    Counselling      48      74    63      11     1     6       2942       57
    CnslMgmt          4      53    49       4     1     4       1894       28
    FDandMkting     412      83    64      19     1     7     773322       71
    ITDepartment      8      22    16       6     1     5       1586       31
    SAProgram         1       5     5       0     0     -       1481        -
    Services          3      55    50       5     1     5       2467       56
    KidsandYouth     24      25    14      11     1     6       1438       32
    Modernize        36      26    16      10     1     6       1426       31
    small             1       3     3       0     0     -       1427        -

Reading: ONE leaf label suffices to force the certified optimum on
every full-size model; on SAProgram and small the unanimity filter
alone finishes the job (all leaves forced, zero candidates).  The
oracle is exact, so tries collapse to 4-7 (vs 5-213 replay batches
in the sampling pipeline) and ddmin costs ~30-70ms.  The bill is
all in sampling: FDandMarketing's rand-freq draws took 13 minutes
(everything else 1.4-3.2s).  Two catches, both discovered the hard
way: draws must be checked for "OPTIMUM FOUND" (a timed-out draw
poisons the unanimity filter), and clingo OMITS a priority level
from its cost vector when grounding leaves it empty (facts that
force every hard goal erase the hmiss level), so optimum vectors
must be left-padded before comparing.

Then the sampling was deleted entirely (rivals_aspmin.py --exact):
clingo computes the unanimity filter NATIVELY.  Cautious
enumeration (--opt-mode=optN --enum-mode=cautious) returns the
atoms true in EVERY optimum = the forced-t leaves; the complement
of brave enumeration (union) = the forced-f leaves; only the
brave-minus-cautious gap goes to ddmin.  Identical
shared/cands/keys on every model, and the clock collapses:

    model         ms(sampled)  ms(exact)
    Counselling      2999         97
    CnslMgmt         1922         53
    FDandMkting    773393        139     (5500x)
    ITDepartment     1617         49
    SAProgram        1481         20
    Services         2523         78
    KidsandYouth     1470         48
    Modernize        1457         53
    small            1427         16

Whole corpus: 0.55s -- faster than the nfr6 sampling pipeline
itself.  Moral: our unanimity filter is a sampled approximation of
cautious consequences; when the generator is a solver, ask the
solver.  Caveat as everywhere in this section: these are keys to
the DETERMINISTIC idealization's optimum -- dice-and-loop worlds
that beat it (Modernize 4/4@2) are invisible to asp-min.

### Do asp-min keys transfer?  (same/cliffs/ks/cohen)

rivals_stats.py replays BOTH key sets 30x through the same engine
(infer.py) and runs the xai.py battery -- cliffs 0.195, ks at 1.36,
cohen's threshold set to 0.35 * sd(b4) per house rules:

    model         ours mu(sd)  asp mu(sd)  cliffs  ks    cohen  verdict
    Counselling   43 (11)      50 (10)     0.41    0.33  n      DIFF
    CnslMgmt      57 (22)      62 (33)     0.01    0.13  y      SAME
    FDandMkting   16 (9)       45 (13)     0.96    0.83  n      DIFF
    ITDepartment  24 (11)      47 (28)     0.42    0.43  n      DIFF
    SAProgram     33 (13)      36 (15)     0.00    0.13  y      SAME
    Services      26 (11)      30 (11)     0.18    0.20  y      SAME
    KidsandYouth  35 (0)       67 (19)     0.73    0.73  n      DIFF
    Modernize     0 (0)        37 (29)     0.80    0.80  n      DIFF
    small         41 (3)       52 (14)     0.44    0.47  n      DIFF

Statistically different on six of nine, and every DIFF favors our
keys.  The reason is semantic, not statistical: asp-min's one key
pins the deterministic idealization, but replayed under the dice
engine it leaves every link roll and or-bet to chance -- its replay
means sit at the random mean (asp 45 vs b4 50 on FDandMkting, 67
vs 70 on Kids).  Keys do not transfer across semantics; each
idealization keeps its own.  (The three SAME rows are the known
rubber-stamp models where OUR keys are also near-random --
agreement in weakness, not strength.) -- rng, trail,
walk, sampler -- is 125 lines of lisp (286 with the pretty-printer
and the model zoo).  The ASP route needs clingo (16MB installed,
4MB solver library, on the order of 1e5 lines of upstream C++)
plus our 120-line model-to-ASP translator.  One is breakfast
reading; the other is a dependency.

## Findings

1. TOTAL ASSIGNMENTS ARE THE TRAP.  Both configuration-style rivals
   pin EVERY leaf, and on gated models a total assignment usually
   contains some denial a hard goal needed to route around: Optuna
   killed 1500/1500 worlds on Counselling and CnslMgmt; NSGA-II
   fronts on the big or-heavy models are dominated by dead points
   (best "d2h" 425, 1141).  shortr2's candidates are PARTIAL
   labellings -- unlabelled atoms stay free for the walk -- which is
   why sampling never faces this.  (This is the leaf-abduction
   under-determination result from nfr6.md, seen from the other
   side: totality over-determines.)
2. ASP IS THE HONEST YARDSTICK, AND FAST: certified optima in
   5-14ms, same order as one shortr2 pipeline row.  Where hard
   goals are feasible its optima bracket ours: Services certified
   14/16 @ 11 leaves vs our sampled 14/16 @ 22 (same benefit,
   HALF the cost -- our footprint has slack); FDandMkting 18/18@16
   vs 17/18@43; SAProgram 11/11@1 vs 10/11@2.
3. BUT ASP RUNS A DIFFERENT WORLD: two semantic gaps, both
   measured.  (a) Stable-model semantics forbids cyclic support:
   1/29 Counselling, 3/36 CnslMgmt and 5/23 ITDept hard goals are
   PROVABLY underivable without loops -- our engine's optimistic
   memo (loop = free t) is load-bearing on three of eight models.
   (b) Links idealized as "support wins unless attacked" cannot
   express our 2:1 dice: Modernize certified 4/4 benefit needs 10
   leaves, while our lucky-roll world got 4/4 with 2 (bigBang's
   hurts rolled t); on small, ASP proves only 1/3 qualities
   co-achievable while dice worlds sometimes show 3/3.  Every
   shortr2-beats-ASP row is dice or loop optimism, not search skill.
4. SPEED, per candidate: shortr2 42us; NSGA-II/Optuna pay the same
   engine cost x3 reps plus framework overhead (0.4-23ms/world
   effective); clingo amortizes to microseconds after grounding.
   Per final answer: shortr2 row 0.1s; Optuna 1-18s; NSGA-II
   0.2-34s; ASP 0.01s.
5. EXPLAIN is where shortr2 stands alone: nobody else returns a
   SMALL answer.  ASP: full model.  Optuna: full config (and on two
   models, an illegal one).  NSGA-II: a front of full vectors.
   Keys (1-12 labels) plus the replay variance test have no
   analogue in any rival.

## Verdict per paradigm

- ASP: adopt as the certification harness for the deterministic
  core -- it found real slack in our footprints (finding 2) and it
  is not slower than sampling.  It cannot replace sampling while
  links are odds and loops are optimism (finding 3).
- NSGA-II: wrong candidate shape for gated models out of the box;
  would need constraint-aware repair operators to compete.  Its
  real offer (a trade-off front) is orthogonal and could be grafted
  onto shortr2's worlds instead.
- SMAC-style: mismatched twice -- total assignments (finding 1) and
  surrogate overhead that only pays when evaluations cost minutes,
  not 42us.
- shortr2: keeps the Explain crown; ASP's cost numbers say ddmin
  should also shrink FOOTPRINT slack, not just label count.

## Caveats

- ASP encoding choices (disclosed in rivals_asp.py header): tseitin
  aux atoms; (= x f) as stratified "not x"; links collapsed to
  support-unless-attacked; hard goals as priority-3 weak
  constraints for diagnosis.  Different link/loop semantics than
  the sampler -- that difference IS finding 3, not noise.
- Optuna is a stand-in for SMAC3 (build failure recorded above);
  same paradigm, different surrogate (TPE vs random forest).
- NSGA-II is default-config; a tuned, repair-operator version
  would do better.  The total-assignment failure mode, however, is
  paradigm-level, not a tuning artifact.
- All rivals scored with our yardstick (b4 min-max from 1000
  untreated worlds, seed 1); numbers >100 mean off-the-ruler.

## The truth-walk shootout: shortr2 = nfr7 (2026-09-02)

Everything above this line compared rivals against the nfr6
pipeline.  This section re-runs the tournament on its successor:
shortr2 now names nfr7.lisp + rig7.lisp -- the honest walk (memo
reports the label, a denied child fails its parent), unfounded
loops failing by default (*loops* nil: ASP-aligned; the coinductive
reading survives behind the knob -- see nfr7.md), and an ABSOLUTE
yardstick: d2h normalized on 0..|quals| x 0..|leaves|, replacing
the sampled min-max ruler.  That last change was forced by a
diagnosis: under fiat play the 1000 untreated worlds compress to a
~1-leaf footprint spread, so the sampled ruler exploded any
out-of-distribution replay (the 283s and 425s quoted above are
that artifact, not bad worlds).  Numbers below are not comparable
to the tables above; the verdicts are.

Protocol, per model per seed 1..20: shortr2 runs its whole
pipeline (1000-world b4, pool/shared/cands, rebaseline, ddmin ->
keys).  The rival contributes ONE prescription, found once at seed
1 under its own machinery -- no minimization on the rival side;
those searches are too slow to repeat per seed:

  - asp-min: exact cautious/brave hulls + ddmin, clingo as oracle
    (deterministic, so one run is all runs);
  - shortr1: best of 1000 runs of the SHORT engine, its touched
    bases as labels (1/-1 -> t/f; 96-100% of names matched);
  - NSGA-II, SMAC3: best incumbent/front-point, EVERY leaf labelled
    (their decision space), searched against the old python engine.

Both prescriptions then replay 30x through the same nfr7.lisp walk
and meet the battery: cliffs (0.197), ks (1.36), cohen with eps =
0.35 x sd(b4).  All three agree = tie; else win by lo, mu breaking
lo collisions.  DEAD = the prescription kills every world (1000
consecutive misses).  Cells are "lo; mu (sd)" of %d2h (lower
better), averaged over the 20 seeds; ms(shortr2) is the keys
pipeline per seed, ms(rival) the rival's one-time search (asp-min:
per-seed clingo, averaged).

Determinism postscript: asp keys initially flapped between runs.
Cause: encode() iterates python sets, PYTHONHASHSEED reorders the
emitted rules, and rule order -- semantically nothing in ASP --
steers clingo's tie-break among equal optima, flipping a key's
LABEL.  Both labels pass asp's oracle: its objective counts
leaves, so it is indifferent between prescriptions the truth walk
separates sharply.  Fix: write the .lp sorted.  The
underdetermination is the finding; the sort is the workaround.

### asp-min vs shortr2

    model                  shortr2 lo; mu (sd)  asp lo; mu (sd)  tie  shortr2  asp  dead  ms(shortr2)  ms(asp)
    Counselling            40; 42 (2)           40; 42 (2)       16   4        0    0     56           310
    CounsellingManagement  51; 53 (1)           52; 54 (1)       6    14       0    0     35           214
    FDandMarketing         37; 41 (2)           38; 42 (3)       8    12       0    0     62           394
    ITDepartment           33; 35 (1)           33; 36 (2)       2    17       1    0     18           233
    SAProgram              28; 40 (7)           29; 43 (8)       9    11       0    0     23           100
    Services               26; 34 (3)           27; 34 (3)       13   6        1    0     66           269
    KidsandYouth           42; 42 (0)           42; 46 (3)       0    20       0    0     10           257
    Modernize              5; 5 (0)             8; 26 (14)       0    20       0    0     6            252
    small                  24; 27 (5)           25; 44 (14)      0    20       0    0     3            92
    TOTAL                  -                    -                54   124      2    0     -            -

### shortr1 vs shortr2

    model                  shortr2 lo; mu (sd)  shortr1 lo; mu (sd)  tie  shortr2  shortr1  dead  ms(shortr2)  ms(shortr1)
    Counselling            40; 42 (2)           43; 44 (1)           0    20       0        0     58           3064
    CounsellingManagement  51; 53 (1)           dead                 0    20       0        20    36           1741
    FDandMarketing         37; 41 (2)           dead                 0    20       0        20    64           5729
    ITDepartment           33; 35 (1)           45; 47 (2)           0    20       0        0     19           1024
    SAProgram              28; 40 (7)           43; 52 (7)           0    20       0        0     24           923
    Services               26; 34 (3)           dead                 0    20       0        20    69           10748
    KidsandYouth           42; 42 (0)           65; 66 (1)           0    20       0        0     10           441
    TOTAL                  -                    -                    0    140      0        60    -            -

### NSGA-II vs shortr2

    model                  shortr2 lo; mu (sd)  nsga2 lo; mu (sd)  tie  shortr2  nsga2  dead  ms(shortr2)  ms(nsga2)
    Counselling            40; 42 (2)           dead               0    20       0      20    59           44368
    CounsellingManagement  51; 53 (1)           dead               0    20       0      20    36           23316
    FDandMarketing         37; 41 (2)           dead               0    20       0      20    64           37449
    ITDepartment           33; 35 (1)           dead               0    20       0      20    19           14457
    SAProgram              28; 40 (7)           28; 34 (4)         3    3        14     0     24           549
    Services               26; 34 (3)           dead               0    20       0      20    69           25964
    KidsandYouth           42; 42 (0)           dead               0    20       0      20    10           489
    Modernize              5; 5 (0)             dead               0    20       0      20    6            292
    small                  24; 27 (5)           dead               0    20       0      20    3            59
    TOTAL                  -                    -                  3    163      14     160   -            -

### SMAC3 vs shortr2

    model                  shortr2 lo; mu (sd)  smac lo; mu (sd)  tie  shortr2  smac  dead  ms(shortr2)  ms(smac)
    Counselling            40; 42 (2)           dead              0    20       0     20    56           386911
    CounsellingManagement  51; 53 (1)           dead              0    20       0     20    35           328576
    FDandMarketing         37; 41 (2)           dead              0    20       0     20    61           440827
    ITDepartment           33; 35 (1)           dead              0    20       0     20    18           322443
    SAProgram              28; 40 (7)           28; 34 (4)        3    1        16    0     23           2030
    Services               26; 34 (3)           dead              0    20       0     20    66           411258
    KidsandYouth           42; 42 (0)           28; 34 (4)        0    0        20    0     10           329706
    Modernize              5; 5 (0)             dead              0    20       0     20    6            2387313
    small                  24; 27 (5)           71; 80 (8)        0    20       0     0     3            333
    TOTAL                  -                    -                 3    141      36    120   -            -

### Findings

1. ASP-MIN IS THE ONLY REAL RIVAL, AND IT LOSES ON HOLD, NOT
   REACH.  124-2 with 54 ties.  The lo columns are near-identical
   everywhere: both key sets can TOUCH the best world.  The mu
   column splits on every model with relief (Modernize 5 vs 26,
   small 27 vs 44, KidsandYouth 42 vs 46): asp keys reach the
   optimum on lucky walks and drift otherwise; shortr2 keys pin
   the walk there.  Runtimes are the same order (shortr2 3-66ms
   vs asp 92-394ms per row) -- so this is not speed-vs-quality,
   shortr2 just wins.
2. LOOP OPTIMISM IS RETIRED AND NOTHING BROKE.  Finding 3a above
   called the old memo's loop-forgiveness load-bearing.  nfr7
   defaults to ASP's rule -- unfounded loops fail -- and the whole
   tournament re-ran without it: zero cycles ever reach derive on
   this corpus (all seven graph cycles thread contribution links,
   which draw labels but never descend; nfr7.md).  Every
   shortr2-beats-asp row is now dice vs idealization alone.
3. TOTAL ASSIGNMENTS DIE UNDER TRUTH.  NSGA-II's prescriptions
   are DEAD on 8 of 9 models; SMAC3's on 6 of 9; shortr1's on its
   three biggest.  Finding 1 above said totality "usually contains
   some denial a hard goal needed"; the mechanism is now exact:
   the old evaluator's memo line returns True for ANY known atom,
   whatever its label ("memo (and replay)", infer.py) -- an engine
   that cannot say no -- so these searches never once felt a
   denial.  The honest walk says no, and their incumbents turn
   out to be impossible.
4. WHEN A TOTAL ASSIGNMENT LIVES, IT CAN WIN.  NSGA-II's one
   survivor (SAProgram) beats shortr2 14-3; SMAC3 wins BOTH of
   its survivors -- SAProgram 16-1, KidsandYouth 20-0 -- and on
   KidsandYouth its lo (28) beats anything our 1000-world sample
   ever visited (42): a surrogate can walk to corners random
   sampling never reaches, and pinning every leaf then holds them
   (mu 34 (4) vs our 42 (0)).  So the b4 sample is not the
   frontier; keys can only pin worlds sampling has seen.
5. BUT THE TRANSFER IS A COIN-FLIP, AND THE PRICE IS ABSURD.
   The same SMAC3, same protocol, on small: incumbent scores
   71; 80 (8) -- confident junk from training on the engine that
   cannot say no -- losing 20-0.  shortr1's surviving
   prescriptions (coverage-trained, four-valued optimism) lose
   80-0 across four models.  And the meter is running: SMAC3
   spends 5.5-40 MINUTES per model (Modernize 40m: each dead
   evaluation waits out the sampler's patience), NSGA-II up to
   44s, shortr1 0.4-10.7s -- against 3-66ms for a whole shortr2
   keys pipeline.  Nothing here bids to replace sampling; the one
   genuine lesson (finding 4) is that a smarter GENERATOR could
   feed our same keys machinery better worlds.

### Caveats

- Rivals searched under their own published setups (old python
  engine, sampled yardstick).  Re-running their searches against
  the honest evaluator might close finding 3's gap; nothing about
  finding 1 or 4 depends on it.
- SMAC3 here is the real thing (2.4.0, random-forest surrogate,
  dedicated venv pinning scikit-learn 1.6.1) -- the Optuna
  stand-in caveat above is retired.
- shortr1 runs the dr-bigfatnoob clone with mechanical py2->py3
  shims (iteritems/xrange/unicode/decode-identity); its bases map
  to our atoms by case-insensitive sanitized name; unmatched
  orphans: 0-4 per model.
- Reproduce: `make rivals S=n` (asp-min); `python3 rivals_best.py
  nsga2|smac|shortr1` then `python3 rivals_best.py replay RIVAL
  SEED` (searches need pymoo / ~/tmp/smacenv / ~/tmp/shortr1).


{% endraw %}