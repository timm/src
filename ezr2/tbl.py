# Tables. `Tbl` = o(names, cols, x, y, rows, ...). `Cols`
# types columns from header suffixes; `add` folds one row in
# (inc=-1 removes; `mids` caches the centroid); `clone`
# reuses a header; `adds` folds any stream.

# Build a table; first row = column names
def Tbl(src):
  src  = iter(src)
  tbl = o(names=next(src), cols={}, x=[], y=[], goal={},
           klass=None, protect=[], rows=[], mid=None)
  return adds(src, Cols(tbl))

# Fresh Tbl over a subset of rows
def clone(tbl, rows):
  return Tbl([tbl.names] + rows)

# Cached centroid: per-column mid, rebuilt after add/remove
def mids(tbl):
  tbl.mid = tbl.mid or [mid(col) for col in tbl.cols.values()]
  return tbl.mid

# Tag cols x/y/klass/protect from name suffixes
def Cols(tbl):
  for at, s in enumerate(tbl.names):
    tbl.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if s[-1] in "+-!":
      tbl.y += [at]; tbl.goal[at] = s[-1] == "+"
      if s[-1] == "!": tbl.klass = at
    else:
      tbl.x += [at]
      if s[-1] == "~": tbl.protect += [at]
  return tbl

# Fold a stream of values/rows into i (Num by default)
def adds(src, i=None):
  i = Num() if i is None else i  # keep empty Sym; {} is falsy
  for v in src: i = add(i,v)
  return i

# Add one value/row to i (inc=-1 removes)
def add(i,v,inc=1):
  if isinstance(i,o):
    i.mid = None  # invalidate cached centroid
    for at,col in i.cols.items(): i.cols[at] = add(col,v[at],inc)
    (i.rows.append if inc==1 else i.rows.remove)(v)
    return i
  if v=="?": return i
  return (count if is_sym(i) else welford)(i, v, inc=inc)
