#!/usr/bin/env python3 -B
"""
y2.py: y1 with naked structs (Num=tuple, Sym=dict)
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

the = o(**{k: atom(v) for k, v in
           re.findall(r"(\w+)=(\S+)", __doc__ or "")})

def csv(file):
  file = file.replace("$MOOT", os.environ.get("MOOT")
                      or os.path.expanduser("~/gits/moot"), 1)
  with open(file, encoding="utf-8") as f:
    return [tuple(atom(x) for x in line.split(","))
            for line in f if line.strip()]

#-- structs -----------------------------------------------
def Num(): return (0, 0, 0, 0)  # n, mu, m2, sd
Sym = dict

def is_num(c): return type(c) is tuple

def size(c): return c[0] if is_num(c) else sum(c.values())

def add(c, v, inc=1): # new Num, or updated Sym
  if v == "?": return c
  if not is_num(c): c[v] = c.get(v, 0) + inc; return c
  n, mu, m2, _ = c
  n += inc
  d = v - mu
  mu += inc * d / max(1, n)
  m2 = max(0, m2 + inc * d * (v - mu))
  return (n, mu, m2, 0 if n < 2 else (m2 / (n - 1)) ** .5)

def without(c, b): # c's numbers (or counts), less b's
  if not is_num(c):
    return {k:n for k,v in c.items() if (n := v - b.get(k,0)) >0}
  (n1, mu1, m21, _), (n2, mu2, m22, _) = c, b
  n = n1 - n2
  if n <= 0: return Num()
  d = mu2 - mu1
  m2 = max(0, m21 - m22 - d*d*n1*n2/n)
  return (n, (n1*mu1-n2*mu2)/n, m2, 0 if n<2 else (m2/(n-1))**.5)

def Tbl(src):
  tbl = o(rows=[],cols={},x=[],y={},names=src[0],nr=0,mid=None)
  for at, s in enumerate(tbl.names):
    if not s.endswith("X"):
      tbl.cols[at] = Num() if s[0].isupper() else Sym()
      if s[-1] in "+-": tbl.y[at] = s[-1] == "+"
      else: tbl.x.append(at)
  for row in src[1:]: adds(tbl, row)
  return tbl

def clone(t, rows=[]): return Tbl([t.names] + rows)

def adds(t, row=None, inc=1):
  t.nr += inc; t.mid = None
  if inc > 0: t.rows.append(row)
  else: row = t.rows.pop()
  for at in t.cols:
    t.cols[at] = add(t.cols[at], row[at], inc)
  return row

#-- distance ----------------------------------------------
def div(c): # Num: sd. Sym: entropy
  if is_num(c): return c[3]
  n = sum(c.values())
  return -sum(v/n * math.log2(v/n) for v in c.values() if v>0)

def norm(c, v):
  z = max(-3, min(3, (v - c[1]) / (1e-32 + c[3])))
  return 1 / (1 + math.exp(-1.7 * z))

def mid(c):
  return c[1] if is_num(c) else max(c, key=c.get) if c else "?"

def mids(t): # cached centroid; adds() zaps it
  t.mid = t.mid or {at: mid(c) for at, c in t.cols.items()}
  return t.mid

def ydist(t, row):
  return (sum(abs(norm(t.cols[at], row[at]) - w) ** the.P
              for at, w in t.y.items()) / len(t.y))**(1/the.P)

def _dist(c, a, b):
  if a == "?" or b == "?": return 1
  return abs(norm(c, a) - norm(c, b)) if is_num(c) else a != b

def xdist(t, row, m):
  return (sum(_dist(t.cols[at], row[at], m[at]) ** the.P
              for at in t.x) / len(t.x)) ** (1 / the.P)

def ymu(t, rows):
  return sum(ydist(t, r) for r in rows) / len(rows)

def ymids(t, rows):
  return [sum(r[at] for r in rows)/len(rows) for at in t.y]

#-- acquire -----------------------------------------------
def pop(t, best, rest, todo):
  b, r = mids(best), mids(rest)
  todo.sort(key=lambda z: xdist(t, z, r) - xdist(t, z, b))
  return todo.pop()

def label(t, best, rest, row):
  adds(best, row)
  best.rows.sort(key=lambda r: ydist(t, r))
  if best.nr > int((1 + best.nr + rest.nr) ** .5):
    adds(rest, adds(best, inc=-1))

def acquire(t, cap=None):
  best, rest = clone(t), clone(t)
  todo = random.sample(t.rows, len(t.rows))[:the.Few]
  for _ in range(the.Start): label(t, best, rest, todo.pop())
  cap = cap or the.Stop
  while todo and best.nr + rest.nr < cap:
    label(t, best, rest, pop(t, best, rest, todo))
  return best.rows + rest.rows

#-- tree --------------------------------------------------
# Node = [edge, n, ymu, ymids, go, kid, kid]
def xpect(a, b):
  return ((div(a)*size(a) + div(b)*size(b))
          / (size(a) + size(b) + 1e-32))

def cutNum(xy, acc):
  xy.sort()
  here = acc()
  for i, (x, y) in enumerate(xy[:-1]):
    here = add(here, y)
    if x != xy[i+1][0]: yield here, x

def cutSym(xy, acc):
  d = {}
  for x, y in xy: d[x] = add(d.get(x) or acc(), y)
  yield from ((here, x) for x, here in d.items())

def cut(t, rows, y=None):
  y = y or (lambda r: ydist(t, r))
  acc = Sym if type(y(rows[0])) is str else Num
  best = (1e30, None, None)
  for at in t.x:
    there, xy = acc(), []
    for r in rows:
      if (x := r[at]) != "?":
        there = add(there, yy := y(r)); xy.append((x, yy))
    for here, v in (cutNum if is_num(t.cols[at])
                    else cutSym)(xy, acc):
      if the.Leaf <= size(here) <= len(xy) - the.Leaf:
        s = xpect(here, without(there, here))
        if s < best[0]: best = (s, at, v)
  return best

def routing(t, at, v):
  s, c = t.names[at], t.cols[at]
  if is_num(c):
    return (f"{s} <= {round(v,2)}", f"{s} > {round(v,2)}",
            lambda r: (c[1] if r[at] == "?" else r[at]) <= v)
  return (f"{s} = {v}", f"{s} != {v}", lambda r: r[at] == v)

def tree(t, rows, edge="", y=None):
  node = [edge, len(rows), ymu(t, rows), ymids(t, rows)]
  _, at, v = (cut(t, rows, y) if len(rows) > the.Leaf
              else 3 * (None,))
  if at is not None:
    e1, e2, go = routing(t, at, v)
    yes = [r for r in rows if go(r)]
    no  = [r for r in rows if not go(r)]
    if yes and no:
      node += [go, tree(t, yes, e1, y), tree(t, no, e2, y)]
  return node

def leaf(tr, row):
  while len(tr) > 4: tr = tr[5] if tr[4](row) else tr[6]
  return tr

#-- report ------------------------------------------------
def leafs(tr):
  return [tr] if len(tr) < 5 else [x for k in tr[5:]
                                   for x in leafs(k)]

def show(t, tr):
  ls = sorted(leafs(tr), key=lambda z: z[2])
  print("  d2h   n" + "".join(f"{t.names[at]:>7}"
                              for at in t.y))
  def walk(z, pre=None):
    m = "+" if z is ls[0] else "-" if z is ls[-1] else " "
    print((f"{m} {round(100*z[2]):>3} {z[1]:>3}"
           + "".join(f"{round(v):>7}" for v in z[3])
           + "   " + (pre or "") + z[0]).rstrip())
    for k in z[5:]: walk(k, "" if pre is None else pre+"|  ")
  walk(tr)

#-- tests -------------------------------------------------
def wins(t):
  ys = sorted(ydist(t, r) for r in t.rows)
  lo, b4 = ys[0], sum(ys) / len(ys)
  return lambda r: max(-100, min(100,
    100 * (1 - (ydist(t, r) - lo) / (b4 - lo + 1e-32))))

def holdout(t):
  rows = random.sample(t.rows, len(t.rows))
  n = len(rows) // 2
  train, test = rows[:n][:the.Few], rows[n:]
  tr = clone(t, train)
  tt = tree(tr, acquire(tr, the.Stop - the.Check))
  top = sorted(test, key=lambda r: leaf(tt,r)[2])[:the.Check]
  return min(top, key=lambda r: ydist(tr, r))

#-- start-up ----------------------------------------------
def test_help():
  "Show usage, settings, demos"
  print("usage: python3 y2.py [-Key val ..] [--demo ..]",
        "\nsettings:",
        *[f"  -{k:<6} {v}"
          for k, v in sorted(vars(the).items())],
        "\ndemos:",
        *[f"  --{k[5:]:<8} {f.__doc__}"
          for k, f in sorted(globals().items())
          if k[:5] == "test_"],
        sep="\n")

def test_tree():
  "Acquire, grow and show the.File's tree"
  t = Tbl(csv(the.File))
  lab = acquire(t)
  print(f"{the.File} n={t.nr}"
        f" mid={round(ymu(t, t.rows), 3)}"
        f" ezr={round(ydist(t, lab[0]), 3)}")
  show(t, tree(t, lab))

def test_holdout():
  "Mean win over 20 train/test holdouts"
  t = Tbl(csv(the.File))
  win = wins(t)
  mu = sum(win(holdout(t)) for _ in range(20)) / 20
  print(f"win {round(mu)}")

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
