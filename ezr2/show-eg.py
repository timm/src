"""
## Reading trees

`show` renders any tree: win, n, per-goal means, branch
conditions, best leaf marked ▲ and worst ▼. Same budget,
two teachers: a tree trained on random rows vs one trained
on acquire's rows.

| call | returns | what |
|------|---------|------|
| `show(tbl, t)` | -- | win, n, means, branches |
"""

def test_trees():
  "Same budget: random-trained vs acquire-trained tree."
  random.seed(the.seed)
  tbl = Tbl(csv(the.file))
  tbl.rows = some(tbl.rows, the.cap)
  land = acquire(tbl)
  rand = some(tbl.rows, len(land))
  W = wins(tbl)
  for tag, rows in [("random", rand), ("acquire", land)]:
    best = min(rows, key=lambda r: disty(tbl,r))
    print("\n== %s  n=%d  best disty=%.3f  win=%.1f ==" %
          (tag, len(rows), disty(tbl,best), W(best)))
    show(tbl, tree(tbl, rows))
