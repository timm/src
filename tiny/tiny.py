#!/usr/bin/env python3 -B
"""
tiny: prune-race regression trees for optimization CSV data.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 tiny.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --budget labels; 0: all train  = 0
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 4
  --check  rows checked on test  = 5
  --round  decimals shown        = 3
  -h       print this help

TESTS: (run with their bare name):
  tree     build+show a depth-maxd tree on all rows
  walk     count all pruned variants of that tree
  holdout  50:50 split; race the variants on train;
           winner picks rows from test
  all      run every test above, reseting seed each
"""
"""
IDEA: a regression tree splits rows on the binary cut that
minimizes the expected sd of y after the cut. Any subtree of
that tree can collapse to a leaf: at every cut, both sides
exit as leaves or one exits and the other descends -- the
fast-and-frugal prunings, at most 2^d - 1 trees. That pool
is small enough to score exhaustively: `race` judges every
pruning by the actual y of the rows it routes to its
best-predicted leaf, and the lowest mean wins.
"""
import os, re, sys, random
from math import log2, exp
from types import SimpleNamespace as o
BIG  = 1e32
TINY = 1e-32
MOOT = (os.environ.get("MOOT")
        or os.path.expanduser("~/gits/moot"))

#-- lib ---------------------------------------------------------
# Strings and files. `thing` coerces csv cells; `settings`
# parses the help text's "--key = val" lines into `the`;
# `csv` streams typed rows, `path` expanding a leading $MOOT
# (env var, else ~/gits/moot). `shuffle` = seeded reorder.
# Coerce a string to int/float/bool, else leave as str

def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  "Parse '--key ... = val' lines of doc into an o()"
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s):
  "Expand a leading $MOOT (env, else ~/gits/moot) and ~"
  s = s.replace("$MOOT", MOOT, 1)
  return os.path.expanduser(s)

def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  "Yield typed rows (lists) from a CSV file"
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]

# All of lst, in seeded-random order
def shuffle(lst): return random.sample(lst, len(lst))

# K items picked at random
def some(lst, k): return random.sample(lst, min(k, len(lst)))

#-- cols --------------------------------------------------------
# Column summaries. `Num` is a (n,mu,m2) tuple grown by
# `welford`; `Sym` is a dict of counts. `mid`/`var` =
# centrality and dispersion for either; `mix` merges two
# summaries (inc=-1 subtracts).

Sym = dict
def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def n_(num)  : return num[0]
def mu_(num) : return num[1]
def m2_(num) : return num[2]

def is_sym(i): return isinstance(i, dict)  # Sym = dict of counts

def size(i): return sum(i.values()) if is_sym(i) else n_(i)

def mid(i): return max(i,key=i.get) if is_sym(i) else mu_(i)
def var(i): return entropy(i)       if is_sym(i) else sd(i)

def sd(num): n,_,m2=num;return 0 if n<2 else(max(0,m2)/(n-1))**.5

def entropy(d):
  "Shannon entropy of a Sym (a dict of counts)"
  N = size(d) or 1
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def count(sym,v,inc=1):
  "Change or delete keys"
  if (c := sym.get(v,0) + inc) > 0: sym[v] = c
  else: sym.pop(v, None)
  return sym

def welford(num, v, inc=1):
  "Fold v into a Num (inc=-1 removes); return new (n,mu,m2)"
  n, mu, m2 = num
  if (n := n + inc) <= 0: return Num()
  d = v - mu; mu += inc * d / n
  return (n, mu, m2 + inc * d * (v - mu))

def mix(i, j, inc=1):
  "Merge two cols; inc=-1 subtracts j from i"
  if is_sym(i):
    return {k: i.get(k, 0) + inc * j.get(k, 0) for k in i | j}
  (ni, mui, m2i), (nj, muj, m2j) = i, j
  n = ni + inc * nj
  if n <= 0: return Num()
  d  = muj - mui
  mu = (ni * mui + inc * nj * muj) / n
  m2 = m2i + inc * m2j + inc * d * d * ni * nj / n
  return Num(n, mu, max(0, m2))  # subtraction can underflow m2

#-- tbl ---------------------------------------------------------
# Tables. `Tbl` = o(names, cols, x, y, rows, ...). `Cols`
# types columns from header suffixes; `add` folds one row in
# (inc=-1 removes); `adds` folds any stream.
# Build a table; first row = column names

def Tbl(src):
  src  = iter(src)
  tbl = o(names=next(src), cols={}, x=[], y=[], goal={},
           klass=None, protect=[], rows=[], mid=None)
  return adds(src, Cols(tbl))

def Cols(tbl):
  "Tag cols x/y/klass/protect from name suffixes"
  for at, s in enumerate(tbl.names):
    tbl.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if s[-1] in "+-!":
      tbl.y += [at]; tbl.goal[at] = s[-1] == "+"
      if s[-1] == "!": tbl.klass = at
    else:
      tbl.x += [at]
      if s[-1] == "~": tbl.protect += [at]
  return tbl

def adds(src, i=None):
  "Fold a stream of values/rows into i (Num by default)"
  i = Num() if i is None else i  # keep empty Sym; {} is falsy
  for v in src: i = add(i,v)
  return i

def add(i,v,inc=1):
  "Add one value/row to i (inc=-1 removes)"
  if isinstance(i,o):
    i.mid = None  # invalidate cached centroid
    for at,col in i.cols.items(): i.cols[at] = add(col,v[at],inc)
    (i.rows.append if inc==1 else i.rows.remove)(v)
    return i
  if v=="?": return i
  return (count if is_sym(i) else welford)(i, v, inc=inc)

#-- dist --------------------------------------------------------
# Distances. `norm` squashes a num to 0..1 by a logistic
# z-score. `disty` = distance to the ideal goals over y
# (0 = best); `labelled` is the live-model hook.
# Map v to 0..1 via a logistic on its z-score

def norm(num, v):
  if v == "?": return v
  z = (v - mu_(num)) / (sd(num) + 1e-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

def minkowski(vals, p=2):
  "Aggregate per-item distances via the p-norm"
  tot = nn = 0
  for v in vals: tot += v**p; nn += 1
  return (tot / (nn or 1)) ** (1/p)

# Hook: label a row on demand
def labelled(row): return row

def disty(tbl, row, **kw):
  "Row's distance to the best goals (0 = ideal)"
  row = labelled(row)
  return minkowski(
    (abs(norm(tbl.cols[at], row[at]) - tbl.goal[at])
     for at in tbl.y if row[at] != "?"), **kw)

#-- bins --------------------------------------------------------
# Bins. `bins` yields candidate (cost,at,v) splits for one
# column; `score` = size-weighted var of the two halves (the
# far half computed by `mix`, not a second pass); sides must
# hold at least the.leaf rows. accum=Num|Sym flips the same
# code between regression and classification.

def score(here, there):
  "Split cost (lower=better): size-weighted mean of var"
  a, b = size(here), size(there)
  return (var(here)*a + var(there)*b) / (a + b + 1e-32)

def bins(tbl,rows,at,Y,accum=Num):
  "Yield (cost,at,v) bins; sides >= the.leaf; accum=Num|Sym"
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), accum())
  bin = lambda here,k: (score(here, mix(tot,here,-1)), at,k)
  big = lambda lo: the.leaf <= lo <= n-the.leaf
  if is_sym(tbl.cols[at]):
    for k in {x for x,_ in xy}:
      ys = [y for x,y in xy if x==k]
      if big(len(ys)): yield bin(adds(ys, accum()), k)
  else:
    xy.sort(); me=accum()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0] and big(j+1):
        yield bin(me, x)

#-- tree --------------------------------------------------------
# Trees. `tree` recurses the min-cost bin while rows and
# depth allow; leaves keep their rows and a `mid`
# prediction. `has` picks a row's side of a bin (? = yes);
# `leaf` routes a row down; `leaves` yields them all.
# Does row fall on the yes-side of a bin? (? = yes)

def has(row, col, at, v):
  w = row[at]
  return w == "?" or (v == w if is_sym(col) else w <= v)

def tree(tbl, rows, Y=None, accum=Num, lvl=0):
  "Recursively split rows on the min-cost bin; accum=Num|Sym"
  Y = Y or (lambda r: disty(tbl, r))
  t = o(at=None, mid=mid(adds((Y(r) for r in rows), accum())),
        n=len(rows), rows=rows)
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if bin:=min((c for at in tbl.x for c in
                 bins(tbl,rows,at,Y,accum)), default=0):
      _, at, v = bin
      col = tbl.cols[at]
      yes, no = [], []
      for r in rows: (yes if has(r,col,at,v) else no).append(r)
      if yes and no:
        t.at, t.v = at, v
        t.yes = tree(tbl, yes, Y, accum, lvl+1)
        t.no  = tree(tbl, no,  Y, accum, lvl+1)
  return t

def sink(tbl, t, row):
  "Walk a row down to its leaf node"
  while t.at is not None:
    t = t.yes if has(row,tbl.cols[t.at],t.at,t.v) else t.no
  return t

def leaf(tbl, t, row):
  "Walk a row down to its leaf; return the leaf's mid"
  return sink(tbl, t, row).mid

def leaves(t):
  "Yield every leaf node of a tree"
  if t.at is None: yield t
  else: yield from leaves(t.yes); yield from leaves(t.no)

#-- walk --------------------------------------------------------
# Prunings. `walk` yields the fft-style prunings of a tree:
# below each cut, both sides exit as leaves (`leafed`), or
# ONE side exits and the other descends -- so a depth-d
# tree yields at most 2^d - 1 prunings. (Letting both sides
# descend grows the pool doubly-exponentially, and in 1270
# raced winners over the whole corpus that shape never won,
# so it is not generated.) `race` scores every pruning on
# every row: judge a tree by the actual Y of rows it routes
# to its best-predicted leaf (a Num seeded with that leaf's
# build-time mid, so a tree no row reaches still has a
# score); lowest mean wins.
# Collapse a subtree to a leaf keeping its rows and mid

def leafed(t): return o(at=None, mid=t.mid, n=t.n, rows=t.rows)

def walk(t):
  "Yield prunings: both sides leaf, or one side descends"
  if t.at is None: yield t; return
  node = lambda yes, no: o(at=t.at, v=t.v, mid=t.mid, n=t.n,
                           rows=t.rows, yes=yes, no=no)
  yield node(leafed(t.yes), leafed(t.no))
  if t.no.at is not None:
    for sub in walk(t.no): yield node(leafed(t.yes), sub)
  if t.yes.at is not None:
    for sub in walk(t.yes): yield node(sub, leafed(t.no))

def race(tbl, ts, rows, Y):
  "Judge each tree by its best leaf's actual Y; take min"
  def worth(t):
    b = min(leaves(t), key=lambda l: l.mid)
    return mu_(adds((Y(r) for r in rows if sink(tbl,t,r) is b),
                    Num(1, b.mid, 0)))
  return min(ts, key=worth)

#-- show --------------------------------------------------------
# Tree show. `show` prints win, n, per-goal means, then
# indented branch conditions (best leaf marked with an up
# triangle, worst down); `branch` recurses best-kid-first;
# `cond` renders one test as text; `wins` grades rows:
# 100 = best, 0 = median, clamped to [-100,100].
# One branch as text, e.g. 'Volume <= 108'

def cond(tbl, t, yes):
  op = (("==" if yes else "!=") if is_sym(tbl.cols[t.at])
        else ("<=" if yes else ">"))
  v  = round(t.v, the.round) if type(t.v)==float else t.v
  return "%s %s %s" % (tbl.names[t.at], op, v)

def wins(tbl, rows=None):
  "Grader: row -> % of gap to best closed, [-100,100]"
  ys = sorted(disty(tbl,r) for r in rows or tbl.rows)
  lo, b4 = ys[0], ys[len(ys)//2]
  return lambda r: max(-100, min(100,
    100 * (1 - (disty(tbl,r)-lo) / (b4-lo+TINY))))

def show(tbl, t):
  "Pretty-print a tree: win, n, goal means, then branches"
  W   = wins(tbl, t.rows)
  win = lambda rows: int(mu_(adds(map(W, rows))))
  ws  = [win(x.rows) for x in leaves(t)]
  print("%s %4s %5s  %s" % (" ", "win", "n",
    " ".join("%8s" % tbl.names[a] for a in tbl.y)))
  branch(tbl, t, win, min(ws), max(ws))

def branch(tbl, t, win, lo, hi, pad="", edge=""):
  "One line per node, then recurse (best kid first)"
  w = win(t.rows)
  m = " " if t.at is not None else (              # mark leaves:
      chr(0x25B2) if w==hi else                   # best=up,
      chr(0x25BC) if w==lo else " ")              # worst=down
  mids = " ".join("%8.*f" % (the.round, mid(adds(r[a]
         for r in t.rows))) for a in tbl.y)
  print(("%s %4d %5d  %s  %s%s" % (
         m,w,t.n,mids,pad,edge)).rstrip())
  if t.at is not None:
    pad += "|  " if edge else ""
    for kid, yes in sorted([(t.yes,True), (t.no,False)],
                           key=lambda kb: kb[0].mid):
      branch(tbl, kid, win, lo, hi, pad, cond(tbl, t, yes))

#-- main --------------------------------------------------------
# Main. `holdout` is the evaluation rig: split 50:50, grow a
# depth-maxd tree on train, race its prunings on train, then
# let the winner rank the unseen half, check only the top
# few rows, return the best found. `main` maps --key=val
# flags onto `the`, then runs any test_* named on the
# command line.
# Rig: train tree -> race prunings -> winner picks test row

def holdout(tbl):
  rows  = shuffle(tbl.rows)
  half  = len(rows)//2
  train, test = rows[:half], rows[half:]
  if the.budget: train = some(train, the.budget - the.check)
  Y     = lambda r: disty(tbl, r)
  best  = race(tbl, list(walk(tree(tbl, train))), train, Y)
  top   = sorted(test, key=lambda r: leaf(tbl,best,r))
  return min(top[:the.check], key=Y), test

def main(funs):
  "Apply --key=val to `the`, then run named test_* in `funs`"
  if "-h" in sys.argv: return print(__doc__)
  for a in sys.argv[1:]:
    if a[:2]=="--" and "=" in a:
      k,v = a[2:].split("=",1)
      if k in vars(the): setattr(the, k, thing(v))
  for a in sys.argv[1:]:
    if (n := "test_"+a) in funs:
      random.seed(the.seed); funs[n]()

def test_tree():
  "Grow one depth-maxd tree over all rows; show it"
  tbl = Tbl(csv(the.file))
  show(tbl, tree(tbl, tbl.rows))

def test_walk():
  "Count the prunings of one tree; full tree is among them"
  tbl = Tbl(csv(the.file))
  t   = tree(tbl, tbl.rows)
  ts  = list(walk(t))
  print("cuts %s, prunings %s" %
        (sum(1 for _ in leaves(t)) - 1, len(ts)))
  assert len(ts) > 1

def test_holdout():
  "Race prunings on train; winner's test pick beats median"
  tbl = Tbl(csv(the.file))
  got, test = holdout(tbl)
  ys = sorted(disty(tbl,r) for r in test)
  print("got %.*f  best %.*f  median %.*f" % (
    the.round, disty(tbl,got), the.round, ys[0],
    the.round, ys[len(ys)//2]))
  assert disty(tbl,got) <= ys[len(ys)//2]

def test_all():
  "Every test above, reseeding before each"
  for f in (test_tree, test_walk, test_holdout):
    random.seed(the.seed); f()

the = settings(__doc__)
if __name__ == "__main__": main(globals())
