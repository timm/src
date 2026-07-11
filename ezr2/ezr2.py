#!/usr/bin/env python3 -B
"""
ezr2: landscape analysis for xai and optimization CSV data.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 ezr2-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 8
  --grow   add labels/round      = 4
  --budget labeling cap          = 50
  --cap    max rows kept         = 1024
  --check  rows labelled by tree = 5
  --keepf  keep frac             = 0.66
  --round  decimals shown        = 3
  --landscape  active | random   = active
  -h       print this help

TESTS: (run with their bare name):
  disty       rows by disty: top 5 / bottom 5
  landscape   20 shuffles; best disty per run
  landscapes  one mean-win line (the sweep)
  tree      build+show a tree on acquired rows
  holdout  50:50 split; tree picks best test row
  holdouts holdout x20; land vs random verdict
  pure     no tree: best labelled, land vs random
  same     demo+validate the same() stat test
  all      run every test above, reseting seed each
"""
"""
INSTALL: grab two files; data lives in the moot repo
(tiny.cc/moot), cloned to ~/gits/moot (or set $MOOT):
  REPO=https://raw.githubusercontent.com/timm/src/main/ezr2
  wget $REPO/ezr2.py $REPO/ezr2-eg.py
  git clone https://github.com/timm/moot ~/gits/moot
  python3 ezr2-eg.py disty

MODES: optimize a static CSV (format below), or a live model by
  overriding labelled() to compute goals live -- worked example
  in dtlz.py ($REPO/dtlz.py).

DATA: comma-separated, first row names the columns. A name's last
character sets that column's role; its first sets its type:
  Upper case first letter  -> numeric  (else: symbolic)
  +  /  -   suffix         -> goal: maximize / minimize  (y-col)
  !         suffix         -> klass   (a y-column)
  X         suffix         -> ignore this column
  ~         suffix         -> protected x-column
  (no suffix)              -> ordinary x-column (input)
E.g. auto93 header Clndrs,Volume,HpX,Model,origin,Lbs-,Acc+,Mpg+
has numeric inputs (Clndrs/Volume/Model), symbolic input origin,
an ignored column (HpX); goals minimize Lbs, maximize Acc/Mpg.

DISTY: each row's "distance to heaven" -- its distance to ideal
point where goals are best (0 = ideal, 1 = worst). `disty` reads
only the y-columns, so optimization scores a row without seeing
how it was made. `python3 ezr2-eg.py disty` sorts by disty and
prints the best 5, a blank line, then the worst 5:

  Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
       4      90   48     78       2  1985  21.5    40  0.075
       ...                                              ...
       8     455  225     70       1  4425    10    10  0.954

Best rows (disty~0) are light, high-Mpg cars; worst (disty~1) are
heavy guzzlers. Optimizers seek low-disty rows while labelling
(inspecting the y of) as few rows as possible.
"""
import os, re, sys, random
from math import log2, exp
from bisect import bisect_left, bisect_right
from types import SimpleNamespace as o
BIG = 1e32
TINY = 1e-32


#-- Cols --------------------------------------------------------
# `Num` is a (n,mu,m2) tuple grown by `welford`; `Sym` is a
# dict of counts. `mid`/`var` = centrality and dispersion for
# either; `mix` merges two summaries (inc=-1 subtracts);
# `pick` samples one (roulette or Irwin-Hall bell).
Sym = dict
def is_sym(i): return isinstance(i, dict)  # Sym = dict of counts
def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def n_(num)  : return num[0]
def mu_(num) : return num[1]
def m2_(num) : return num[2]

def mid(i): return max(i,key=i.get) if is_sym(i) else mu_(i)
def var(i): return entropy(i)       if is_sym(i) else sd(i)

def sd(num): n,_,m2=num;return 0 if n<2 else(max(0,m2)/(n-1))**.5

def entropy(d):
  "Shannon entropy of a Sym (a dict of counts)."
  N = sum(d.values()) or 1
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def count(sym,v,inc=1):
  "Change or delete keys."
  if (c := sym.get(v,0) + inc) > 0: sym[v] = c
  else: sym.pop(v, None)             
  return sym

def welford(num, v, inc=1):
  "Fold v into a Num (inc=-1 removes); return new (n,mu,m2)."
  n, mu, m2 = num
  if (n := n + inc) <= 0: return Num()
  d = v - mu; mu += inc * d / n
  return (n, mu, m2 + inc * d * (v - mu))

def mix(i, j, inc=1):
  "Merge two cols; inc=-1 subtracts j from i."
  if is_sym(i):
    return {k: i.get(k, 0) + inc * j.get(k, 0) for k in i | j}
  (ni, mui, m2i), (nj, muj, m2j) = i, j
  n = ni + inc * nj
  if n <= 0: return Num()
  d  = muj - mui
  mu = (ni * mui + inc * nj * muj) / n
  m2 = m2i + inc * m2j + inc * d * d * ni * nj / n
  return Num(n, mu, max(0, m2))  # subtraction can underflow m2

def pick(col, v=None):
  "Sample one value: roulette for a Sym, Irwin-Hall for a Num."
  if is_sym(col):                  # roulette wheel over counts
    n = sum(col.values()) * random.random()
    for k, c in col.items():
      if (n := n - c) <= 0: return k
    return k
  mu = mu_(col) if v is None or v == "?" else v  # bell at v|mu
  r  = random.random
  return mu + sd(col)*2*(r()+r()+r()-1.5)


#-- Data --------------------------------------------------------
# `Data` = o(names, cols, x, y, rows, ...). `roles` types
# columns from header suffixes; `add` folds one row in
# (inc=-1 removes, `mids` caches the centroid); `clone`
# reuses a header; `adds` folds any stream.
def Data(src):
  "Build a table; first row = column names."
  src  = iter(src)
  data = o(names=next(src), cols={}, x=[], y=[], goal={},
           klass=None, protect=[], rows=[], mid=None)
  return adds(src, roles(data))

def clone(data, rows):
  "Fresh Data over a subset of rows."
  return Data([data.names] + rows)

def mids(data):
  "Cached centroid: per-column mid, rebuilt after add/remove."
  data.mid = data.mid or [mid(col) for col in data.cols.values()]
  return data.mid

def roles(data):
  "Tag cols x/y/klass/protect from name suffixes."
  for at, s in enumerate(data.names):
    data.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if s[-1] in "+-!":
      data.y += [at]; data.goal[at] = s[-1] == "+"
      if s[-1] == "!": data.klass = at
    else:
      data.x += [at]
      if s[-1] == "~": data.protect += [at]
  return data

def adds(src, i=None):
  "Fold a stream of values/rows into i (Num by default)."
  i = Num() if i is None else i  # keep empty Sym; {} is falsy
  for v in src: i = add(i,v)
  return i

def add(i,v,inc=1):
  "Add one value/row to i (inc=-1 removes)."
  if isinstance(i,o):
    i.mid = None  # invalidate cached centroid
    for at,col in i.cols.items(): i.cols[at] = add(col,v[at],inc)
    (i.rows.append if inc==1 else i.rows.remove)(v)
    return i
  if v=="?": return i
  return (count if is_sym(i) else welford)(i, v, inc=inc)


#-- Dist --------------------------------------------------------
# `norm` squashes a num to 0..1 by a logistic z-score.
# `disty` = distance to the ideal goals over y (0 = best);
# `gap` scores one column pair for `distx`, distance over x.
# `labelled` is the live-model hook (see dtlz.py). `wins`
# grades rows: 100 = best, 0 = median, [-100,100].

def norm(num, v):
  "Map v to 0..1 via a logistic on its z-score."
  if v == "?": return v
  z = (v - mu_(num)) / (sd(num) + 1e-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

def minkowski(vals, p=2):
  "Aggregate per-item distances via the p-norm."
  tot = nn = 0
  for v in vals: tot += v**p; nn += 1
  return (tot / (nn or 1)) ** (1/p)

def gap(col, u, v):
  "Distance 0..1 between two values of one column."
  if u == v == "?": return 1
  if is_sym(col): return u != v
  u, v = norm(col, u), norm(col, v)
  if u == "?": u = 1 if v < .5 else 0
  if v == "?": v = 1 if u < .5 else 0
  return abs(u - v)

def labelled(row): return row

def disty(data, row, **kw):
  "Row's distance to the best goals (0 = ideal)."
  row = labelled(row)
  return minkowski(
    (abs(norm(data.cols[at], row[at]) - data.goal[at])
     for at in data.y if row[at] != "?"), **kw)

def distx(data, r1, r2, **kw):
  "Distance between two rows over the x-columns."
  return minkowski((gap(data.cols[at], r1[at], r2[at])
                    for at in data.x), **kw)

def wins(data, rows=None):
  "Grader: row -> % of gap to best closed, [-100,100]."
  ys = sorted(disty(data,r) for r in rows or data.rows)
  lo, b4 = ys[0], ys[len(ys)//2]
  return lambda r: max(-100, min(100,
    100 * (1 - (disty(data,r)-lo) / (b4-lo+TINY))))


#-- Tree build --------------------------------------------------
# `cuts` yields candidate (cost,at,v) splits per column;
# `score` = size-weighted var of the halves; `tree` recurses
# the min-cost cut; `has` picks a row's side (? = yes);
# `leaf` routes a row down. accum=Num|Sym flips the same
# code between regression and classification.
def size(c): return sum(c.values()) if is_sym(c) else n_(c)

def score(here, there):
  "Split cost (lower=better): size-weighted mean of var."
  a, b = size(here), size(there)
  return (var(here)*a + var(there)*b) / (a + b + 1e-32)

def cuts(data,rows,at,Y,accum=Num):
  "Yield (cost,at,v) cuts; sides >= the.leaf. accum=Num|Sym"
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), accum())
  cut = lambda here,k: (score(here, mix(tot,here,-1)), at,k)
  big = lambda lo: the.leaf <= lo <= n-the.leaf
  if is_sym(data.cols[at]):
    for k in {x for x,_ in xy}:
      ys = [y for x,y in xy if x==k]
      if big(len(ys)): yield cut(adds(ys, accum()), k)
  else:
    xy.sort(); me=accum()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0] and big(j+1):
        yield cut(me, x)

def has(row, col, at, v):
  "Does row fall on the yes-side of a cut? (? = yes)."
  w = row[at]
  return w == "?" or (v == w if is_sym(col) else w <= v)

def tree(data, rows, Y=None, accum=Num, lvl=0):
  "Recursively split rows on the min-cost cut. accum=Num|Sym."
  Y = Y or (lambda r: disty(data, r))
  t = o(at=None, mid=mid(adds((Y(r) for r in rows), accum())),
        n=len(rows), rows=rows)
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if cut := min((c for at in data.x
        for c in cuts(data,rows,at,Y,accum)), default=0):
      _, at, v = cut
      col = data.cols[at]
      yes, no = [], []
      for r in rows: (yes if has(r,col,at,v) else no).append(r)
      if yes and no:
        t.at, t.v = at, v
        t.yes = tree(data, yes, Y, accum, lvl+1)
        t.no  = tree(data, no,  Y, accum, lvl+1)
  return t

def leaf(data, t, row):
  "Walk a row down to its leaf; return the leaf's mid."
  while t.at is not None:
    t = t.yes if has(row,data.cols[t.at],t.at,t.v) else t.no
  return t.mid


#-- Tree show ---------------------------------------------------
# `show` prints win, n, per-goal means, then indented
# branch conditions (best leaf marked with an up triangle,
# worst down); `branch` recurses best-kid-first; `cond`
# renders one test as text.
def leaves(t):
  "Yield every leaf node of a tree."
  if t.at is None: yield t
  else: yield from leaves(t.yes); yield from leaves(t.no)

def cond(data, t, yes):
  "One branch as text, e.g. 'Volume <= 108'."
  op = (("==" if yes else "!=") if is_sym(data.cols[t.at])
        else ("<=" if yes else ">"))
  v  = round(t.v, the.round) if type(t.v)==float else t.v
  return "%s %s %s" % (data.names[t.at], op, v)

def show(data, t):
  "Pretty-print a tree: win, n, goal means, then branches."
  W   = wins(data, t.rows)
  win = lambda rows: int(mu_(adds(map(W, rows))))
  ws  = [win(x.rows) for x in leaves(t)]
  print("%s %4s %5s  %s" % (" ", "win", "n",
    " ".join("%8s" % data.names[a] for a in data.y)))
  branch(data, t, win, min(ws), max(ws))

def branch(data, t, win, lo, hi, pad="", edge=""):
  "One line per node, then recurse (best kid first)."
  w = win(t.rows)
  m = " " if t.at is not None else (              # mark leaves:
      chr(0x25B2) if w==hi else                   # best=up,
      chr(0x25BC) if w==lo else " ")              # worst=down
  mids = " ".join("%8.*f" % (the.round, mid(adds(r[a]
         for r in t.rows))) for a in data.y)
  print(("%s %4d %5d  %s  %s%s" % (
         m,w,t.n,mids,pad,edge)).rstrip())
  if t.at is not None:
    pad += "|  " if edge else ""
    for kid, yes in sorted([(t.yes,True), (t.no,False)],
                           key=lambda kb: kb[0].mid):
      branch(data, kid, win, lo, hi, pad, cond(data, t, yes))


#-- Landscape ---------------------------------------------------
# The active learner. `project` maps rows onto the line
# joining two far labelled poles; `landscape` labels a few,
# culls the third nearest the bad pole, repeats -- spending
# at most budget-check labels, returned best first.
def project(rows, x, y):
  "Row -> position on the east-west line (x=dist,y=goal)."
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = far(rows[0]); west = far(east)
  if y(east) < y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def landscape(data):
  "Label <=budget-check rows, best first. --landscape picks how."
  y   = lambda r: disty(data, r)
  cap = the.budget - the.check
  if the.landscape == "random":
    return sorted(some(data.rows, cap), key=y)
  x   = lambda r1, r2: distx(data, r1, r2)
  pool = shuffle(data.rows)
  lab  = {}
  while len(lab) < cap and len(pool) >= 2*the.leaf:
    here, grown = [], 0
    for r in pool:
      if id(r) not in lab and grown<the.grow and len(lab) < cap:
        lab[id(r)] = r; grown += 1
      if id(r) in lab: here.append(r)
    if len(lab) < cap:                       
      n = max(1, int((1-the.keepf)*len(pool)))
      pool = sorted(pool, key=project(here, x, y))[n:]
  return sorted(lab.values(), key=y)


#-- misc --------------------------------------------------------
# `shuffle`/`some` = seeded sampling. `cliffs`+`ks`+`cohen`
# feed `same`, the conservative stats-equality. `thing`
# coerces strings; `settings` parses the docstring into
# `the`; `csv` streams rows, `path` expanding $MOOT.
def shuffle(lst): return random.sample(lst, len(lst))
def some(lst, k): return random.sample(lst, min(k, len(lst)))

def cliffs(xs, ys):
  "Cliff's delta effect size in 0..1 (0 = identical)."
  ys = sorted(ys); m = len(ys)
  gt = sum(bisect_left(ys, x)      for x in xs)
  lt = sum(m - bisect_right(ys, x) for x in xs)
  return abs(gt - lt) / (len(xs) * m + 1e-32)

def ks(xs, ys):
  "Kolmogorov-Smirnov: max gap between the two CDFs."
  xs, ys = sorted(xs), sorted(ys); n, m = len(xs), len(ys)
  gap = lambda v: abs(bisect_right(xs,v)/n
                      - bisect_right(ys,v)/m)
  return max(map(gap, xs + ys))

def cohen(xs, ys, eps=0.35):
  "Small effect: |mean gap| < eps * pooled stdev."
  x, y = adds(xs), adds(ys); n, m = n_(x), n_(y)
  pooled = (((n-1)*sd(x)**2 + (m-1)*sd(y)**2)/(n+m-2))**.5
  return abs(mu_(x) - mu_(y)) <= eps * (pooled + TINY)

def same(xs, ys, cliff=0.195, conf=1.36):
  "True if xs,ys are statistically indistinguishable."
  if not cohen(xs, ys): return False
  if cliffs(xs, ys) > cliff: return False
  n, m = len(xs), len(ys)
  return ks(xs, ys) <= conf * ((n + m) / (n * m)) ** 0.5

def thing(s):
  "Coerce a string to int/float/bool, else leave as str."
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  "Parse '--key ... = val' lines of doc into an o()."
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s):
  "Expand a leading $MOOT (env, else ~/gits/moot) and ~."
  s = s.replace("$MOOT", MOOT, 1)
  return os.path.expanduser(s)

def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  "Yield typed rows (lists) from a CSV file."
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]


#-- Holdout (evaluation harness) --------------------------------
# The budget rig: label half the data via `landscape`, grow
# a tree, let it rank the unseen half, check only the top
# few rows, return the best found.
def holdout(data):
  "Budget rig: landscape train -> tree -> pick best test row."
  rows  = shuffle(data.rows)
  half  = len(rows)//2
  train, test = rows[:half], rows[half:]
  got   = landscape(clone(data, train))
  t     = tree(data, got)
  top   = sorted(test, key=lambda r: leaf(data,t,r))[:the.check]
  return min(top, key=lambda r: disty(data,r))


#-- Main --------------------------------------------------------
# `main` maps --key=val flags onto `the`, then runs any
# test_* named on the command line (from the caller's
# globals -- the eg file registers nothing).
def main(funs):
  "Apply --key=val to `the`, then run named test_* in `funs`."
  if "-h" in sys.argv: return print(__doc__)
  for a in sys.argv[1:]:
    if a[:2]=="--" and "=" in a:
      k,v = a[2:].split("=",1)
      if k in vars(the): setattr(the, k, thing(v))
  for a in sys.argv[1:]:
    if (n := "test_"+a) in funs:
      random.seed(the.seed); funs[n]()

MOOT = os.environ.get("MOOT") or os.path.expanduser("~/gits/moot")

the = settings(__doc__)
