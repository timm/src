#!/usr/bin/env python3
"""rg.py : repgrids, on a labeling budget.                 (c) 2026, MIT license

Cover the x-space with furthest-point sampling (Gonzalez'85); label only the
cover; rank everything else by 1-nn onto that cover. Constructs prune/fuse
themselves each era, unsupervised. Same dist() runs both axes.

   bin    : rg.py bin  IN.csv [B=10]              raw csv -> binned csv (stdout)
   run    : rg.py run  BINNED.csv [N=3] [eras=6] [eps=.1] [seed=1] [Check=5]
            -> model as tag lines (stdout): meta / con / ele (sorted, best
            first) / tst (guess-sorted; the first Check rows are labeled,
            so those sort on true d)
   report : rg.py report < model.txt              classify, regress, optimize

   e.g.   : rg.py bin coc81.csv 6 > b.csv
            rg.py run b.csv 3 6 .1 1 > m.txt
            rg.py report < m.txt

Header suffixes: X=ignore, +=maximize, -=minimize, else input. Goals stay raw
(binning is for x only); d2h = distance to heaven over normalized goals, 0=best.
Total label cost = number of ele lines, plus Check confirmations off tst's top.
"""
import sys, random

SYM = dict(vl=1, l=2, n=3, h=4, vh=5, xh=6)      # ordinal words, if seen

#--------------------------------------------------------------- bin ---------
def num(v):
  try: return float(v)
  except: return None

def bins(path, B=10):
  rows = [l.strip().split(",") for l in open(path) if l.strip()]
  head, body = rows[0], rows[1:]
  keep = [i for i, h in enumerate(head) if h[-1] != "X"]
  head = [head[i] for i in keep]
  body = [[r[i] for i in keep] for r in body]
  for c, h in enumerate(head):
    if h[-1] in "+-": continue                   # goals stay raw
    col = [r[c] for r in body]
    if all(num(v) is not None for v in col):     # numeric: equal-frequency
      cuts = sorted(num(v) for v in col)
      cuts = [cuts[len(cuts) * i // B] for i in range(1, B)]
      for r in body: r[c] = str(1 + sum(num(r[c]) > x for x in cuts))
    else:                                        # symbolic: ordinal or enum
      seen = {v: i + 1 for i, v in enumerate(sorted(set(col)))}
      for r in body: r[c] = str(SYM.get(r[c], seen[r[c]]))
  print(",".join(head))
  for r in body: print(",".join(r))

#--------------------------------------------------------------- run ---------
def read(path):
  rows = [l.strip().split(",") for l in open(path) if l.strip()]
  head = rows[0]
  x = [i for i, h in enumerate(head) if h[-1] not in "+-"]
  y = [(i, 1 if head[i][-1] == "+" else 0)
       for i, h in enumerate(head) if h[-1] in "+-"]
  return head, x, y, [[float(v) for v in r] for r in rows[1:]]

def dist(a, b, cols, B):
  "city block over the given columns, normalized to 0..1"
  return sum(abs(a[c] - b[c]) for c in cols) / ((B - 1) * len(cols))

def far(items, cols, B, eps):
  "furthest-point cover (Gonzalez). all items end within eps of a delegate."
  D    = [0]
  near = [dist(items[0], i, cols, B) for i in items]
  while max(near) >= eps:
    j = near.index(max(near))
    D += [j]
    near = [min(n, dist(items[j], i, cols, B)) for n, i in zip(near, items)]
  out = [dict(at=d, kin=[d]) for d in D]
  for j, i in enumerate(items):
    if j not in D:
      min(out, key=lambda o: dist(items[o["at"]], i, cols, B))["kin"] += [j]
  return out

def run(path, N=3, eras=6, eps=.1, seed=1, check=5):
  head, x, y, rows = read(path)
  B = max(max(r[c] for r in rows) for c in x)
  random.seed(seed); random.shuffle(rows)
  train, test = rows[:N * eras], rows[N * eras:]
  lohi = {c: (min(t[c] for t in train), max(t[c] for t in train)) for c, _ in y}

  def d2h(r):
    g = 0
    for c, h in y:
      lo, hi = lohi[c]
      g += (h - (r[c] - lo) / (hi - lo + 1E-32)) ** 2
    return (g / len(y)) ** .5

  E, live = [], x                                # delegates, live constructs
  for era in range(eras):
    for row in train[era * N:(era + 1) * N]:     # one element at a time
      if not E or min(dist(row, e["lead"], live, B) for e in E) >= eps:
        E += [dict(lead=row, kin=[])]            # novel -> new delegate
      else:
        min(E, key=lambda e: dist(row, e["lead"], live, B))["kin"] += [row]
    grid = [[e["lead"][c] for c in x] for e in E]     # pause: reflect on
    cons = [[g[j] for g in grid] for j in range(len(x))]    # constructs
    C    = (far(cons, range(len(E)), B, eps) if len(E) > 1
            else [dict(at=i, kin=[i]) for i in range(len(x))])
    live = [x[c["at"]] for c in C]

  E.sort(key=lambda e: d2h(e["lead"]))           # best towards the top
  guess = lambda r: d2h(min(E, key=lambda e: dist(r, e["lead"], live, B))["lead"])
  test.sort(key=guess)                           # labels=0: sorted on guess
  test[:check] = sorted(test[:check], key=d2h)   # label top Check: true d sort
  ints = lambda r: ",".join(str(int(r[c])) for c in live)
  raws = lambda r: ",".join(f"{r[c]:g}" for c, _ in y)
  print(f"meta\teps={eps}\tB={B:g}\tN={N}\teras={eras}\tcheck={check}\t"
        f"heaven={','.join(str(h) for _, h in y)}")
  for c in C:
    print(f"con\t{head[x[c['at']]]}\t"
          f"{','.join(head[x[i]] for i in c['kin'][1:])}")
  for e in E:
    print(f"ele\td={d2h(e['lead']):.2f}\t{len(e['kin']) + 1}\t"
          f"{ints(e['lead'])}\t{raws(e['lead'])}")
  print()
  for j, r in enumerate(test):
    if j == check: print()
    print(f"tst\tguess={guess(r):.2f}\td={d2h(r):.2f}\t{ints(r)}\t{raws(r)}")

#--------------------------------------------------------------- report ------
def d2h1(ys, lohi, heaven):
  g = sum((h - (v - lo) / (hi - lo + 1E-32)) ** 2
          for v, (lo, hi), h in zip(ys, lohi, heaven))
  return (g / len(ys)) ** .5

def report(src):
  E, T = [], []
  for line in src:
    f = line.strip().split("\t")
    if f[0] == "meta":
      m = dict(kv.split("=") for kv in f[1:])
      B, heaven = float(m["B"]), [int(v) for v in m["heaven"].split(",")]
    if f[0] == "ele": E += [dict(x=[int(v) for v in f[3].split(",")],
                                 y=[float(v) for v in f[4].split(",")])]
    if f[0] == "tst": T += [dict(x=[int(v) for v in f[3].split(",")],
                                 y=[float(v) for v in f[4].split(",")])]
  lohi = [(min(r["y"][i] for r in E + T), max(r["y"][i] for r in E + T))
          for i in range(len(heaven))]
  for r in E + T: r["d"] = d2h1(r["y"], lohi, heaven)
  cut = sorted(r["d"] for r in E)[len(E) // 4]
  for r in E: r["c"] = r["d"] <= cut
  nn = lambda t: min(E, key=lambda e: sum(abs(a - b) for a, b in
                     zip(t["x"], e["x"])) / ((B - 1) * len(t["x"])))
  hits = sum((t["d"] <= cut) == nn(t)["c"] for t in T)
  mae  = sum(abs(t["d"] - nn(t)["d"]) for t in T)
  print(f"{len(E)} delegates (=labels), {len(T)} test rows")
  print(f"classify d2h<={cut:.2f}: acc {hits / len(T):.2f}")
  print(f"regress  d2h: mae {mae / len(T):.3f} "
        f"(test spread {max(t['d'] for t in T) - min(t['d'] for t in T):.2f})")
  top5 = sorted(T, key=lambda t: nn(t)["d"])[:5]
  print(f"optimize: best-of-top-5-guesses d2h = "
        f"{min(t['d'] for t in top5):.2f}  "
        f"(pool best {min(t['d'] for t in T):.2f}; cost {len(E)}+5 labels)")

#--------------------------------------------------------------- main --------
if __name__ == "__main__":
  a = sys.argv[1:]
  if   not a or a[0] == "report": report(sys.stdin)
  elif a[0] == "bin": bins(a[1], *[int(v) for v in a[2:3]])
  elif a[0] == "run": run(a[1], *[t(v) for t, v in
                                  zip((int, int, float, int, int), a[2:])])
  else: print(__doc__)
