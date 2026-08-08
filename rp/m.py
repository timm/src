#!/usr/bin/env python3
"""m.py: M -- one-primitive row+column squeezer, on a label budget.

Rows in; labels counted; theory out (few rows x few cols + marks).
Norm is 10th/90th percentile lo-hi capped 0..1 (outliers saturate;
syms enum to 0..1). One SWEEP: pick ~anchors mutually-distant rows
(diverse, so twins never both labeled); weight every anchor pair by
d = dy/dx (labeled rounds) or dx (free rounds); mark each item with
sum over pairs of weight * |its projection - that view's median|;
cull marks below top/2 (anchors always survive). Transpose, sweep
columns the same way (always free), repeat till nothing shrinks;
then keep the cap best-marked rows and cols.

Findings (20 seeds x 10 moot datasets, win = normalized regret
complement, always vs random labeling at matched budget):
  labelled sweeps (~40 labels): win 100 on smooth sets, 75-83 rough;
  free sweeps + label survivors (~12): matches, except rough sets;
  free + label one per nearest pair (~6): usually beats random,
    loses where x-near rows are y-far (smoothness fails: LLVM);
  p sweep: labelled arm indifferent (p=2 a nudge better on the
    rough sets), so house p=2 stays; free arm swings per dataset
    (p=2 rescued X264's capped grid, 46->100; p=1 better SS-O/I).

Demos: python3 m.py [--k v].  (c) 2026 Tim Menzies, MIT license."""
import os, re, sys
from types import SimpleNamespace as o
from random import choice as any1, sample as anys, seed as srand

the  = o(anchors=10, close=.3, budget=50, top=.5, cap=10, p=2,
         seed=1234567891,
         file=os.environ["HOME"] + "/gits/moot/optimize/misc/auto93.csv")
TINY = 1e-32

def thing(s):
  try: return float(s)
  except: return s

def csv(f):
  for l in open(f, encoding="utf-8-sig"):
    if l := l.strip():
      yield [thing(s.strip()) for s in l.split(",")]

Num = lambda: (0, 0, 0)                          # n, mu, m2 (Welford)

def add(it, v):
  n, mu, m2 = it
  n += 1; d = v - mu; mu += d / n
  return (n, mu, m2 + d * (v - mu))

def sd(it):
  n, _, m2 = it
  return 0 if n < 2 else (m2 / (n - 1)) ** .5

def M(src):
  "rows + normalized view N[i][c] in 0..1 (None = '?')"
  rows = list(src)
  head, rows = rows[0], rows[1:]
  N = [[None] * len(head) for _ in rows]
  for c in range(len(head)):
    vals = [r[c] for r in rows if r[c] != "?"]
    if all(not isinstance(v, str) for v in vals):
      a      = sorted(vals)
      lo, hi = a[int(.1 * len(a))], a[int(.9 * len(a))]
      f = lambda v, lo=lo, hi=hi: max(0, min(1, (v-lo) / (hi-lo+TINY)))
    else:
      ks = {k: i for i, k in enumerate(sorted(set(vals), key=str))}
      k1 = max(1, len(ks) - 1)
      f  = lambda v, ks=ks, k1=k1: ks[v] / k1
    for i, r in enumerate(rows):
      if r[c] != "?": N[i][c] = f(r[c])
  return o(head=head, rows=rows, N=N,
           x=[c for c, s in enumerate(head) if s[-1] not in "+-!"],
           y=[c for c, s in enumerate(head) if s[-1] in "+-"],
           w=[s[-1] != "-" for s in head])

def dist(N, i, j, cols):
  "minkowski over shared cells; nothing shared = 1"
  d = n = 0
  for c in cols:
    a, b = N[i][c], N[j][c]
    if a is not None and b is not None:
      d += abs(a - b) ** the.p; n += 1
  return (d / n) ** (1 / the.p) if n else 1

def distc(N, rows, c1, c2):
  "column-column minkowski over the live rows"
  d = n = 0
  for i in rows:
    a, b = N[i][c1], N[i][c2]
    if a is not None and b is not None:
      d += abs(a - b) ** the.p; n += 1
  return (d / n) ** (1 / the.p) if n else 1

def disty(m, i):
  "distance to heaven; 0 = best"
  d = n = 0
  for c in m.y:
    v = m.N[i][c]
    if v is not None:
      d += abs(v - (1 if m.w[c] else 0)) ** the.p; n += 1
  return (d / n) ** (1 / the.p) if n else 1

def sweep(items, distf, ylab=None):
  "anchors -> weighted pair views -> marks -> cull below top/2"
  dn = Num()
  for _ in range(64): dn = add(dn, distf(any1(items), any1(items)))
  A = []
  for i in anys(items, len(items)):
    if all(distf(i, a) > the.close * sd(dn) for a in A):
      A += [i]
      if len(A) == min(the.anchors, len(items)): break
  ys   = {a: ylab(a) for a in A} if ylab else None
  DA   = {a: {i: distf(i, a) for i in items} for a in A}
  mark = {i: 0.0 for i in items}
  for k, a in enumerate(A):
    for b in A[k+1:]:
      c = DA[a][b] + TINY
      w = abs(ys[a] - ys[b]) / c if ys else c
      pos = {i: (DA[a][i]**2 + c*c - DA[b][i]**2) / (2*c)
             for i in items}
      med = sorted(pos.values())[len(items) // 2]
      for i in items: mark[i] += w * abs(pos[i] - med)
  hi, keepA = max(mark.values()) + TINY, set(A)
  return [i for i in items
          if mark[i] >= the.top * hi or i in keepA], mark

def squeeze(m, labelled=True):
  "alternate row sweeps (maybe labeled) and col sweeps (free)"
  R, C = list(range(len(m.rows))), m.x[:]
  ycache = {}
  def ylab(i):
    if i not in ycache: ycache[i] = disty(m, i)
    return ycache[i]
  mR = mC = None
  while True:
    r0, c0 = len(R), len(C)
    if len(ycache) + the.anchors <= the.budget and len(R) > 4:
      R, mR = sweep(R, lambda i, j: dist(m.N, i, j, C),
                    ylab if labelled else None)
    if len(C) > 4:
      C, mC = sweep(C, lambda a, b: distc(m.N, R, a, b))
    if len(R) == r0 and len(C) == c0: break
  if mR and len(R) > the.cap:
    R = sorted(R, key=mR.get, reverse=True)[:the.cap]
  if mC and len(C) > the.cap:
    C = sorted(C, key=mC.get, reverse=True)[:the.cap]
  return R, C, len(ycache), ycache

#------------------------------------------------------------- demos ---------
def test_m():
  m = M(csv(the.file))
  print("  m:", len(m.rows), "rows,", len(m.x), "x cols")
  assert len(m.rows) == 398 and len(m.x) == 5

def test_labelled():
  m = M(csv(the.file))
  R, C, spent, ys = squeeze(m)
  print(f"  {len(m.rows)}x{len(m.x)} -> {len(R)}x{len(C)}; "
        f"labels {spent}; best lbl {min(ys.values()):.2f}")
  assert spent <= the.budget and 2 <= len(R) <= the.cap

def test_free():
  m = M(csv(the.file))
  R, C, spent, _ = squeeze(m, labelled=False)
  best = min(disty(m, i) for i in R)             # cash out: label R
  print(f"  {len(m.rows)}x{len(m.x)} -> {len(R)}x{len(C)}; "
        f"labels 0 (+{len(R)} to cash); best alive {best:.2f}")
  assert spent == 0 and 2 <= len(R) <= the.cap

def cli(d, s):
  for k, old in vars(d).items():
    if mm := re.search(f"--{k}[= ]+(\\S+)", s):
      vars(d)[k] = type(old)(mm.group(1))

def tests(funs):
  for k, f in sorted(funs.items()):
    if k[:5] == "test_": print("#", k); srand(the.seed); f()
  print("all passed")

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
