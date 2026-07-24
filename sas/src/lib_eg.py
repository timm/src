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

def test_the():
  "Print the settings (after any command-line overrides)."
  print(the)
  assert the.p >= 1

def test_thing():
  "String coercion round-trip."
  got = [thing(s) for s in
         ["23", "3.14", "-1e2", "True", "False", "?", "ab"]]
  print(got)
  assert got == [23, 3.14, -100.0, True, False, "?", "ab"]

def test_rand():
  "Seeded shuffle repeats; some() respects k."
  random.seed(1); a = shuffle(list(range(20)))
  random.seed(1); b = shuffle(list(range(20)))
  print(a[:8])
  assert a == b
  assert len(some(a, 5)) == 5
  assert len(some(a, 999)) == 20

def test_idioms():
  "Sort rows by a computed score; transpose with zip."
  rows = [[1, 10], [3, 30], [2, 20]]
  print(sorted(rows, key=lambda r: -r[1]))
  print(list(zip(*rows)))
  assert list(zip(*rows))[1] == (10, 30, 20)

def test_cols():
  "Sym mode+entropy on a known bag; Num mu,sd via gauss."
  s = adds("aaaabbc", Sym())
  print("sym mid %s ent %.3f" % (mid(s), var(s)))
  assert mid(s) == "a" and abs(var(s) - 1.379) < 0.01
  random.seed(the.seed)
  n = adds(random.gauss(0, 1) for _ in range(10000))
  print("num mu %.3f sd %.3f" % (mid(n), var(n)))
  assert abs(mid(n)) < 0.05 and abs(var(n) - 1) < 0.05

def test_unadd():
  "add() then sub(): summaries forget, exactly."
  random.seed(the.seed)
  vs = [random.gauss(10, 2) for _ in range(100)]
  n  = adds(vs)
  b4 = (mid(n), var(n))
  extra = [add(n, random.gauss(99, 5)) for _ in range(50)]
  for v in extra: sub(n, v)
  print("mu %.3f sd %.3f (before: %.3f %.3f)" %
        (mid(n), var(n), *b4))
  assert abs(mid(n) - b4[0]) < 1e-9
  assert abs(var(n) - b4[1]) < 1e-9

def test_move():
  "add(i, sub(j, v)): values walk from summary j to i."
  random.seed(the.seed)
  a = [random.gauss(5, 1) for _ in range(50)]
  b = [random.gauss(9, 1) for _ in range(50)]
  i, j = adds(a), adds(b)
  for v in b[25:]: add(i, sub(j, v))
  k = adds(a + b[25:])
  print("i: n %s mu %.3f sd %.3f" % (i.n, mid(i), var(i)))
  assert i.n == 75 and j.n == 25
  assert abs(mid(i) - mid(k)) < 1e-9
  assert abs(var(i) - var(k)) < 1e-9

def test_tbl():
  "Tbl build: column roles and goal stats."
  tbl = Tbl(csv(the.file))
  print("rows %s |x| %s |y| %s" % (len(tbl.rows),
        len(tbl.x), len(tbl.y)))
  if "auto93" in the.file:
    assert len(tbl.rows) == 398
    assert len(tbl.x) == 4 and len(tbl.y) == 3
    mpg = tbl.cols[tbl.y[-1]]
    print("%s mu %.2f sd %.2f" %
          (mpg.name, mid(mpg), var(mpg)))
    assert abs(mid(mpg) - 23.84) < 0.5
    assert abs(var(mpg) - 8.34) < 0.5

def test_dist():
  "Rows sorted by disty: header, top 5, blank, bottom 5."
  tbl  = Tbl(csv(the.file))
  rows = sorted(tbl.rows, key=lambda r: disty(tbl, r))
  hdr  = list(tbl.names) + ["disty"]
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

def test_stats():
  "Validate same(): small shift = same, big = different."
  random.seed(the.seed)
  a = [random.gauss(0, 1) for _ in range(20)]
  shift = lambda d: [x + d for x in a]
  print("shift  same   cliffs cohen")
  for d in (0, 0.1, 0.3, 0.5, 1.0, 2.0):
    b = shift(d)
    print(" %+.1f  %-5s  %.2f   %s" % (d, same(a, b),
          cliffs(a, b), cohen(a, b)))
  assert same(a, a) and not same(a, shift(2))

def test_all():
  "Run every other test_*, reseeding before each."
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
