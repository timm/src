# shortr2 vs NSGA-II vs SMAC-style vs ASP

Ran overnight 2026-08-30/31 on the eight SHORT models + small.
Every rival consumes the SAME models (loaded from models/*.py) and,
where it needs an evaluator, the SAME python engine (infer.py).
Scripts: scratchpad rivals_asp.py, rivals_nsga2.py, rivals_optuna.py
(session scratchpad; copy into repo if wanted).

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
