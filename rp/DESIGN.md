{% raw %}
# DESIGN.md: the option space around M (rp/m.py)

M grew from a spec sketched in conversation (2026-08-08). At
several points the spec was open to readings, and at several
more there are credible alternatives nobody has benched. This
note maps that space, so if the current build underperforms we
know which knob was a *choice*, not a law. Evidence tags:
[bench] = 20 seeds x 10 moot sets, win vs matched-budget
random (see skills/win-bench); [none] = untested.

## 1. Normalization

- CHOSEN: 10th/90th percentile lo-hi, capped 0..1; outliers
  saturate. Syms enum-ranked to 0..1.
- Alts: logistic cdf over Welford mu/sd (rpl1, ezr house);
  plain min-max (outlier-fragile); sym as 0/1-distinct only
  (ezr) rather than ordinal rank.
- Note: the cap makes wide 0.00 floors in disty — win washes
  that out, raw "best d2h" comparisons across metrics do not.

## 2. Distance

- CHOSEN: minkowski over shared cells, p=2; missing cells
  jumped (Gower pairwise deletion); nothing shared = 1.
- [bench] p=1 vs p=2: labelled arm statistically same 8/10
  (diffs are at-ceiling tails); FREE arm really differs 6/10,
  both directions (p=1 better SS-O/SS-I; p=2 rescued X264).
  p is a live knob only when labels are off.
- Alts: pessimistic "?" (ezr: assume max gap) — bad here,
  novelty mints delegates = spends budget; 0-sentinel (treats
  missing as extreme low; rejected in rp.py already).

## 3. Anchor selection (where labels go)

- CHOSEN: greedy eps-net in shuffled order, eps = close * sd
  of the.some free distance probes; stop at the.anchors.
  Twins never both labeled (dedup lives HERE, not in culling).
- Alts: kpp d^2-weighted seeding; Gonzalez true-farthest
  (fringe-prone; earlier designs pulled back to far=.85 for
  this reason); pure random (wastes labels on twins). [none]

## 4. View weight w (one per anchor pair)

- CHOSEN: labeled rounds w = |dy|/dx (sampled gradient);
  free rounds w = dx (long baselines count more).
- Alts: w = 1 (all views equal); w = |dy| alone; w = 1/dx
  (short baselines = local detail). [none]

## 5. Item mark (THE ambiguous spec point)

Spec said "mark items with their sum of the d score"; d
belongs to pairs, so items need a reading. 
- CHOSEN: distinctiveness. mark[i] = sum over views of
  w * |pos[i] - med|: "how unusual am I, summed over the
  informative directions". Cull LOW marks (the dull middle
  looks average from every angle). Median not mean
  (robust); abs not squared (respect the cap).
- Alt A: dullness. mark[i] += w when i lies BETWEEN the
  anchors (Thales sphere / segment test); cull HIGH marks.
  This is the sphere-culling design (see 7) rephrased.
  [none as a mark scheme]
- Alt B: raw pos (sign depends on which anchor is "a" —
  broken); squared deviation (outlier-amplifying). Rejected
  on argument, not data.

## 6. Cull rule

- CHOSEN: keep mark >= top * max(mark) (top=.5), anchors
  always survive.
- Alts: keep top-k; keep above a mark percentile (scale-free
  vs the max, which one weird item can inflate); cull only
  HALF the losers at random — the sentinel idea: survivors
  in every culled zone can falsify a bad verdict later.
  Sentinels were a settled feature of the sphere design and
  were silently lost in the move to marks. [none]

## 7. Lineage: the abandoned designs (kept as ablations)

- rpl1.py tournament: shuffle, pop pairs, kill the less-vary
  twin under eps = close * sd of the seen-distance stream;
  generational, stops after dry barren gens. Unsupervised
  twin-dedup; [bench] compresses twin-rich tables only, and
  that selectivity is a feature (redundancy profile).
- Sphere y-culling (designed, part-built in rpl1): probe pair
  at reach*sd, Thales-sphere interior, dull verdict from
  eps * sd of labels, cull half at random. Subsumed by M but
  its two good ideas — sentinels (see 6) and the 2-label
  smoothness probe (see 8) — did not all survive the move.

## 8. Label placement policies (the arms ladder) [bench]

- labelled sweeps (~40 lbls): win 100 smooth, 75-85 rough;
  only arm that helps on rough tables (coc1000, Scrum1k).
- free + label all survivors (~12): win ~100 on smooth.
- free + one label per nearest survivor pair (~6): beats
  random 6/10; loses where x-near is y-far (LLVM, SS-O).
- OPEN: adaptive M-v3 — spend 2 labels on both ends of one
  nearest pair; agree -> stay cheap, differ -> escalate to
  labelled rounds. Dominates the ladder on paper. [none]

## 9. Cap (grid-sized output)

- CHOSEN: keep the cap best-marked rows/cols (cap=10).
- [bench] harmless on compressible tables; at p=1 it
  destroyed X264 (win 46 vs random 100) — forcing 10 rows
  onto a flat redundancy profile throws away the floor.
  p=2 rescued that case, but the lesson stands: sweep close
  and read the survivor curve before trusting a forced cap.

## 10. Termination

- CHOSEN: fixpoint — stop when neither axis shrinks; kills
  are monotone so this must arrive. Budget guards the
  labelled sweeps independently.
- Alts: barren-generation patience (rpl1); pure budget.

## 11. Ward clustering: rejected for inference, ok as typography

Stochastic culling already at win ceiling; rough tables are
label-limited, not merge-order-limited; Ward is O(n^2) for
precision nobody can measure. At display time (<=20 items)
Ward is free and its merge costs annotate the seriation.

## 12. Two masters (the day's big result, measured)

One survivor set cannot both optimize and sort. Trophy
retention (cells/M: cull dull+bad) -> win ~100 at 30 labels
but holdout Spearman rho <= 0 (auto93 -0.28, LLVM top-decile
lift NEGATIVE). Coverage retention (rp.py: keep every
eps-cover delegate, good AND bad) -> rho 0.77 auto93 / 0.55
SS-M / 0.43 LLVM at similar cost. Sorting needs the bad
delegates that optimizing deliberately discards. The unified
repgrid bundle (grow+prune+classify+regress+optimize+explain;
Gaines&Shaw Induct/FOCUS, Salzberg NGE, Domingos RISE, CBR
are ancestors) therefore uses COVERAGE as the default;
trophy mode is an optional optimizer flag.

## 13. cells.py + rp0.py lessons

- cells (cell-granularity scores): culling is regret-free
  (pick win == survivor win, 20 seeds x 10 sets) but score =
  rowterm+colterm is SEPARABLE — the cell layer is
  bookkeeping until a cell-local term (rarity, cell dy,
  surprise) is added. Its knn holdout ranking does NOT work
  (see 12).
- rp0 (unsupervised eps-cover, labels only for medoids,
  paid at the end): eps = close * MU of sampled pair
  distances — sd is spread-around-mu and collapses on tight
  tables. Warm-up must sample RANDOM rows (sorted csvs make
  file-order neighbours twins; auto93 227 -> 38 delegates on
  fixing this). close sweep: .3 = redundancy profile (only
  twin-rich tables shrink); 1.0 = 4-16 delegates on EVERY
  table (label bill visible before buying). Label the MEDOID
  (a real, labelable row), never the centroid.

## Standing questions

1. Mark semantics A/B (5) is the biggest untested fork.
2. Sentinel culling (6) may matter exactly on the rough
   tables where everything else struggles.
3. M-v3 adaptive policy (8) is specified and unbuilt.
4. Free-arm p sensitivity (2) suggests the free arm's
   geometry is under-determined — worth understanding
   before trusting free-mode results on new data.
5. rp0 at close=1.0: do the 4-16 labeled medoids SORT the
   holdout (rp.py's 18 gave rho .77)? The coverage thesis
   predicts yes; unbenched.

{% endraw %}