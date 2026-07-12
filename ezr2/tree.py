# Trees. `tree` recurses the min-cost cut while rows and
# depth allow; leaves keep their rows and a `mid`
# prediction. `has` picks a row's side of a cut (? = yes);
# `leaf` routes a row down; `leaves` yields them all.

# Does row fall on the yes-side of a cut? (? = yes)
def has(row, col, at, v):
  w = row[at]
  return w == "?" or (v == w if is_sym(col) else w <= v)

# Recursively split rows on the min-cost cut; accum=Num|Sym
def tree(data, rows, Y=None, accum=Num, lvl=0):
  Y = Y or (lambda r: disty(data, r))
  t = o(at=None, mid=mid(adds((Y(r) for r in rows), accum())),
        n=len(rows), rows=rows)
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if cut := min((c for at in data.x
        for c in cuts(data,rows,at,Y,accum)), default=0):
      _, at, v = cut
      col = data.cols[at]
      yes, no = [], []
      for r in rows: (yes if has(r,col,at,v) else no).append(r)
      if yes and no:
        t.at, t.v = at, v
        t.yes = tree(data, yes, Y, accum, lvl+1)
        t.no  = tree(data, no,  Y, accum, lvl+1)
  return t

# Walk a row down to its leaf; return the leaf's mid
def leaf(data, t, row):
  while t.at is not None:
    t = t.yes if has(row,data.cols[t.at],t.at,t.v) else t.no
  return t.mid

# Yield every leaf node of a tree
def leaves(t):
  if t.at is None: yield t
  else: yield from leaves(t.yes); yield from leaves(t.no)
