#!/usr/bin/env python3
"""depth6.py: does depth > 4 ever win the pruning race?
Rig = WHY_NO_3 head-to-head: $MOOT/optimize corpus, cap 1024,
50:50 split, sway3 labels @ B=50 (shared across arms per
repeat), no-3 walk, race on train, winner picks top-5 test
rows, graded by wins(). Arms: maxd in {4,6,8}. Paired seeds,
20 repeats. same() decides ties. Also: actual depth of each
raced winner."""
import sys, os, glob, json, time, random
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "ezr-py"))
import tiny, xai

REPEATS = 20
BUDGET  = 50
DEPTHS  = (4, 6, 8)

def tdepth(t):
  if t.at is None: return 0
  return 1 + max(tdepth(t.yes), tdepth(t.no))

def dataset(file):
  t0 = time.perf_counter()
  xai.the.acquire, xai.the.budget = "active", BUDGET
  try:
    random.seed(tiny.the.seed)
    tbl = tiny.Tbl(tiny.csv(file))
    tbl.rows = xai.some(tbl.rows, xai.the.cap)
    W  = xai.wins(tbl)
    scores = {d: [] for d in DEPTHS}
    wdepth = {d: [] for d in DEPTHS}
    npool  = {d: [] for d in DEPTHS}
    for k in range(REPEATS):
      random.seed(xai.the.seed + k)
      rows  = xai.shuffle(tbl.rows)
      half  = len(rows)//2
      train, test = rows[:half], rows[half:]
      xai.the.maxd = 4
      got = list(xai.acquire(xai.clone(tbl, train)))
      Y   = lambda r: tiny.disty(tbl, r)
      for d in DEPTHS:
        tiny.the.maxd = d
        t    = tiny.tree(tbl, got)
        pool = list(tiny.walk(t))
        best = tiny.race(tbl, pool, got, Y)
        top  = sorted(test, key=lambda r: tiny.leaf(tbl, best, r))
        scores[d].append(W(min(top[:xai.the.check], key=Y)))
        wdepth[d].append(tdepth(best))
        npool[d].append(len(pool))
    mu = lambda xs: sum(xs)/len(xs)
    r = dict(file=os.path.basename(file), rows=len(tbl.rows))
    for d in DEPTHS:
      r["mu%d" % d]     = mu(scores[d])
      r["depths%d" % d] = wdepth[d]
      r["pool%d" % d]   = mu(npool[d])
    for d in DEPTHS[1:]:
      r["d%dv4" % d] = (0.0 if xai.same(scores[d], scores[4])
                        else mu(scores[d]) - mu(scores[4]))
    r["secs"] = time.perf_counter() - t0
    return r
  except Exception as e:
    return dict(file=os.path.basename(file),
                error="%s: %s" % (type(e).__name__, e))

if __name__ == "__main__":
  files = sorted(glob.glob(tiny.path("$MOOT/optimize/*/*.csv")))
  t0 = time.perf_counter()
  with Pool(os.cpu_count()) as p: out = p.map(dataset, files)
  ok  = [r for r in out if "error" not in r]
  bad = [r for r in out if "error" in r]
  here = os.path.dirname(os.path.abspath(__file__))
  with open(os.path.join(here, "depth6.jsonl"), "w") as f:
    for r in out: f.write(json.dumps(r) + "\n")
  for r in bad: print("ERROR", r["file"], r["error"])
  print("%d datasets ok, %d errors, %.1fs wall"
        % (len(ok), len(bad), time.perf_counter()-t0))
  for d in DEPTHS[1:]:
    k = "d%dv4" % d
    print("\nmaxd=%d vs maxd=4 (same sway3 labels, paired):" % d)
    print("  wins %d  losses %d  ties %d"
          % (sum(1 for r in ok if r[k] > 0),
             sum(1 for r in ok if r[k] < 0),
             sum(1 for r in ok if r[k] == 0)))
    if ok:
      print("  max %+.1f  min %+.1f"
            % (max(r[k] for r in ok), min(r[k] for r in ok)))
  print("\nwinner-tree ACTUAL depth distribution "
        "(all datasets x %d repeats):" % REPEATS)
  for d in DEPTHS:
    from collections import Counter
    c = Counter(x for r in ok for x in r["depths%d" % d])
    n = sum(c.values())
    print("  maxd=%d: %s" % (d, "  ".join(
      "%d:%d(%d%%)" % (k, c[k], round(100*c[k]/n))
      for k in sorted(c))))
  med = lambda k: sorted(r[k] for r in ok)[len(ok)//2]
  print("\nmedian mu(win): " + "  ".join(
    "maxd=%d %.1f" % (d, med("mu%d" % d)) for d in DEPTHS))
  print("mean pool size: " + "  ".join(
    "maxd=%d %.0f" % (d, sum(r["pool%d" % d] for r in ok)/len(ok))
    for d in DEPTHS))
