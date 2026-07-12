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
  --more   add labels/round      = 4
  --budget labeling cap          = 50
  --cap    max rows kept         = 1024
  --check  rows labelled by tree = 5
  --keepf  keep frac             = 0.66
  --round  decimals shown        = 3
  --acquire  active | random   = active
  -h       print this help

TESTS: (run with their bare name):
  disty       rows by disty: top 5 / bottom 5
  acquire   20 shuffles; best disty per run
  acquires  one mean-win line (the sweep)
  tree      build+show a tree on acquired rows
  holdout  50:50 split; tree picks best test row
  holdouts holdout x20; land vs random verdict
  pure     no tree: best labelled, land vs random
  same     demo+validate the same() stat test
  all      run every test above, reseting seed each
"""
"""
INSTALL: one curl fetches every file; data lives in the moot
repo (tiny.cc/moot), cloned to ~/gits/moot (or set $MOOT):
  REPO=https://raw.githubusercontent.com/timm/src/main/ezr2
  curl -fL $REPO/INSTALL.md | sh
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
BIG  = 1e32
TINY = 1e-32
MOOT = (os.environ.get("MOOT")
        or os.path.expanduser("~/gits/moot"))

#-- lib ---------------------------------------------------------
def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s):
  s = s.replace("$MOOT", MOOT, 1)
  return os.path.expanduser(s)

def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]

#-- rand --------------------------------------------------------
def shuffle(lst): return random.sample(lst, len(lst))

def some(lst, k): return random.sample(lst, min(k, len(lst)))

#-- cols --------------------------------------------------------
Sym = dict
def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def n_(num)  : return num[0]
def mu_(num) : return num[1]
def m2_(num) : return num[2]

def is_sym(i): return isinstance(i, dict)  # Sym = dict of counts

def size(i): return sum(i.values()) if is_sym(i) else n_(i)

def mid(i): return max(i,key=i.get) if is_sym(i) else mu_(i)
def var(i): return entropy(i)       if is_sym(i) else sd(i)

def sd(num): 
  n,_,m2=num
  return 0 if n<2 else(max(0,m2)/(n-1))**.5

def entropy(d):
  N = sum(d.values()) or 1
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def count(sym,v,inc=1):
  if (c := sym.get(v,0) + inc) > 0: sym[v] = c
  else: sym.pop(v, None)
  return sym

def welford(num, v, inc=1):
  n, mu, m2 = num
  if (n := n + inc) <= 0: return Num()
  d = v - mu; mu += inc * d / n
  return (n, mu, m2 + inc * d * (v - mu))

def mix(i, j, inc=1):
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
  if is_sym(col):                  # roulette wheel over counts
    n = sum(col.values()) * random.random()
    for k, c in col.items():
      if (n := n - c) <= 0: return k
    return k
  mu = mu_(col) if v is None or v == "?" else v  # bell at v|mu
  r  = random.random
  return mu + sd(col)*2*(r()+r()+r()-1.5)

#-- tbl --------------------------------------------------------
def Tbl(src):
  src  = iter(src)
  tbl = o(names=next(src), cols={}, x=[], y=[], goal={},
           klass=None, protect=[], rows=[], mid=None)
  return adds(src, Cols(tbl))

def Cols(tbl):
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

def clone(tbl, rows):
  return Tbl([tbl.names] + rows)

def mids(tbl):
  tbl.mid = tbl.mid or [mid(col) for col in tbl.cols.values()]
  return tbl.mid

def adds(src, i=None):
  i = Num() if i is None else i  # keep empty Sym; {} is falsy
  for v in src: i = add(i,v)
  return i

def add(i,v,inc=1):
  if isinstance(i,o):
    i.mid = None  # invalidate cached centroid
    for at,col in i.cols.items(): i.cols[at] = add(col,v[at],inc)
    (i.rows.append if inc==1 else i.rows.remove)(v)
    return i
  if v=="?": return i
  return (count if is_sym(i) else welford)(i, v, inc=inc)

#-- dist --------------------------------------------------------
def norm(num, v):
  if v == "?": return v
  z = (v - mu_(num)) / (sd(num) + 1e-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

def minkowski(vals, p=2):
  tot = nn = 0
  for v in vals: tot += v**p; nn += 1
  return (tot / (nn or 1)) ** (1/p)

def gap(col, u, v):
  if u == v == "?": return 1
  if is_sym(col): return u != v
  u, v = norm(col, u), norm(col, v)
  if u == "?": u = 1 if v < .5 else 0
  if v == "?": v = 1 if u < .5 else 0
  return abs(u - v)

def labelled(row): return row

def disty(tbl, row, **kw):
  row = labelled(row)
  return minkowski(
    (abs(norm(tbl.cols[at], row[at]) - tbl.goal[at])
     for at in tbl.y if row[at] != "?"), **kw)

def distx(tbl, r1, r2, **kw):
  return minkowski((gap(tbl.cols[at], r1[at], r2[at])
                    for at in tbl.x), **kw)

#-- acquire -----------------------------------------------------
def project(rows, x, y, east=None, west=None):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = east or far(rows[0])
  west = west or far(east)
  if y(east) > y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def acquire(tbl):
  y   = lambda r: disty(tbl, r)
  x   = lambda r1, r2: distx(tbl, r1, r2)
  cap = the.budget - the.check
  if the.acquire == "random":
    return sorted(some(tbl.rows, cap), key=y)
  return sorted(sway3(shuffle(tbl.rows), y, x, cap), key=y)

def sway3(rows, y, x, cap, lab=None, east=None, west=None):
  b4  = rows[:]
  lab = lab or {}
  while len(rows) >= 2*the.leaf:
    more = min(the.more, cap - len(lab))
    less = int(max(1, the.keepf * len(rows)))
    new  = []
    for r in rows:
      if   id(r) in lab         : new += [r]
      elif (more := more-1) >= 0: new += [r]; lab[id(r)]=r
    if len(lab) >= cap: return lab.values()  # budget spent
    rows = sorted(rows, key=project(new, x,y, east, west))[:less]
  if len(lab) < len(b4):                     # redo: reshuffle,
    seen = sorted(lab.values(), key=y)       # anchored at the
    return sway3(shuffle(b4), y, x, cap,
                 lab, seen[0], seen[-1])     # best+worst seen
  return lab.values()


#-- bins --------------------------------------------------------
def score(here, there):
  a, b = size(here), size(there)
  return (var(here)*a + var(there)*b) / (a + b + 1e-32)

def bins(tbl,rows,at,Y,accum=Num):
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
def has(row, col, at, v):
  w = row[at]
  return w == "?" or (v == w if is_sym(col) else w <= v)

def tree(tbl, rows, Y=None, accum=Num, lvl=0):
  Y = Y or (lambda r: disty(tbl, r))
  t = o(at=None, mid=mid(adds((Y(r) for r in rows), accum())),
        n=len(rows), rows=rows)
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if bin := min((c for at in tbl.x
        for c in bins(tbl,rows,at,Y,accum)), default=0):
      _, at, v = bin
      col = tbl.cols[at]
      yes, no = [], []
      for r in rows: (yes if has(r,col,at,v) else no).append(r)
      if yes and no:
        t.at, t.v = at, v
        t.yes = tree(tbl, yes, Y, accum, lvl+1)
        t.no  = tree(tbl, no,  Y, accum, lvl+1)
  return t

def leaf(tbl, t, row):
  while t.at is not None:
    t = t.yes if has(row,tbl.cols[t.at],t.at,t.v) else t.no
  return t.mid

def leaves(t):
  if t.at is None: yield t
  else: yield from leaves(t.yes); yield from leaves(t.no)

#-- stats -------------------------------------------------------
def cliffs(xs, ys):
  ys = sorted(ys); m = len(ys)
  gt = sum(bisect_left(ys, x)      for x in xs)
  lt = sum(m - bisect_right(ys, x) for x in xs)
  return abs(gt - lt) / (len(xs) * m + 1e-32)

def ks(xs, ys):
  xs, ys = sorted(xs), sorted(ys); n, m = len(xs), len(ys)
  gap = lambda v: abs(bisect_right(xs,v)/n
                      - bisect_right(ys,v)/m)
  return max(map(gap, xs + ys))

def cohen(xs, ys, eps=0.35):
  x, y = adds(xs), adds(ys); n, m = n_(x), n_(y)
  pooled = (((n-1)*sd(x)**2 + (m-1)*sd(y)**2)/(n+m-2))**.5
  return abs(mu_(x) - mu_(y)) <= eps * (pooled + TINY)

def same(xs, ys, cliff=0.195, conf=1.36):
  if not cohen(xs, ys): return False
  if cliffs(xs, ys) > cliff: return False
  n, m = len(xs), len(ys)
  return ks(xs, ys) <= conf * ((n + m) / (n * m)) ** 0.5

def wins(tbl, rows=None):
  ys = sorted(disty(tbl,r) for r in rows or tbl.rows)
  lo, b4 = ys[0], ys[len(ys)//2]
  return lambda r: max(-100, min(100,
    100 * (1 - (disty(tbl,r)-lo) / (b4-lo+TINY))))

#-- show --------------------------------------------------------
def cond(tbl, t, yes):
  op = (("==" if yes else "!=") if is_sym(tbl.cols[t.at])
        else ("<=" if yes else ">"))
  v  = round(t.v, the.round) if type(t.v)==float else t.v
  return "%s %s %s" % (tbl.names[t.at], op, v)

def show(tbl, t):
  W   = wins(tbl, t.rows)
  win = lambda rows: int(mu_(adds(map(W, rows))))
  ws  = [win(x.rows) for x in leaves(t)]
  print("%s %4s %5s  %s" % (" ", "win", "n",
    " ".join("%8s" % tbl.names[a] for a in tbl.y)))
  branch(tbl, t, win, min(ws), max(ws))

def branch(tbl, t, win, lo, hi, pad="", edge=""):
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
def holdout(tbl):
  rows  = shuffle(tbl.rows)
  half  = len(rows)//2
  train, test = rows[:half], rows[half:]
  got   = acquire(clone(tbl, train))
  t     = tree(tbl, got)
  top   = sorted(test, key=lambda r: leaf(tbl,t,r))[:the.check]
  return min(top, key=lambda r: disty(tbl,r))

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
