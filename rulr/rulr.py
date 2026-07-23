#!/usr/bin/env python3 -B
"""
rulr: greedy rule learner for optimization CSV data.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 rulr-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --leaf   min rows to keep going = 3
  --check  rows checked on test  = 5
  --round  decimals shown        = 3
  -h       print this help

TESTS: (in rulr-eg.py; run with their bare name):
  tbl disty entropy cut grow holdout   one seam each
  all      run every test above, reseting seed each
"""
"""
IDEA: grow one conjunctive rule, never looking back. Each
round: sort the rows by disty, call the top sqrt(n) best
and the rest rest, find the single (col,value) cut that
best separates them (min ent), keep only the rows on
the best side, recurse. The rule is the cuts seen on the
way down.
"""
import os, re, sys, random
from math import log2
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
  for row in src:
    t.rows += [row]
    for at in t.num:
      if (v := row[at]) != "?":
        t.lo[at] = min(v, t.lo.get(at,  BIG))
        t.hi[at] = max(v, t.hi.get(at, -BIG))
  return t

def norm(t,at,v): 
  lo,hi = t.lo[at],t.hi[at]
  return (v - lo)/(hi - lo + TINY)

def disty(t, row):
  d = [abs(norm(t,at,row[at]) - g)
       for at, g in t.y.items() if row[at] != "?"]
  return (sum(x*x for x in d) / len(d)) ** .5

def sat(t,at,x,v): return x <= v if at in t.num else x == v

def match(t, row, c):
  at, v, keep = c
  return row[at] == "?" or sat(t, at, row[at], v) == keep

Sym = dict

def size(d): return sum(d.values())

def ent(d):
  N = size(d)
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def count(sym, v):
  sym[v] = sym.get(v, 0) + 1
  return sym

def mix(i, j, inc=1):
  return {k: i.get(k,0) + inc*j.get(k,0) for k in i | j}

def adds(src, i):
  for v in src: i = add(i, v)
  return i

def add(i, v): return i if v == "?" else count(i, v)

def score(here, there):
  a, b = size(here), size(there)
  return (ent(here)*a + ent(there)*b) / (a + b + TINY)

def bins(t, rows, at, Y):
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), Sym())
  bin = lambda here,k: (score(here, mix(tot,here,-1)), at, k)
  if at not in t.num:
    for k in {x for x,_ in xy}:
      ys = [y for x,y in xy if x == k]
      if 0 < len(ys) < n: yield bin(adds(ys, Sym()), k)
  else:
    xy.sort(); me = Sym()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0]: yield bin(me, x)

def cut(t, rows, Y):
  b = min((c for at in t.x for c in bins(t, rows, at, Y)),
          default=None)
  if not b: return None
  _, at, v = b
  d = {True: Sym(), False: Sym()}
  for r in rows:
    if (x := r[at]) != "?":
      d[sat(t, at, x, v)] = add(d[sat(t, at, x, v)], Y(r))
  good = lambda i: i.get("best", 0) / (size(i) + TINY)
  return at, v, good(d[True]) >= good(d[False])

def grow(t, rows):
  rule = []
  while len(rows) >= 2*the.leaf:
    rows = sorted(rows, key=lambda r: disty(t, r))
    n    = max(1, int(len(rows)**.5))
    tag  = {id(r): "best" if i < n else "rest"
            for i, r in enumerate(rows)}
    if not (c := cut(t, rows, lambda r: tag[id(r)])): break
    rule.append(c)
    kept = [r for r in rows if match(t, r, c)]
    if len(kept) == len(rows): break
    rows = kept
  return rule

def show(t, c):
  at, v, keep = c
  op = (("<=" if keep else ">") if at in t.num
        else ("==" if keep else "!="))
  v  = round(v, the.round) if type(v) == float else v
  return "%s %s %s" % (t.names[at], op, v)

def holdout(t):
  rows = shuffle(t.rows)
  half = len(rows)//2
  train, test = rows[:half], rows[half:]
  rule = grow(t, train)
  m    = lambda r: sum(match(t, r, c) for c in rule)
  top  = sorted(test, key=m, reverse=True)[:the.check]
  return rule, min(top, key=lambda r: disty(t,r)), test

def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s): 
  return os.path.expanduser(s.replace("$MOOT",MOOT,1))

def csv(file,clean=lambda s: s.partition("#")[0].split(",")):
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]

def shuffle(lst): return random.sample(lst, len(lst))

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
