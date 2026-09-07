#!/usr/bin/env python3 -B
"""
y3.py: y2 with fewer parts (ydist trees, derived sd, no without)
(c) 2026 Tim Menzies <timm@ieee.org> MIT license

Options:

  -P=2       minkowski coefficient
  -Start=4   acquire: initial random labels
  -Stop=50   acquire: total labelling budget
  -Few=128   max train rows
  -Leaf=4    tree: min rows in any leaf
  -Check=5   holdout: top picks to label
  -Seed=1234567891  random number seed
  -File=$MOOT/optimize/misc/auto93.csv
"""
import math, os, random, re, sys
from types import SimpleNamespace as o

def atom(s):
  try: return int(s)
  except ValueError:
    try: return float(s)
    except ValueError: return s.strip()

pat = r"(\w+)=(\S+)"
the = o(**{k: atom(v) for k,v in re.findall(pat, __doc__ or "")})

def csv(file):
  file = file.replace("$MOOT", os.environ.get("MOOT")
                      or os.path.expanduser("~/gits/moot"), 1)
  with open(file, encoding="utf-8") as f:
    return [tuple(atom(x) for x in line.split(","))
            for line in f if line.strip()]

#-- structs -----------------------------------------------
Num = lambda: (0, 0, 0) # n, mu, m2: all Welford keeps
Sym = dict

def is_num(col): return type(col) is tuple

def sd(col): return 0 if col[0] < 2 else (col[2]/(col[0]-1))**.5

def add(col, v, inc=1): # new Num, or updated Sym; inc=-1 undoes
  if v == "?": return col
  if not is_num(col): col[v] = col.get(v, 0) + inc; return col
  n, mu, m2 = col
  n += inc
  d = v - mu
  mu += inc * d / max(1, n)
  return (n, mu, max(0, m2 + inc * d * (v - mu)))

def adds(lst, it=None): # accumulate a list into it
  if it is None: it = Num()   # NB: "it or Num()" would
  for y in lst: it = add(it, y)  # clobber an empty Sym()
  return it

def size(col):
  return col[0] if is_num(col) else sum(col.values())

def div(col): # Num: sd. Sym: entropy
  if is_num(col): return sd(col)
  n = sum(col.values())
  return -sum(v/n * math.log2(v/n) for v in col.values() if v>0)

def Tbl(src):
  tbl = o(rows=[], cols={}, x=[], y={}, names=src[0],
          klass=None)
  for at, s in enumerate(tbl.names):
    if not s.endswith("X"):
      tbl.cols[at] = Num() if s[0].isupper() else Sym()
      if   s[-1] == "!":  tbl.klass = at
      elif s[-1] in "+-": tbl.y[at] = s[-1] == "+"
      else: tbl.x.append(at)
  for row in src[1:]: addRow(tbl, row)
  return tbl

def clone(tbl, rows=[]): return Tbl([tbl.names] + rows)

def addRow(tbl, row=None, inc=1): # inc=-1 pops the last row
  if inc > 0: tbl.rows.append(row)
  else: row = tbl.rows.pop()
  for at in tbl.cols:
    tbl.cols[at] = add(tbl.cols[at], row[at], inc)
  return row

#-- distance ----------------------------------------------
def norm(col, v):
  z = max(-3, min(3, (v - col[1]) / (1e-32 + sd(col))))
  return 1 / (1 + math.exp(-1.7 * z))

def mid(col):
  return col[1] if is_num(col) else max(col, key=col.get)

def mids(tbl): # centroid; only ever read over x columns
  return {at: mid(tbl.cols[at]) for at in tbl.x}

def ydist(tbl, row):
  return (sum(abs(norm(tbl.cols[at], row[at]) - w) ** the.P
             for at, w in tbl.y.items()) / len(tbl.y))**(1/the.P)

def _dist(col, a, b):
  if a == "?" or b == "?": return 1
  return abs(norm(col,a) - norm(col,b)) if is_num(col) else a!=b

def xdist(tbl, row, m):
  return (sum(_dist(tbl.cols[at], row[at], m[at]) ** the.P
              for at in tbl.x) / len(tbl.x)) ** (1 / the.P)

def ymu(tbl, rows):
  return sum(ydist(tbl, r) for r in rows) / len(rows)

def ymids(tbl, rows):
  return [sum(r[at] for r in rows)/len(rows) for at in tbl.y]

#-- acquire -----------------------------------------------
def pop(tbl, best, rest, todo):
  b, r = mids(best), mids(rest)
  todo.sort(key=lambda z: xdist(tbl, z, r) - xdist(tbl, z, b))
  return todo.pop()

def label(tbl, best, rest, row): # b > int(sqrt(m)) iff b*b > m
  addRow(best, row)
  best.rows.sort(key=lambda r: ydist(tbl, r))
  b, r = len(best.rows), len(rest.rows)
  if b*b > 1 + b + r: addRow(rest, addRow(best, inc=-1))

def acquire(tbl, cap=None):
  best, rest = clone(tbl), clone(tbl)
  todo = random.sample(tbl.rows, len(tbl.rows))[:the.Few]
  for _ in range(the.Start): label(tbl, best, rest, todo.pop())
  cap = cap or the.Stop
  while todo and len(best.rows) + len(rest.rows) < cap:
    label(tbl, best, rest, pop(tbl, best, rest, todo))
  return best.rows + rest.rows

#-- tree --------------------------------------------------
# Node = [edge, n, ymu, ymids, go, kid, kid]
def xpect(a, b): # sizes are >= the.Leaf, so no zero guard
  return ((div(a)*size(a) + div(b)*size(b))
          / (size(a) + size(b)))

def cutNum(xy, acc): # (left, right, x) per value boundary
  xy.sort()
  here, there = acc(), adds((y for _, y in xy), acc())
  for i, (x, y) in enumerate(xy[:-1]):
    here, there = add(here, y), add(there, y, -1)
    if x != xy[i+1][0]: yield here, there, x

def cutSym(xy, acc): # (in, out, sym), one per symbol
  for v in dict.fromkeys(x for x, _ in xy):
    yield (adds((y for x, y in xy if x == v), acc()),
           adds((y for x, y in xy if x != v), acc()), v)

def cut(tbl, rows, ys, acc): # best (col, val) split
  best = (1e30, None, None)
  for at in tbl.x:
    xy = [(x, y) for r,y in zip(rows, ys) if (x := r[at]) != "?"]
    what = cutNum if is_num(tbl.cols[at]) else cutSym
    for here, there, v in what(xy, acc):
      if the.Leaf <= size(here) <= len(xy) - the.Leaf:
        if (s := xpect(here, there)) < best[0]:
          best = (s, at, v)
  if best[1] is not None: return best[1:]

def routing(tbl, at, v):
  s, c = tbl.names[at], tbl.cols[at]
  if is_num(c):
    return (f"{s} <= {round(v,2)}", f"{s} > {round(v,2)}",
            lambda r: (c[1] if r[at] == "?" else r[at]) <= v)
  return (f"{s} = {v}", f"{s} != {v}", lambda r: r[at] == v)

def tree(tbl, rows, edge="", y=None):
  y    = y or (lambda r: ydist(tbl, r))
  ys   = [y(r) for r in rows]
  acc  = Sym if type(ys[0]) is str else Num
  node = [edge, len(rows), mid(adds(ys,acc())), ymids(tbl,rows)]
  if (len(rows) > the.Leaf and (best := cut(tbl, rows, ys,acc))):
    e1, e2, go = routing(tbl, *best)
    yes, no = [], []
    for r in rows:
      (yes if go(r) else no).append(r)
    if yes and no:
      node += [go, tree(tbl, yes, e1, y), tree(tbl, no, e2, y)]
  return node

def kids(n): return n[5:]

def leaf(tr, row):
  while kids(tr): tr = tr[5] if tr[4](row) else tr[6]
  return tr

#-- report ------------------------------------------------
def leafs(tr):
  return [x for k in kids(tr) for x in leafs(k)] or [tr]

def show(tbl, tr):
  ls = sorted(leafs(tr), key=lambda z: z[2])
  print("  d2h   n" + "".join(f"{tbl.names[at]:>7}"
                              for at in tbl.y))
  def walk(z, pre=None):
    m = "+" if z is ls[0] else "-" if z is ls[-1] else " "
    print((f"{m} {round(100*z[2]):>3} {z[1]:>3}"
           + "".join(f"{round(v):>7}" for v in z[3])
           + "   " + (pre or "") + z[0]).rstrip())
    for k in kids(z): walk(k, "" if pre is None else pre+"|  ")
  walk(tr)

#-- tests -------------------------------------------------
def wins(tbl):
  ys = sorted(ydist(tbl, r) for r in tbl.rows)
  lo, b4 = ys[0], sum(ys) / len(ys)
  return lambda r: max(-100, min(100,
    100 * (1 - (ydist(tbl, r) - lo) / (b4 - lo + 1e-32))))

def holdout(tbl):
  rows = random.sample(tbl.rows, len(tbl.rows))
  n = len(rows) // 2
  train, test = rows[:n][:the.Few], rows[n:]
  tr = clone(tbl, train)
  tt = tree(tr, acquire(tr, the.Stop - the.Check))
  top = sorted(test, key=lambda r: leaf(tt,r)[2])[:the.Check]
  return min(top, key=lambda r: ydist(tr, r))

#-- start-up ----------------------------------------------
def test_help():
  "Show usage, settings, demos"
  print("usage: python3 y3.py [-Key val ..] [--demo ..]",
        "\nsettings:",
        *[f"  -{k:<6} {v}" for k,v in sorted(vars(the).items())],
        "\ndemos:",
        *[f"  --{k[5:]:<8} {f.__doc__}"
         for k,f in sorted(globals().items()) if k[:5]=="test_"],
        sep="\n")

def test_tree():
  "Acquire, grow and show the.File's tree"
  tbl = Tbl(csv(the.File))
  lab = acquire(tbl)
  print(f"{the.File} n={len(tbl.rows)}"
        f" mid={round(ymu(tbl, tbl.rows), 3)}"
        f" ezr={round(ydist(tbl, lab[0]), 3)}")
  show(tbl, tree(tbl, lab))

def test_holdout():
  "Mean win over 20 train/test holdouts"
  tbl = Tbl(csv(the.File))
  win = wins(tbl)
  mu = sum(win(holdout(tbl)) for _ in range(20)) / 20
  print(f"win {round(mu)}")

def test_klass():
  "Classify diabetes: accuracy over 5 holdouts"
  tbl = Tbl(csv("$MOOT/classify/diabetes.csv"))
  y = lambda r: r[tbl.klass]
  mu = 0
  for _ in range(5):
    rows = random.sample(tbl.rows, len(tbl.rows))
    n = len(rows) * 2 // 3
    tt = tree(clone(tbl, rows[:n]), rows[:n], y=y)
    mu += (sum(leaf(tt, r)[2] == y(r) for r in rows[n:])
           / (len(rows) - n))
  print(f"accuracy {round(mu/5, 2)}")

def run(f=None):
  random.seed(the.Seed)
  try: (f or test_help)()
  except Exception:
    import traceback; traceback.print_exc(); return 1
  return 0

def cli(d, args):
  n = 0
  while args:
    s = args.pop(0)
    if   s[:2] == "--": n += run(globals().get("test_"+s[2:]))
    elif s[0] == "-" and s[1:] in d:
      d[s[1:]] = atom(args.pop(0))
    else: print(f"unknown arg: {s}")
  sys.exit(n)

if __name__ == "__main__":
  cli(vars(the), sys.argv[1:] or ["--help"])
