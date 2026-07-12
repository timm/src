"""
## Column summaries

Two summaries, one interface. `Num` folds values one at a
time by Welford's trick (no list kept, just n, mu, m2);
`Sym` counts. `mid`/`var` answer for either. First a Sym
tiny enough to check by eye; then 10,000 Irwin-Hall samples
(three uniforms, centered, scaled): mean lands on 0, sd on
1 -- testing `add`, `welford`, `mid` and `var` in one shot.

| call | returns | what |
|------|---------|------|
| `add(col, v)` | col | fold v in (Num or Sym) |
| `mid(col)` | value | mean or mode |
| `var(col)` | float | sd or entropy |
"""

def test_cols():
  "Sym mode+entropy on a known bag; Num mu,sd via Irwin-Hall."
  s = adds("aaaabbc", Sym())
  print("sym mid %s ent %.3f" % (mid(s), var(s)))
  assert mid(s) == "a" and abs(var(s) - 1.379) < 0.01
  random.seed(the.seed)
  r = random.random
  n = adds(((r()+r()+r()-1.5)/0.5 for _ in range(10000)))
  print("num mu %.3f sd %.3f" % (mid(n), var(n)))
  assert abs(mid(n)) < 0.05 and abs(var(n) - 1) < 0.05
