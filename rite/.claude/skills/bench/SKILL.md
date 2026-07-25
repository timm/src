---
name: bench
description: Benchmark furniture and stats gates the target field expects -- datasets, baselines, indicators, statistics, reporting. Per-project; rewrite for each paper's field. Use at HOWTO steps 9, 14.
---

# bench

## Short form

- Public datasets by canonical name; report per-dataset, persist raw per-run numbers.
- Floor = random search; ceiling = strongest SOTA with a public, runnable implementation.
- 20+ repeats; distributions not means; significance AND effect size, conjunctively; Scott-Knott for multi-treatment rankings.
- Budgets (labels bought, wall-clock) stated up front.
- Replication package to SIGSOFT artifact standard; construct-validity paragraph; include tasks where the method loses.
- [verify] marks must be confirmed against the coded papers before any number ships.

## Detail

# Accepted benchmarking practices in this field (draft)

Working list for the benchmarking section. Sources: ACM
SIGSOFT Empirical Standards (OptimizationStudies,
Benchmarking, SystematicReviews); norms visible in the
field's own methodological papers (Arcuri & Briand 2014;
Li, Chen & Yao 2020; Agrawal & Menzies 2018). Numbers
marked [verify] must be confirmed against our coded
papers during reading; the coding.tsv grids get extra
columns (#datasets, baselines, indicators) as we read.

## Datasets

- Public corpora, cited by canonical name: PROMISE /
  SEACRAFT lineage for defect data; MOOT for
  multi-objective SE tasks; SPLC feature models and
  config-performance systems for configuration work.
- Typical dataset counts per paper: 5-20 [verify].
  Exemplar: Agrawal & Menzies 2018 used 9 defect sets;
  config-optimization papers commonly 10-30 systems.
- Report per-dataset results, not only aggregates;
  persist raw per-run numbers (Benchmarking standard:
  no aggregate-only reporting).
- Sort/describe datasets by hardness (class imbalance,
  size, dimensionality) so wins can be tied to data
  character.

## Standard algorithms (the expected furniture)

- Multi-objective optimizers: NSGA-II is the default
  comparator; SPEA2, MOEA/D; NSGA-III for many-objective;
  differential evolution for tuning tasks.
- Mandatory floor: random search (OptimizationStudies
  essential: never-tackled problems compare at least to
  random). Sampling ("SWAY") as a cheap baseline
  (Chen et al., TSE 2019 -- a named exemplar in the
  standard).
- Sequential model-based methods where budgets matter:
  SMAC/Bayesian optimization, FLASH.
- Explanation baselines: LIME, SHAP (both in our
  classics list); directly interpretable models
  (small decision trees, rule lists) as the
  "explain-by-construction" comparison.

## SOTA to beat [verify against coded papers]

- For explanation-guided or explainable SE analytics:
  LIME/SHAP-based pipelines applied to SE models are the
  common comparator in 2021-2026 papers.
- For multi-objective SE optimization: NSGA-II variants
  plus problem-specific SOTA from each task's lineage.
- Rule: compare to the strongest method with a public,
  runnable implementation (OptimizationStudies lists
  "unavailable baseline" as an invalid criticism).

## Measures

- Multi-objective quality: hypervolume, IGD/GD, spread.
  Choose per Li, Chen & Yao 2020 guidance and justify;
  never evaluate objectives one at a time (listed as an
  invalid comparison).
- Prediction tasks: recall, false alarm, AUC; avoid
  precision-only claims on imbalanced data.
- Cost: number of evaluations (labels bought), wall-clock
  runtime. Budgets stated up front.
- Explanation quality: fidelity, sparsity/size, stability
  across reruns [verify: field consensus still forming;
  cite Doshi-Velez & Kim for the evaluation taxonomy].

## Statistics

- 20+ repeats per (dataset, treatment); distributions,
  not means (boxplots or equivalent).
- Significance AND effect size, conjunctively:
  non-parametric (bootstrap + Cliff's delta, or
  Mann-Whitney + A12). Never significance alone
  (named antipattern).
- Multi-treatment ranking: Scott-Knott over the repeated
  results.
- Same seeds, published; splits reproducible.

## Reporting

- Replication package conforming to SIGSOFT artifact
  standards: code, data, seeds, analysis scripts, raw
  results.
- Construct-validity paragraph: why these measures
  measure the claim.
- Tailoring disclosure: benchmark curation predates the
  proposed method; include tasks where the method loses.
