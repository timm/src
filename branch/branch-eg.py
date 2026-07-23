#!/usr/bin/env python3 -B
"""
branch-eg.py: tutorial and tests for branch (in branch.py).

Run any test by its bare name; pass --key=val to override:
  python3 branch-eg.py walk
  python3 branch-eg.py all

One -eg file per engine file, loaded below in tutorial
order; prose lives in string blocks; every sample is pasted
from a real run, never hand-typed.
"""
from bisect import bisect_left, bisect_right
from branch import *

"""

Can a tiny pruned tree, grown from a few actively chosen
labels, sort unseen rows as well as its full parent? One
table runs through this tutorial: auto93 (via $MOOT), 398
cars, goals minimize Lbs-, maximize Acc+ and Mpg+.
"""

#-- data-eg ----------------------------------------------------
"""

`Tbl` types columns from the header (uppercase = numeric,
+/- suffix = goal); `disty` scores a row by distance to the
ideal goal point (0 = best).

| call | returns | what |
|------|---------|------|
| `Tbl(src)` | o | rows, x, y, num, lo, hi |
| `disty(t,row)` | 0..1 | distance to best goals |
"""

def test_tbl():
  "auto93 shape: 398 rows, 3 goals."
  t = Tbl(csv(the.file))
  print(len(t.rows), [t.names[a] for a in t.y])
  assert len(t.rows) == 398 and len(t.y) == 3

def test_disty():
  "Sorting by disty puts light thrifty cars first."
  t  = Tbl(csv(the.file))
  rs = sorted(t.rows, key=lambda r: disty(t, r))
  print(rs[0], "%.3f" % disty(t, rs[0]))
  print(rs[-1], "%.3f" % disty(t, rs[-1]))
  assert disty(t, rs[0]) < .2 < .8 < disty(t, rs[-1])

#-- acquire-eg -------------------------------------------------
"""

`acquire` labels `more` rows per round, then projects the
unlabelled pool onto the line joining its best and worst
labels (FASTMAP-style, via `distx`) and keeps the `best`
fraction nearest the good pole. Labels are dear: it stops
at budget - check.

| call | returns | what |
|------|---------|------|
| `distx(t,r1,r2)` | 0..1 | x-space distance |
| `acquire(t,rows)` | rows | labelled rows, best first |
"""

def test_acquire():
  "Budget respected; labels skew far better than the pool."
  t   = Tbl(csv(the.file))
  lab = acquire(t, t.rows)
  mu  = lambda rs: sum(disty(t,r) for r in rs)/len(rs)
  print(len(lab), "%.3f vs %.3f" % (mu(lab), mu(t.rows)))
  assert len(lab) <= the.budget - the.check
  assert mu(lab) < mu(t.rows)

#-- tree-eg ----------------------------------------------------
"""

A binary regression tree on the labels' d2h: `bins` yields
(cost,at,v) splits (cost = size-weighted sd; the far side
is `sub(tot, here)`, total minus here); `tree` recurses the
min-cost split. Every node carries `score` = min mean-d2h
of the leaves below it, so a tree's promise is read off its
root in O(1).

| call | returns | what |
|------|---------|------|
| `bins(t,rows,at,Y)` | iter | (cost,at,v) for one column |
| `tree(t,rows)` | o | regression tree, scored nodes |
| `leaf(t,w,row)` | mu | route a row; leaf's mean d2h |
"""

def test_tree():
  "Root score = best leaf mean; deeper = purer."
  t = Tbl(csv(the.file))
  w = tree(t, acquire(t, t.rows))
  print("n %d  mu %.3f  score %.3f" % (w.n, w.mu, w.score))
  assert w.score <= w.mu

def test_klass():
  "Same tree code classifies: accum=Sym, Y=a symbol."
  t  = Tbl(csv(the.file))
  at = next(a for a in t.x if is_sym(t.cols[a]))    # origin
  t2 = o(**vars(t)); t2.x = [a for a in t.x if a != at]
  w  = tree(t2, t.rows, lambda r: r[at], Sym)
  b  = min(walk(w),
           key=lambda x: (x.score, x.leafs))
  print("root ent %.2f  best leaf ent %.2f  mode %s"
        % (w.here, b.score, b.mu if b.at is None else "-"))
  assert b.score <= w.here

#-- walk-eg ----------------------------------------------------
"""

`walk` yields every pruning of a tree: below each cut, each
side either collapses to a leaf (`leafed`) or descends --
four shapes per cut, up to 4^d trees, all sharing structure
(no row copies). Scores ride along, so the best pruning is
one min() over the generator; nothing is materialized.

| call | returns | what |
|------|---------|------|
| `walk(w)` | iter | every pruning, scored at the root |
| `leafed(x)` | o | a subtree collapsed to one leaf |
| `show(t,w)` | str | one pruning as (cut yes no); leaf=mu |
"""

def cond(t, w):
  v = round(w.v, the.round) if type(w.v) == float else w.v
  return "%s%s%s" % (t.names[w.at],
                     "==" if is_sym(t.cols[w.at])
                     else "<=", v)

def show(t, w):
  if w.at is None: return "%.2f" % w.mu
  return "(%s %s %s)" % (cond(t, w), show(t, w.yes),
                         show(t, w.no))

def test_walk():
  "Every pruning printed, best first; winner marked."
  t  = Tbl(csv(the.file))
  w  = tree(t, acquire(t, t.rows))
  ts = sorted(walk(w),
              key=lambda x: (x.score, x.leafs))
  for x in ts:
    print("%s %.3f %d  %s" % ("->" if x is ts[0] else "  ",
                              x.score, x.leafs,
                              show(t, x)))
  print("prunings %d  full %.3f  best %.3f"
        % (len(ts), w.score, ts[0].score))
  assert len(ts) >= 1 and ts[0].score <= w.score

#-- main-eg ----------------------------------------------------
"""

The rig: 50:50 split; acquire labels from one half; the
best pruning of their tree sorts the other half; buy the
top `check` rows; return the best. Beating the median test
row means the tiny tree generalized.

| call | returns | what |
|------|---------|------|
| `holdout(t,get?)` | tree, row, test | get overrides acquire |
"""

def test_holdout():
  "Best pruning's test pick beats the median test row."
  t = Tbl(csv(the.file))
  _, got, test = holdout(t)
  ys = sorted(disty(t, r) for r in test)
  print("got %.*f  best %.*f  median %.*f" % (
    the.round, disty(t, got), the.round, ys[0],
    the.round, ys[len(ys)//2]))
  assert disty(t, got) <= ys[len(ys)//2]

#-- stats-eg ---------------------------------------------------
"""

Comparisons need a conservative equality: `same` says two
result sets differ only if Cohen (d > 0.35), Cliff's delta
(> 0.195) and Kolmogorov-Smirnov (95%) all agree.

| call | returns | what |
|------|---------|------|
| `cliffs(xs,ys)` | 0..1 | effect size (0 = identical) |
| `ks(xs,ys)` | 0..1 | max gap between the two CDFs |
| `cohen(xs,ys)` | bool | mean gap small vs pooled sd? |
| `same(xs,ys)` | bool | statistically indistinguishable? |
| `confuse(log)` | dict | class -> o(n,pd,pf) from (got,want) |
"""

def cliffs(xs, ys):
  ys = sorted(ys); m = len(ys)
  gt = sum(bisect_left(ys, x)      for x in xs)
  lt = sum(m - bisect_right(ys, x) for x in xs)
  return abs(gt - lt) / (len(xs) * m + TINY)

def ks(xs, ys):
  xs, ys = sorted(xs), sorted(ys)
  n, m = len(xs), len(ys)
  gap = lambda v: abs(bisect_right(xs,v)/n
                      - bisect_right(ys,v)/m)
  return max(map(gap, xs + ys))

def cohen(xs, ys, eps=0.35):
  x, y = adds(xs), adds(ys)
  n, m = x[0], y[0]
  pool = (((n-1)*sd(x)**2 + (m-1)*sd(y)**2)/(n+m-2))**.5
  return abs(x[1] - y[1]) <= eps * (pool + TINY)

def same(xs, ys, cliff=0.195, conf=1.36):
  if not cohen(xs, ys): return False
  if cliffs(xs, ys) > cliff: return False
  n, m = len(xs), len(ys)
  return ks(xs, ys) <= conf * ((n + m) / (n * m)) ** .5

def test_same():
  "Same distribution reads same; shifted reads different."
  random.seed(1)
  a = [random.gauss(10, 1) for _ in range(40)]
  b = [random.gauss(10, 1) for _ in range(40)]
  c = [random.gauss(14, 1) for _ in range(40)]
  print(same(a, b), same(a, c))
  assert same(a, b) and not same(a, c)

def confuse(log):
  "Per-class o(n,pd,pf) from a [(got, want),...] log"
  out = {}
  for got, want in log:
    for k in (got, want):
      out[k] = out.get(k) or o(n=0,tp=0,fp=0,tn=0,fn=0)
  for got, want in log:
    for k, c in out.items():
      if want == k:
        c.n += 1
        if got == k: c.tp += 1
        else:        c.fn += 1
      elif got == k: c.fp += 1
      else:          c.tn += 1
  for c in out.values():
    c.pd = c.tp / (c.tp + c.fn + TINY)
    c.pf = c.fp / (c.fp + c.tn + TINY)
  return out

def test_confuse():
  "Known log gives known pd, pf."
  log = ([("a","a")]*3 + [("b","a")] + [("b","b")]*2
         + [("a","b")])
  cs = confuse(log)
  for k, c in sorted(cs.items()):
    print(k, "n", c.n, "pd %.2f pf %.2f" % (c.pd, c.pf))
  assert cs["a"].n == 4 and round(cs["a"].pd, 2) == .75
  assert round(cs["a"].pf, 2) == .33
  assert round(cs["b"].pd, 2) == .67

def test_compare():
  "Active acquire vs same-budget random labels, 20 runs."
  t = Tbl(csv(the.file))
  rand = lambda t, rows: sorted(
    some(rows, the.budget - the.check),
    key=lambda r: disty(t, r))
  out = {}
  for k, get in [("active", None), ("random", rand)]:
    out[k] = []
    for i in range(20):
      random.seed(the.seed + i)
      out[k] += [disty(t, holdout(t, get)[1])]
  mu = lambda xs: sum(xs)/len(xs)
  v  = ("tie" if same(out["active"], out["random"]) else
        "active" if mu(out["active"]) < mu(out["random"])
        else "random")
  print("active %.3f  random %.3f  %s"
        % (mu(out["active"]), mu(out["random"]), v))
  assert v in ("tie", "active", "random")

"""
## Runner

`test_all` walks this file's globals in definition order,
reseeding before each, so the tutorial runs top to bottom.
"""

def test_all():
  "Run every other test_*, reseting the seed before each."
  for n, f in list(globals().items()):
    if n.startswith("test_") and n != "test_all":
      print("\n#", n, "-"*40)
      try: random.seed(the.seed); f()
      except Exception as e:
        print("FAIL:", n, type(e).__name__, e)

if __name__ == "__main__": main(globals())
