# Tables. `Data` = o(names, cols, x, y, rows, ...). `roles`
# types columns from header suffixes; `add` folds one row in
# (inc=-1 removes; `mids` caches the centroid); `clone`
# reuses a header; `adds` folds any stream.

# Build a table; first row = column names
def Data(src):
  src  = iter(src)
  data = o(names=next(src), cols={}, x=[], y=[], goal={},
           klass=None, protect=[], rows=[], mid=None)
  return adds(src, roles(data))

# Fresh Data over a subset of rows
def clone(data, rows):
  return Data([data.names] + rows)

# Cached centroid: per-column mid, rebuilt after add/remove
def mids(data):
  data.mid = data.mid or [mid(col) for col in data.cols.values()]
  return data.mid

# Tag cols x/y/klass/protect from name suffixes
def roles(data):
  for at, s in enumerate(data.names):
    data.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if s[-1] in "+-!":
      data.y += [at]; data.goal[at] = s[-1] == "+"
      if s[-1] == "!": data.klass = at
    else:
      data.x += [at]
      if s[-1] == "~": data.protect += [at]
  return data

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
