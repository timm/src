---
name: softgoals-isamp
description: Run and extend the softgoals keys pipeline (sample worlds, d2h, unanimity filter + ddmin seeds) in python (syntax/infer/run.py) or lisp (nfr5/rig.lisp). Use for keys tables, world sampling, or engine changes.
---

# softgoals keys: sample -> best -> filter -> ddmin -> assess

Two engines, one table:

    make keys          # python, ~5s   (Mersenne rng)
    make keys-lisp     # lisp,  ~1.2s  (park-miller; regenerates
                       #   models/*.lisp via to-lisp.py first)
    ./run.py -n1 256 -seed 3 models/CSServices.py
    ./small.py         # a theory file runs itself

Layout: syntax.py = authoring algebra (`h <= b*c + d`, compiled
to plain tuples at `<=` time); infer.py = isamp interpreter;
run.py = pipeline; nfr5.lisp + rig.lisp mirror engine+pipeline;
to-lisp.py regenerates the sexpr models (python is source of
truth). Prolog originals: branch prolog1. REPORT_keys.md is the
paper draft -- every number reproduces from make.

## Semantics (doctrine B) -- do not forget

- Bare atom = LABEL, never a demand. Only `X=V` demands kill a
  world. Derive-then-insist is `(must x)` (= `(seq x (= x t))`,
  python `must(x)`); ordered form is load-bearing -- a shuffled
  and() runs the demand first and fiats the goal.
- Failed derivation = denial (X=f), not death. Leaves abduce t.
  Denial is SAMPLED failure (one body tried), weaker than NAF;
  sound because bodies are negation-free (f never a premise,
  only consumed by demands and or-delivery).
- or is a BET (since 2026-08-30): picked branch must be
  `delivered` (no denied task inside) or the or fails. Killed
  the vacuous-or bug; models no longer need must-gating.
- replay mechanisms, commented in both engines: intake ADOPT
  (abducible + f labels preload) / RE-EARN (believed-t defined
  atom -> internal (must x); can't re-earn = dead world); walk
  STEER (or takes settled+delivered branch) / CITE (won subtree
  not rederived) / YIELD (links defer to labels; = never yields).
- Seed ONLY settable labels (leaves + or-alternatives): seeding
  heads assumes the conclusion, seeding qualities assumes the
  happiness.
- In isamp's or-row, `(or (and replay settled) bet)` is NOT
  `(if replay settled bet)` -- replay-with-no-settled-branch
  must fall through to the bet.
- PM rng needs `reseed` (3 warmup draws): small seeds' first
  draw ~ seed/2^31, so ors always pick branch 0 without it.

## Hard-won engine facts

- Undo is a trail, not a snapshot: 20% faster than dict-copy in
  python; lisp trail is a let-over-defun closure (add/mark/
  undo/wipe -- `reset` is package-locked by sb-profile).
- Worlds: hash/dict, never alists -- O(n) alist reads made the
  replay-heavy pipeline 6x slower (README has both lessons).
- CPython `match` with `('and', *xs)` patterns copies the tail
  per visit: hot paths use hand dispatch on g[0].
- Atom is a value object (__eq__/__hash__ by name); without it
  two Atom("x") split-brain RULES silently.
- Never price two optimizations from one diff (the trail's win
  hid behind match's regression at first measurement).

## Report conventions

Table = d2h x100 ints, seed 1, columns mu,sd,best,muSeed,
sdSeed,cands,|seed|,tests,%seed. Claims to keep synced when
rerunning: seed sizes (1-13 labels, 1-5%), muSeed 1.8-2.8 sd
below random mean, KidsandYouth structural floor (35, sd 0),
FDandMarketing luck gap (177 helps vs 1 hurt).
