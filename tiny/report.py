#!/usr/bin/env python3
"""
report.py: does the pruning race earn its keep? Both arms
label the SAME rows (sway3 active learning, budget B in
{50,100,200}; paired seeds); then the fft arm races the
depth-4 tree's prunings (tiny) while the active arm keeps
the full tree (xai). Corpus: $MOOT/optimize.

USAGE (from the tiny dir):
  python3 report.py            # 25 random datasets
  python3 report.py all        # every dataset
  python3 report.py 50         # 50 random datasets
  python3 report.py auto93     # only files matching substring

Per dataset: cap rows at 1024, then 20 paired repeats
(repeat k reseeds both arms with seed+k) of six arms --
fft@B and active@B for B in 50, 100, 200 -- graded by
wins(). Delta is 0 when same() says the two win
distributions are indistinguishable. Results go to
report.jsonl; the histograms print at the end.
"""
import sys, os, glob, json, time, random
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "ezr-py"))
import tiny, xai

REPEATS = 20
BUDGETS = (50, 100, 200)

def fft_arm(tbl, W, budget):
  "20 reseeded holdouts: sway3 labels, race the prunings"
  xai.the.budget = budget
  out = []
  for k in range(REPEATS):
    random.seed(xai.the.seed + k)
    rows  = xai.shuffle(tbl.rows)
    half  = len(rows)//2
    train, test = rows[:half], rows[half:]
    got   = list(xai.acquire(xai.clone(tbl, train)))
    Y     = lambda r: tiny.disty(tbl, r)
    t     = tiny.tree(tbl, got)
    best  = tiny.race(tbl, list(tiny.walk(t)), got, Y)
    top   = sorted(test,
                   key=lambda r: tiny.leaf(tbl, best, r))
    out.append(W(min(top[:xai.the.check], key=Y)))
  return out

def active_arm(tbl, W, budget):
  "20 reseeded xai holdouts: sway3 active labelling @ budget"
  xai.the.budget = budget
  out = []
  for k in range(REPEATS):
    random.seed(xai.the.seed + k)
    out.append(W(xai.holdout(tbl)))
  return out

def dataset(file):
  t0 = time.perf_counter()
  tiny.the.maxd = 4
  xai.the.maxd, xai.the.acquire = 4, "active"
  try:
    random.seed(tiny.the.seed)
    tbl = tiny.Tbl(tiny.csv(file))
    tbl.rows = xai.some(tbl.rows, xai.the.cap)
    W  = xai.wins(tbl)
    mu = lambda xs: sum(xs)/len(xs)
    r  = dict(file=os.path.basename(file), rows=len(tbl.rows))
    for b in BUDGETS:
      f, a = fft_arm(tbl, W, b), active_arm(tbl, W, b)
      r["muF%d" % b], r["muA%d" % b] = mu(f), mu(a)
      r["d%d" % b] = 0.0 if xai.same(f,a) else mu(f) - mu(a)
    r["secs"] = time.perf_counter() - t0
    return r
  except Exception as e:
    return dict(file=os.path.basename(file),
                error="%s: %s" % (type(e).__name__, e))

# ezr-py style histogram: percent + stars
def hist(vals, lo, hi, width, ties=False, per_star=1):
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

def verdicts(key, ok):
  print("wins %d  losses %d  ties %d  max %+.1f  min %+.1f"
        % (sum(1 for r in ok if r[key] > 0),
           sum(1 for r in ok if r[key] < 0),
           sum(1 for r in ok if r[key] == 0),
           max(r[key] for r in ok), min(r[key] for r in ok)))

if __name__ == "__main__":
  args  = sys.argv[1:]
  files = sorted(glob.glob(tiny.path("$MOOT/optimize/*/*.csv")))
  n     = 25
  for a in args:
    if a.isdigit():   n = int(a)
    elif a == "all":  n = len(files)
    else:             files = [f for f in files if a in f]
  random.seed(tiny.the.seed)
  files = sorted(random.sample(files, min(n, len(files))))
  t0 = time.perf_counter()
  with Pool(os.cpu_count()) as p: out = p.map(dataset, files)
  ok  = [r for r in out if "error" not in r]
  bad = [r for r in out if "error" in r]
  with open(os.path.join(HERE, "report.jsonl"), "w") as f:
    for r in out: f.write(json.dumps(r) + "\n")
  for r in bad: print("ERROR", r["file"], r["error"])
  print("%d datasets, %.1fs wall, mean %.2fs/dataset "
        "(%d arms x %d repeats)"
        % (len(ok), time.perf_counter()-t0,
           sum(r["secs"] for r in ok)/len(ok),
           2*len(BUDGETS), REPEATS))
  for b in BUDGETS:
    print("\nmu(win(fft@%d)) - mu(win(active@%d)):" % (b,b))
    hist([r["d%d" % b] for r in ok], -30, 30, 5, ties=True)
    verdicts("d%d" % b, ok)
  print("\nmu(win) per arm (median over datasets):")
  med = lambda k: sorted(r[k] for r in ok)[len(ok)//2]
  for b in BUDGETS:
    print("  B=%3d  fft %5.1f  active %5.1f"
          % (b, med("muF%d" % b), med("muA%d" % b)))
