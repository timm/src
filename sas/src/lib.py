#!/usr/bin/env python3 -B
"""
lib.py: the substrate. Cells, columns, tables, distance,
and the statistics that police every claim in this book.
Reads its knobs from about.py. Imports nothing else but
the standard library.
"""
import random, math, sys
from about import o, the

TINY = 1e-32

#-- cells -------------------------------------------------------
def thing(s):
  "Coerce one csv cell: int, float, bool, else string."
  for fn in (int, float):
    try: return fn(s)
    except ValueError: pass
  s = s.strip()
  return {"True": True, "False": False}.get(s, s)

def csv(file):
  "Stream a csv file, one row of coerced cells at a time."
  with open(file) as f:
    for line in f:
      line = line.split("%")[0].strip()
      if line:
        yield [thing(s) for s in line.split(",")]

#-- random ------------------------------------------------------
def shuffle(lst):
  "All the items, in seeded-random order. Copies first."
  lst = lst[:]
  random.shuffle(lst)
  return lst

def some(lst, k):
  "k items at random (all of them, if k is too big)."
  return lst[:] if k >= len(lst) else random.sample(lst, k)

#-- columns -----------------------------------------------------
def Num(at=0, name=" "):
  "Summary of a numeric column."
  return o(it=Num, at=at, name=name, n=0, mu=0, m2=0,
           heaven=0 if name.endswith("-") else 1)

def Sym(at=0, name=" "):
  "Summary of a symbolic column."
  return o(it=Sym, at=at, name=name, n=0, has={})

def count(sym, v):
  "Update symbol counts."
  sym.n += 1
  sym.has[v] = 1 + sym.has.get(v, 0)

def welford(num, v):
  "One-pass update of mean and spread."
  num.n  += 1
  d       = v - num.mu
  num.mu += d / num.n
  num.m2 += d * (v - num.mu)

def add(i, v):
  "Fold a value into a column, or a row into a table."
  if i.it is Tbl:
    i.rows += [v]
    for col in i.cols: add(col, v[col.at])
  elif v != "?":
    (count if i.it is Sym else welford)(i, v)
  return v

def adds(lst, col=None):
  "Fold many values; guess Num or Sym from the first."
  for v in lst:
    col = col or (Num() if isinstance(v, (int, float))
                  else Sym())
    add(col, v)
  return col

def mid(col):
  "Central tendency: mean (Num) or mode (Sym)."
  return col.mu if col.it is Num else \
         max(col.has, key=col.has.get)

def var(col):
  "Dispersion: standard deviation (Num) or entropy (Sym)."
  if col.it is Sym:
    return -sum(k/col.n * math.log(k/col.n, 2)
                for k in col.has.values() if k > 0)
  return 0 if col.n < 2 else (max(col.m2, 0)
                              / (col.n - 1)) ** 0.5

def norm(col, v):
  "Map v to 0..1: the gaussian cdf of v (Nums only)."
  if v == "?" or col.it is Sym: return v
  return 0.5 * (1 + math.erf(
    (v - col.mu) / (var(col) * 2 ** 0.5 + TINY)))

#-- tables ------------------------------------------------------
def Tbl(src):
  "First row names the columns; the rest are data."
  src = iter(src)
  return adds(src, _tbl(next(src)))

def _tbl(names):
  "An empty table: column summaries, roles, no rows yet."
  cols = [(Num if s[0].isupper() else Sym)(at, s)
          for at, s in enumerate(names)]
  return o(it=Tbl, names=names, cols=cols, rows=[],
           x=[c.at for c in cols if c.name[-1] not in "X+-"],
           y=[c.at for c in cols if c.name[-1] in "+-"])

def clone(tbl, rows=[]):
  "A fresh table with the same header; optionally refill."
  return Tbl([tbl.names] + rows)

#-- distance ----------------------------------------------------
def distx(tbl, row1, row2):
  "Difference between two rows, over the x columns; 0..1."
  d = n = 0
  for at in tbl.x:
    col, a, b = tbl.cols[at], row1[at], row2[at]
    if a == "?" and b == "?": g = 1
    elif col.it is Sym:       g = a != b
    else:
      a, b = norm(col, a), norm(col, b)
      a = a if a != "?" else (0 if b > 0.5 else 1)
      b = b if b != "?" else (0 if a > 0.5 else 1)
      g = abs(a - b)
    d, n = d + g ** the.p, n + 1
  return (d / (n + TINY)) ** (1 / the.p)

def disty(tbl, row):
  "Distance from a row's goals to heaven; 0=best, 1=worst."
  d = n = 0
  for col in (tbl.cols[a] for a in tbl.y):
    v = row[col.at]
    if v != "?":
      d += abs(norm(col, v) - col.heaven) ** the.p
      n += 1
  return (d / (n + TINY)) ** (1 / the.p)

#-- clusters ----------------------------------------------------
def fastmap(tbl, rows=None):
  "Divide a table in two, splitting on two far points."
  rows = rows or tbl.rows
  far  = lambda row1: max(some(rows, the.few),
                key=lambda row2: distx(tbl, row1, row2))
  a    = far(random.choice(rows))
  b    = far(a)
  c    = distx(tbl, a, b) + TINY
  x    = lambda row: (distx(tbl, a, row)**2 + c*c
                      - distx(tbl, b, row)**2) / (2*c)
  rows = sorted(rows, key=x)
  n    = len(rows) // 2
  return a, b, clone(tbl, rows[:n]), clone(tbl, rows[n:])

#-- statistics --------------------------------------------------
def cohen(xs, ys, d=0.35):
  "Same if the means differ by under d times pooled sd."
  nx, ny = len(xs), len(ys)
  sx, sy = var(adds(xs)), var(adds(ys))
  sd = (((nx - 1) * sx * sx + (ny - 1) * sy * sy)
        / (nx + ny - 2)) ** 0.5
  return abs(mid(adds(xs)) - mid(adds(ys))) < d * sd

def cliffs(xs, ys):
  "Effect size: how often xs sit above or below ys; 0..1."
  n = gt = lt = 0
  for x in xs:
    for y in ys:
      gt += x > y
      lt += x < y
      n  += 1
  return abs(gt - lt) / n

def ks(xs, ys, crit=1.36):
  "Kolmogorov-Smirnov: same if max cdf gap under critical."
  xs, ys = sorted(xs), sorted(ys)
  nx, ny = len(xs), len(ys)
  d = i = j = 0
  while i < nx and j < ny:
    if xs[i] <= ys[j]: i += 1
    else:              j += 1
    d = max(d, abs(i / nx - j / ny))
  return d < crit * ((nx + ny) / (nx * ny)) ** 0.5

def same(xs, ys):
  "Same only if cohen AND cliffs AND ks all agree."
  return cohen(xs, ys) and cliffs(xs, ys) <= 0.197 \
         and ks(xs, ys)

#-- start-up ----------------------------------------------------
def cli(d):
  "Update settings from any --key=val flags."
  for k in d:
    for s in sys.argv:
      if s.startswith("--%s=" % k):
        d[k] = thing(s.split("=", 1)[1])
  return d

def main(g):
  "For each bare command-line word w, run test_w, seeded."
  cli(the.__dict__)
  todo = [s for s in sys.argv[1:]
          if not s.startswith("-")] or ["all"]
  for word in todo:
    random.seed(the.seed)
    g.get("test_" + word,
          lambda: print("?", word, "(no such test)"))()
