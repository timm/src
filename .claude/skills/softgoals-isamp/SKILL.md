---
name: softgoals-isamp
description: Sample, score, and BORE-rank worlds from softgoals goal models with nfr5.pl (isamp). Use for Monte Carlo runs over models/, d2h frontiers, or constraint-feedback experiments.
---

# isamp worlds: sample -> score -> rank -> reseed

nfr5.pl is a ~50-line ISAMP world sampler (one random committed
draw per choice point, no backtracking). All experiments follow
one loop: prep once, sample N worlds, score each, rank labels,
feed winners back as Inits.

## Semantics you must not forget (doctrine B)

- Bare atom = LABEL, never a demand. Only `X=V` demands (and so
  `must/1`, `makes/1`, `breaks/1`) can kill a world.
- `must(X)` = derive X then insist X=t. Query hard goals as
  `isamp(must(start), Inits, World)`; a bare `isamp(g,...)`
  always succeeds and just labels g.
- Leaves abduce to t; failed derivations record `X=f` (denial);
  worlds read three-valued: t / f / unseen.
- Soft links are weighted demands: helps draws from [t,t,f].
  Shrinking bags to their majority collapses to classical logic
  (Zadeh extension principle; see REPORT_extend.md section 4).
- Seeded branch beliefs steer `or` (the pick/2 todo row).

## Pipeline

    cd softgoals && swipl -q -g go -t halt exp.pl

    :- ['nfr5.pl'].  :- ['models/CSServices.pl'].
    go :- set_random(seed(1)), prep(P), mm0(M0),
          % N worlds, folding min/max:
          ...isamp(Goal,[],W), score(P,W,S), mmadd(S,M,M1)...
          % d2h(MM,S,D), msort D-W pairs, best=top 10%,
          % bore = B*B/(B+R) with b,r freqs in best/rest.

score(P,World,score(B,F,S)): B=qualities t (max), F=non-quality
leaves bought (min), S=unseen (diagnostic only -- collinear with
F, never a d2h objective). d2h over B,F only; out-of-range
scores from constrained runs break the normalization -- pool mm
or report raw.

## Constraint feedback rules (hard-won 2026-08-14)

- Seed ONLY controllables: or-branch atoms (`choice/1`) and
  non-head non-quality leaves. Seeding heads assumes the
  conclusion (memo short-circuits derivation); seeding qualities
  assumes the happiness.
- Leaf-seeding alone did nothing on CSServices; choice-seeding
  at k=50 pushed mean B above the best-of-1000 random worlds.
- Rank choices and leaves in separate BORE tables (choices
  dilute below junk in a joint table).

## Traps

- (<--)/2 needs multifile+dynamic+discontiguous or a model file
  wipes nfr5's clauses.
- nfr3-dialect models (models/*.pl) were written for edge-combine
  semantics; nfr5 or-commits one body per world. Distributions
  approximate the mix; single worlds do not.
- `lint.` catches typos/orphans (found real misspellings in
  CSServices). Run it after loading any model.
- Baselines: ~140us/world CSServices (352 clauses); 1000 worlds
  + rank ~0.5s. Numbers in REPORT_extend.md section 5.
