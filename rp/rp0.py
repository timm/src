#!/usr/bin/env python3
"""rp0.py: step one of grid-from-table — incremental eps-cover.

Unsupervised leader clustering: warm up on the first the.warm rows
(sample pairs among them; eps = close * sd of those distances),
then stream every row: farther than eps from every delegate ->
found a new delegate; else fuse into the nearest delegate's kin.
No labels anywhere; the label bill, paid later, is one per
delegate. Demos: python3 rp0.py [--k v]."""
import sys
from m import (M, csv, the, TINY, Num, add, sd, dist,
               any1, anys, srand, cli, tests)

the.warm = 30

def eps0(m, rows):
  "eps = close * MEAN pair distance among the warm-up rows"
  few, dn = anys(rows, min(the.warm, len(rows))), Num()  # random,
  for _ in range(the.some):     # not first-N: sorted csvs make
    dn = add(dn, dist(m.N, any1(few), any1(few), m.x))  # file-order
  return the.close * dn[1]      # neighbours twins; mu is scale

def cover(m,    eps=None):
  "stream rows; novel -> new delegate, else fuse into nearest kin"
  rows = anys(range(len(m.rows)), len(m.rows))
  eps  = eps or eps0(m, rows)
  D, kin = [], {}
  for i in rows:
    d, at = min(((dist(m.N, i, j, m.x), j) for j in D),
                default=(2, None))
    if d > eps: D += [i]; kin[i] = [i]
    else:       kin[at] += [i]
  return D, kin, eps

#------------------------------------------------------------- demos ---------
def test_cover():
  m = M(csv(the.file))
  D, kin, eps = cover(m)
  n = sum(len(v) for v in kin.values())
  print(f"  eps {eps:.3f}; rows {len(m.rows)} -> {len(D)} "
        f"delegates; kin conserve {n} rows")
  assert n == len(m.rows) and 1 <= len(D) < len(m.rows)

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
