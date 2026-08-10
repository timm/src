---
name: moot-sweep
description: Sweep the moot corpus to find datasets where a method beats its baseline, and prove the finding is not seed noise. Use before quoting any "our method wins on dataset X" number in a paper, lecture, or README.
---

# Finding a dataset that really beats the baseline

A single `--holdouts` run over the corpus produces a leaderboard
that is mostly **noise**. Confirming a winner takes a second
pass. Skip it and you will publish a result that flips when a
reader changes the seed.

## Step 1: sweep (126 tables x 6 budgets, ~85s on 8 cores)

    ls $MOOT/optimize/*/*.csv | grep -v '/test/' | while read f; do
      for b in 10 12 16 20 28 40; do echo "$f $b"; done
    done | xargs -P 8 -n 2 sh -c '
      r=$(lua ezr-eg.lua --budget=$1 --file=$0 --holdouts | tail -1)
      ... parse :active :random :verdict, print one TSV row'

Rank candidates by how many budgets give a `land` verdict.

## Step 2: DO NOT TRUST STEP 1. Re-run the top few.

`--holdouts` does 20 repeats seeded from `the.seed + j`, so
changing `--seed` gives an independent set of 20. Run the
leaders under 4-8 different `--seed` values and count wins,
ties, and **losses**.

2026-08 numbers, the whole reason this skill exists:

| dataset | first pass | on re-run |
|---|---|---|
| process/pom3d | +26, best in corpus | rand -10, tie -1, rand -10 |
| process/xomo_osp2 | +20 | tie -4, rand -10 |
| binary_config/Scrum1k | +19 | tie -1, rand -8 |
| systems/HSQLDB | +18 | tie -4, tie -6, tie -4 |
| **behavior_data/all_players** | +17 | **7 land, 1 tie, 0 loss over 8 seed sets** |

The biggest first-pass margin in the corpus was noise. Only
`all_players` (budget 20) survived. Report mean gap AND the
per-seed list, so a reader sees the spread.

## Step 3: check the budget curve, not one budget

The gap is not monotone. On all_players: +1.2 at budget 12,
**+8.5 at 20**, +6.6 at 30, +3.4 at 50, +4.6 at 80. Random
catches up as the budget grows, so the honest claim is "same
answer, sooner", not "better answer". Below ~12, `budget -
check` leaves too few labels for acquire to cull anything and
the two arms become identical.

Corpus-wide across 756 runs: land 131, rand 92, tie 533. The
random arm is the control, not a formality.

## Step 4: read the data before you build a story on it

`all_players` is FIFA video-game ratings (see the moot README in
that directory). Checking it turned up three kinds of dirt:

- **11 constant columns** (Name, Position, Nation, Team, url,
  ...) anonymised to `0` and left in.
- **5 mean-imputed columns**: 15,738 of 17,737 rows carry the
  identical 8-decimal float `GK Diving = 65.88294147`.
- **`Rank` has 139 distinct values** for 17,737 rows; 1,099 tie
  at rank 9009. It is binned, not an ordering.

So 16 of 57 columns carry no signal. None of this changes the
rankings (dead columns scale every distance by a constant, a
monotone transform), but it changes what you may claim.

Also check for **definitional leaks**: PHY correlates +0.836
with goal `Strength+` because FIFA computes PHY *from* Strength.
Test it by renaming the column to `PHYX` (trailing X = ignore)
and re-running. Result: best-leaf d2h held at 0.05-0.06, but the
win gap fell +8.2 -> +2.0, and only recovered (+7.9) once the
whole composite family (PHY, Jumping, Stamina, Aggression) was
ignored. A partial fix was worse than none.

## Traps

- zsh: `set -- $spec` inside a `for` loop silently fails to
  split. Use `while read -r a b; do ... done <<EOF`.
- moot's default branch is **master**, not main. A
  `refs/heads/main.zip` URL 404s.
- `--cap` (default 1024) samples the pool. Headline row counts
  must say which pool was used; `--cap=20000` on all_players is
  ~15s per `--holdouts` versus 0.4s capped.
- One `land` verdict is one coin flip. Never quote it alone.
