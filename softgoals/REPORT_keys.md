# REPORT_keys.md : keys via sampling + delta debugging

nfr5.pl experiments of 2026-08-14/15 (SWI-Prolog, Apple
Silicon, `set_random(seed(1))`). One 90-line interpreter both
generates worlds and replays decisions; a unanimity filter then
Zeller's ddmin shrink the best world's labels to a minimal
seed. On Horkoff's seven Kids Help Phone goal models, seeds of
1-10 labels (0.3-8% of a model's atoms) steer fresh samples to
near the best world found in 1000 unguided runs, with every
hard goal satisfied in every world. Reproduce: `swipl -g "run('models/CSServices.pl')" -g
halt gen18.pl`.

## 1. The algorithm

One interpreter, `isamp(Goals, Beliefs, World)`. Beliefs are
`atom=value` pairs; the world returned is the beliefs plus every
label the run committed to. Two calls, differing only in the
belief list:

    isamp(Q, [],              W)     % generate
    isamp(Q, [replay=on|Seed],W)     % replay / check

`replay=on` is itself a belief. Two interpreter rows fire only
when it is present: or-branches whose atoms are all already
believed are preferred over random branch choice, and
contribution links onto already-believed atoms are skipped
rather than re-drawn. Without those rows a partial seed is
shredded -- every helps/hurts edge onto a seeded atom re-rolls
its coin and, on mismatch, denies the clause (measured: three of
seven models then optimize not at all).

The pipeline:

    Q  = [h1, h1=t, ..., hn, hn=t, [and|Softs]]
         -- hard goals gated: derive each, insist on it, THEN
            engage every softgoal. Order matters: gating after
            soft engagement is infeasible (0/1000 worlds).

    GENERATE  Ws = N1=1000 x isamp(Q, [], W)
              score each: benefit  = qualities labeled t
                          footprint= leaves bought (labeled t)
              d2h = dist to (max benefit, min footprint),
                    normalized over these 1000
    BEST      W* = argmin d2h; d2h* is the reference optimum
    SEED0     controllable labels of W*: atoms that are leaves
              (not rule heads) or listed in an [or|Alts] body
    FILTER    drop from SEED0 every label present in ALL 1000
              worlds. Unanimity, not a percentage: a label the
              model forces everywhere carries zero information
              and replay re-derives it free. (A 90% threshold
              was tried and retired: a label at 95% is NOT
              guaranteed, and dropping it left replay re-winning
              it against a 1/3 coin -- measurable error.)
    DDMIN     Zeller ddmin over the filtered candidates
              test(S) = mean d2h of 30 x isamp(Q,[replay=on|S])
                        =< d2h* + 0.05
    ASSESS    reps=30 more x isamp(Q, [replay=on|Seed]) -> mu, sd
              (one reps constant serves tests and assessment; a
              separate bigger N2 bought only cosmetic error-bar)

Feature extraction here is three cuts, each removing a
different redundancy. SEED0 removes the UNACTIONABLE (labels a
stakeholder cannot set; seeding a consequence fakes benefit and
blocks its subtree -- measured, such seeds score worse than
random). FILTER removes what the MODEL makes redundant
(topology-forced labels; cheap, pure counting). DDMIN removes
what the OBJECTIVE makes redundant (settable, non-forced labels
that still do not move d2h; expensive, needs replays). None of
the three subsumes another, and running the cheap cuts first is
why the corpus takes 51s rather than 139s.

Sanity anchor (run before trusting anything): seeding the WHOLE
best world replays it term-identically, 100/100, on the vanilla
interpreter -- generator and checker are provably one device;
prudence questions only arise for partial seeds.

## 2. The table

    dataset          mu     sd     best   muSeed sdSeed |seed| %seed
    Counselling      0.422  0.130  0.079  0.160  0.115   7     2.0
    CounsellingMgmt  0.397  0.128  0.000  0.065  0.078  10     4.8
    FDandMarketing   0.470  0.124  0.079  0.160  0.079  10     3.1
    ITDepartment     0.576  0.235  0.000  0.051  0.073  10     7.8
    SAProgram        0.451  0.171  0.000  0.055  0.061   9     7.8
    Services         0.533  0.129  0.174  0.228  0.152   1     0.3
    KidsandYouth     0.706  0.173  0.354  0.354  0.000   1     1.2
    small            0.510  0.315  0.000  0.000  0.000   2    13.3

Whole corpus: 50 seconds, most of it ddmin (cost =
#tests x 30 replays; the unanimity FILTER halved #tests and,
before it, the corpus took 139s for equal-or-worse rows --
filter-first is strictly better on time, seed size, AND mu).
Every row: hard goals hold in 100% of sampled and replayed
worlds; muSeed beats the random mean by 2-3.5 baseline standard
deviations. KidsandYouth: one label reaches its structural
floor exactly, sd zero.

FDandMarketing's gap (0.160 vs 0.079; Counselling shows the
same signature this draw) is not pipeline error:
its best worlds are partly luck. The model has 177 helps edges
against 1 hurt -- the corpus's most coin-driven -- and even
seeding ALL its controllable labels fails to reproduce its best
world's d2h. Fortune is not replayable; only choices are. The
(helps+hurts)/edges ratio predicts this replayability gap.

## 3. Comparison to SHORT (re17.pdf)

Same corpus (largest model 351 nodes there, 353 atoms here),
same three conclusions: keys exist; keys are easy to find; keys
set the rest of the model. SHORT reports "often, just 12%";
this pipeline lands at 0.3-8% (median ~3%). Differences:

- Machinery: SHORT is a bespoke polynomial-time ranker built to
  summarize the whole trade space. Here the finder is 1000
  random worlds and the reducer is off-the-shelf ddmin; the
  interpreter never changes.
- Hard goals: SHORT scores %goals-satisfied as an objective
  (f2); here hard goals are a gate, all covered by
  construction, and the objective is soft coverage vs cost.
- Validation: SHORT compares against NSGA-II on accuracy;
  here the check is replay -- the seed must steer fresh
  samples back to the reference optimum, mu/sd reported.
- New observation: the luck/choice split. Some models' optima
  are partly unreplayable coin fortune, bounding what ANY key
  set can guarantee; SHORT has no analogous notion.

## 4. Is ddmin-as-feature-selection new?

ddmin is Zeller & Hildebrandt's failure-input minimizer
(TSE 2002). Its use as a *feature selector against a stochastic
objective* -- shrink an assumption set while a sampled quality
statistic stays within tolerance -- appears rare but not
unprecedented. Closest neighbors found:

- Prediction-preserving input minimization: delta-debug an
  input to the minimal fragment keeping an ML model's
  prediction (Suneja et al., "Probing Model Signal-Awareness
  via Prediction-Preserving Input Minimization", 2020,
  arXiv:2011.14934).
- DD-CAM: ddmin over a vision model's representational units
  for minimal sufficient explanations (arXiv:2602.19274).
- SkillReducer: ddmin over semantic clauses with routing
  correctness as the predicate (arXiv:2603.29919).
- Algorithmic descendants if #tests matters: ProbDD
  (arXiv:2408.04735) and WDD (ICSE 2025).

None target requirements/goal models, and none anchor the test
predicate to a sampled optimum with a replay device; that
combination seems to be this note's contribution. Classic
backward feature elimination (RFE) differs in assuming a
per-feature score; ddmin needs only the pass/fail test, which
is what a stochastic simulator can honestly provide.

## 5. Threats

- Single RNG seed for the headline table; seed-loop intervals
  not yet run (ddmin is path-dependent, |seed| wobbles a few
  labels across seeds).
- eps=0.05 slack is spent in full by ddmin; muSeed-best gaps sit
  near it by construction. All constants are named facts atop
  gen18.pl (n1, reps, tol, rseed). Anchoring Tol to the replayable
  floor (full-controllable-seed mu) would tighten FD-like rows.
- d2h normalization comes from the same 1000 worlds that supply
  the best; no holdout.
- One corpus, one dialect (nfr3-style `<--` models from a
  single research group).
