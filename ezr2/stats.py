# Stats. `cliffs`+`ks`+`cohen` feed `same`, a conservative
# equality: all three must agree before two result sets are
# called equal. `wins` grades rows: 100 = best, 0 = median,
# clamped to [-100,100].

# Cliff's delta effect size in 0..1 (0 = identical)
def cliffs(xs, ys):
  ys = sorted(ys); m = len(ys)
  gt = sum(bisect_left(ys, x)      for x in xs)
  lt = sum(m - bisect_right(ys, x) for x in xs)
  return abs(gt - lt) / (len(xs) * m + 1e-32)

# Kolmogorov-Smirnov: max gap between the two CDFs
def ks(xs, ys):
  xs, ys = sorted(xs), sorted(ys); n, m = len(xs), len(ys)
  gap = lambda v: abs(bisect_right(xs,v)/n
                      - bisect_right(ys,v)/m)
  return max(map(gap, xs + ys))

# Small effect: |mean gap| < eps * pooled stdev
def cohen(xs, ys, eps=0.35):
  x, y = adds(xs), adds(ys); n, m = n_(x), n_(y)
  pooled = (((n-1)*sd(x)**2 + (m-1)*sd(y)**2)/(n+m-2))**.5
  return abs(mu_(x) - mu_(y)) <= eps * (pooled + TINY)

# True if xs,ys are statistically indistinguishable
def same(xs, ys, cliff=0.195, conf=1.36):
  if not cohen(xs, ys): return False
  if cliffs(xs, ys) > cliff: return False
  n, m = len(xs), len(ys)
  return ks(xs, ys) <= conf * ((n + m) / (n * m)) ** 0.5

# Grader: row -> % of gap to best closed, [-100,100]
def wins(tbl, rows=None):
  ys = sorted(disty(tbl,r) for r in rows or tbl.rows)
  lo, b4 = ys[0], ys[len(ys)//2]
  return lambda r: max(-100, min(100,
    100 * (1 - (disty(tbl,r)-lo) / (b4-lo+TINY))))
