"""
## Reading trees

`show` renders any tree: win, n, per-goal means, branch
conditions, best leaf marked ▲ and worst ▼. Same budget,
two teachers: a tree trained on random rows vs one trained
on landscape's rows.

| call | returns | what |
|------|---------|------|
| `show(data, t)` | -- | win, n, means, branches |
"""

def test_trees():
  "Same budget: random-trained vs landscape-trained tree."
  random.seed(the.seed)
  data = Data(csv(the.file))
  data.rows = some(data.rows, the.cap)
  land = landscape(data)
  rand = some(data.rows, len(land))
  W = wins(data)
  for tag, rows in [("random", rand), ("landscape", land)]:
    best = min(rows, key=lambda r: disty(data,r))
    print("\n== %s  n=%d  best disty=%.3f  win=%.1f ==" %
          (tag, len(rows), disty(data,best), W(best)))
    show(data, tree(data, rows))
