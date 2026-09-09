# rulr-eg.py

{% raw %}
```python
#!/usr/bin/env python3 -B
"""
rulr-eg.py: tutorial and tests for rulr (library in rulr.py).

Run any test by its bare name; pass --key=val to override a knob:
  python3 rulr-eg.py grow
  python3 rulr-eg.py all

One -eg file per engine file, loaded below in tutorial order;
prose lives in string blocks; every sample is pasted from a
real run, never hand-typed.
"""
from rulr import *

"""

One question drives rulr: can a single conjunctive rule,
grown greedily and never revisited, find near-best rows?
One table runs through this tutorial: auto93 (via $MOOT),
398 cars, goals minimize Lbs-, maximize Acc+ and Mpg+.
"""

#-- data-eg -----------------------------------------------------
"""

`Tbl` reads the header: uppercase first letter = numeric,
trailing +/- = goal (1=maximize, 0=minimize), trailing X =
ignored, the rest are x columns. Numerics track lo/hi so
`norm` squashes to 0..1 and `disty` scores each row by its
distance to the ideal goal point (0 = best).

| call | returns | what |
|------|---------|------|
| `Tbl(src)` | o | rows, x, y, num, lo, hi |
| `norm(t,at,v)` | 0..1 | min-max squash one numeric |
| `disty(t,row)` | 0..1 | distance to best goals |
"""

def test_tbl():
  "auto93 shape: 398 rows, 3 goals, origin is symbolic."
  t = Tbl(csv(the.file))
  print(len(t.rows), [t.names[a] for a in t.y], t.x)
  assert len(t.rows) == 398 and len(t.y) == 3
  assert all(t.names[a][-1] in "+-" for a in t.y)
  assert any(at not in t.num for at in t.x)  # origin

def test_disty():
  "Sorting by disty puts light thrifty cars first."
  t  = Tbl(csv(the.file))
  rs = sorted(t.rows, key=lambda r: disty(t, r))
  print(rs[0], "%.3f" % disty(t, rs[0]))
  print(rs[-1], "%.3f" % disty(t, rs[-1]))
  assert disty(t, rs[0]) < .2 < .8 < disty(t, rs[-1])

#-- cuts-eg -----------------------------------------------------
"""

Rows tagged best or rest make a Sym (a dict of counts).
`bins` scans one column for the (cost,at,v) split
minimizing size-weighted entropy of the tags -- the far
side is `mix(tot, here, -1)`, total minus here, never a
second pass. `cut` takes the min over all x columns and
picks the keep side: whichever holds the higher fraction
of best.

| call | returns | what |
|------|---------|------|
| `ent(d)` | bits | disorder of a count dict |
| `mix(i,j,inc)` | Sym | merge counts; inc=-1 subtracts |
| `bins(t,rows,at,Y)` | iter | (cost,at,v) splits, one col |
| `cut(t,rows,Y)` | (at,v,keep) | min-cost split, all cols |
| `match(t,row,c)` | bool | row satisfies cut? (? = yes) |
"""

def test_entropy():
  "Fifty-fifty counts = 1 bit; without trick = recount."
  print(ent({"a": 1, "b": 1}))
  assert ent({"a": 1, "b": 1}) == 1
  assert mix({"b": 3, "r": 2}, {"b": 1}, -1) == {"b": 2, "r": 2}

def test_cut():
  "Best first cut: keep side has better mean disty."
  t    = Tbl(csv(the.file))
  rows = sorted(t.rows, key=lambda r: disty(t, r))
  n    = int(len(rows)**.5)
  tag  = {id(r): "best" if i < n else "rest"
          for i, r in enumerate(rows)}
  c    = cut(t, rows, lambda r: tag[id(r)])
  yes  = [disty(t, r) for r in rows if match(t, r, c)]
  no   = [disty(t, r) for r in rows if not match(t, r, c)]
  print(show(t, c), len(yes), len(no))
  assert sum(yes)/len(yes) < sum(no)/len(no)

#-- grow-eg -----------------------------------------------------
"""

`grow` is the whole learner: sort rows by disty, tag the
top sqrt(n) best, cut, keep the best side, recurse. The
rule is the cuts seen on the way down; rows matching every
cut sit far from the population mean.

| call | returns | what |
|------|---------|------|
| `grow(t,rows)` | [cuts] | greedy rule, best side only |
| `show(t,c)` | str | one cut as text |
"""

def test_grow():
  "Rule's matching rows beat the population mean disty."
  t    = Tbl(csv(the.file))
  rule = grow(t, t.rows)
  for c in rule: print(show(t, c))
  got = [r for r in t.rows
         if all(match(t, r, c) for c in rule)]
  mu  = lambda rs: sum(disty(t, r) for r in rs)/len(rs)
  print("matched %d  mu %.3f  vs all %.3f"
        % (len(got), mu(got), mu(t.rows)))
  assert len(rule) >= 1 and mu(got) < mu(t.rows)

#-- main-eg -----------------------------------------------------
"""

The honest test: grow on one half, apply to the unseen
half. Test rows sort by how many cuts they match; buy the
top `check`; the best of those should beat the median.

| call | returns | what |
|------|---------|------|
| `holdout(t)` | rule, row, test | 50:50 rig, best buy |
"""

def test_holdout():
  "Rule's test pick beats the median test row."
  t = Tbl(csv(the.file))
  _, got, test = holdout(t)
  ys = sorted(disty(t, r) for r in test)
  print("got %.*f  best %.*f  median %.*f" % (
    the.round, disty(t, got), the.round, ys[0],
    the.round, ys[len(ys)//2]))
  assert disty(t, got) <= ys[len(ys)//2]
```

## Runner

`test_all` walks this file's globals in definition order,
reseeding before each, so the tutorial runs top to bottom.

```python
def test_all():
  "Run every other test_*, reseting the seed before each."
  for n, f in list(globals().items()):
    if n.startswith("test_") and n != "test_all":
      print("\n#", n, "-"*40)
      try: random.seed(the.seed); f()
      except Exception as e:
        print("FAIL:", n, type(e).__name__, e)

if __name__ == "__main__": main(globals())
```

{% endraw %}