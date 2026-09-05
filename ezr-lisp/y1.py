#!/usr/bin/env python3 -B
"""
y1.py: explainable multi-objective active learning
(c) 2026 Tim Menzies <timm@ieee.org> MIT license

Options:

  -P=2       minkowski coefficient
  -Start=4   acquire: initial random labels
  -Stop=50   acquire: total labelling budget
  -Few=128   max train rows, bayes sample size
  -Leaf=4    tree: min rows in any leaf
  -Check=5   holdout: top picks to label
  -Seed=1234567891  random number seed
  -File=$MOOT/optimize/misc/auto93.csv
"""
import math, os, random, re, sys
from types import SimpleNamespace as o


#-- lib ---------------------------------------------------
def atom(s): # Text to int, else to float, else to stripped text
  try: return int(s)
  except ValueError:
    try: return float(s)
    except ValueError: return s.strip()

the = o(**{k: atom(v) for k, v in
           re.findall(r"(\w+)=(\S+)", __doc__ or "")})

def csv(file): # Csv file --> row tuples (so rows can be keys)
  with open(path(file), encoding="utf-8") as f:
    return [tuple(atom(x) for x in line.split(","))
            for line in f if line.strip()]

def path(s): # Expand leading $MOOT: env var, else ~/gits/moot
  return s.replace("$MOOT", os.environ.get("MOOT")
                   or os.path.expanduser("~/gits/moot"), 1)


#-- columns and tables ------------------------------------
def Col(s="", at=0): # New column; role read off its name
  return o(txt=s, at=at, n=0, mu=0, m2=0, sd=0, has={},
           w=-1 if s.endswith("-") else 1, num=s[0].isupper())

def Tbl(src): # Rows in, table out; row 0 = names
  tbl = o(rows=[], all=[], x=[], y=[], nr=0, mid=None,
        names=src[0])
  for at, s in enumerate(tbl.names):
    tbl.all += [Col(s, at)]
    if not s.endswith("X"):
      (tbl.y if s[-1] in "+-" else tbl.x).append(tbl.all[-1])
  for row in src[1:]: adds(tbl, row)
  return tbl

def clone(tbl, rows=[]): # New table, tbl's shape
  return Tbl([tbl.names] + rows)

def add(col, v, inc=1): # Update col col with v; return v
  if v == "?": return v
  col.n += inc
  if not col.num: col.has[v] = col.has.get(v, 0) + inc
  else:
    d = v - col.mu
    col.mu += inc * d / max(1, col.n)
    col.m2 += inc * d * (v - col.mu)
    col.sd = (0 if col.n < 2 else
              (max(0, col.m2) / (col.n - 1)) ** .5)
  return v

def adds(tbl, row=None, inc=1): # inc=-1 pops last
  tbl.nr += inc
  tbl.mid = None
  if inc > 0: tbl.rows.append(row)
  else: row = tbl.rows.pop()
  for c in tbl.all: add(c, row[c.at], inc)
  return row


#-- distance ----------------------------------------------
def norm(col, v): # Z-score --> 0..1 logistic
  z = max(-3, min(3, (v - col.mu) / (1e-32 + col.sd)))
  return 1 / (1 + math.exp(-1.7 * z))

def ydist(tbl, row): # Distance to heaven
  return (sum(abs(norm(c, row[c.at]) - (c.w > 0)) ** the.P
              for c in tbl.y) / len(tbl.y)) ** (1 / the.P)

def mid(col): # Num: mean. Sym: mode
  return col.mu if col.num else max(col.has, key=col.has.get) 

def div(col): # Num: sd. Sym: entropy
  return col.sd if col.num else \
    -sum(v/col.n * math.log2(v/col.n)
         for v in col.has.values() if v > 0)

def mids(tbl): # Cached centroid: one mid per column
  tbl.mid = tbl.mid or [mid(c) for c in tbl.all]
  return tbl.mid

def _dist(col, a, b): # One column's distance; "?" maxes out
  if a == "?" or b == "?": return 1
  return abs(norm(col, a) - norm(col, b)) if col.num else a != b

def xdist(tbl, row, mid2): # Row to a centroid, over x columns
  return (sum(_dist(c, row[c.at], mid2[c.at]) ** the.P
              for c in tbl.x) / len(tbl.x)) ** (1 / the.P)

def ymu(tbl, rows): # Mean ydist over rows
  return sum(ydist(tbl, r) for r in rows) / len(rows)

def ymids(tbl, rows): # Mean value of each goal over rows
  return [sum(r[c.at] for r in rows)/len(rows) for c in tbl.y]

#-- acquire -----------------------------------------------
def pop(tbl, best, rest, todo): # Sort todo; pop its best end
  b, r = mids(best), mids(rest)
  todo.sort(key=lambda z: xdist(tbl, z, r) - xdist(tbl, z, b))
  return todo.pop()

def label(tbl, best, rest, row): # To best; overflow to rest
  adds(best, row)
  best.rows.sort(key=lambda r: ydist(tbl, r))
  if best.nr > int((1 + best.nr + rest.nr) ** .5):
    adds(rest, adds(best, inc=-1))

def acquire(tbl, cap=None): # Labels, best first
  best, rest = clone(tbl), clone(tbl)
  todo = random.sample(tbl.rows, len(tbl.rows))[:the.Few]
  for _ in range(the.Start): label(tbl, best, rest, todo.pop())
  cap = cap or the.Stop
  while todo and best.nr + rest.nr < cap:
    label(tbl, best, rest, pop(tbl, best, rest, todo))
  return best.rows + rest.rows


#-- tree --------------------------------------------------
# Node = [edge, n, ymu, ymids, go, kid, kid]
def xpect(a, b): # Expected diversity once split into a and b
  return (div(a)*a.n + div(b)*b.n) / (a.n + b.n + 1e-32)

def cutNum(xy, k="N"): # Yield (here, x) per value boundary
  xy.sort()
  here = Col(k)
  for i, (x, y) in enumerate(xy[:-1]):
    add(here, y)
    if x != xy[i+1][0]: yield here, x

def cutSym(xy, k="N"): # Yield (here, sym), one per symbol
  d = {}
  for x, y in xy:
    if x not in d: d[x] = Col(k)
    add(d[x], y)
  for x, here in d.items(): yield here, x

def cut(tbl, rows, y=None): # Best (score, col, val)
  y = y or (lambda r: ydist(tbl, r))
  k = "n" if type(y(rows[0])) is str else "N"
  best = (1e30, None, None)
  for col in tbl.x:
    there = Col(k)
    xy  = [(r[col.at], add(there, y(r)))
           for r in rows if r[col.at] != "?"]
    for here, v in (cutNum if col.num else cutSym)(xy, k):
      if the.Leaf <= here.n <= len(xy) - the.Leaf:
        s = xpect(here, sub(there, here))
        if s < best[0]: best = (s, col, v)
  return best

def sub(a, b): # New col: a's numbers (or counts), less b's
  c = Col(a.txt)
  c.n = n = a.n - b.n
  if not a.num:
    c.has = {k: n2 for k, v in a.has.items()
             if (n2 := v - b.has.get(k, 0)) > 0}
  elif n > 0:
    c.mu = (a.n*a.mu - b.n*b.mu) / n
    d = b.mu - a.mu
    c.m2 = max(0, a.m2 - b.m2 - d*d*a.n*b.n/n)
    c.sd = 0 if n < 2 else (c.m2 / (n - 1)) ** .5
  return c

def routing(col, v): # Cut (col,v): 2 labels + router
  if col.num:
    return (f"{col.txt} <= {round(v, 2)}",
            f"{col.txt} > {round(v, 2)}",
            lambda r: (col.mu if r[col.at] == "?"
                       else r[col.at]) <= v)
  return (f"{col.txt} = {v}", f"{col.txt} != {v}",
          lambda r: r[col.at] == v)

def tree(tbl, rows, edge="", y=None): # See Node
  node = [edge, len(rows), ymu(tbl, rows), ymids(tbl,rows)]
  _, c, v = (cut(tbl, rows, y) if len(rows) > the.Leaf
             else 3*(None,))
  if c:
    e1, e2, go = routing(c, v)
    yes = [r for r in rows if go(r)]
    no  = [r for r in rows if not go(r)]
    if yes and no:
      node += [go, tree(tbl, yes, e1, y),
               tree(tbl, no, e2, y)]
  return node

def leaf(tree, row): # Walk row down to its leaf
  while len(tree) > 4:
    tree = tree[5] if tree[4](row) else tree[6]
  return tree

#-- report ------------------------------------------------
def leafs(t): # Every leaf of a tree, left to right
  return [t] if len(t) < 5 else [x for k in t[5:]
                                 for x in leafs(k)]

def show(tbl, tree): # Print tree; +/- = best, worst leaf
  ls = sorted(leafs(tree), key=lambda t: t[2])
  print("  d2h   n"
        + "".join(f"{c.txt:>7}" for c in tbl.y))
  def walk(t, pre=None):
    m = "+" if t is ls[0] else "-" if t is ls[-1] else " "
    print((f"{m} {round(100*t[2]):>3} {t[1]:>3}"
           + "".join(f"{round(v):>7}" for v in t[3])
           + "   " + (pre or "") + t[0]).rstrip())
    for k in t[5:]: walk(k, "" if pre is None else pre + "|  ")
  walk(tree)


#-- stats -------------------------------------------------
def cohen(xs, ys, d=0.35): # Mean gap small, in pooled sds?
  a, b = Col("N"), Col("N")
  for x in xs: add(a, x)
  for y in ys: add(b, y)
  sd = (((a.n-1)*a.sd**2 + (b.n-1)*b.sd**2)/(a.n+b.n-2))**.5
  return abs(a.mu - b.mu) <= d * sd

def cliffs(xs, ys, d=0.197): # Sorted in. Rank imbalance ok?
  gt = lt = j = k = 0
  for x in xs:
    while j < len(ys) and ys[j] <  x: j += 1; k = j
    while k < len(ys) and ys[k] <= x: k += 1
    gt += j; lt += len(ys) - k
  return abs(gt - lt) / (len(xs) * len(ys)) <= d

def ks(xs, ys, a=1.36): # Sorted in. 95% kolmogorov-smirnov
  n, m, i, j, d = len(xs), len(ys), 0, 0, 0
  while i < n and j < m:
    v = min(xs[i], ys[j])
    while i < n and xs[i] <= v: i += 1
    while j < m and ys[j] <= v: j += 1
    d = max(d, abs(i/n - j/m))
  return d <= a * ((n + m) / (n * m)) ** .5

def same(xs, ys): # Indistinguishable, by all three tests
  xs, ys = sorted(xs), sorted(ys)
  return cliffs(xs, ys) and ks(xs, ys) and cohen(xs, ys)

def abcd(pairs): # (want, got) pairs --> per-class scores
  out = {}
  for pair in pairs:
    for x in pair:
      if x not in out:
        out[x] = o(label=x, tp=0, fp=0, fn=0, tn=0)
  for want, got in pairs:
    for x, c in out.items():
      if   x == want: c.tp += got == want; c.fn += got != want
      elif x == got : c.fp += 1
      else          : c.tn += 1
  for c in out.values():
    n = c.tp + c.fp + c.fn + c.tn + 1e-32
    c.acc  = (c.tp + c.tn) / n
    c.pd   = c.tp / (c.tp + c.fn + 1e-32)
    c.pf   = c.fp / (c.fp + c.tn + 1e-32)
    c.prec = c.tp / (c.tp + c.fp + 1e-32)
  return out


#-- tests -------------------------------------------------
def wins(tbl): # Grader: row --> % of the mid-to-best gap closed
  ys = sorted(ydist(tbl, r) for r in tbl.rows)
  lo, b4 = ys[0], sum(ys) / len(ys)
  return lambda r: max(-100, min(100,
    100 * (1 - (ydist(tbl, r) - lo) / (b4 - lo + 1e-32))))

def holdout(tbl): # Train on half (max Few); pick from rest
  rows = random.sample(tbl.rows, len(tbl.rows))
  n = len(rows) // 2
  train, test = rows[:n][:the.Few], rows[n:]
  tr = clone(tbl, train)
  tt = tree(tr, acquire(tr, the.Stop - the.Check))
  top = sorted(test,
               key=lambda r: leaf(tt, r)[2])[:the.Check]
  return min(top, key=lambda r: ydist(tr, r))


#-- start-up ----------------------------------------------
def test_stats():
  "same() ok on tiny shifts, not on big ones"
  a = [random.random() for _ in range(40)]
  b = [x + 0.05 for x in a]
  c = [x + 2.00 for x in a]
  assert same(a, b) and not same(a, c)
  print("a~a+.05", same(a, b), "| a~a+2", same(a, c))

def test_abcd():
  "Confusion stats on a tiny example"
  pairs = ([("a","a")] * 4 + [("b","a")] +
           [("b","b")] * 2 + [("a","b")])
  for c in abcd(pairs).values():
    print(f"{c.label} acc {c.acc:.2f} pd {c.pd:.2f}"
          f" pf {c.pf:.2f} prec {c.prec:.2f}")

def test_help():
  "Show usage, settings, demos"
  print("usage: python3 y1.py [-Key val ..] [--demo ..]",
        "\nsettings:",
        *[f"  -{k:<6} {v}"
          for k, v in sorted(vars(the).items())],
        "\ndemos:",
        *[f"  --{k[5:]:<8} {f.__doc__}"
          for k, f in sorted(globals().items())
          if k[:5] == "test_"],
        sep="\n")

def test_data():
  "Per-goal n, mu and sd of the whole table"
  for c in Tbl(csv(the.File)).y:
    print(f"{c.txt} n {c.n} mu {round(c.mu,2)}"
          f" sd {round(c.sd,2)}")

def test_acquire():
  "Best ydist after spending Stop labels"
  d = Tbl(csv(the.File))
  print(f"ezr {round(ydist(d, acquire(d)[0]), 3)}")

def test_tree():
  "Acquire, grow and show the.File's tree"
  d = Tbl(csv(the.File))
  lab = acquire(d)
  print(f"{the.File} n={d.nr}"
        f" mid={round(ymu(d, d.rows), 3)}"
        f" ezr={round(ydist(d, lab[0]), 3)}")
  show(d, tree(d, lab))

def test_holdout():
  "Mean win over 20 train/test holdouts"
  d = Tbl(csv(the.File))
  win = wins(d)
  mu = sum(win(holdout(d)) for _ in range(20)) / 20
  print(f"win {round(mu)}")

def run(f=None): # Seed, call f, catch crashes; 1 if crashed
  random.seed(the.Seed)
  try: (f or test_help)()
  except Exception:
    import traceback; traceback.print_exc(); return 1
  return 0

def cli(d, funs, args): # "-Key val" sets; "--demo" runs
  n = 0
  while args:
    s = args.pop(0)
    if   s[:2] == "--": n += run(funs.get("test_" + s[2:]))
    elif s[1:] in d: d[s[1:]] = atom(args.pop(0))
    else: print(f"unknown arg: {s}")
  sys.exit(n)

if __name__ == "__main__":
  cli(vars(the), globals(), sys.argv[1:] or ["--help"])
