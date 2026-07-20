#!/usr/bin/env python3
"""
report.py: rebuild REPORT.md's stats (RQ0-RQ2) over the
$MOOT/optimize corpus.

USAGE (from the ezr2 dir):
  python3 report.py            # all datasets, all cores
  python3 report.py 4          # use 4 cores
  python3 report.py auto93     # only files matching substring

Per dataset: 20 paired repeats (repeat k reseeds with
seed+k) of five arms -- active@50, active@20, active@200,
random@50, random@200 -- through the holdout rig, graded
by wins().
Deltas are 0 when same() says the two win-distributions are
indistinguishable. Results go to report.jsonl; the
histograms used in REPORT.md print at the end.
"""
import sys, os, glob, json, time, random
from multiprocessing import Pool

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ezr2 import *

REPEATS = 20

def arm(tbl, budget, mode):
  the.budget, the.acquire = budget, mode
  W, out = wins(tbl), []
  for k in range(REPEATS):
    random.seed(the.seed + k)
    out.append(W(holdout(tbl)))
  return out

def dataset(file):
  t0 = time.perf_counter()
  the.maxd = 4               # the study rig (matches tiny-xai)
  try:
    random.seed(the.seed)
    tbl = Tbl(csv(file))
    tbl.rows = some(tbl.rows, the.cap)
    a50, a20  = arm(tbl, 50, "active"), arm(tbl, 20, "active")
    a200, r50 = arm(tbl, 200, "active"), arm(tbl, 50, "random")
    r200      = arm(tbl, 200, "random")
    d = lambda xs,ys: (0.0 if same(xs,ys)
                       else sum(xs)/len(xs) - sum(ys)/len(ys))
    return dict(file=os.path.basename(file),
                rows=len(tbl.rows),
                mu=sum(a50)/len(a50), d50v20=d(a50,a20),
                d200v50=d(a200,a50), dAvR=d(a50,r50),
                dAvR200=d(a50,r200),
                secs=time.perf_counter()-t0)
  except Exception as e:
    return dict(file=os.path.basename(file),
                error="%s: %s" % (type(e).__name__, e))

# tiny-xai style histogram: percent + stars (1 star = 3 items)
def hist(vals, lo, hi, width, ties=False, per_star=3):
  n = len(vals)
  def bar(c): return " %s" % ("*"*round(c/per_star)) if c else ""
  def row(label, c):
    print("%s %3d%%%s" % (label, round(100*c/n), bar(c)))
  b = lo
  while b < hi:
    c = sum(1 for v in vals
            if b <= v < b+width and not (ties and v == 0))
    last = b + width >= hi
    row("[%3d,%3d%s" % (b, b+width, "]" if last else ")"),
        c + (sum(1 for v in vals if v == hi) if last else 0))
    if ties and b < 0 <= b+width:
      row("   ties=0 ", sum(1 for v in vals if v == 0))
    b += width

def pctl(vals):
  vs = sorted(vals); n = len(vs)
  return vs[0], vs[n//4], vs[n//2], vs[3*n//4], vs[-1]

def verdicts(tag, key, ok):
  print("wins %d  losses %d  ties %d  max %+.1f  min %+.1f"
        % (sum(1 for r in ok if r[key] > 0),
           sum(1 for r in ok if r[key] < 0),
           sum(1 for r in ok if r[key] == 0),
           max(r[key] for r in ok), min(r[key] for r in ok)))

if __name__ == "__main__":
  args  = sys.argv[1:]
  cores = (int(args[0]) if args and args[0].isdigit()
           else os.cpu_count())
  pat   = next((a for a in args if not a.isdigit()), "")
  files = [f for f in
           sorted(glob.glob(path("$MOOT/optimize/*/*.csv")))
           if pat in f]
  t0 = time.perf_counter()
  with Pool(cores) as p: out = p.map(dataset, files)
  ok  = [r for r in out if "error" not in r]
  bad = [r for r in out if "error" in r]
  with open("report.jsonl", "w") as f:
    for r in out: f.write(json.dumps(r) + "\n")
  for r in bad: print("ERROR", r["file"], r["error"])
  print("\n%d datasets, %.1fs wall, mean %.2fs/dataset "
        "(5 arms x %d repeats)"
        % (len(ok), time.perf_counter()-t0,
           sum(r["secs"] for r in ok)/len(ok), REPEATS))
  print("\nRQ0: mu(win), active, budget 50")
  hist([r["mu"] for r in ok], 0, 100, 10)
  print("quartiles: min %d, q1 %d, median %d, q3 %d, max %d"
        % tuple(round(v) for v in pctl([r["mu"] for r in ok])))
  print("\nRQ1: mu(win@50) - mu(win@20), active")
  hist([r["d50v20"] for r in ok], -15, 30, 5, ties=True)
  verdicts("RQ1", "d50v20", ok)
  print("\nRQ1b: mu(win@200) - mu(win@50), active")
  hist([r["d200v50"] for r in ok], -30, 30, 5, ties=True)
  verdicts("RQ1b", "d200v50", ok)
  print("\nRQ2: mu(win(active)) - mu(win(random)), budget 50")
  hist([r["dAvR"] for r in ok], -15, 30, 5, ties=True)
  verdicts("RQ2", "dAvR", ok)
  print("\nRQ2b: mu(win(active@50)) - mu(win(random@200))")
  hist([r["dAvR200"] for r in ok], -30, 30, 5, ties=True)
  verdicts("RQ2b", "dAvR200", ok)
