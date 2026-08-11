---
name: grid-from-table
description: Use when building a repertory grid, delegate/medoid model, or few-rows-few-cols summary from a tabular csv (rp/, moot data), or when deciding what to retain for sorting vs optimizing a holdout.
---

# grid-from-table: the validated recipe

Six steps; 1-4 and 6 are the machine, 5 is display only.
Working exemplars: rp/rp.py (full pipeline, holdout rho .77
auto93), rp/rp0.py (step 2 alone). Full option map with
evidence tags: rp/DESIGN.md.

1. ONE ROOT ORACLE. Coerce cells EAFP (`thing`: float or
   the string). Normalize nums by percentile saturation
   (below f -> 0, above 1-f -> 1; f=.15); enum syms. Fit
   once; never re-fit per subset.
2. ELEMENTS = eps-cover over rows, UNSUPERVISED. Stream:
   >= eps from every delegate -> founds one; else fuses
   into nearest delegate's kin. eps = close * MU of sampled
   pair distances (NOT sd — sd is spread-around-mu and
   collapses on tight tables). Warm-up on RANDOM rows
   (sorted csvs make file-order neighbours twins). close=1
   -> 4-16 delegates on every moot table; close=.3 -> a
   redundancy profile (only twin-rich tables shrink).
3. CONSTRUCTS = same cover on the transpose, over the
   element grid only. Optional for accuracy (ablation:
   reduced vs all cols barely moves rho) — it buys
   measurement cost + grid readability, not signal.
4. RATINGS = binned element values per construct; '?' -> 0.
5. DISPLAY (never affects 6): FOCUS seriation (any
   clustering is free at <=20 items; Ward ok here, and only
   here), pole names from column lo/hi, merge identical
   elements with xN counts, annotate elements with d2h and
   kin majority class, sort best-first.
6. LABEL THE MEDOIDS — one real, labelable row per kin
   group, paid AFTER structure is fixed; the bill is
   countable before buying. Then knn to nearest element:
   classify = kin majority class (kin labels free in
   classification data); regress = kin mean IF labels free,
   else the element's own label; optimize = rank holdout by
   nearest element's d2h, confirm top-check.

## The law this recipe obeys (measured, 2026-08)

RETENTION DECIDES THE PRODUCT. Coverage retention (keep
every delegate the cover emits, good AND bad) sorts
holdouts: rho .77 auto93 / .55 SS-M at ~18 labels. Trophy
retention (cull dull and bad — m.py, cells.py) optimizes
(win ~100 at 30 labels) but CANNOT sort (rho <= 0, negative
top-decile lifts). Sorting needs the bad delegates that
optimizing throws away. Default to coverage; trophy mode is
an optimizer flag.

## Ancestors (for writeups)

Gaines & Shaw (FOCUS, Induct, WebGrid: grid -> rules),
Hart CNN / prototype selection, Salzberg NGE, Domingos
RISE, CBR; leader clustering (Hartigan), canopy (McCallum
2000), Gonzalez'85 covers. KS = Chebyshev distance between
CDFs; Chebyshev (max-gap) is the correct twin-merge test
(indistinguishable EVERYWHERE), minkowski p=2 the house
distance elsewhere.
