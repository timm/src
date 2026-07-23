#!/usr/bin/env python3 -B
"""
branch: prune one regression tree into many small trees.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 branch-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --budget labeling cap          = 50
  --more   labels per round      = 4
  --best   pool keep fraction    = 0.66
  --cap    acquire pool cap      = 1024
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 4
  --check  rows checked on test  = 5
  --round  decimals shown        = 3
  -h       print this help

TESTS: (in branch-eg.py; run with their bare name):
  tbl disty acquire tree klass walk holdout
  same confuse compare
  all      run every test above, reseting seed each
"""
"""
IDEA: an active learner labels a few rows per round and
culls the pool toward the good pole; a binary regression
tree fits the labels' d2h; a walk then yields every pruned
version of that tree (at each cut, each side stays or
collapses to a leaf: 4 shapes per cut). Every yielded tree
carries at its root the min mean-d2h of its leaves, so the
best pruning is one min() over a generator, and that tree
sorts the holdout.
"""
import os, re, sys, random
from math import exp, log2
from types import SimpleNamespace as o
TINY = 1e-32
MOOT = (os.environ.get("MOOT")
        or os.path.expanduser("~/gits/moot"))

#--------------------------------------------------------------
def Tbl(src):
  src = iter(src)
  t = o(names=next(src), cols={}, x=[], y={}, rows=[],
        klass=None)
  return adds(list(src), Cols(t))

def Cols(t):
  for at, s in enumerate(t.names):
    t.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if   s[-1] == "!":  t.klass = at
    elif s[-1] in "+-": t.y[at] = s[-1] == "+"
    else: t.x.append(at)
  return t

#--------------------------------------------------------------
def norm(t, at, v):
  if v == "?": return v
  z = (v - t.cols[at][1]) / (sd(t.cols[at]) + TINY)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

def disty(t, row):
  d = n = 0
  for at, g in t.y.items():
    if (v := row[at]) != "?":
      d += (norm(t, at, v) - g)**2; n += 1
  return (d / n) ** .5

def distx(t, r1, r2):
  d = n = 0
  for at in t.x:
    u, v = r1[at], r2[at]
    if u == v == "?": g = 1
    elif is_sym(t.cols[at]): g = u != v
    else:
      u, v = norm(t, at, u), norm(t, at, v)
      if u == "?": u = 1 if v < .5 else 0
      if v == "?": v = 1 if u < .5 else 0
      g = abs(u - v)
    d += g*g; n += 1
  return (d/n) ** .5

#--------------------------------------------------------------
def project(rows, x, y, east=None, west=None):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = east or far(rows[0])
  west = west or far(east)
  if y(east) > y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def acquire(t, rows):
  y = lambda r: disty(t, r)
  x = lambda a, b: distx(t, a, b)
  return sorted(sway3(some(rows, the.cap), y, x,
                      the.budget - the.check), key=y)

def sway3(rows, y, x, cap, lab=None, east=None, west=None):
  b4  = rows[:]
  lab = lab or {}
  while len(rows) >= 2*the.leaf:
    more = min(the.more, cap - len(lab))
    less = int(max(1, the.best * len(rows)))
    new  = []
    for r in rows:
      if   id(r) in lab         : new += [r]
      elif (more := more-1) >= 0: new += [r]; lab[id(r)]=r
    if len(lab) >= cap: return lab.values()
    rows = sorted(rows,
                  key=project(new, x, y, east, west))[:less]
  if len(lab) < len(b4):
    seen = sorted(lab.values(), key=y)
    return sway3(shuffle(b4), y, x, cap,
                 lab, seen[0], seen[-1])
  return lab.values()

#--------------------------------------------------------------
Sym = dict
def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def is_sym(i): return isinstance(i, dict)

def size(i): return sum(i.values()) if is_sym(i) else i[0]

def mid(i): return max(i, key=i.get) if is_sym(i) else i[1]

def var(i): return ent(i) if is_sym(i) else sd(i)

def ent(d):
  N = size(d)
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def sd(i):
  n,_,m2 = i
  return 0 if n < 2 else (max(0,m2)/(n-1))**.5

def count(sym, v):
  sym[v] = sym.get(v, 0) + 1
  return sym

def add(i, v):
  if isinstance(i, o):
    i.rows += [v]
    for at, c in i.cols.items(): i.cols[at] = add(c, v[at])
    return i
  if v == "?": return i
  if is_sym(i): return count(i, v)
  n, mu, m2 = i
  n += 1; d = v - mu; mu += d/n
  return (n, mu, m2 + d*(v - mu))

def adds(src, i=None):
  i = Num() if i is None else i
  for v in src: i = add(i, v)
  return i

def sub(i, j):
  if is_sym(i):
    return {k: n for k in i
            if (n := i[k] - j.get(k, 0)) > 0}
  (ni,mui,m2i), (nj,muj,m2j) = i, j
  if (n := ni - nj) <= 0: return Num()
  d = muj - mui
  return (n, (ni*mui - nj*muj)/n,
          max(0, m2i - m2j - d*d*ni*nj/n))

#--------------------------------------------------------------
def score(a, b):
  return ((var(a)*size(a) + var(b)*size(b))
          / (size(a) + size(b) + TINY))

def has(t, row, at, v):
  x = row[at]
  return x == "?" or (x == v if is_sym(t.cols[at])
                      else x <= v)

def bins(t, rows, at, Y, accum=Num):
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), accum())
  bin = lambda here,k: (score(here, sub(tot,here)), at, k)
  if is_sym(t.cols[at]):
    d = {}
    for x, y in xy: d[x] = add(d.get(x) or accum(), y)
    if len(d) > 1:
      for k, here in d.items(): yield bin(here, k)
  else:
    xy.sort(key=lambda z: z[0]); me = accum()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0]: yield bin(me, x)

def tree(t, rows, Y=None, accum=Num, lvl=0):
  Y  = Y or (lambda r: disty(t, r))
  ys = adds(map(Y, rows), accum())
  w  = o(at=None, n=len(rows), mu=mid(ys), leafs=1,
         ys=ys, here=var(ys) if is_sym(ys) else mid(ys))
  w.score = w.here
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if b := min((c for at in t.x
                 for c in bins(t,rows,at,Y,accum)),
                default=None, key=lambda c: c[0]):
      _, at, v = b
      yes, no = [], []
      for r in rows:
        (yes if has(t, r, at, v) else no).append(r)
      if yes and no:
        w.at, w.v = at, v
        w.yes = tree(t, yes, Y, accum, lvl+1)
        w.no  = tree(t, no,  Y, accum, lvl+1)
        w.score = min(w.yes.score, w.no.score)
        w.leafs = w.yes.leafs + w.no.leafs
  return w

def leafed(x):
  return o(at=None, n=x.n, mu=x.mu, here=x.here,
           score=x.here, leafs=1, ys=x.ys)

#--------------------------------------------------------------
def walk(w):
  if w.at is None: yield w; return
  for yes in sides(w.yes):
    for no in sides(w.no):
      yield o(at=w.at, v=w.v, n=w.n, yes=yes, no=no,
              score=min(yes.score, no.score),
              leafs=yes.leafs + no.leafs)

def sides(x):
  yield leafed(x)
  if x.at is not None: yield from walk(x)

def leaf(t, w, row):
  while w.at is not None:
    w = w.yes if has(t, row, w.at, w.v) else w.no
  return w.mu

#--------------------------------------------------------------
def holdout(t, get=None):
  rows = shuffle(t.rows)
  half = len(rows)//2
  train, test = rows[:half], rows[half:]
  lab  = (get or acquire)(t, train)
  best = min(walk(tree(t, lab)),
             key=lambda x: (x.score, x.leafs))
  top  = sorted(test, key=lambda r: leaf(t, best, r))
  return best, min(top[:the.check],
                   key=lambda r: disty(t, r)), test

#--------------------------------------------------------------
def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s):
  return os.path.expanduser(s.replace("$MOOT", MOOT, 1))

def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]

def shuffle(lst): return random.sample(lst, len(lst))

def some(lst, k): return random.sample(lst, min(k, len(lst)))

#--------------------------------------------------------------
def main(funs):
  if "-h" in sys.argv: return print(__doc__)
  for a in sys.argv[1:]:
    if a[:2]=="--" and "=" in a:
      k,v = a[2:].split("=",1)
      if k in vars(the): setattr(the, k, thing(v))
  for a in sys.argv[1:]:
    if (n := "test_"+a) in funs:
      random.seed(the.seed); funs[n]()

the = settings(__doc__)
