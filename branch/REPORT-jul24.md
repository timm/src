<a href="https://timm.fyi"><img align="right" alt="Author" src="https://img.shields.io/badge/Author-timm-dc143c?logo=readme&logoColor=white"></a><img align="right" alt="Study" src="https://img.shields.io/badge/Study-XAI%C2%B7%2B%C2%B7Stability-7b68ee?logo=githubcopilot&logoColor=white"><img align="right" alt="Data" src="https://img.shields.io/badge/Data-20%C2%B7of%C2%B7127%C2%B7MOOT-000080?logo=databricks&logoColor=white"><img align="right" alt="Result" src="https://img.shields.io/badge/Result-47%25%C2%B7agreement%C2%B7at%C2%B745%C2%B7labels-32cd32?logo=checkmarx&logoColor=white"><img align="right" alt="Cost" src="https://img.shields.io/badge/Cost-45%C2%B7labels%C2%B7per%C2%B7model-ff8c00?logo=speedtest&logoColor=white">

# branch, 2026-07-24: explanation utility and stability

**tl;dr** branch -- 45 labels, one small tree, every
pruning enumerated, best kept -- was tested against two
published rigs: the JSS'26 "Minimal Data, Maximum
Clarity" feature-selection benchmark and the 2026 model
-instability study (arXiv:2607.10420). Four conclusions,
posed below as RQ1-RQ4: branch's selections rival
standard XAI methods at a third of their labels (RQ1,
evidence promising but partial); a handful of variables
carry the signal (RQ2, solid); branch sets the best
performance-stability score yet seen in this rig (RQ3,
leading but ungated); paid for by the worst structural
stability (RQ4, solid -- and, per that paper's own
thesis, the cheap price).

## What is branch?

branch (branch.py, ~280 lines) is an active-learning
tree pruner:

1. **Label little.** `acquire` spends 45 labels (budget
   50): rows are projected FASTMAP-style onto the line
   joining the best and worst labelled rows, the pool is
   culled toward the good pole, a few more rows are
   labelled per round.
2. **Fit one small tree.** A binary regression tree
   (maxd 4, min leaf 3) fits the labels' d2h -- distance
   to the ideal objective point.
3. **One tree is many.** `walk` lazily yields every
   pruning: below each cut, each side stays or collapses
   -- up to 4^depth trees sharing structure, each scored
   at its root in O(1).
4. **Pick one.** The best pruning = min (score, leafs):
   the smallest tree containing the best leaf. Its 2-4
   split attributes are branch's explanation -- and, in
   this study, its feature selection.

Full background: REPORT.md (RQ1-RQ7: the pruning zoo,
fairness-for-free, few-variable winners).

## Method

**Rig A -- explanation utility (JSS'26 Table 10).** The
published rig, unchanged: 80/20 split; each selector
names a feature subset; an independent learner (LightGBM
headline; linear/RF/SVR/ANN also run) trains on just
those columns; 20 repeats; score = win(d2h) of the best
of the 10 rows the learner recommends. branch's N
attributes set the subset size for all ranking rivals
(SHAP, ReliefF, ANOVA); "All" keeps every column. 20
datasets across the MOOT space. Sanity first: the
paper's own Table 10 was reproduced from its shipped
code, 49/50 lgbm cells exact.
Code: github.com/amiiralii/Minimal-Data-Maximum-Clarity
pull 1.

**Rig B -- instability (arXiv:2607.10420).** The
published measures, unchanged, three arms (EZR-initial,
EZR-refined per its Table IV, branch), 20 repeats each:
performance agreement (fixed test rows through all 20
models; agree when sd(models) < 0.35 * sd(data));
error spread (sd of win(best) - win(recommended));
structural similarity (root-weighted Jaccard over the 20
trees' feature sets). Same 20 datasets.
Code: github.com/timm/Model-Instability pull 1.

## RQ1: is branch competitive with state-of-the-art XAI?

Downstream lgbm wins, branch vs rivals (win/tie/loss,
20 datasets): SHAP +3/=13/-4, ReliefF +8/=7/-5, ANOVA
+6/=10/-4, all-features +2/=9/-9. For x < 20 columns
(15 datasets) branch ties or beats every ranking rival
and loses at most 1 point to all-features -- at 45
labels vs the rivals' full supervision (SHAP trains on
the whole 80% split) and EZR's 75-150. For x >= 39 the
cheap ride ends: SQL-AM -15, FFM-125 -31 vs
all-features.

**Answer: evidence so far is competitive with SOTA --
but needs more data.** Wins are on 20 of 127 datasets,
lgbm-downstream, mean-based (no statistical gate), and
explanation QUALITY (vs LIME/SHAP/BreakDown narratives,
the JSS paper's RQ2) was not measured -- only selection
utility. The wide-data losses are real; on FFM-125,
SHAP at the same N=4 scores 92, so the failure is
branch's ranking under 45 labels, not the subset size.

## RQ2: is most of the signal in few variables?

branch's winner used N = 2-4 attributes on every dataset
(of up to 128 on offer), and RQ1 shows those 2-4 columns
feeding an independent learner at no measurable cost
below x = 20. This replicates REPORT.md RQ7 (winner
median 4 variables over 220 repeats) on a second rig
with independent downstream learners.

**Answer: yes -- solid.** Caveat kept small: on some
wide landscapes (SQL-AM) NO small subset matches
all-features; "most" is not "always".

## RQ3: is branch a new high-water mark in performance stability?

Paper's Eq-7 agreement at alpha = 0.35, mean over 20
datasets:

                 EZR-initial  EZR-refined  branch
    agreement         4%          28%       47%
    error spread     19.2         20.2      19.2

branch beats the paper's refined configuration 13/5/2
on agreement; on auto93, HSMGP and SS-K its error spread
is 0.00 -- all 20 repeats recommend the same row.

**Answer: leading, not yet a high-water mark -- needs
more data.** Same hedge as RQ1: 20 of 127 datasets, raw
means (the paper gates with KS + Cliff's + top-set),
and the paper's stablest baselines (the RQ3 clusterers:
KMeans, HDBSCAN, CURE) were not run against branch.
Three datasets (SQL-AM, Scrum1k, coc1000) sit at 0%
agreement for every arm -- the data-inherent floor that
the paper predicts no learner escapes.

## RQ4: does this cost structural stability?

Root-weighted Jaccard over the 20 trees per dataset:
EZR-initial 0.39, EZR-refined 0.54, branch 0.37 (branch
full tree, before pruning selection: 0.42). branch loses
to refined 19/20. Worst where columns abound: FFM-125
0.10, SQL-AM 0.07, coc1000 0.06.

**Answer: yes -- solid.** Fewer variables did NOT buy
structural stability; the instability paper's own
ablation ("feature selection ... in fact increased
instability") is confirmed by an outside method. Note
the pruning tiebreak itself adds churn (winner 0.37 vs
full tree 0.42). And note the frame that paper supplies:
structural and performance instability are decoupled,
structural is largely irreducible (Rashomon), and only
performance stability governs trust. branch is both
extremes at once -- different trees, same
recommendations -- which is that paper's central claim,
demonstrated.

## Future work

1. **Run on all 127** MOOT datasets, both rigs (the
   instability script costs seconds per dataset; the
   selection rig's SVR arm is the only slow part).
2. Gate every comparison with the source papers' own
   statistics (KS + Cliff's delta + top-set ranking)
   instead of raw means.
3. Add the clusterer arms (KMeans, HDBSCAN, CURE) before
   any high-water-mark claim in RQ3.
4. Measure explanation quality, not just selection
   utility: branch vs LIME/SHAP/BreakDown under the
   JSS'26 RQ2 walkthrough protocol.
5. Wide data: scale branch's budget with column count
   (FFM-125 suggests 45 labels cannot rank 128 columns);
   and try a stability-aware tiebreak among score-tied
   prunings -- it cannot hurt performance and may claw
   back some of RQ4.

## Threats to validity

Twenty datasets, chosen for spread, are not 127; all
conclusions above inherit that. Rig A compares 20-repeat
means without a statistical gate. Rig B reuses the
paper's exact split protocol (first 100 rows as fixed
test set) including its quirks. branch ran one
configuration (budget 50, leaf 3, maxd 4) -- knobs that
happen to match the instability paper's Table IV
recommendations on budget and leaf size, which flatters
RQ3. The d2h scales of branch and EZR differ (logistic
vs min-max normalization); agreement rates are computed
within-arm, so cross-arm comparison is of rates, not raw
sds.
