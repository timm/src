"""
## Explaining: one bin

Why are the good rows good? `bins` offers candidate splits
per x-column; the cheapest (size-weighted variance of the
two halves) wins. The assert: the best bin beats the
unsplit spread, else explanation would be hopeless.

| call | returns | what |
|------|---------|------|
| `bins(tbl,rows,at,Y)` | iter | (cost, at, v) candidates |
"""

def test_bins():
  "Best single bin beats the unsplit spread."
  tbl = Tbl(csv(the.file))
  Y    = lambda r: disty(tbl, r)
  best = min(c for at in tbl.x
             for c in bins(tbl, tbl.rows, at, Y))
  tot  = adds(map(Y, tbl.rows))
  print("best cost %.3f at %s v %s  (unsplit var %.3f)" %
        (best[0], tbl.names[best[1]], best[2], var(tot)))
  assert best[0] < var(tot)
