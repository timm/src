#!/usr/bin/env python3 -B
"""
xaiplus: learners and optimizers layered on xai (which it
never edits, bar one hook).
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 xaiplus-eg.py [--key=val ...] [test ...]

OPTIONS (added to xai's `the`; new names, never old):
  --knn     neighbors for the knn classifier = 3
  --kluster clusters for kmeans / kmeans++   = 8
  --iters   kmeans passes                    = 10
  --few     sample pool for kmeans++ seeding = 128
  --k       naive-bayes laplace smoothing    = 1
  --m       naive-bayes m-estimate weight    = 2
  --wait    rows seen before bayes scores    = 10
  --F       DE extrapolation factor          = 0.5
  --cr      DE crossover rate                = 0.3
  --np      DE/GA population size            = 20
  --gens    DE/GA generations                = 20
  --tour    GA tournament size               = 5
  --budget1 SA/LS eval budget                = 300
  --restart LS restart-on-stagnation gap     = 40
  --start   acquire warm-start labels        = 20

Each learner and optimizer -- knn, kmeans, naive bayes,
DE, GA, SA, local search, racing, synthesis, anomaly -- is
a plain function over a xai Tbl. After ezr-lua/xaiplus.lua.
"""
from contextlib import contextmanager
from math import exp, log, pi
import xai
from xai import *

def addopts(doc):
  "Add my --key=val defaults to xai's `the` (new keys only)"
  for k,v in re.findall(r"--(\w+)\s+[^=\n]*=\s*(\S+)", doc):
    assert not hasattr(the,k), "xaiplus reuses xai option: "+k
    setattr(the, k, thing(v))

addopts(__doc__)


#-- knn ---------------------------------------------------------
# k-nearest-neighbor classifier: a row's klass is the mode
# of its k closest rows' klasses (distx from xai). No fit
# step -- the data IS the model. Needs a "!" klass column.
# The k rows of tbl nearest r0, by distx

def near(tbl, r0, k=None):
  return sorted(tbl.rows,
                key=lambda r: distx(tbl,r0,r))[:k or the.knn]

def nearest(tbl, r0, rows=None):
  "The one row nearest r0: no sort, one pass"
  return min(rows or tbl.rows, key=lambda r: distx(tbl,r0,r))

def knn(tbl, r0, k=None):
  "Predict r0's klass = mode of its k neighbors' klasses"
  at = tbl.klass
  return mid(adds((r[at] for r in near(tbl,r0,k)), Sym()))


#-- kmeans ------------------------------------------------------
# k clusters: drop each row into its nearest centroid, move
# the centroids to their members' middle, repeat. A
# centroid is just a `mids` row; a cluster is a xai clone.
# One pass: each row into its nearest centroid's clone

def assign(tbl, cents):
  out = [clone(tbl, []) for _ in cents]
  for r in tbl.rows:
    add(out[min(range(len(cents)),
                key=lambda j: distx(tbl,cents[j],r))], r)
  return out

def recentre(clusters):
  "Centroids = the middle of each non-empty cluster"
  return [mids(c) for c in clusters if c.rows]

def kmeans(tbl, k=None, iters=None):
  "K clusters: iters rounds of assign then recentre"
  cents = some(tbl.rows, k or the.kluster)
  for _ in range(iters or the.iters):
    cents = recentre(assign(tbl, cents))
  return assign(tbl, cents)


#-- kmeanspp ----------------------------------------------------
# kmeans++ seeding: centroids far apart. Each new centroid
# is drawn from a small random pool, with chance
# proportional to its squared distance to the nearest
# centroid so far (the d^2 trick). Returns the seed rows.
# Squared distance from r to its nearest centroid

def d2(tbl, cents, r):
  return min(distx(tbl,r,c)**2 for c in cents)

def farther(tbl, cents, few=None):
  "One more centroid: d^2-weighted pick from a random pool"
  pool = some(tbl.rows, few or the.few)
  ws   = [d2(tbl,cents,r) for r in pool]
  n    = sum(ws) * random.random()
  for r,w in zip(pool, ws):
    if (n := n - w) <= 0: return r
  return pool[-1]

def kpp(tbl, k=None, few=None):
  "K centroids by kmeans++ seeding"
  cents = some(tbl.rows, 1)
  while len(cents) < (k or the.kluster):
    cents += [farther(tbl, cents, few)]
  return cents


#-- bayes -------------------------------------------------------
# naive Bayes likelihoods. `like` = P(v | col): a Sym
# m-estimate, or a Num gaussian pdf. `likes` = the log-sum
# likelihood of a whole row under one klass's model (a xai
# Tbl holding just that klass's rows).
# P(v|col): Sym m-estimate, else Num gaussian pdf

def like(col, v, prior):
  if is_sym(col):
    return (col.get(v,0) + the.k*prior)/(size(col) + the.k)
  z = 2*sd(col)**2 + TINY
  return exp(-(v - mu_(col))**2/z)/(pi*z)**.5

def likes(h, row, nrows, nh):
  "Log-likelihood of a row under klass model h (a xai Tbl)"
  prior = (len(h.rows) + the.m)/(nrows + the.m*nh)
  out   = log(prior)
  for at in h.x:
    if (v := row[at]) != "?":
      if (l := like(h.cols[at], v, prior)) > 0:
        out += log(l)
  return out

def mostlikes(h, row, nrows, nh):
  "Klass in h (a dict klass -> Tbl) most liking the row"
  return max(sorted(h),
             key=lambda k: likes(h[k], row, nrows, nh))


#-- classify ----------------------------------------------------
# Incremental naive Bayes, test-then-train: for each row,
# predict its klass from the models seen so far, keep the
# (got,want) pair, then train the true klass's model. One
# pass, no held-out split.
# Fraction of seen (got,want) pairs that agree

def acc(seen):
  return sum(g == w for g,w in seen)/(len(seen) + TINY)

def classify(tbl, wait=None):
  "Test-then-train naive Bayes; returns the (got,want)s"
  wait, at = wait or the.wait, tbl.klass
  h, seen  = {}, []
  for i,row in enumerate(tbl.rows, 1):
    want = row[at]
    if i >= wait and h:
      seen += [(mostlikes(h, row, len(tbl.rows), len(h)),
                want)]
    if want not in h: h[want] = clone(tbl, [])
    add(h[want], row)
  return seen


#-- mutate ------------------------------------------------------
# Mutators for the optimizers. xai's `pick` samples one
# fresh value (Sym roulette, Num gaussian); `picks` mutates
# n random x cells; `extrapolate` is DE's a + F*(b - c),
# with one column always kept from a, so a kid never fully
# forgets its base.
# Copy row; mutate n of its x columns via pick

def picks(tbl, row, n=1):
  out = row[:]
  for at in shuffle(tbl.x)[:n]:
    out[at] = pick(tbl.cols[at], out[at])
  return out

def extrapolate(tbl, a, b, c, F=None, cr=None):
  "DE blend a + F*(b - c) per x col; one col kept from a"
  F, cr = F or the.F, cr or the.cr
  out, keep = a[:], random.choice(tbl.x)
  for at in tbl.x:
    col = tbl.cols[at]
    if at != keep and random.random() < cr:
      va, vb, vc = a[at], b[at], c[at]
      if   va == "?"    : out[at] = "?"
      elif is_sym(col)  :
        out[at] = vb if random.random() < F else va
      elif "?" in (vb, vc): out[at] = va
      else:
        v      = va + F*(vb - vc)
        lo, hi = mu_(col) - 4*sd(col), mu_(col) + 4*sd(col)
        out[at] = lo + (v - lo) % (hi - lo + TINY)
  return out


#-- optimize ----------------------------------------------------
# Shared gear. `surrogate` hooks xai's `labelled` so disty
# can score any row -- even a synthetic one -- by snapping
# it to its nearest real row (a cheap surrogate for the
# true, expensive objective; identity on real rows). Every
# optimizer below MINIMIZES the hooked disty and returns
# its best row.

@contextmanager
def surrogate(tbl):
  "Hook disty: any row scores via its nearest real row"
  b4, xai.labelled = xai.labelled, lambda r: nearest(tbl,r)
  try: yield lambda r: disty(tbl, r)
  finally: xai.labelled = b4


#-- de ----------------------------------------------------------
# Differential evolution. A population of rows; each
# generation every parent spawns a DE kid (blend three
# random pop rows via extrapolate) that replaces the parent
# when the hooked disty scores the kid better.

def de(tbl):
  "Differential evolution; returns the best row found"
  with surrogate(tbl) as y:
    pop = some(tbl.rows, the.np)
    for _ in range(the.gens):
      for i,parent in enumerate(pop):
        a,b,c = some(pop, 3)
        kid   = extrapolate(tbl, a, b, c)
        if y(kid) < y(parent): pop[i] = kid
    return min(pop, key=y)


#-- ga ----------------------------------------------------------
# Genetic algorithm. Each generation: mutate the whole pop
# (one cell each), then refill by one-point crossover of
# two tournament-picked parents.
# Lowest-scoring row among the.tour random pop rows

def tourney(pop, y):
  return min(some(pop, the.tour), key=y)

def cross(tbl, mum, dad):
  "One-point crossover of two rows over the x columns"
  kid, cut = mum[:], random.randrange(len(tbl.x))
  for j,at in enumerate(tbl.x):
    if j > cut: kid[at] = dad[at]
  return kid

def ga(tbl):
  "Genetic algorithm; returns the best row found"
  with surrogate(tbl) as y:
    pop = some(tbl.rows, the.np)
    for _ in range(the.gens):
      pop = [picks(tbl, r, 1) for r in pop]
      pop = [cross(tbl, tourney(pop,y), tourney(pop,y))
             for _ in range(the.np)]
    return min(pop, key=y)


#-- sa ----------------------------------------------------------
# Simulated annealing, (1+1). From one row, repeatedly
# mutate one cell; always keep a better kid, and sometimes
# a worse one (metropolis, cooling as the budget spends).

def sa(tbl):
  "Simulated annealing; returns the best row seen"
  with surrogate(tbl) as y:
    s  = random.choice(tbl.rows)
    es = y(s); best, eb = s, es
    for h in range(1, the.budget1 + 1):
      kid = picks(tbl, s, 1)
      e   = y(kid)
      if e < es or random.random() < exp(
          (es - e)/(1 - h/the.budget1 + TINY)):
        s, es = kid, e
      if e < eb: best, eb = kid, e
    return best


#-- ls ----------------------------------------------------------
# Greedy local search, (1+1) with restarts. Keep only
# strict improvements; after `restart` steps with no new
# best, jump to a fresh random row.

def ls(tbl):
  "Greedy local search; returns the best row found"
  with surrogate(tbl) as y:
    s  = random.choice(tbl.rows)
    es = y(s); best, eb, imp = s, es, 0
    for h in range(1, the.budget1 + 1):
      kid = picks(tbl, s, 1)
      e   = y(kid)
      if e < es: s, es = kid, e
      if e < eb: best, eb, imp = kid, e, h
      if h - imp > the.restart:
        s, imp = random.choice(tbl.rows), h
        es     = y(s)
    return best


#-- race --------------------------------------------------------
# Race the optimizers head to head: run each on one
# dataset, score its best row by the hooked disty, return
# them ranked best first. A cheap answer to "which search
# wins here?".

def race(tbl):
  "(name, score) per optimizer, best first"
  with surrogate(tbl) as y:
    return sorted(((f.__name__, y(f(tbl)))
                   for f in (de, ga, ls, sa)),
                  key=lambda p: p[1])


#-- sample ------------------------------------------------------
# Synthesize new rows. Grow a tree, then for each new row
# pick a leaf and DE-blend three of its rows -- so
# synthetic rows land inside real, coherent regions, not in
# the voids between them.

def sample(tbl, n=100):
  "N synthetic rows, each a DE-blend inside one tree leaf"
  t   = tree(tbl, tbl.rows)
  big = [l for l in leaves(t) if len(l.rows) >= 3]
  out = []
  while big and len(out) < n:
    a,b,c = some(random.choice(big).rows, 3)
    out  += [extrapolate(tbl, a, b, c)]
  return out


#-- acquire -----------------------------------------------------
# The HISTORIC active learner, kept for comparison (xai's
# own acquire uses poles; this one does not). Label a
# warm-start, split it best/rest by sqrt(N), then
# repeatedly label the top-scored unlabeled row and re-cap
# best. Two scorers: Bayes likelihood, or centroid
# distance.
# Score: like(best) - like(rest); higher = likelier good

def acquire_bayes(tbl, best, rest, row):
  n = len(best.rows) + len(rest.rows)
  return likes(best, row, n, 2) - likes(rest, row, n, 2)

def acquire_centroid(tbl, best, rest, row):
  "Score: dist to rest mid - dist to best mid"
  return (distx(tbl, row, mids(rest))
          - distx(tbl, row, mids(best)))

def acquire_top(tbl, score=acquire_bayes,
                budget=None, start=None):
  "Warm-start, then label the top-scored row per round"
  budget = budget or the.budget
  start  = start or the.start
  rows   = shuffle(tbl.rows)
  lab    = clone(tbl, rows[:start])
  srtd   = sorted(lab.rows, key=lambda r: disty(tbl,r))
  cap    = int(len(srtd)**.5)
  best   = clone(tbl, srtd[:cap])
  rest   = clone(tbl, srtd[cap:])
  unlab  = rows[start:]
  for _ in range(budget):
    if not unlab: break
    unlab.sort(key=lambda r: -score(tbl, best, rest, r))
    add(lab, unlab[0]); add(best, unlab[0])
    unlab = unlab[1:]
    if len(best.rows) > int(len(lab.rows)**.5):
      worst = max(best.rows, key=lambda r: disty(tbl,r))
      add(best, worst, -1); add(rest, worst)
  return lab


#-- anomaly -----------------------------------------------------
# Calibrate a 1-nearest-neighbor distance on the training
# rows (a Num of every row's gap to its nearest OTHER row),
# then score any row's gap against that spread: a high
# normalized score = a lonely row = an anomaly.

def anomaly(tbl):
  "Detector row -> 0..1; high = far from all neighbors"
  gap1 = lambda r: distx(tbl, r, nearest(
    tbl, r, [z for z in tbl.rows if z is not r]))
  dn = adds(gap1(r) for r in tbl.rows)
  return lambda r: norm(dn, gap1(r))
