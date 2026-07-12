"""
## When do two results differ?

A tool needed before any experiment: `same` calls two lists
equal only if cohen AND cliffs AND ks all agree. Watch it
on a gaussian nudged by ever-larger shifts: same up to 0.1,
different from 0.3 on. Notice how conservative that is --
later "X beats Y" claims must clear all three tests.

| call | returns | what |
|------|---------|------|
| `same(xs, ys)` | bool | cohen+cliffs+ks all agree |
| `cliffs(xs, ys)` | 0..1 | effect size (0 = identical) |
"""

def test_same():
  "Validate same(): small shift = same, big shift = differ."
  random.seed(the.seed)
  a = [random.gauss(0, 1) for _ in range(20)]
  shift = lambda d: [x + d for x in a]
  print("shift  same   cliffs cohen")
  for d in (0, 0.1, 0.3, 0.5, 1.0, 2.0):
    b = shift(d)
    print(" %+.1f  %-5s  %.2f   %s" % (d, same(a,b),
          cliffs(a,b), cohen(a,b)))
  assert same(a, a) and not same(a, shift(2))
