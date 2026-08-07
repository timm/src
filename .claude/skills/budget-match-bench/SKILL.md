---
name: budget-match-bench
description: Compare rp.py vs ezr-lua at a matched labeling budget over 20 seeds; report best-found d2h distributions. Use to reproduce or extend the auto93 numbers.
---

# Budget-matched bench: rp.py vs ezr-lua

Question: with the same number of labels, whose best-found row
has lower d2h? 20 seeds each, report sorted d list + median.

## Procedure

1. Pick budget T. Both sides spend T = train-labels + check(5).
2. ezr side (adaptive acquire, budget is a direct knob):

       cd ezr-lua
       for j in $(seq 1 20); do
         lua ezr-eg.lua --budget=$T --check=5 --seed=$j --holdout
       done   # prints {:disty D :win W}; D is the score

3. rp side (cost EMERGES: #delegates + 5). First probe eps/eras
   until `grep -c '^ele'` + 5 lands near T, then:

       cd rp
       for s in $(seq 1 20); do
         python3 rp.py run X_b.csv 3 ERAS EPS $s 5 |
           grep -m1 '^tst'   # first tst line: d= is best-of-check
       done

   Log actual per-seed cost next to d — it varies (+/-3).
4. Compare sorted distributions + medians. Caveats to state:
   d2h normalizations differ slightly (ezr disty: whole table,
   p=2; rp: train lohi), and splits differ (ezr half/half; rp
   trains N*eras, tests rest).

## Known results (auto93, 2026-08)

- T=18: ezr median .15, rp median .21. rp bimodal — 6/20 runs
  land <=.09 (beats ezr's best mode), rest .19-.38.
- T=32: ezr median .135, rp median .20 (eras=11 eps=.05,
  cost 28-34). rp flat vs T=18 and worst case worsened (.49).
- Why: furthest-point cover spends extra labels on coverage
  (bad corners included), not exploitation; ezr acquire adapts.
  rp story = fixed small cost + explainable grid, NOT a
  budget-scalable optimizer.

## Traps

- zsh: `echo ===X===` fails (= triggers path expansion); quote it.
- rp delegates saturate at eps=.1 on auto93 (~18); raising eras
  alone will not raise cost past that.
