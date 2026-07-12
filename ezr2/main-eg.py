"""
## Someplace cool: the whole rig

Split the table 50:50; acquire-label the train half; grow
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
## Studies

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
    the.acquire = mode; out[mode] = []
    for i in range(20):
      random.seed(the.seed + i); out[mode] += [W(pick(tbl))]
  the.acquire = "active"
  L, R = out["active"], out["random"]
  ml, mr = sum(L)/20, sum(R)/20
  v = "tie" if same(L, R) else ("land" if ml > mr else "rand")
  print("%6.1f %6.1f %-5s %s" % (ml, mr, v,
        the.file.split("/")[-1]))

def test_holdouts():
  "active vs random acquire, through the holdout pipeline."
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  vs(tbl, holdout)

def test_pure():
  "active vs random acquire; best labelled row, no tree."
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  vs(tbl, lambda d: acquire(d)[0])
