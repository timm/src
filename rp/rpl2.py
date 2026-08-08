#!/usr/bin/env python3
"""rpl2.py: M — the one-primitive squeezer. Rows in, labels counted.
Norm = 10th/90th percentile lo-hi, capped 0..1 (outliers saturate;
syms enum to 0..1). One sweep: ~10 mutually-distant anchors (labeled,
on row passes), all anchor pairs weighted d = dy/dx (rows) or dx
(cols); every item marked with sum over pairs of weight * |its
projection - that view's median|; cull marks under half the top.
Transpose, sweep again, repeat till nothing shrinks or budget dies.
Demos: python3 rpl2.py [--k v]."""
from rpl1 import (o, thing, csv, adds, add, Num, var,
                  anys, any1, srand, cli, tests)
import rpl1, sys

the  = o(anchors=10, close=.3, budget=50, top=.5, cap=10,
         seed=1234567891, file=rpl1.the.file)
TINY = 1e-32

def M(src):
  "rows + normalized view. N[i][c] in 0..1, or None for '?'"
  rows = list(src)
  head, rows = rows[0], rows[1:]
  N = [[None] * len(head) for _ in rows]
  for c in range(len(head)):
    vals = [r[c] for r in rows if r[c] != "?"]
    if all(not isinstance(v, str) for v in vals):  # thing made floats
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
  "mean abs gap over shared cells; nothing shared = 1"
  d = n = 0
  for c in cols:
    a, b = N[i][c], N[j][c]
    if a is not None and b is not None: d += abs(a - b); n += 1
  return d / n if n else 1

def distc(N, rows, c1, c2):
  "column-column gap over the live rows"
  d = n = 0
  for i in rows:
    a, b = N[i][c1], N[i][c2]
    if a is not None and b is not None: d += abs(a - b); n += 1
  return d / n if n else 1

def disty(m, i):
  "distance to heaven; 0 = best"
  d = n = 0
  for c in m.y:
    v = m.N[i][c]
    if v is not None:
      d += abs(v - (1 if m.w[c] else 0)); n += 1
  return d / n if n else 1

def sweep(items, distf, ylab=None):
  "anchors -> pair views -> marks -> cull below top/2"
  dn  = adds(distf(any1(items), any1(items)) for _ in range(64))
  eps = the.close * var(dn)
  A   = []
  for i in anys(items, len(items)):               # diverse anchors:
    if all(distf(i, a) > eps for a in A):         # twins never both
      A += [i]                                    # get labeled
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
  "alternate row sweeps (labeled, unless not) and col sweeps (free)"
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
  if mR and len(R) > the.cap:                    # grid-sized theory:
    R = sorted(R, key=mR.get, reverse=True)[:the.cap]
  if mC and len(C) > the.cap:                    # top marks only
    C = sorted(C, key=mC.get, reverse=True)[:the.cap]
  return R, C, len(ycache), ycache

#------------------------------------------------------------- demos ---------
def test_m():
  m = M(csv(the.file))
  print("  m:", len(m.rows), "rows,", len(m.x), "x cols")
  assert len(m.rows) == 398 and len(m.x) == 5

def test_squeeze2():
  m = M(csv(the.file))
  R, C, spent, ys = squeeze(m)
  best = min(ys.values())
  pool = min(disty(m, i) for i in range(len(m.rows)))
  print(f"  rows {len(m.rows)} -> {len(R)}; cols {len(m.x)} -> "
        f"{len(C)}; labels {spent}; best lbl {best:.2f} "
        f"(pool {pool:.2f})")
  assert spent <= the.budget and 2 <= len(R)

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  rpl1.the.seed = the.seed
  tests(globals())
