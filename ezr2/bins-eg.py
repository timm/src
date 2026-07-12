"""
## Explaining: one bin

Why are the good rows good? `bins` offers candidate splits
per x-column; the cheapest (size-weighted variance of the
two halves) wins. The assert: the best bin beats the
unsplit spread, else explanation would be hopeless.

| call | returns | what |
|------|---------|------|
| `bins(data,rows,at,Y)` | iter | (cost, at, v) candidates |
"""

def test_bins():
  "Best single bin beats the unsplit spread."
  data = Data(csv(the.file))
  Y    = lambda r: disty(data, r)
  best = min(c for at in data.x
             for c in bins(data, data.rows, at, Y))
  tot  = adds(map(Y, data.rows))
  print("best cost %.3f at %s v %s  (unsplit var %.3f)" %
        (best[0], data.names[best[1]], best[2], var(tot)))
  assert best[0] < var(tot)
