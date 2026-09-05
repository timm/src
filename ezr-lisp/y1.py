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
def path(s): # Expand leading $MOOT: env var, else ~/gits/moot
  return s.replace("$MOOT", os.environ.get("MOOT")
                   or os.path.expanduser("~/gits/moot"), 1)

def thing(s): # Text to int, else to float, else to stripped text
  try: return int(s)
  except ValueError:
    try: return float(s)
    except ValueError: return s.strip()

the = o(**{k: thing(v) for k, v in
           re.findall(r"(\w+)=(\S+)", __doc__ or "")})

def csv(file): # Csv file --> row tuples (so rows can be keys)
  with open(path(file), encoding="utf-8") as f:
    return [tuple(thing(x) for x in line.split(","))
            for line in f if line.strip()]

#-- columns and tables ------------------------------------
def col(s, at): # New column, its role read off its header name
  return o(txt=s, at=at, n=0, mu=0, m2=0, sd=0, has={},
           w=-1 if s.endswith("-") else 1, num=s[0].isupper())

def data(src): # Rows in, table out; row 0 names the columns
  d = o(rows=[], all=[], x=[], y=[], nr=0, center=None,
        names=src[0])
  for at, s in enumerate(d.names):
    d.all += [col(s, at)]
    if not s.endswith("X"):
      (d.y if s[-1] in "+-" else d.x).append(d.all[-1])
  for row in src[1:]: adds(d, row)
  return d

def clone(d, rows=[]): # New table wearing d's columns
  return data([d.names] + rows)

def add(c, v, inc=1): # Update col c with v; inc=-1 undoes
  if v == "?": return
  c.n += inc
  if not c.num: c.has[v] = c.has.get(v, 0) + inc
  else:
    d = v - c.mu
    c.mu += inc * d / max(1, c.n)
    c.m2 += inc * d * (v - c.mu)
    c.sd = 0 if c.n < 2 else (max(0, c.m2) / (c.n - 1)) ** .5

def adds(d, row=None, inc=1): # Add row; inc=-1 pops the last
  d.nr += inc
  d.center = None
  if inc > 0: d.rows.append(row)
  else: row = d.rows.pop()
  for c in d.all: add(c, row[c.at], inc)
  return row

#-- distance ----------------------------------------------
def norm(c, v): # Z-score, squashed into 0..1 by a logistic
  z = max(-3, min(3, (v - c.mu) / (1e-32 + c.sd)))
  return 1 / (1 + math.exp(-1.7 * z))

def ydist(d, row): # Distance from a row to heaven
  return (sum(abs(norm(c, row[c.at]) - (c.w > 0)) ** the.P
              for c in d.y) / len(d.y)) ** (1 / the.P)

def ymu(d, rows): # Mean ydist over rows
  return sum(ydist(d, r) for r in rows) / len(rows)

def mid(c): # Num: mean. Sym: mode
  return (c.mu if c.num else
          max(c.has, key=c.has.get) if c.has else "?")

def mids(d): # Cached centroid: one mid per column
  d.center = d.center or [mid(c) for c in d.all]
  return d.center

def ymids(d, rows): # Mean raw value of each goal over rows
  return [sum(r[c.at] for r in rows) / len(rows) for c in d.y]

#-- acquire -----------------------------------------------
def _dist(c, a, b): # One column's distance; "?" maxes out
  if a == "?" or b == "?": return 1
  if not c.num: return a != b
  return abs(norm(c, a) - norm(c, b))

def xdist(d, row, mid2): # Row to a centroid, over x columns
  return (sum(_dist(c, row[c.at], mid2[c.at]) ** the.P
              for c in d.x) / len(d.x)) ** (1 / the.P)

def pop(d, best, rest, todo): # Pop: near best, far from rest
  b, r = mids(best), mids(rest)
  few = min(len(todo), the.Few)
  at = max(random.sample(range(len(todo)), few),
           key=lambda i: xdist(d, todo[i], r)
                       - xdist(d, todo[i], b))
  todo[at], todo[-1] = todo[-1], todo[at]
  return todo.pop()

def label(d, best, rest, row): # To best; overflow to rest
  adds(best, row)
  best.rows.sort(key=lambda r: ydist(d, r))
  if best.nr > int((1 + best.nr + rest.nr) ** .5):
    adds(rest, adds(best, inc=-1))

def acquire(d): # Spend Stop labels; return rows, best first
  best, rest = clone(d), clone(d)
  todo = random.sample(d.rows, len(d.rows))
  for _ in range(the.Start): label(d, best, rest, todo.pop())
  while todo and best.nr + rest.nr < the.Stop:
    label(d, best, rest, pop(d, best, rest, todo))
  return best.rows + rest.rows

#-- tree --------------------------------------------------
def xpect(a, b): # Expected sd once rows split into a and b
  return (a.sd*a.n + b.sd*b.n) / (a.n + b.n + 1e-32)

def keys(col, rows, ys): # Key rows: value, or symbol mean y
  if col.num:
    k = lambda v: col.mu if v == "?" else v
  else: # order symbols by the mean y of their rows
    mu = {}
    for r in rows: mu[x] = mu.get(x := r[col.at], []) + [ys[r]]
    k = {x: sum(a) / len(a) for x, a in mu.items()}.get
  return sorted(((k(r[col.at]), ys[r], r) for r in rows),
                key=lambda t: t[0])

def sweep(xy): # Sweep sorted keys; best score + cut index
  lhs, rhs, b, at = col("N",0), col("N",0), 1e30, None
  for _, y, _ in xy: add(rhs, y)
  for i in range(len(xy) - 1):
    add(lhs, xy[i][1]); add(rhs, xy[i][1], -1)
    if (xy[i][0] != xy[i+1][0]
        and the.Leaf <= i+1 <= len(xy) - the.Leaf):
      s = xpect(lhs, rhs)
      if s < b: b, at = s, i
  return b, at

def cut(d, rows): # Best split: (score, col, keys, index)
  ys = {r: ydist(d, r) for r in rows}
  best = (1e30, None, None, None)
  for c in d.x:
    xy = keys(c, rows, ys)
    s, at = sweep(xy)
    if at is not None and s < best[0]: best = (s, c, xy, at)
  return best

def cutted(c, xy, i): # A cut at xy[i]: two labels + a router
  if c.num:
    v = xy[i][0]
    return (f"{c.txt} <= {round(v, 2)}",
            f"{c.txt} > {round(v, 2)}",
            lambda r: (c.mu if r[c.at]=="?" else r[c.at]) <= v)
  left = {r[c.at] for _, _, r in xy[:i+1]}
  cat = lambda t: c.txt + " = " + "|".join(sorted(map(str, t)))
  return (cat(left), cat({r[c.at] for _, _, r in xy[i+1:]}),
          lambda r: r[c.at] in left)

def grow(d, rows, edge=""): # Node=[edge,n,ymu,ymids,go,kids]
  node = [edge, len(rows), ymu(d, rows), ymids(d, rows)]
  _, c, xy, i = (cut(d, rows) if len(rows) > the.Leaf
                 else 4*(None,))
  if c:
    e1, e2, go = cutted(c, xy, i)
    node += [go,
             grow(d, [r for _,_,r in xy[:i+1]], e1),
             grow(d, [r for _,_,r in xy[i+1:]], e2)]
  return node

def leaf(tree, row): # Walk row down to its leaf
  while len(tree) > 4:
    tree = tree[5] if tree[4](row) else tree[6]
  return tree

#-- report ------------------------------------------------
def leafs(t): # Every leaf of a tree, left to right
  return [t] if len(t) < 5 else [x for k in t[5:]
                                 for x in leafs(k)]

def show(d, tree): # Print tree; +/- = best, worst leaf
  ls = sorted(leafs(tree), key=lambda t: t[2])
  print("  d2h   n" + "".join(f"{c.txt:>7}" for c in d.y))
  def walk(t, pre=None):
    m = "+" if t is ls[0] else "-" if t is ls[-1] else " "
    print((f"{m} {round(100*t[2]):>3} {t[1]:>3}"
           + "".join(f"{round(v):>7}" for v in t[3])
           + "   " + (pre or "") + t[0]).rstrip())
    for k in t[5:]: walk(k, "" if pre is None else pre + "|  ")
  walk(tree)

#-- tests -------------------------------------------------
def wins(d): # Grader: row --> % of the mid-to-best gap closed
  ys = sorted(ydist(d, r) for r in d.rows)
  lo, b4 = ys[0], sum(ys) / len(ys)
  return lambda r: max(-100, min(100,
    100 * (1 - (ydist(d, r) - lo) / (b4 - lo + 1e-32))))

def holdout(d): # Train on half (clipped to Few); pick from rest
  rows = random.sample(d.rows, len(d.rows))
  n = len(rows) // 2
  train, test = rows[:n][:the.Few], rows[n:]
  tr = clone(d, train)
  tree = grow(tr, acquire(tr))
  top = sorted(test, key=lambda r: leaf(tree, r)[2])[:the.Check]
  return min(top, key=lambda r: ydist(tr, r))

#-- start-up ----------------------------------------------
def main(f): # Read f, spend labels, grow the tree, print it
  random.seed(the.Seed)
  d = data(csv(f))
  lab = acquire(d)
  print(f"{f} n={d.nr} mid={round(ymu(d, d.rows), 3)}"
        f" ezr={round(ydist(d, lab[0]), 3)}")
  show(d, grow(d, lab))

def go_help(): # Show usage, settings, demos
  print("usage: python3 y1.py [-Key val ..] [--demo ..]"
        " [file.csv]", "\nsettings:",
        *[f"  -{k:<6} {v}"
          for k, v in sorted(vars(the).items())],
        "\ndemos:",
        *[f"  --{k[3:]}"
          for k in sorted(globals()) if k[:3] == "go_"],
        sep="\n")

def go_data(): # Per-goal n, mu and sd of the whole table
  for c in data(csv(the.File)).y:
    print(f"{c.txt} n {c.n} mu {round(c.mu,2)}"
          f" sd {round(c.sd,2)}")

def go_acquire(): # Best ydist after spending Stop labels
  random.seed(the.Seed)
  d = data(csv(the.File))
  print(f"ezr {round(ydist(d, acquire(d)[0]), 3)}")

def go_tree(): # Acquire, grow and show the default table
  main(the.File)

def go_holdout(): # Mean win over 20 train/test holdouts
  random.seed(the.Seed)
  d = data(csv(the.File))
  win = wins(d)
  mu = sum(win(holdout(d)) for _ in range(20)) / 20
  print(f"win {round(mu)}")

def cli(args): # -Key val sets; --demo runs; else csv file
  while args:
    s = args.pop(0)
    if s[:2] == "--": globals().get("go_"+s[2:], go_help)()
    elif s[0] == "-": setattr(the, s[1:], thing(args.pop(0)))
    else: main(s)

if __name__ == "__main__": cli(sys.argv[1:] or ["--help"])
