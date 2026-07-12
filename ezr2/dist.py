# Distances. `norm` squashes a num to 0..1 by a logistic
# z-score. `disty` = distance to the ideal goals over y
# (0 = best); `gap` scores one column pair for `distx`,
# distance over x. `labelled` is the live-model hook
# (see dtlz.py).

# Map v to 0..1 via a logistic on its z-score
def norm(num, v):
  if v == "?": return v
  z = (v - mu_(num)) / (sd(num) + 1e-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

# Aggregate per-item distances via the p-norm
def minkowski(vals, p=2):
  tot = nn = 0
  for v in vals: tot += v**p; nn += 1
  return (tot / (nn or 1)) ** (1/p)

# Distance 0..1 between two values of one column
def gap(col, u, v):
  if u == v == "?": return 1
  if is_sym(col): return u != v
  u, v = norm(col, u), norm(col, v)
  if u == "?": u = 1 if v < .5 else 0
  if v == "?": v = 1 if u < .5 else 0
  return abs(u - v)

# Hook: label a row on demand (see dtlz.py)
def labelled(row): return row

# Row's distance to the best goals (0 = ideal)
def disty(data, row, **kw):
  row = labelled(row)
  return minkowski(
    (abs(norm(data.cols[at], row[at]) - data.goal[at])
     for at in data.y if row[at] != "?"), **kw)

# Distance between two rows over the x-columns
def distx(data, r1, r2, **kw):
  return minkowski((gap(data.cols[at], r1[at], r2[at])
                    for at in data.x), **kw)
