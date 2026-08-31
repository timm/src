# shortr2 vs NSGA-II vs SMAC-style vs ASP

Ran overnight 2026-08-30/31 on the eight SHORT models + small.
Every rival consumes the SAME models (loaded from models/*.py) and,
where it needs an evaluator, the SAME python engine (infer.py).
Scripts: softgoals/rivals_asp.py, rivals_nsga2.py, rivals_optuna.py
(in this directory; shortr1_table.py drives the SHORT repo).

Versions: clingo 5.8.2 (brew), pymoo 0.6.2, optuna 4.9.0.
SMAC3 itself would not install (pynisher native build fails on this
mac); Optuna TPE stands in -- same paradigm: model-based,
single-objective, returns one incumbent configuration.

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
- SMAC3: pip install fails building pynisher (native) on this
  machine; not run.  Optuna TPE is the paradigm stand-in
  (surrogate differs: TPE vs random forest).

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

Code size, for the locals: the nfr6.lisp engine -- rng, trail,
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
