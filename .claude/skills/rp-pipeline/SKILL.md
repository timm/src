---
name: rp-pipeline
description: Run the rp.py repgrid pipeline (bin, run, report) on a moot csv via rp/Makefile. Use for building or reading rp model files, or auditing label cost.
---

# rp.py: repgrids on a labeling budget

Code: rp/rp.py (~160 lines, stdlib only). Makefile beside it.

## Pipeline

    make X.txt              # X.csv found in cwd, else anywhere under $MOOT
    make X.txt D=/some/dir  # explicit csv dir (wins over MOOT)

expands to:

    python3 rp.py bin X.csv 6 > X_b.csv        # raw -> binned (goals stay raw)
    python3 rp.py run X_b.csv 3 6 .1 1 5 > X.txt   # N eras eps seed Check
    python3 rp.py report < X.txt

Makefile vars (override on command line): D BINS K FAR P SEED,
MOOT (default ~/gits/timm/moot). vpath searches every MOOT subdir;
5 basenames are duplicated across moot (auto93, Hall, Kitchenham,
Radjenovic, Wahono) — vpath takes first hit, use D= to disambiguate.

## Model file layout (tab-separated tags)

- `meta` — eps, B, N, eras, check, heaven vector
- `con`  — surviving construct + fused kin
- `ele`  — delegates, sorted best (lowest d2h) first
- blank line
- `tst`  — first `check` rows labeled and sorted on TRUE d;
  blank line; rest sorted on guess only (zero labels)

## Label accounting (be honest in writeups)

- Cost = #ele lines + check. Delegates EMERGE from N*eras*eps,
  not set directly; auto93 saturates ~18 delegates at eps=.1
  (cover complete). More labels needs smaller eps (eps=.05 ->
  ~25-36 depending on eras/seed).
- Known leak: run()'s lohi normalization reads y of ALL train
  rows (N*eras), not just delegates. Small; fix = lohi from
  delegate leads only.
- `d=` on every tst line and all report metrics (acc, mae,
  spread, pool best) are oracle/evaluation numbers, never used
  by the method's ranking.
