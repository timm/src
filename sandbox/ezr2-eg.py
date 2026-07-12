#!/usr/bin/env python3 -B
"""
ezr2-eg.py: tutorial and tests for ezr2 (library in ezr2.py).

Run any test by its bare name; pass --key=val to override a knob:
  python3 ezr2-eg.py tree
  python3 ezr2-eg.py all

One -eg file per engine file, loaded below in tutorial order;
prose lives in string blocks; every sample is pasted from a
real run, never hand-typed.
"""
from ezr2 import *

"""

Tables of data are cheap; *labels* are dear. So: how few
labels buy a good row, plus an explanation of why it is
good? One table runs through this tutorial: auto93 (via
$MOOT), 398 cars, goals minimize Lbs-, maximize Acc+ and
Mpg+.
"""

#-- lib-eg ------------------------------------------------------
"""

Csv cells arrive as strings. `thing` coerces each one:
"23" becomes an int, "-1e2" a float (csv cells can hide
exponents), "True"/"False" become bools, "?" marks a
missing value, anything else stays text.

| call | returns | what |
|------|---------|------|
| `thing(s)` | int, float, bool, text | coerce one cell |
"""

def test_thing():
  "String coercion round-trip."
  got = [thing(s) for s in
         ["23", "3.14", "-1e2", "True", "False", "?", "abc"]]
  print(got)
  assert got == [23, 3.14, -100.0, True, False, "?", "abc"]

#-- rand-eg -----------------------------------------------------
"""

Later demos shuffle and sample, so first: everything random
runs through python's `random`, seeded from `the.seed`
before every test, so any demo reproduces in isolation.

| call | returns | what |
|------|---------|------|
| `shuffle(lst)` | list | all items, seeded-random order |
| `some(lst, k)` | list | k items picked at random |
"""

def test_rand():
  "Seeded shuffle repeats; some() respects k."
  random.seed(1); a = shuffle(list(range(20)))
  random.seed(1); b = shuffle(list(range(20)))
  print(a[:8])
  assert a == b
  assert len(some(a, 5)) == 5
  assert len(some(a, 999)) == 20

#-- cols-eg -----------------------------------------------------
"""

Two summaries, one interface. `Num` folds values one at a
time by Welford's trick (no list kept, just n, mu, m2);
`Sym` counts. `mid`/`var` answer for either. First a Sym
tiny enough to check by eye; then 10,000 Irwin-Hall samples
(three uniforms, centered, scaled): mean lands on 0, sd on
1 -- testing `add`, `welford`, `mid` and `var` in one shot.

| call | returns | what |
|------|---------|------|
| `add(col, v)` | col | fold v in (Num or Sym) |
| `mid(col)` | value | mean or mode |
| `var(col)` | float | sd or entropy |
"""

def test_cols():
  "Sym mode+entropy on a known bag; Num mu,sd via Irwin-Hall."
  s = adds("aaaabbc", Sym())
  print("sym mid %s ent %.3f" % (mid(s), var(s)))
  assert mid(s) == "a" and abs(var(s) - 1.379) < 0.01
  random.seed(the.seed)
  r = random.random
  n = adds(((r()+r()+r()-1.5)/0.5 for _ in range(10000)))
  print("num mu %.3f sd %.3f" % (mid(n), var(n)))
  assert abs(mid(n)) < 0.05 and abs(var(n) - 1) < 0.05

#-- tbl-eg -----------------------------------------------------
"""

`Tbl` streams the csv once: the first row names the
columns and `roles` types them from the name suffixes;
later rows update the per-column summaries. Notice auto93's
shape: 4 x-columns, 3 goals (minimize Lbs-, maximize Acc+
and Mpg+), one ignored column (HpX).

| call | returns | what |
|------|---------|------|
| `Tbl(csv(f))` | tbl | rows + column summaries |
| `clone(tbl, rows)` | tbl | fresh table, same header |
"""

def test_data():
  "Tbl build: col roles and goal stats."
  tbl = Tbl(csv(the.file))
  print("rows %s |x| %s |y| %s" % (len(tbl.rows),
        len(tbl.x), len(tbl.y)))
  if "auto93" in the.file:
    assert len(tbl.rows) == 398
    assert len(tbl.x) == 4 and len(tbl.y) == 3
    mpg = tbl.cols[tbl.y[-1]]
    print("Mpg+ mu %.2f sd %.2f" % (mu_(mpg), sd(mpg)))
    assert abs(mu_(mpg) - 23.84) < 0.1
    assert abs(sd(mpg) - 8.34) < 0.1

#-- dist-eg -----------------------------------------------------
"""

`disty` scores each row by distance to the ideal goals
(0 = best), reading only the y columns. Sort our table by
it and the best cars float to the top:

    Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
         4      90   48     78       2  1985  21.5    40  0.075
         4      90   48     80       2  2085  21.7    40  0.087
         4      85   65     81       3  1975  19.4    40  0.087

         8     440  215     70       1  4312   8.5    10  0.956
         8     455  225     73       1  4951    11    10  0.956

Notice the shape: light, late, high-mpg cars up top; big
old guzzlers at the bottom.

| call | returns | what |
|------|---------|------|
| `disty(tbl, row)` | 0..1 | distance to ideal goals |
| `distx(tbl, r1, r2)` | 0..1 | difference over x cols |
"""

def test_disty():
  "Rows sorted by disty: header, top 5, blank, bottom 5."
  tbl = Tbl(csv(the.file))
  rows = sorted(tbl.rows, key=lambda r: disty(tbl, r))
  hdr  = list(tbl.names) + ["disty"]
  fmt  = lambda r: [str(v) for v in r]+["%.3f" % disty(tbl,r)]
  body = [fmt(r) for r in rows[:5] + rows[-5:]]
  w = [max(len(row[c]) for row in [hdr]+body)
       for c in range(len(hdr))]
  line = lambda cs: print("  ".join(c.rjust(w[i])
                                    for i,c in enumerate(cs)))
  line(hdr)
  for r in body[:5]: line(r)
  print()
  for r in body[5:]: line(r)
  assert disty(tbl, rows[0]) <= disty(tbl, rows[-1])

#-- stats-eg ----------------------------------------------------
"""

A tool needed before any experiment: `same` calls two lists
equal only if cohen AND cliffs AND ks all agree. Watch it
on a gaussian nudged by ever-larger shifts: same up to 0.1,
different from 0.3 on. Notice how conservative that is --
later "X beats Y" claims must clear all three tests.

| call | returns | what |
|------|---------|------|
| `same(xs, ys)` | bool | cohen+cliffs+ks all agree |
| `cliffs(xs, ys)` | 0..1 | effect size (0 = identical) |
"""

def test_same():
  "Validate same(): small shift = same, big shift = differ."
  random.seed(the.seed)
  a = [random.gauss(0, 1) for _ in range(20)]
  shift = lambda d: [x + d for x in a]
  print("shift  same   cliffs cohen")
  for d in (0, 0.1, 0.3, 0.5, 1.0, 2.0):
    b = shift(d)
    print(" %+.1f  %-5s  %.2f   %s" % (d, same(a,b),
          cliffs(a,b), cohen(a,b)))
  assert same(a, a) and not same(a, shift(2))

#-- acquire-eg --------------------------------------------------
"""

`landscape` spends the label budget (default 50): label a
few rows, project the rest onto the line joining two far
labelled poles, cull the third nearest the bad pole,
repeat. Two studies: per-run active vs random deltas on a
bigger table, then one mean-win summary line.

| call | returns | what |
|------|---------|------|
| `landscape(tbl)` | rows | labelled few, best first |
"""

def test_landscape():
  "20 shuffles; active vs random, sorted by significant delta."
  f0 = the.file
  the.file = "$MOOT/optimize/binary_config/billing10k.csv"
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  A, R = [], []
  for i in range(20):
    random.seed(the.seed + i)
    tbl.rows = shuffle(tbl.rows)
    the.landscape = "active"
    A += [disty(tbl, landscape(tbl)[0])]
    the.landscape = "random"
    R += [disty(tbl, landscape(tbl)[0])]
  the.landscape = "active"
  sd_ = lambda z: (sum((v - sum(z)/len(z))**2
                       for v in z) / (len(z)-1)) ** 0.5
  pooled = (((len(A)-1)*sd_(A)**2 + (len(R)-1)*sd_(R)**2)
            / (len(A)+len(R)-2)) ** 0.5
  thr = 0.35 * pooled  # tie below small effect; +ve => active
  out = [(a, r, (r-a if abs(r-a) >= thr else 0.0))
         for a, r in zip(A, R)]
  up = chr(0x25B2)     # marks whichever side won this run
  print("rank  aDisty  rDisty   delta  win  (%s)"
        % the.file.split("/")[-1])
  for k,(a,r,d) in enumerate(sorted(out, key=lambda t:-t[2])):
    win = ("tie" if d == 0 else
           "%s active" % up if d > 0 else "%s random" % up)
    print("%4d %7.3f %7.3f  %+6.3f  %s" % (k, a, r, d, win))
  win  = sum(d for _,_,d in out if d > 0)
  loss = -sum(d for _,_,d in out if d < 0)
  the.file = f0
  assert win > loss  # size of wins beats size of losses

def test_landscapes():
  "One summary line: mean win/disty over 20 runs."
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  W, ds, ws, n = wins(tbl), [], [], 0
  for i in range(20):
    random.seed(the.seed + i)
    tbl.rows = shuffle(tbl.rows)
    got = landscape(tbl)
    ds += [disty(tbl,got[0])]; ws += [W(got[0])]; n = len(got)
  print("%6.1f %7.3f %4d  %s" % (sum(ws)/len(ws),
        sum(ds)/len(ds), n, the.file.split("/")[-1]))
  assert -100 <= sum(ws)/len(ws) <= 100

#-- cuts-eg -----------------------------------------------------
"""

Why are the good rows good? `cuts` offers candidate splits
per x-column; the cheapest (size-weighted variance of the
two halves) wins. The assert: the best cut beats the
unsplit spread, else explanation would be hopeless.

| call | returns | what |
|------|---------|------|
| `cuts(tbl,rows,at,Y)` | iter | (cost, at, v) candidates |
"""

def test_cuts():
  "Best single cut beats the unsplit spread."
  tbl = Tbl(csv(the.file))
  Y    = lambda r: disty(tbl, r)
  best = min(c for at in tbl.x
             for c in cuts(tbl, tbl.rows, at, Y))
  tot  = adds(map(Y, tbl.rows))
  print("best cost %.3f at %s v %s  (unsplit var %.3f)" %
        (best[0], tbl.names[best[1]], best[2], var(tot)))
  assert best[0] < var(tot)

#-- tree-eg -----------------------------------------------------
"""

`landscape` spends the label budget; `tree` then recurses
min-cost cuts over just those labelled rows, and `show`
prints it -- win (100=best, 0=median), n, per-goal means,
then the branch conditions:

       win     n      Lbs-     Acc+     Mpg+
         3    44  2520.545   16.609   28.182
        41    21  2017.762   16.914   31.905  Volume <= 108
    ▲   83     3  1924.000   20.333   30.000  |  Model <= 73

Notice: ~44 labels, and the ▲ best leaf reads as advice --
small engine, early model.

| call | returns | what |
|------|---------|------|
| `tree(tbl, rows)` | node | recurse min-cost cuts |
| `leaf(tbl, t, row)` | value | route row to its leaf |
"""

def test_tree():
  "Build a tree over landscape's rows and print it."
  random.seed(the.seed)
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  show(tbl, tree(tbl, landscape(tbl)))

#-- show-eg -----------------------------------------------------
"""

`show` renders any tree: win, n, per-goal means, branch
conditions, best leaf marked ▲ and worst ▼. Same budget,
two teachers: a tree trained on random rows vs one trained
on landscape's rows.

| call | returns | what |
|------|---------|------|
| `show(tbl, t)` | -- | win, n, means, branches |
"""

def test_trees():
  "Same budget: random-trained vs landscape-trained tree."
  random.seed(the.seed)
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  land = landscape(tbl)
  rand = some(tbl.rows, len(land))
  W = wins(tbl)
  for tag, rows in [("random", rand), ("landscape", land)]:
    best = min(rows, key=lambda r: disty(tbl,r))
    print("\n== %s  n=%d  best disty=%.3f  win=%.1f ==" %
          (tag, len(rows), disty(tbl,best), W(best)))
    show(tbl, tree(tbl, rows))

#-- main-eg -----------------------------------------------------
"""

Split the table 50:50; landscape-label the train half; grow
a tree from those labels; let it rank the *unseen* test
half; label only the top `check` rows and keep the best.
Notice the win: a few dozen labels find a near-best car
among cars never seen in training.

| call | returns | what |
|------|---------|------|
| `holdout(tbl)` | row | best check from unseen half |
| `wins(tbl)` | fn | grader: row -> [-100, 100] |
"""

def test_holdout():
  "One run: the holdout-picked best row's disty and win."
  random.seed(the.seed)
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  b = holdout(tbl)
  print("best disty %.3f  win %.1f  (%s)" % (disty(tbl,b),
        wins(tbl)(b), the.file.split("/")[-1]))
  assert -100 <= wins(tbl)(b) <= 100

"""

Demos convince; studies measure -- 20 repeats each, wins
scale, `same` deciding ties. holdouts: active vs random
through the full rig. pure: no tree, just the best
labelled row.

| call | returns | what |
|------|---------|------|
| `vs(tbl, pick)` | -- | active-vs-random verdict line |
"""

def vs(tbl, pick):
  "active vs random over 20 runs of pick(); verdict line."
  W, out = wins(tbl), {}
  for mode in ("active", "random"):
    the.landscape = mode; out[mode] = []
    for i in range(20):
      random.seed(the.seed + i); out[mode] += [W(pick(tbl))]
  the.landscape = "active"
  L, R = out["active"], out["random"]
  ml, mr = sum(L)/20, sum(R)/20
  v = "tie" if same(L, R) else ("land" if ml > mr else "rand")
  print("%6.1f %6.1f %-5s %s" % (ml, mr, v,
        the.file.split("/")[-1]))

def test_holdouts():
  "active vs random landscape, through the holdout pipeline."
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  vs(tbl, holdout)

def test_pure():
  "active vs random landscape; best labelled row, no tree."
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  vs(tbl, lambda d: landscape(d)[0])

"""
## Runner

`test_all` walks this file's globals in definition order,
reseeding before each, so the tutorial runs top to bottom.
"""

def test_all():
  "Run every other test_*, reseting the seed before each."
  for n,f in list(globals().items()):
    if n.startswith("test_") and n != "test_all":
      print("\n#", n, "-"*40)
      try: random.seed(the.seed); f()
      except Exception as e:
        print("FAIL:", n, type(e).__name__, e)

if __name__ == "__main__": main(globals())
