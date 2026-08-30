#!/usr/bin/env python3
"""winners.py: shapes of raced winners over the whole corpus.
Same rig as depth6.py (sway3 labels @ B=50 shared per repeat,
no-3 walk, race). Prints, for one maxd (default 6):
policy strings (digit per level: 0=both sides leaf,
1=worst side exits, 2=best side exits; trailing 0 = the
fallback cut) and two histograms -- levels-before-fallback
and distinct-attributes-before-fallback (both sum to 100%).

USAGE: python3 winners.py [maxd]"""
import sys, os, glob, random
from collections import Counter
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "ezr-py"))
import tiny, xai

REPEATS, BUDGET = 20, 50
MAXD = int(sys.argv[1]) if len(sys.argv) > 1 else 6

def leafy(t): return t.at is None

def policy(t):
  s = ""
  while not leafy(t):
    if leafy(t.yes) and leafy(t.no): return s + "0"
    kid, down = (t.yes, t.no) if leafy(t.yes) else (t.no, t.yes)
    s += "1" if kid.mid >= down.mid else "2"
    t = down
  return s or "0"

def ats(t):
  "Distinct split attrs, NOT counting the fallback cut"
  if leafy(t) or (leafy(t.yes) and leafy(t.no)): return set()
  return {t.at} | ats(t.yes) | ats(t.no)

def dataset(file):
  xai.the.acquire, xai.the.budget = "active", BUDGET
  try:
    random.seed(tiny.the.seed)
    tbl = tiny.Tbl(tiny.csv(file))
    tbl.rows = xai.some(tbl.rows, xai.the.cap)
    out = []
    for k in range(REPEATS):
      random.seed(xai.the.seed + k)
      rows  = xai.shuffle(tbl.rows)
      train = rows[:len(rows)//2]
      got   = list(xai.acquire(xai.clone(tbl, train)))
      Y     = lambda r: tiny.disty(tbl, r)
      tiny.the.maxd = MAXD
      best = tiny.race(tbl, list(tiny.walk(tiny.tree(tbl, got))),
                       got, Y)
      out.append((policy(best), len(ats(best))))
    return out
  except Exception as e:
    print("ERROR", file, e); return []

def hist(c, label):
  n = sum(c.values())
  print("\n%s (n=%d):" % (label, n))
  for k in sorted(c):
    pct = 100*c[k]/n
    print("%2d  %4.1f%% %s" % (k, pct, "*"*round(pct)))

if __name__ == "__main__":
  files = sorted(glob.glob(tiny.path("$MOOT/optimize/*/*.csv")))
  with Pool(os.cpu_count()) as p: outs = p.map(dataset, files)
  got = [x for o in outs for x in o]
  pol = Counter(s for s,_ in got)
  print("%d winners at maxd=%d, %d distinct policies:"
        % (len(got), MAXD, len(pol)))
  for s,k in pol.most_common(): print("%6d %-8s" % (k, s))
  hist(Counter(len(s)-1 for s,_ in pol.items()
               for _ in range(pol[s])), "levels before fallback")
  hist(Counter(a for _,a in got),
       "distinct attrs before fallback")
