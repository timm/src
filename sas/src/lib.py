#!/usr/bin/env python3 -B
"""
lib.py: the substrate. Cells, columns, tables, distance,
and the statistics that police every claim in this book.
Reads its knobs from about.py. Imports nothing else but
the standard library.
"""
import random, sys
from math import exp, log, sqrt
from about import o, the

TINY = 1e-32

#-- cells -------------------------------------------------------
def thing(s): # string to int, float, bool, or string
  for fn in (int, float):
    try: return fn(s)
    except ValueError: pass
  s = s.strip()
  return {"True": True, "False": False}.get(s, s)

def csv(file): # stream rows of coerced cells
  with open(file) as f:
    for line in f:
      if (line := line.split("%")[0].strip()):
        yield [thing(s) for s in line.split(",")]

#-- random ------------------------------------------------------
def shuffle(lst): # seeded-random order; copies first
  lst = lst[:]; random.shuffle(lst); return lst

def some(lst, k): # k items at random (all, if k too big)
  return random.sample(lst, min(k, len(lst)))

#-- columns -----------------------------------------------------
def Col(name="", at=0): # column kind from name's first letter
  return (Sym if name[:1].islower() else Num)(name, at)

def Num(name="", at=0): # summary of a numeric column
  return o(it=Num, at=at, name=name, n=0, mu=0, m2=0,
           heaven=0 if name.endswith("-") else 1)

def Sym(name="", at=0): # summary of a symbolic column
  return o(it=Sym, at=at, name=name, n=0, has={})

def count(sym, v): # update symbol counts
  sym.n += 1; sym.has[v] = 1 + sym.has.get(v, 0)

def welford(num, v): # one-pass update of mu and m2
  num.n += 1; d = v - num.mu; num.mu += d / num.n
  num.m2 += d * (v - num.mu)

def entropy(sym): # diversity of symbolic distribution
  f = lambda p: p*log(p,2)
  return -sum(f(n/sym.n) for n in sym.has.values() if n > 0)

def mid(col): # center: mean (Num) or mode (Sym)
 return col.mu if col.it is Num else max(col.has,key=col.has.get)

def div(col): # diversity: sd (Num) or entropy (Sym)
  return entropy(col) if col.it is Sym else (
         0 if col.n < 2 else sqrt(max(col.m2, 0) / (col.n - 1)))

def norm(col, v): # v's cdf, via logistic; 0..1 (Nums only)
  if v == "?" or col.it is Sym: return v
  z = (v - col.mu) / (div(col) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z))))

#-- tables ------------------------------------------------------
def Tbl(src): # first row names columns; rest is data
  src   = iter(src)
  names = next(src)
  all   = [Col(s, at) for at, s in enumerate(names)]
  cols  = o(names=names, all=all,
            x=[c for c in all if c.name[-1] not in "X+-"],
            y=[c for c in all if c.name[-1] in "+-"])
  return adds(src, o(it=Tbl, rows=[], cols=cols, mid=None))

def add(i, v): # fold value into col, row into tbl
  if i.it is Tbl:
    i.rows += [v]; i.mid = None
    for col in i.cols.all: add(col, v[col.at])
  elif v != "?":
    (count if i.it is Sym else welford)(i, v)
  return v

def adds(lst, col=None): # fold many; Num unless told otherwise
  col = col or Num()
  for v in lst: add(col, v)
  return col

def clone(tbl, rows=[]): # same header, fresh summaries
  return Tbl([tbl.cols.names] + rows)

def mids(tbl): # return centroid of this tbl
  tbl.mid = tbl.mid or [mid(col) for col in tbl.cols.all]
  return tbl.mid

#-- distance ----------------------------------------------------
def distx(tbl, row1, row2): # row gap over x cols; 0..1
  d,n = 0,TINY
  for col in tbl.cols.x:
    a, b = row1[col.at], row2[col.at]
    if a == "?" and b == "?": g = 1
    elif col.it is Sym:       g = a != b
    else:
      a, b = norm(col, a), norm(col, b)
      a = a if a != "?" else (0 if b > 0.5 else 1)
      b = b if b != "?" else (0 if a > 0.5 else 1)
      g = abs(a - b)
    d, n = d + g ** the.p, n + 1
  return (d / n) ** (1 / the.p)

def disty(tbl, row): # goal gap to heaven; 0=best
  d,n = 0,TINY
  for col in tbl.cols.y:
    if (v := row[col.at]) != "?":
      d, n = d + abs(norm(col, v) - col.heaven)**the.p, n+1
  return (d / n) ** (1 / the.p)

#-- clusters ----------------------------------------------------
def project(tbl, row, a, b, c): # project row onto the a-b line
  return (distx(tbl,a,row)**2 + c*c
          - distx(tbl,b,row)**2) / (2*c + TINY)

def halve(tbl, rows=None): # split rows on far poles, best first
  rows = rows or tbl.rows
  far  = lambda r: max(some(rows, the.few),
                       key=lambda r2: distx(tbl, r, r2))
  a    = far(random.choice(rows))
  b    = far(a)
  c    = distx(tbl, a, b)
  if disty(tbl, b) < disty(tbl, a): a, b = b, a
  rows = sorted(rows, key=lambda r: project(tbl, r, a, b, c))
  n    = len(rows) // 2
  return a, b, rows[:n], rows[n:]

def Node(tbl, rows=None): # tree of halves
  rows = rows or tbl.rows
  node = o(it=Node, here=clone(tbl, rows),
           a=None, b=None, west=None, east=None)
  if len(rows) >= 2 * the.stop:
    node.a, node.b, west, east = halve(tbl, rows)
    if west and east:
      node.west, node.east = Node(tbl,west), Node(tbl,east)
  return node

def leaf(node, row): # walk row down to its leaf group
  while node.west:
    d = lambda pole: distx(node.here, row, pole)
    node = node.west if d(node.a) <= d(node.b) else node.east
  return node

#-- statistics --------------------------------------------------
def cohen(xsort, ysort): # mid gap, in units of spread
  mid = lambda a: a[len(a) // 2]
  spd = lambda a: (a[len(a)*9//10] - a[len(a)//10]) / 2.56
  return abs(mid(xsort) - mid(ysort)) / \
         ((spd(xsort) + spd(ysort)) / 2 + TINY)

def ks(xsort, ysort): # max cdf gap, in critical units
  nx, ny = len(xsort), len(ysort)
  d = i = j = 0
  while i < nx and j < ny:
    if xsort[i] <= ysort[j]: i += 1
    else:                    j += 1
    d = max(d, abs(i / nx - j / ny))
  return d / ((nx + ny) / (nx * ny)) ** 0.5

def cliffs(xsort, ysort): # rank imbalance; 0..1
  gt = lt = j = k = 0     # j,k: how many ys sit <x, <=x
  for x in xsort:         # x ascends, so j,k only advance
    while j < len(ysort) and ysort[j] <  x: j += 1
    while k < len(ysort) and ysort[k] <= x: k += 1
    gt += j; lt += len(ysort) - k
  return abs(gt - lt) / (len(xsort) * len(ysort))

def same(xs, ys,        # any evidence of "similar"?
         Cohen=0.2,     # J. Cohen 1988, stat. power analysis
         Ks=1.36,       # F. Massey 1951, Kolmogorov-Smirnov
         Cliffs=0.197): # N. Cliff 1993, dominance statistics
  xsort, ysort = sorted(xs), sorted(ys)
  return (cohen(xsort, ysort) < Cohen
          or ks(xsort, ysort) < Ks
          or cliffs(xsort, ysort) <= Cliffs)

def top(d, max=False): # winners; best = least, unless max
  out, mid = [], lambda a: sorted(a)[len(a) // 2]
  for k in sorted(d, key=lambda k: mid(d[k]), reverse=max):
    if out and not same(d[out[0]], d[k]): break
    out += [k]
  return out

#-- start-up ----------------------------------------------------
def cli(d): # --key=val flags update settings
  for k in d:
    for s in sys.argv:
      if s.startswith("--%s=" % k):
        d[k] = thing(s.split("=", 1)[1])
  return d

def main(g): # for each bare word w, run test_w, seeded
  cli(the.__dict__)
  todo = [s for s in sys.argv[1:]
          if not s.startswith("-")] or ["all"]
  for word in todo:
    random.seed(the.seed)
    g.get("test_" + word,
          lambda: print("?", word, "(no such test)"))()
