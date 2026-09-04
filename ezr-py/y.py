#!/usr/bin/env python3 -B
"""
y.py: multi-objective active learning, one file. MIT.
usage: python3 y.py [-Key val ..] [--demo ..] [file.csv]

Read a table of rows, spend a tiny labelling budget on the
rows naive bayes finds promising, then grow a tree over
what you learned and print which x-ranges explain the good
rows. Port of ezr-lua/y.lua (itself a trim of
ezr-lisp/y.lisp), standing on the same six bets:

1. No classes. A column is a SimpleNamespace and `add`
   branches once on `num`.
2. `add(c,v,-1)` UNDOES an add. That one primitive buys
   both the O(1) spill of a labelled row from `best` to
   `rest` and the single-pass tree sweep.
3. Every split is numeric. Symbols are ranked by their
   mean y INSIDE the node (Breiman's trick, and optimal
   for variance), so one sweep serves both column kinds.
4. `cut` returns the PARTITION, not a predicate. The tree
   is a report, not a classifier, so `selects?` and the
   re-scan it needs both vanish -- as do `liked` and the
   entropy arm of `div`, which nothing ever called.
5. Guessing takes the ARGMAX of a `Few`-row sample, not a
   sort of it. `acquire` pops one row per step, so the
   rest of that sort was always thrown away.
6. Settings are the capitalized module globals, so the cli
   sets one with `globals()[key]=val` and `--help` lists
   them by scanning for names that start upper case.

Python pays four of those back cheaply. Rows are TUPLES,
so `{row: ydist}` is a plain dict and dedup is a set.
`max(pool, key=..)` IS bet 5, in one expression. `round`
returns an int, so no float-printing guard is needed. And
comprehensions collapse ymids, ydist, leafs and the tree
partition to a line each. Net: 201 lines of code, against
y.lua's 251 and y.lisp's 286.
"""
import math, os, random, sys
from types import SimpleNamespace as o

P, Start, Stop, Few, M, K, Leaf = 2, 4, 24, 128, 1, 2, 8
Seed, File = 1234567891, "$MOOT/optimize/misc/auto93.csv"

#-- lib ---------------------------------------------------
# Strings and files. Nothing here knows what a column is.

def path(s):
  "Expand a leading $MOOT: the env var, else ~/gits/moot"
  return s.replace("$MOOT", os.environ.get("MOOT")
                   or os.path.expanduser("~/gits/moot"), 1)

def thing(s):
  "Text to int, else to float, else to stripped text"
  try: return int(s)
  except ValueError:
    try: return float(s)
    except ValueError: return s.strip()

def csv(file):
  "Csv file to a list of row tuples (so rows can be keys)"
  with open(path(file), encoding="utf-8") as f:
    return [tuple(thing(x) for x in line.split(","))
            for line in f if line.strip()]

#-- columns and tables ------------------------------------
# Header names carry the whole schema: leading uppercase
# means numeric, a trailing `+` or `-` marks a goal to
# maximize or minimize, a trailing `X` says ignore me.
# Goals are assumed complete; x cells may hold "?".

def col(s, at):
  "New column, its role read off its header name"
  return o(txt=s, at=at, n=0, mu=0, m2=0, has={},
           w=-1 if s.endswith("-") else 1, num=s[0].isupper())

def data(src):
  "Rows in, table out; row 0 names the columns"
  d = o(rows=[], all=[], x=[], y=[], nr=0, names=src[0])
  for at, s in enumerate(d.names):
    d.all += [col(s, at)]
    if not s.endswith("X"):
      (d.y if s[-1] in "+-" else d.x).append(d.all[-1])
  for row in src[1:]: adds(d, row)
  return d

def clone(d):
  "Empty table wearing d's columns"
  return data([d.names])

def add(c, v, inc=1):
  "Update col c with v; inc=-1 undoes an earlier add"
  if v == "?": return v
  c.n += inc
  if not c.num: c.has[v] = c.has.get(v, 0) + inc
  else:
    d = v - c.mu
    c.mu += inc * d / max(1, c.n)
    c.m2 += inc * d * (v - c.mu)
  return v

def adds(d, row=None, inc=1):
  "Add a row; with inc=-1, pop the last row and return it"
  d.nr += inc
  if inc > 0: d.rows.append(row)
  else: row = d.rows.pop()
  for c in d.all: add(c, row[c.at], inc)
  return row

#-- distance ----------------------------------------------
# One number per row: how far its goals sit from the best
# corner of goal space. Everything downstream sorts on it.

def sd(c):
  "Standard deviation"
  return 0 if c.n < 2 else (max(0, c.m2) / (c.n - 1)) ** .5

def norm(c, v):
  "Z-score, squashed into 0..1 by a logistic"
  z = max(-3, min(3, (v - c.mu) / (1e-32 + sd(c))))
  return 1 / (1 + math.exp(-1.7 * z))

def ydist(d, row):
  "Distance from a row to heaven (every goal at its best)"
  return (sum(abs(norm(c, row[c.at]) - (c.w > 0)) ** P
              for c in d.y) / len(d.y)) ** (1 / P)

def ymu(d, rows):
  "Mean ydist over rows"
  return sum(ydist(d, r) for r in rows) / len(rows)

def ymids(d, rows):
  "Mean raw value of each goal over rows"
  return [sum(r[c.at] for r in rows) / len(rows) for c in d.y]

#-- acquire -----------------------------------------------
# Label `Start` random rows, keep the good ones in `best`
# and the others in `rest`, then repeatedly ask naive bayes
# which unlabelled row `best` likes most and `rest` likes
# least. Stop after `Stop` labels.

def like(c, v, prior):
  "Likelihood of value v in column c"
  if not c.num: return (c.has.get(v,0) + M*prior) / (c.n + M)
  s = 1e-32 + sd(c)
  return math.exp(-(v-c.mu)**2 / (2*s*s)) / (2.5066 * s)

def likes(d, row, nall, nh):
  "Log-likelihood that row was drawn from table d"
  prior = (d.nr + K) / (nall + K * nh)
  return math.log(prior) + sum(
    math.log(max(1e-32, like(c, row[c.at], prior)))
    for c in d.x if row[c.at] != "?")

def pop(d, best, rest, todo):
  "Pop the row a fresh `Few`-row sample likes best"
  at = max(random.sample(range(len(todo)), min(len(todo), Few)),
           key=lambda i: likes(best, todo[i], d.nr, 2)
                       - likes(rest, todo[i], d.nr, 2))
  todo[at], todo[-1] = todo[-1], todo[at]
  return todo.pop()

def label(d, best, rest, row):
  "Row joins `best`, sorted; if best overflows, worst goes"
  adds(best, row)
  best.rows.sort(key=lambda r: ydist(d, r))
  if best.nr > int((1 + best.nr + rest.nr) ** .5):
    adds(rest, adds(best, inc=-1))

def acquire(d):
  "Spend `Stop` labels; return those rows, best first"
  random.seed(Seed)
  best, rest = clone(d), clone(d)
  todo = random.sample(d.rows, len(d.rows))
  for _ in range(Start): label(d, best, rest, todo.pop())
  while todo and best.nr + rest.nr < Stop:
    label(d, best, rest, pop(d, best, rest, todo))
  return best.rows + rest.rows

#-- tree --------------------------------------------------
# One sweep per x column finds the split that most shrinks
# the sd of ydist. Ranking symbols by their mean y first
# means the sweep never has to ask a column its type. A
# sorted key list is (key, ydist, row) triples, so the
# winning sweep hands `grow` its partition for free.

def xpect(a, b):
  "Expected sd once rows split into a and b"
  return (sd(a)*a.n + sd(b)*b.n) / (a.n + b.n + 1e-32)

def keys(c, rows, ys):
  "Key each row by col c: value, or its symbol's mean y"
  mu = {}
  for r in rows: mu.setdefault(r[c.at], []).append(ys[r])
  k = ((lambda v: c.mu if v == "?" else v) if c.num else
       (lambda v: sum(mu[v]) / len(mu[v])))
  return sorted(((k(r[c.at]), ys[r], r) for r in rows),
                key=lambda t: t[0])

def sweep(xy):
  "Sweep sorted keys; best score, and the index it cuts at"
  lhs, rhs, b, at = col("N",0), col("N",0), 1e30, None
  for _, y, _ in xy: add(rhs, y)
  for i in range(len(xy) - 1):
    add(lhs, xy[i][1]); add(rhs, xy[i][1], -1)
    if xy[i][0] != xy[i+1][0]:
      s = xpect(lhs, rhs)
      if s < b: b, at = s, i
  return b, at

def cut(d, rows):
  "Best split over every x col: (score, col, keys, index)"
  ys = {r: ydist(d, r) for r in rows}
  best = (1e30, None, None, None)
  for c in d.x:
    xy = keys(c, rows, ys)
    s, at = sweep(xy)
    if at is not None and s < best[0]: best = (s, c, xy, at)
  return best

def edges(c, xy, i):
  "The two edge labels naming a cut at xy[i]"
  if c.num:
    v = round(xy[i][0], 2)
    return f"{c.txt} <= {v}", f"{c.txt} > {v}"
  cat = lambda t: c.txt + " = " + "|".join(
    sorted({str(r[c.at]) for _, _, r in t}))
  return cat(xy[:i+1]), cat(xy[i+1:])

def grow(d, rows, edge=""):
  "Recurse; a node is [edge, n, ymu, ymids, kid, kid]"
  node = [edge, len(rows), ymu(d, rows), ymids(d, rows)]
  _, c, xy, i = cut(d, rows) if len(rows) > Leaf else 4*(None,)
  if c:
    e1, e2 = edges(c, xy, i)
    node += [grow(d, [r for _,_,r in xy[:i+1]], e1),
             grow(d, [r for _,_,r in xy[i+1:]], e2)]
  return node

#-- report ------------------------------------------------
# The tree exists to be read, so printing it is the whole
# api: d2h as a percent, then the raw goal means, then the
# branch that got you here.

def leafs(t):
  "Every leaf of a tree, left to right"
  return [t] if len(t) < 5 else [x for k in t[4:]
                                 for x in leafs(k)]

def show(d, tree):
  "Print a tree; + and - flag its best and worst leaf"
  ls = sorted(leafs(tree), key=lambda t: t[2])
  print("  d2h   n" + "".join(f"{c.txt:>7}" for c in d.y))
  def walk(t, pre):
    m = "+" if t is ls[0] else "-" if t is ls[-1] else " "
    print((f"{m} {round(100*t[2]):>3} {t[1]:>3}"
           + "".join(f"{round(v):>7}" for v in t[3])
           + "   " + pre + t[0]).rstrip())
    for k in t[4:]: walk(k, pre + "|  ")
  walk(tree, "")

#-- start-up ----------------------------------------------
# `main` is the whole app and `go_*` are the demos, which
# `--help` lists. Every `-Key` it prints is a live setting
# because the help text and the settings are one namespace.

def main(f):
  "Read f, spend labels, grow the tree, print it"
  d = data(csv(f))
  lab = acquire(d)
  print(f"{f} n={d.nr} mid={round(ymu(d, d.rows), 3)}"
        f" ezr={round(ydist(d, lab[0]), 3)}")
  show(d, grow(d, lab))

def go_help():
  "Show usage, settings, demos"
  g = globals()
  print("usage: python3 y.py [-Key val ..] [--demo ..]"
        " [file.csv]", "\nsettings:",
        *[f"  -{k:<6} {g[k]}"
          for k in sorted(g) if k[0].isupper()],
        "\ndemos:",
        *[f"  --{k[3:]}" for k in sorted(g) if k[:3] == "go_"],
        sep="\n")

def go_data():
  "Per-goal n, mu and sd of the whole table"
  for c in data(csv(File)).y:
    print(f"{c.txt} n {c.n} mu {round(c.mu,2)}"
          f" sd {round(sd(c),2)}")

def go_acquire():
  "Best labelled row's ydist, after spending `Stop` labels"
  d = data(csv(File))
  print(f"ezr {round(ydist(d, acquire(d)[0]), 3)}")

def go_tree():
  "Acquire, grow and show the default table"
  main(File)

def cli(args):
  "'-Key val' sets a setting, '--demo' runs one, else csv"
  while args:
    s = args.pop(0)
    if s[:2] == "--": globals().get("go_"+s[2:], go_help)()
    elif s[0] == "-": globals()[s[1:]] = thing(args.pop(0))
    else: main(s)

if __name__ == "__main__": cli(sys.argv[1:] or ["--help"])
