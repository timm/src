#!/usr/bin/env python3
"""rp2.py: stream rows -> clusters -> prune rows and cols, cheap.
Pipeline: warm-up marginal stats; cull degenerate cols; freeze
coders; far poles -> projections -> hash rows to buckets
(reservoir, cap rows each); KS(bucket vs global) col prune.
Demos: python3 rp2.py [--k v ...]"""
from types import SimpleNamespace as o
from math import exp, log, floor
from random import choice as any1, seed as srand
import random, time, os, sys, re

the = o(bins=9, pbins=3, poles=6, far=.85, cap=10,
        warm=32, most=.9, ks=.45, seed=1234567891,
        file=os.environ["HOME"] + "/gits/moot/optimize/misc/auto93.csv")
TINY = 1e-32

#------------------------------------------------------------ stats ----------
Sym = dict
Num = lambda: (0,0,0) # (n mu, m2)

def add(it, v):
  if v == "?": return it
  if type(it) is tuple: return  welford(it,v)                       
  if type(it) is dict: it[v] = it.get(v, 0) + 1; return it
  it.rows += [v]                                    
  it.cols.all = {at:add(c,v[at]) for at,c in it.cols.all.items()}
  return it

def adds(src, it=None, n=1e32):
  it = Num() if it is None else it
  for i, v in enumerate(src):
    it = add(it, v)
    if i + 1 >= n: break
  return it

def mid(it): return max(it, key=it.get) if type(it) is dict else it[1]

def var(it):
  if type(it) is dict:
    N = sum(it.values())
    return -sum(n/N * log(n/N, 2) for n in it.values() if n)
  n, mu, m2 = it
  return 0 if n < 2 else (max(0, m2) / (n - 1)) ** .5

def norm(num, v):
  z = (v - num[1]) / (var(num) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z))))

def welford(it,v):
  n, mu, m2 = it
  n += 1; d = v - mu; mu += d / n
  return (n, mu, m2 + d * (v - mu))

#------------------------------------------------------------ table ----------
def Cols(names):
  return o(names=names,
           all={at: (Num() if s[0].isupper() else Sym())
                for at, s in enumerate(names)},
           xs={at for at, s in enumerate(names) if s[-1] not in "X+-!"},
           ys={at for at, s in enumerate(names) if s[-1] in "+-!"})

def Tbl(src, n=1e32):
  "first row is names; then read rows (all, or just the first n)"
  src = iter(src)
  return adds(src, o(rows=[], cols=Cols(next(src))), n)

def degenerate(tbl, at):
  "bob's rules: cull the syntactically dead. cheap, early, marginal."
  col, n = tbl.cols.all[at], len(tbl.rows)
  q = sum(1 for r in tbl.rows if r[at] == "?")
  if q > .5 * n: return "missing"
  if type(col) is dict:
    if len(col) > .9 * (n - q): return "id"
    if max(col.values()) > the.most * (n - q): return "const"
  elif var(col) == 0: return "const"

def deads(tbl):
  return {at: why for at in sorted(tbl.cols.xs)
          if (why := degenerate(tbl, at))}

def coder(col):
  "raw cell -> int code; 0 = '?' (or never-seen sym)"
  if type(col) is dict:
    seen = {k: i + 1 for i, k in enumerate(sorted(col, key=str))}
    return lambda v: 0 if v == "?" else seen.get(v, 0)
  return lambda v: 0 if v == "?" else 1 + floor((the.bins-1) * norm(col, v))

def coders(tbl, xs):
  "freeze one coder per live x col; row -> code vector"
  fs = [coder(tbl.cols.all[c]) for c in xs]
  return lambda r: [f(r[c]) for f, c in zip(fs, xs)]

#--------------------------------------------------------- geometry ----------
def distc(u, v):
  "city block over codes; 0 = missing: skip that cell (Gower)"
  d = n = 0
  for a, b in zip(u, v):
    if a and b: d += abs(a - b); n += 1
  return d / ((the.bins - 1) * n) if n else 1

def poles(rows):
  "each new pole far (percentile, not max) from those before"
  out = [any1(rows)]
  while len(out) < the.poles:
    tmp = sorted(rows, key=lambda r: min(distc(r, p) for p in out))
    out += [tmp[int(the.far * (len(tmp) - 1))]]
  return out

def project(a, b):
  c = distc(a, b) + TINY
  return lambda r: (distc(a, r)**2 + c*c - distc(b, r)**2) / (2*c)

def cuts(vals):
  vals = sorted(vals); n = len(vals)
  return [vals[i * n // the.pbins] for i in range(1, the.pbins)]

def digit(v, cut): return sum(v >= c for c in cut)

def grid(rows):
  "poles -> consecutive-pair projections -> equal-freq cuts -> int key"
  ps    = poles(rows)
  projs = [project(a, b) for a, b in zip(ps, ps[1:])]
  cutss = [cuts([p(r) for r in rows]) for p in projs]
  def key(cr):
    k = 0
    for p, cut in zip(projs, cutss): k = k * the.pbins + digit(p(cr), cut)
    return k
  return key

def push(buckets, k, x):
  "reservoir: bucket sees all, keeps the.cap, unbiased"
  b = buckets.setdefault(k, o(n=0, kept=[]))
  b.n += 1
  if len(b.kept) < the.cap: b.kept += [x]
  elif random.random() < the.cap / b.n:
    b.kept[random.randrange(the.cap)] = x
  return b

#------------------------------------------------------------ prune ----------
def ks(a, b):
  "max gap between two sample cdfs"
  a, b = sorted(a), sorted(b)
  d = i = j = 0
  while i < len(a) and j < len(b):
    x = a[i] if a[i] <= b[j] else b[j]
    while i < len(a) and a[i] <= x: i += 1
    while j < len(b) and b[j] <= x: j += 1
    d = max(d, abs(i / len(a) - j / len(b)))
  return d

def kolmogorov(buckets, nxs):
  "timm's rule: a col lives iff some bucket differs from the crowd"
  live = set()
  bs = [b for b in buckets.values() if len(b.kept) >= 4]
  for cx in range(nxs):
    glob = [cr[cx] for b in bs for _, cr in b.kept if cr[cx]]
    for b in bs:
      vals = [cr[cx] for _, cr in b.kept if cr[cx]]
      if len(vals) >= 4 and ks(vals, glob) >= the.ks:
        live.add(cx); break
  return live

#--------------------------------------------------------- pipeline ----------
def pipeline(src):
  src  = iter(src)
  tbl  = Tbl(src, the.warm)                        # 1. warm-up
  dead = deads(tbl)                                # 2. bob's rules
  tbl.cols.xs -= set(dead)
  xs   = sorted(tbl.cols.xs)                            # 3. freeze coders
  code = coders(tbl, xs)
  warm = [code(r) for r in tbl.rows]
  key  = grid(warm)                                # 4. geometry
  buckets, n = {}, len(tbl.rows)
  for raw, cr in zip(tbl.rows, warm): push(buckets, key(cr), (raw, cr))
  for raw in src:                                  # 5. stream the rest
    n += 1; cr = code(raw); push(buckets, key(cr), (raw, cr))
  live = kolmogorov(buckets, len(xs))              # 6. timm's rule
  return o(tbl=tbl, buckets=buckets, n=n, dead=dead, xs=xs,
           live={xs[cx] for cx in live})

#------------------------------------------------------------ demos ----------
def test_pipe():
  z    = pipeline(csv(the.file))
  kept = sum(len(b.kept) for b in z.buckets.values())
  print(f"  rows {z.n} -> {kept} kept in {len(z.buckets)} buckets"
        f" (of {the.pbins ** (the.poles - 1)} possible)")
  print(f"  cols: dead {z.dead or 'none'};"
        f" live {[z.tbl.cols.names[c] for c in sorted(z.live)]}"
        f" of {[z.tbl.cols.names[c] for c in z.xs]}")
  assert kept <= len(z.buckets) * the.cap
  assert z.live <= z.tbl.cols.xs

def test_hist():
  z = pipeline(csv(the.file))
  for k, b in sorted(z.buckets.items(), key=lambda kb: -kb[1].n):
    pct = 100 * b.n / z.n
    print(f"  {k:6} {b.n:4} {pct:5.1f}% {'*' * round(pct)}")

def test_speed():
  t0 = time.perf_counter()
  z  = pipeline(csv(the.file))
  ms = 1000 * (time.perf_counter() - t0)
  print(f"  {z.n} rows in {ms:.1f} ms ({z.n / ms:.1f} rows/ms)")
  assert ms < 1000

#------------------------------------------------------------- lib -----------
def thing(s):
  try: return float(s)
  except ValueError: return s

def csv(f):
  for l in open(f, encoding="utf-8-sig"):
    if l := l.strip():
      yield [thing(s.strip()) for s in l.split(",")]

def cli(d, s):
  "--k v or --k=v, any key of d; coerce to the old value's type"
  for k, old in vars(d).items():
    if m := re.search(f"--{k}[= ]+(\\S+)", s):
      vars(d)[k] = type(old)(m.group(1))

def tests(funs):
  for k, f in sorted(funs.items()):
    if k[:5] == "test_":
      print("#", k); srand(the.seed); f()
  print("all passed")

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(dict(globals()))
