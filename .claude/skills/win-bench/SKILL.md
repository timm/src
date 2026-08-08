---
name: win-bench
description: Use when evaluating any label-budget optimizer or data squeezer in this repo (rp/, ezr-*), comparing methods that spend labels, or when asked for "win", regret, or an honest baseline for best-found results.
---

# win-bench: honest scoring for label-budget methods

Score = **win**, the normalized regret complement (ezr's
TBL.wins; WIN in tut.md):

    win = 100 * (1 - (found - best) / (median - best + TINY))

capped to [-100, 100]. 100 = found the pool best; 0 = no
better than the median row; negative = worse than median.
best/median come from an oracle pass over the whole pool
(evaluation only — never let the method see them).

## Non-negotiables

- **Random arm, matched budget, every table.** If the method
  spent k labels, draw k random rows, take their best, score
  its win. On smooth landscapes 40 random labels reach win
  ~100 — a method that "hits pool best" may be riding a wide
  floor, not skill. Only the gap to random is evidence.
  (2026-08 bench: labeled M tied random at 40+ labels on 8/10
  moot sets; machinery only mattered at ~6 labels or on rough
  landscapes.)
- **20 seeds, report medians** (spread on request). Single
  runs of stochastic squeezers wobbled +-25% on survivor
  counts and flipped win by 20+ points.
- **Count labels honestly.** A "free" (unsupervised) arm's
  answer costs len(survivors) labels to cash out — report
  it as `0 (+k to cash)`.
- **Same disty for all quantities** in one table. Capped
  percentile norms make wide 0.00 floors; win washes that
  out ONLY if found/best/median share the metric.

## Arms ladder (report all that apply)

1. free squeeze + label all survivors (~12 labels)
2. free + label one per nearest pair (~6; assumes x-near =>
   y-near — loses where landscape is rough, e.g. LLVM)
3. labeled/gradient rounds (~40+; only arm that helps on
   rough tables: coc1000, Scrum1k)
4. random at each arm's budget

## Traps found the hard way

- Forcing a size cap (top-10 grid) on a table whose
  redundancy profile is flat destroys win (X264: 46 vs
  random 100). Sweep close/cap and read the survivor curve
  first; incompressible tables must keep their rows.
- 2-label smoothness probe (label both ends of one nearest
  pair): agree -> cheap arms are safe; differ -> pay for
  labeled rounds. Decide the arm from data, not habit.
