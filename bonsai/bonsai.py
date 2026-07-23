#!/usr/bin/env python3 -B
"""
bonsai: prune one regression tree into many small trees.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 bonsai-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --budget labeling cap          = 50
  --more   labels per round      = 4
  --best   pool keep fraction    = 0.66
  --cap    max rows kept         = 1024
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 4
  --check  rows checked on test  = 5
  --round  decimals shown        = 3
  -h       print this help

TESTS: (in bonsai-eg.py; run with their bare name):
  tbl disty acquire tree walk holdout same compare
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
from types import SimpleNamespace as o
BIG  = 1e32
TINY = 1e-32
MOOT = (os.environ.get("MOOT")
        or os.path.expanduser("~/gits/moot"))

def Tbl(src):
  src = iter(src)
  t = o(names=next(src), rows=[], x=[], y={}, num=set(),
        lo={}, hi={})
  for at, s in enumerate(t.names):
    if s[0].isupper(): t.num.add(at)
    if s[-1] != "X":
      if s[-1] in "+-": t.y[at] = s[-1] == "+"
      else: t.x.append(at)
  t.rows = some(list(src), the.cap)
  for row in t.rows:
    for at in t.num:
      if (v := row[at]) != "?":
        t.lo[at] = min(v, t.lo.get(at,  BIG))
        t.hi[at] = max(v, t.hi.get(at, -BIG))
  return t

def norm(t, at, v):
  return (v - t.lo[at])/(t.hi[at] - t.lo[at] + TINY)

def disty(t, row):
  d = [abs(norm(t, at, row[at]) - g)
       for at, g in t.y.items() if row[at] != "?"]
  return (sum(x*x for x in d) / len(d)) ** .5

def distx(t, r1, r2):
  d = n = 0
  for at in t.x:
    u, v = r1[at], r2[at]
    if u == "?" and v == "?": g = 1
    elif at not in t.num:     g = u != v
    else:
      if u != "?": u = norm(t, at, u)
      if v != "?": v = norm(t, at, v)
      if u == "?": u = 1 if v < .5 else 0
      if v == "?": v = 1 if u < .5 else 0
      g = abs(u - v)
    d += g*g; n += 1
  return (d/n) ** .5

def acquire(t, rows):
  Y = lambda r: disty(t, r)
  X = lambda a, b: distx(t, a, b)
  rows, lab = shuffle(rows), []
  while rows and len(lab) < the.budget - the.check:
    lab  = sorted(lab + rows[:the.more], key=Y)
    rows = rows[the.more:]
    e, w = lab[0], lab[-1]
    c    = X(e, w) + TINY
    p    = lambda r: (X(e,r)**2 + c*c - X(w,r)**2)/(2*c)
    rows = sorted(rows, key=p)[:int(the.best*len(rows))]
  return lab


def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def add(i, v):
  n, mu, m2 = i
  n += 1; d = v - mu; mu += d/n
  return (n, mu, m2 + d*(v - mu))

def adds(src):
  i = Num()
  for v in src: i = add(i, v)
  return i

def sub(i, j):
  (ni,mui,m2i), (nj,muj,m2j) = i, j
  if (n := ni - nj) <= 0: return Num()
  d = muj - mui
  return (n, (ni*mui - nj*muj)/n,
          max(0, m2i - m2j - d*d*ni*nj/n))

def sd(i):
  n,_,m2 = i
  return 0 if n < 2 else (max(0,m2)/(n-1))**.5

def score(a, b):
  return (sd(a)*a[0] + sd(b)*b[0]) / (a[0] + b[0] + TINY)

def has(t, row, at, v):
  x = row[at]
  return x == "?" or (x <= v if at in t.num else x == v)

def bins(t, rows, at, Y):
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds(y for _,y in xy)
  bin = lambda here,k: (score(here, sub(tot,here)), at, k)
  if at not in t.num:
    for k in {x for x,_ in xy}:
      ys = [y for x,y in xy if x == k]
      if 0 < len(ys) < n: yield bin(adds(ys), k)
  else:
    xy.sort(); me = Num()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0]: yield bin(me, x)

def tree(t, rows, lvl=0):
  Y = lambda r: disty(t, r)
  w = o(at=None, n=len(rows), mu=adds(map(Y, rows))[1])
  w.score = w.mu
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if b := min((c for at in t.x
                 for c in bins(t,rows,at,Y)), default=None):
      _, at, v = b
      yes = [r for r in rows if has(t, r, at, v)]
      no  = [r for r in rows if not has(t, r, at, v)]
      if yes and no:
        w.at, w.v = at, v
        w.yes = tree(t, yes, lvl+1)
        w.no  = tree(t, no,  lvl+1)
        w.score = min(w.yes.score, w.no.score)
  return w

def leafed(x): return o(at=None, n=x.n, mu=x.mu, score=x.mu)

def walk(w):
  if w.at is None: yield w; return
  for yes in sides(w.yes):
    for no in sides(w.no):
      yield o(at=w.at, v=w.v, n=w.n, yes=yes, no=no,
              score=min(yes.score, no.score))

def sides(x):
  yield leafed(x)
  if x.at is not None: yield from walk(x)

def leaf(t, w, row):
  while w.at is not None:
    w = w.yes if has(t, row, w.at, w.v) else w.no
  return w.mu

def holdout(t, get=None):
  rows = shuffle(t.rows)
  half = len(rows)//2
  train, test = rows[:half], rows[half:]
  lab  = (get or acquire)(t, train)
  best = min(walk(tree(t, lab)), key=lambda x: x.score)
  top  = sorted(test, key=lambda r: leaf(t, best, r))
  return best, min(top[:the.check],
                   key=lambda r: disty(t, r)), test


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
