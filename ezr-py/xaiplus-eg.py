#!/usr/bin/env python3 -B
"""
xaiplus-eg.py: tutorial and tests for xaiplus (library in
xaiplus.py).

Run any test by its bare name; pass --key=val to override:
  python3 xaiplus-eg.py race
  python3 xaiplus-eg.py all

Prose lives in string blocks; every sample is pasted from a
real run, never hand-typed.
"""
from xaiplus import *

"""

xai (the engine) knows columns, distance, labels and trees.
This layer spends that vocabulary: classifiers (knn, naive
bayes), clusterers (kmeans, kmeans++), optimizers (DE, GA,
SA, local search), and the odd jobs around them (racing,
synthesis, anomaly detection). Two tables run through these
demos: breast.w (699 biopsies, a "!" klass column) for the
classifiers, and auto93 (398 cars, three goals) for the
optimizers.
"""

DATA = "$MOOT/classify/breast.w.csv"
DOPT = "$MOOT/optimize/misc/auto93.csv"

# Median disty of a tbl's rows
def med(tbl):
  ys = sorted(disty(tbl, r) for r in tbl.rows)
  return ys[len(ys)//2]

# Disty of r's nearest real row (the surrogate score)
def nny(tbl, r): return disty(tbl, nearest(tbl, r))


#-- knn-eg ------------------------------------------------------
"""

No fit step: to classify a row, find its --knn nearest
labelled rows (distx, from xai) and vote. Train on 490
random biopsies, test on the rest.

| call | returns | what |
|------|---------|------|
| `knn(tbl, r0)` | klass | mode of the k nearest klasses |
| `near(tbl, r0, k)` | rows | the k rows nearest r0 |
| `nearest(tbl, r0)` | row | one nearest row, no sort |
"""

def test_knn():
  "3-NN accuracy on a 70:30 split of breast.w."
  d    = Tbl(csv(DATA))
  rows = shuffle(d.rows)
  tr, te = clone(d, rows[:490]), rows[490:]
  ok   = sum(knn(tr, r) == r[tr.klass] for r in te)
  print("3-NN accuracy on breast.w:", round(ok/len(te), 3))
  assert ok/len(te) > 0.9              # easy data, easy win
  assert knn(tr, tr.rows[0]) is not None


#-- kmeans-eg ---------------------------------------------------
"""

Unsupervised now: no klass, just geometry. Drop each row
into its nearest centroid, move each centroid to its
cluster's middle (`mids`), repeat --iters times.

| call | returns | what |
|------|---------|------|
| `kmeans(tbl, k, iters)` | clones | k clusters of the rows |
| `mids(tbl)` | row | the centroid: mid of every column |
"""

def test_kmeans():
  "5 kmeans clusters; every row placed exactly once."
  d  = Tbl(csv(DATA))
  cl = kmeans(d, 5)
  ns = sorted(len(c.rows) for c in cl)
  print("5 clusters, sizes:", ns)
  assert 1 <= len(cl) <= 5
  assert sum(ns) == len(d.rows)        # every row placed once


#-- kmeanspp-eg -------------------------------------------------
"""

Random seeds can land in one clump. The ++ trick: pick each
new seed with chance proportional to its SQUARED distance
from the seeds so far -- far rows likely, clumps unlikely.

| call | returns | what |
|------|---------|------|
| `kpp(tbl, k)` | rows | k seed rows, spread far apart |
"""

def test_kpp():
  "5 kmeans++ seeds; distinct, spread apart."
  d  = Tbl(csv(DATA))
  cs = kpp(d, 5)
  ds = [distx(d, a, b) for i,a in enumerate(cs)
                       for b in cs[i+1:]]
  print("5 kmeans++ seeds, mean pair distance:",
        round(sum(ds)/len(ds), 3))
  assert len(cs) == 5
  assert sum(ds)/len(ds) > 0           # seeds are distinct


#-- bayes-eg ----------------------------------------------------
"""

`like` asks: how likely is value v under this column's
summary? Sym columns use an m-estimate over their counts;
Num columns a gaussian pdf.

| call | returns | what |
|------|---------|------|
| `like(col, v, prior)` | float | P(v given col) |
| `likes(h, row, n, nh)` | float | log-likelihood of a row |
"""

def test_like():
  "Gaussian likelihood: the mean beats 3 sds out."
  d    = Tbl(csv(DATA))
  c    = d.cols[d.x[0]]                # a numeric feature
  hi   = like(c, mu_(c), 0.5)
  lo   = like(c, mu_(c) + 3*sd(c), 0.5)
  print("like at mean vs 3sd out:",
        round(hi, 3), round(lo, 3))
  assert hi > lo                       # typical = likelier
  assert hi > 0


#-- classify-eg -------------------------------------------------
"""

Test-then-train: for each row, guess its klass from the
models seen SO FAR, record (got, want), then train the true
klass's model. One pass, no split.

| call | returns | what |
|------|---------|------|
| `classify(tbl)` | pairs | (got, want) per scored row |
| `acc(seen)` | 0..1 | fraction where got == want |
"""

def test_classify():
  "Test-then-train naive Bayes on breast.w."
  d    = Tbl(csv(DATA))
  seen = classify(d)
  print("naive Bayes accuracy on breast.w:",
        round(acc(seen), 3))
  assert acc(seen) > 0.9
  assert len(seen) > 600               # scored most rows


#-- mutate-eg ---------------------------------------------------
"""

The optimizers bend rows. `picks` copies a row and
resamples n of its x cells (xai's `pick`: Sym roulette,
Num gaussian); `extrapolate` is DE's a + F*(b - c) blend,
one column always kept from a.

| call | returns | what |
|------|---------|------|
| `picks(tbl, row, n)` | row | copy, n cells resampled |
| `extrapolate(tbl, a, b, c)` | row | DE blend of three |
"""

def test_picks():
  "picks(n=3) changes at most 3 x cells."
  d    = Tbl(csv(DATA))
  r    = d.rows[0]
  m    = picks(d, r, 3)
  diff = sum(m[at] != r[at] for at in d.x)
  print("cells changed by picks(n=3):", diff,
        "of", len(d.x))
  assert len(m) == len(r)
  assert diff <= 3                     # at most n changed

def test_extrapolate():
  "extrapolate always keeps >= 1 col from its base."
  d       = Tbl(csv(DATA))
  a, b, c = d.rows[0], d.rows[1], d.rows[2]
  kid     = extrapolate(d, a, b, c)
  same    = sum(kid[at] == a[at] for at in d.x)
  print("x cols kept from base a:", same, "of", len(d.x))
  assert len(kid) == len(a)
  assert same >= 1                     # keep guarantees >=1


#-- de-eg -------------------------------------------------------
"""

Optimization on auto93: find a row with good goals, scoring
candidates by the surrogate -- disty of the nearest REAL
row (synthetic rows never get their own labels). DE: each
parent fights a kid blended from three random pop rows.

| call | returns | what |
|------|---------|------|
| `de(tbl)` | row | best row found, hooked disty |
"""

def test_de():
  "DE beats the median row."
  d    = Tbl(csv(DOPT))
  best = de(d)
  print("DE   best (nearest-real disty):",
        round(nny(d, best), 3), " median", round(med(d), 3))
  assert nny(d, best) < med(d)


#-- ga-eg -------------------------------------------------------
"""

Each generation: mutate everyone a little, then refill by
one-point crossover of tournament winners. GA mixes whole
rows; DE blends arithmetic differences.

| call | returns | what |
|------|---------|------|
| `ga(tbl)` | row | best row found, hooked disty |
"""

def test_ga():
  "GA beats the median row."
  d    = Tbl(csv(DOPT))
  best = ga(d)
  print("GA   best (nearest-real disty):",
        round(nny(d, best), 3), " median", round(med(d), 3))
  assert nny(d, best) < med(d)


#-- sa-eg -------------------------------------------------------
"""

(1+1) search: one current row, one mutated kid at a time.
Better kids always replace; worse kids sometimes do, less
often as the budget cools.

| call | returns | what |
|------|---------|------|
| `sa(tbl)` | row | best row seen, hooked disty |
"""

def test_sa():
  "SA beats the median row."
  d    = Tbl(csv(DOPT))
  best = sa(d)
  print("SA   best (nearest-real disty):",
        round(nny(d, best), 3), " median", round(med(d), 3))
  assert nny(d, best) < med(d)


#-- ls-eg -------------------------------------------------------
"""

Greedy (1+1): keep only strict improvements; after
--restart steps without a new best, jump to a fresh random
row. Restarts are often embarrassingly hard to beat.

| call | returns | what |
|------|---------|------|
| `ls(tbl)` | row | best row found, hooked disty |
"""

def test_ls():
  "LS beats the median row."
  d    = Tbl(csv(DOPT))
  best = ls(d)
  print("LS   best (nearest-real disty):",
        round(nny(d, best), 3), " median", round(med(d), 3))
  assert nny(d, best) < med(d)


#-- race-eg -----------------------------------------------------
"""

Which search wins HERE? Run all four on the same table,
rank their best rows by the hooked disty. The answer is a
ranking, not a winner: on another table the order may flip.

| call | returns | what |
|------|---------|------|
| `race(tbl)` | pairs | (name, score), best first |
"""

def test_race():
  "All four optimizers, ranked best first."
  d    = Tbl(csv(DOPT))
  rank = race(d)
  print("optimizer race (best first):")
  for name, s in rank: print("   ", name, round(s, 3))
  assert len(rank) == 4
  assert rank[0][1] <= rank[-1][1]     # sorted best first
  assert rank[0][1] < med(d)


#-- sample-eg ---------------------------------------------------
"""

New rows without new labels: grow a tree, pick a leaf,
DE-blend three of its rows. Kids land inside real, coherent
regions -- not in the voids between clusters.

| call | returns | what |
|------|---------|------|
| `sample(tbl, n)` | rows | n synthetic, leaf-coherent |
"""

def test_sample():
  "30 synthetic rows, full width."
  d    = Tbl(csv(DOPT))
  rows = sample(d, 30)
  print("synthesized rows:", len(rows),
        " width", len(rows[0]), "of", len(d.names))
  assert len(rows) == 30
  assert len(rows[0]) == len(d.names)  # full-width rows


#-- acquire-eg --------------------------------------------------
"""

The HISTORIC active learner, kept for comparison with xai's
pole-based `acquire`: warm-start some labels, split them
best/rest by sqrt(N), then repeatedly label the unlabeled
row that best separates the two models.

| call | returns | what |
|------|---------|------|
| `acquire_top(tbl, score)` | Tbl | the labelled rows |
| `acquire_bayes(tbl, b, r, row)` | float | like gap |
| `acquire_centroid(tbl, b, r, row)` | float | dist gap |
"""

def test_acquire():
  "Both scorers find a good row under budget."
  d = Tbl(csv(DOPT))
  for score in [acquire_bayes, acquire_centroid]:
    random.seed(the.seed)
    lab = acquire_top(d, score)
    ys  = sorted(disty(d, r) for r in lab.rows)
    print("acquire best disty:", round(ys[0], 3),
          " labels", len(lab.rows))
    assert ys[0] < med(d)
    assert len(lab.rows) > the.start


#-- anomaly-eg --------------------------------------------------
"""

Calibrate on the training rows: a Num summarizing each
row's gap to its nearest OTHER row. A new row far from even
its nearest neighbor gets a high normalized score.

| call | returns | what |
|------|---------|------|
| `anomaly(tbl)` | function | detector: row -> 0..1 |
"""

def test_anomaly():
  "Anomaly scores span 0..1; someone is lonely."
  d   = Tbl(csv(DOPT))
  det = anomaly(d)
  ss  = sorted(det(r) for r in d.rows)
  print("anomaly scores lo/mid/hi:", round(ss[0], 3),
        round(ss[len(ss)//2], 3), round(ss[-1], 3))
  assert ss[0] >= 0 and ss[-1] <= 1
  assert ss[-1] > 0.5                  # some row is lonely


#-- main-eg -----------------------------------------------------
"""

`test_all` finds its tests by name in this file's globals,
reseeding before each so any demo reproduces in isolation.
"""

def test_all():
  "Run every other test_*, reseting the seed before each."
  for n,f in list(globals().items()):
    if n.startswith("test_") and n != "test_all":
      print("\n#", n, "-"*40)
      try: random.seed(the.seed); f()
      except Exception as e:
        print("FAIL:", n, type(e).__name__, e)

if __name__ == "__main__": main(globals())
