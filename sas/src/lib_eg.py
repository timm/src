#!/usr/bin/env python3 -B
"""
lib_eg.py: tutorial and tests for lib.py (the substrate).

Run any test by its bare name; --key=val overrides a knob:
  python3 src/lib_eg.py cols
  python3 src/lib_eg.py dist --p=1
  python3 src/lib_eg.py all

Every sample shown in the book is pasted from a real run
of this file, never hand-typed.
"""
from lib import *

def test_the(): # print settings, after cli overrides
  print(the)
  assert the.p >= 1

def test_thing(): # string coercion round-trip
  got = [thing(s) for s in
         ["23", "3.14", "-1e2", "True", "False", "?", "ab"]]
  print(got)
  assert got == [23, 3.14, -100.0, True, False, "?", "ab"]

def test_rand(): # seeded shuffle repeats; some honors k
  random.seed(1); a = shuffle(list(range(20)))
  random.seed(1); b = shuffle(list(range(20)))
  print(a[:8])
  assert a == b
  assert len(some(a, 5)) == 5
  assert len(some(a, 999)) == 20

def test_idioms(): # sort by computed key; zip transpose
  rows = [[1, 10], [3, 30], [2, 20]]
  print(sorted(rows, key=lambda r: -r[1]))
  print(list(zip(*rows)))
  assert list(zip(*rows))[1] == (10, 30, 20)

def test_cols(): # sym mode+entropy; num mu,sd via gauss
  s = adds("aaaabbc", Sym())
  print("sym mid %s ent %.3f" % (mid(s), div(s)))
  assert mid(s) == "a" and abs(div(s) - 1.379) < 0.01
  random.seed(the.seed)
  n = adds(random.gauss(0, 1) for _ in range(10000))
  print("num mu %.3f sd %.3f" % (mid(n), div(n)))
  assert abs(mid(n)) < 0.05 and abs(div(n) - 1) < 0.05

def test_tbl(): # column roles and goal stats
  tbl = Tbl(csv(the.file))
  print("rows %s |x| %s |y| %s" % (len(tbl.rows),
        len(tbl.cols.x), len(tbl.cols.y)))
  if "auto93" in the.file:
    assert len(tbl.rows) == 398
    assert len(tbl.cols.x) == 4 and len(tbl.cols.y) == 3
    mpg = tbl.cols.y[-1]
    print("%s mu %.2f sd %.2f" %
          (mpg.name, mid(mpg), div(mpg)))
    assert abs(mid(mpg) - 23.84) < 0.5
    assert abs(div(mpg) - 8.34) < 0.5

def test_dist(): # disty sort: top 5, blank, bottom 5
  tbl  = Tbl(csv(the.file))
  rows = sorted(tbl.rows, key=lambda r: disty(tbl, r))
  hdr  = list(tbl.cols.names) + ["disty"]
  fmt  = lambda r: [str(v) for v in r] + \
                   ["%.3f" % disty(tbl, r)]
  body = [fmt(r) for r in rows[:5] + rows[-5:]]
  w    = [max(len(row[c]) for row in [hdr] + body)
          for c in range(len(hdr))]
  line = lambda cs: print("  ".join(c.rjust(w[i])
                          for i, c in enumerate(cs)))
  line(hdr)
  for r in body[:5]: line(r)
  print()
  for r in body[5:]: line(r)
  assert disty(tbl, rows[0]) <= disty(tbl, rows[-1])

def test_halve(): # split rows; summarize halves on demand
  tbl = Tbl(csv(the.file))
  a, b, west, east = halve(tbl)
  goal = tbl.cols.y[-1]
  w, e = clone(tbl, west), clone(tbl, east)
  print("poles apart %.3f" % distx(tbl, a, b))
  print("west %s east %s rows" % (len(west), len(east)))
  print("%s mu: west %.1f east %.1f" %
        (goal.name, mid(w.cols.all[goal.at]),
         mid(e.cols.all[goal.at])))
  assert len(west) + len(east) == len(tbl.rows)
  assert abs(len(west) - len(east)) <= 1
  assert distx(tbl, a, b) > 0

def test_node(): # tree: small leaves, no rows lost
  tbl = Tbl(csv(the.file))
  t = Node(tbl)
  def leaves(n):
    if not n.west: return [n]
    return leaves(n.west) + leaves(n.east)
  ls = leaves(t)
  print("leaves %s sizes %s" % (len(ls),
        sorted(len(l.here.rows) for l in ls)))
  assert sum(len(l.here.rows) for l in ls) == len(tbl.rows)
  assert all(len(l.here.rows) < 2*the.stop for l in ls)

def test_leaf(): # walker drops rows into sane groups
  tbl = Tbl(csv(the.file))
  t = Node(tbl)
  rows = sorted(tbl.rows, key=lambda r: disty(tbl, r))
  best, worst = leaf(t, rows[0]), leaf(t, rows[-1])
  m = lambda n: mid(n.here.cols.y[-1])
  print("%s mu: best leaf %.1f worst leaf %.1f" %
        (tbl.cols.y[-1].name, m(best), m(worst)))
  assert not best.west and not worst.west
  if "auto93" in the.file:
    assert m(best) > m(worst)

def test_stats(): # small shift = same, big = different
  random.seed(the.seed)
  a = sorted(random.gauss(0, 1) for _ in range(20))
  shift = lambda d: [x + d for x in a]
  print("shift  same   cohen  ks    cliffs")
  for d in (0, 0.1, 0.3, 0.5, 1.0, 2.0):
    b = shift(d)
    print(" %+.1f  %-5s  %5.2f %5.2f  %5.2f" % (d,
          same(a, b), cohen(a, b), ks(a, b), cliffs(a, b)))
  assert same(a, a) and not same(a, shift(2))

def test_top(): # winner set = best plus its peers
  random.seed(the.seed)
  g = lambda mu: [random.gauss(mu, 1) for _ in range(20)]
  d = dict(slow=g(2), fast=g(0), ok=g(0.1), bad=g(3))
  print(top(d), top(d, max=True))
  assert sorted(top(d)) == ["fast", "ok"]
  assert top(d, max=True) == ["bad"]

def test_all(): # run every test_*, reseeding each
  bad = 0
  for name, fn in list(globals().items()):
    if name.startswith("test_") and name != "test_all":
      print("\n#", name, "-" * 40)
      try:
        random.seed(the.seed); fn()
      except Exception as e:
        bad += 1
        print("FAIL:", name, type(e).__name__, e)
  print("\n%s failure(s)" % bad)
  assert bad == 0

if __name__ == "__main__": main(globals())
