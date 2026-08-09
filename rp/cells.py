#!/usr/bin/env python3
"""cells.py: repgrid squeeze at CELL granularity (timm 2026-08-08).

Label the.picks random rows (one round: bingo effect — discretized
columns hold few patterns, so 30 rows cover them). Cell values come
from m.py's norm: saturate past the f/1-f percentiles, so outliers
just score 0 or 1. Every scored cell earns three 0..1 terms:
(1-y) of its row, its row's mean Chebyshev gap to the other picks,
its col's mean Chebyshev gap to the other live cols (all gaps over
the picks only — never O(n^2)). Dump the bottom half of scored
cells; a row or col dies on losing more than half its cells. Rows
never picked carry no evidence: they survive by default, but the
emitted grid draws from the evidenced picks.
Demos: python3 cells.py [--k v]."""
import sys
from m import M, csv, the, anys, srand, cli, tests, disty

the.picks = 30

def cheb(V, i, j, live):
  "chebyshev: the one worst gap over live shared cells"
  d = 0
  for c in live:
    a, b = V[i][c], V[j][c]
    if a is not None and b is not None: d = max(d, abs(a - b))
  return d

def cells(m):
  "one round: pick, label, score cells, cull cells then rows/cols"
  S  = anys(range(len(m.rows)), min(the.picks, len(m.rows)))
  C  = m.x[:]
  y  = {i: disty(m, i) for i in S}                # the label bill
  rd = {i: sum(cheb(m.N, i, j, C) for j in S if j != i)
           / (len(S) - 1) for i in S}
  cd = {c: sum(cheb(m.NT, c, b, S) for b in C if b != c)
           / (len(C) - 1) for c in C}
  score = {(i, c): (1 - y[i]) + rd[i] + cd[c] for i in S for c in C}
  cut   = sorted(score.values())[len(score) // 2]
  dead  = {k for k, v in score.items() if v < cut}
  R = [i for i in S if sum((i, c) in dead for c in C) <= len(C) / 2]
  C = [c for c in C if sum((i, c) in dead for i in S) <= len(S) / 2]
  return R, C, S, y, score

def holdout(m, R, C, y, check=5):
  "rank unpicked by nearest labeled y (reduced cols); label top 5"
  guess = lambda r: y[min(R, key=lambda i: cheb(m.N, r, i, C))]
  rest  = [r for r in range(len(m.rows)) if r not in y]
  top   = sorted(rest, key=guess)[:check]
  return sorted(top, key=lambda r: disty(m, r)), top

#------------------------------------------------------------- demos ---------
def test_cells():
  m = M(csv(the.file))
  R, C, S, y, _ = cells(m)
  best = min(y[i] for i in R) if R else 1
  print(f"  picks {len(S)} (=labels); grid {len(R)} x {len(C)}; "
        f"best pick {min(y.values()):.2f}, best survivor {best:.2f}")
  assert len(R) <= len(S) and 1 <= len(C) <= len(m.x)

def test_holdout():
  m = M(csv(the.file))
  R, C, S, y, _ = cells(m)
  best5, top = holdout(m, R, C, y)
  d = disty(m, best5[0])
  print(f"  {len(y)}+{len(top)} labels; best of top-5 d2h {d:.2f}; "
        f"best pick was {min(y.values()):.2f}")
  assert len(best5) == 5

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
