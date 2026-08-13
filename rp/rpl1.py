#!/usr/bin/env python3
"""rpl1.py: repgrids, two passes, on a budget. Part 1: the substrate.
Tbl/Num/Sym, distance, ball trees. Demos: python3 rpl1.py [X.csv]
(or pytest rpl1.py, if you have it; same test_* functions)."""
from types import SimpleNamespace as o
from math import log, exp, floor
from random import choice as any1, sample as anys, seed as srand
import re, os, sys

the  = o(bins=7, far=.85, p=2, seed=1234567891,
         close=.3, warm=30, dry=2,
         reach=2, dull=.6, cull=.5, budget=50, wait=10,
         file=os.environ["HOME"] + "/gits/moot/optimize/misc/auto93.csv")
TINY = 1e-32

Sym = dict
Num = lambda n=0, mu=0, m2=0: (n, mu, m2)


[
["names","a","n","c","d"]
["happp",  1,  2,  3,  4]
]
def shuffle(lst): random.shuffle(lst); return lst

def squeeze(m):
  cols, rows, dists = Cols(m[0]), shuffle(m[1:]), Num()
  b4 = None
  for r,(txt,*row) in enumerate(rows):
    add(cols.row)
    if b4: 
      d = distx(cols,b4,row)
      dists = add(dists,d)
      if r > 20 

def Num(txt="",at=0): return o(it=Num,txt=txt,at=at,n=0,mu=0,m2=0)
def Sym(txt="",at=0): return o(it=Sym,txt=txt,at=at,n=0,has={})
      
def add(i, v):
  if v=="?": return v
  if   i.it is Sym: i.has[v] = i.has.get(v, 0) + 1
  elif i.it is Num:
    i.n  += 1
    d     = v - i.mu                                 
    i.mu += d / i.n
    i.m2 += d * (v - i.mu)            
  elif: i.it is Cols:
    for col in i.all: add(col, v[col.at])
  return v

def Cols(names):
  ys = {i for i, s in enumerate(names) if s[-1] in "+-!"}
  return o(it=Cols, names=names, ys=ys,
           xs  = set(range(len(names))) - ys,
           w   = [s[-1] != "-" for s in names],
           all = [(Num if s[0].isupper() else Sym)(n,s) 
                  for n,s in enumerate(names)])

def adds(src, it=None):
  it = Num() if it is None else it     # not `or`: Sym() is falsy
  for v in src: it = add(it, v)
  return it

def mid(it):
  if type(it) is tuple: return it[1]             # Num: mean
  if type(it) is dict:  return max(it, key=it.get)   # Sym: mode
  return [mid(c) for c in it.cols.all]           # Tbl: centroid

def var(col):
  if type(col) is tuple:                         # Num: sd
    n, mu, m2 = col
    return 0 if n < 2 else (m2 / (n - 1)) ** 0.5
  N = sum(col.values())                          # Sym: entropy
  return -sum(n/N * log(n/N, 2) for n in col.values())

def norm(num, v):
  "v's cdf under num, via a logistic; 0..1"
  if v == "?": return v
  n, mu, m2 = num
  z = (v - mu) / (var(num) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z))))

def bin(col, v):
  "raw cell -> 1..the.bins (Nums) or itself (Syms); '?' -> 0"
  if v == "?": return 0
  return 1 + floor(the.bins * norm(col, v)) if type(col) is tuple else v

def aha(col, a, b):
  "gap between two cells of one column; 0..1"
  if a == b == "?": return 1
  if type(col) is dict: return a != b
  a, b = norm(col, a), norm(col, b)
  if a == "?": a = 0 if b > .5 else 1
  if b == "?": b = 0 if a > .5 else 1
  return abs(a - b)

def distx(tbl, row1, row2):
  d, n = 0, TINY
  for x in tbl.cols.xs:
    n, d = n + 1, d + aha(tbl.cols.all[x], row1[x], row2[x]) ** the.p
  return (d / n) ** (1 / the.p)

def distxs(tbl, rows):
  return {(i, j): distx(tbl, rows[i], rows[j])
          for i in range(len(rows)) for j in range(len(rows)) if i < j}

def dists(D):
  return lambda i, j: 0 if i == j else D[min(i, j), max(i, j)]

def ball(d, ids):
  x, y = max(((i, j) for i in ids for j in ids if i < j),
             key=lambda p: d(*p))                # subset diameter
  c    = d(x, y) + TINY
  proj = lambda i: (d(x,i)**2 + c*c - d(y,i)**2) / (2*c)
  t    = sorted(ids, key=proj)
  a    = t[int((1 - the.far) * len(t))]          # good-end pole
  return a, sorted(d(a, i) for i in ids)[len(ids) // 2]

def tree(d, ids, stop=4):
  if len(ids) >= 2 * stop:
    a, r  = ball(d, ids)
    left  = [i for i in ids if d(a, i) <= r]
    right = [i for i in ids if d(a, i) >  r]
    if left and right:
      return o(a=a, r=r,
               left=tree(d, left, stop), right=tree(d, right, stop))
  return o(a=None, ids=ids)                      # leaf

def leaf(node, tbl, rows, row):
  while node.a is not None:
    node = (node.left if distx(tbl, row, rows[node.a]) <= node.r
            else node.right)
  return node.ids

def thing(s):
  try: return float(s)
  except: return s

def csv(f):
  for l in open(f, encoding="utf-8-sig"):
    if l := l.strip():
      yield [thing(s.strip()) for s in l.split(",")]

#----------------------------------------------------------- squeeze ---------
def coder(col):
  "root-oracle coder: raw cell -> int code 0..the.bins (0 = '?')"
  if type(col) is tuple:
    return lambda v: 0 if v == "?" else 1 + floor(the.bins * norm(col, v))
  ks = {k: 1 + i for i, k in enumerate(sorted(col, key=str))}
  return lambda v: 0 if v == "?" else ks[v]

def binned(tbl):
  "the theory's cells: x columns of every row, as int codes"
  xs = sorted(tbl.cols.xs)
  fs = [coder(tbl.cols.all[c]) for c in xs]
  return [[f(r[c]) for f, c in zip(fs, xs)] for r in tbl.rows], xs

def transpose(m): return [list(v) for v in zip(*m)]

def distb(u, v):
  "city block over codes; 0 = missing: jump that cell (Gower)"
  d = n = 0
  for a, b in zip(u, v):
    if a and b: d += abs(a - b); n += 1
  return d / ((the.bins - 1) * n) if n else 1

def var2(vec):
  "a vector's information: sd of its nonzero codes"
  return var(adds(v for v in vec if v))

def squeeze(items, dist, varf):
  "pair off; too-close pair loses its less-vary twin; regenerate"
  dn, dry, kills, gens = Num(), 0, 0, 0
  while dry < the.dry:
    gen, out, k = anys(items, len(items)), [], 0
    while len(gen) > 1:
      a, b = gen.pop(), gen.pop()
      dab  = dist(a, b)
      dn   = add(dn, dab)
      if dn[0] > the.warm and dab < the.close * var(dn):
        out += [a if varf(a) >= varf(b) else b]; k += 1
      else:
        out += [a, b]
    items  = out + gen                           # odd one rides along
    kills += k; gens += 1
    dry    = dry + 1 if k == 0 and dn[0] > the.warm else 0
  return items, kills, gens, dn

def squeezes(m):
  "row ids, then col ids, till one full pass kills nothing"
  R, C = list(range(len(m))), list(range(len(m[0])))
  while True:
    dr = lambda i, j: distb([m[i][c] for c in C], [m[j][c] for c in C])
    vr = lambda i: var2([m[i][c] for c in C])
    R, k1, g1, d1 = squeeze(R, dr, vr)
    dc = lambda i, j: distb([m[r][i] for r in R], [m[r][j] for r in R])
    vc = lambda i: var2([m[r][i] for r in R])
    C, k2, g2, d2 = squeeze(C, dc, vc)
    print(f"  pass: {len(R)} x {len(C)} "
          f"(rows -{k1} in {g1} gens, sd {round(var(d1),3)}; "
          f"cols -{k2} in {g2} gens, sd {round(var(d2),3)})")
    if k1 + k2 == 0: return R, C

def disty(tbl, row):
  "distance to heaven over the y columns; 0 = best"
  d = n = 0
  for c in tbl.cols.ys:
    v = norm(tbl.cols.all[c], row[c])
    if v != "?":
      d += abs(v - (1 if tbl.cols.w[c] else 0)) ** the.p; n += 1
  return (d / (n + TINY)) ** (1 / the.p)

def ysqueeze(tbl, m, R, C):
  "aimed sphere probes on labels; dull sphere -> cull interior"
  vec = {i: [m[i][c] for c in C] for i in R}
  D   = {(i, j): distb(vec[i], vec[j]) for i in R for j in R if i < j}
  dd  = dists(D)
  sd  = var(adds(iter(D.values())))
  lo, hi = .75 * the.reach * sd, 1.25 * the.reach * sd
  cands  = [k for k, v in D.items() if lo <= v <= hi]
  alive, ys, yn, spent = set(R), {}, Num(), 0
  for a, b in anys(cands, len(cands)):
    if spent + 2 > the.budget: break
    if a not in alive or b not in alive: continue
    for r in (a, b):
      if r not in ys:
        ys[r] = disty(tbl, tbl.rows[r]); yn = add(yn, ys[r]); spent += 1
    if yn[0] > the.wait and abs(ys[a] - ys[b]) < the.dull * var(yn):
      ball = [r for r in alive if r not in ys
              and dd(r,a)**2 + dd(r,b)**2 <= dd(a,b)**2]
      for r in anys(ball, floor(len(ball) * the.cull)):
        alive.remove(r)
  return alive, spent, ys

#------------------------------------------------------------- demos ---------

def test_num():
  it = adds([2, 4, 4, 4, 5, 5, 7, 9])
  print("num", mid(it), round(var(it), 2))
  assert mid(it) == 5 and 2 < var(it) < 2.2

def test_sym():
  it = adds("aaaabbc", Sym())
  print("sym", mid(it), round(var(it), 2))
  assert mid(it) == "a" and 1.3 < var(it) < 1.5

def test_tbl():
  t = Tbl(csv(the.file))
  print("tbl", len(t.rows), "rows;", "mid", mid(t)[:4])
  assert len(t.rows) == 398 and len(t.cols.xs) == 5

def test_bin():
  t = Tbl(csv(the.file))
  c = t.cols.all[1]                              # Volume: a Num
  bs = {bin(c, r[1]) for r in t.rows}
  print("bins used", sorted(bs))
  assert bs <= set(range(1, the.bins + 1))

def test_dist():
  t = Tbl(csv(the.file))
  r = t.rows[0]
  assert distx(t, r, r) == 0
  ds = sorted(distx(t, r, z) for z in t.rows)
  print("dist lo/mid/hi",
        round(ds[0],2), round(ds[len(ds)//2],2), round(ds[-1],2))
  assert 0 <= ds[0] and ds[-1] <= 1

def test_tree():
  t    = Tbl(csv(the.file))
  rows = anys(t.rows, 32)
  root = tree(dists(distxs(t, rows)), list(range(len(rows))))
  n    = [0]
  def walk(nd):
    if nd.a is None: n[0] += len(nd.ids)
    else: walk(nd.left); walk(nd.right)
  walk(root)
  print("tree leaves hold", n[0], "of", len(rows))
  assert n[0] == len(rows)                       # rows conserved

def test_squeeze():
  t = Tbl(csv(the.file))
  m, xs = binned(t)
  print("  start:", len(m), "x", len(m[0]))
  R, C = squeezes(m)
  print("  final:", len(R), "x", len(C))
  assert 2 <= len(R) and 2 <= len(C)

def test_ysqueeze():
  t = Tbl(csv(the.file))
  m, xs = binned(t)
  R, C = squeezes(m)
  alive, spent, ys = ysqueeze(t, m, R, C)
  y    = lambda r: disty(t, t.rows[r])
  best = min(y(r) for r in alive)
  pool = min(y(i) for i in range(len(t.rows)))     # oracle, eval only
  print(f"  labels {spent}; rows {len(R)} -> {len(alive)}; "
        f"best alive d2h {best:.2f} (pool best {pool:.2f})")
  assert spent <= the.budget and 2 <= len(alive) <= len(R)

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
  tests(globals())
