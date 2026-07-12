# Bins. `bins` yields candidate (cost,at,v) splits for one
# column; `score` = size-weighted var of the two halves (the
# far half computed by `mix`, not a second pass); sides must
# hold at least the.leaf rows. accum=Num|Sym flips the same
# code between regression and classification.

# Rows in a summary, either flavor
def size(c): return sum(c.values()) if is_sym(c) else n_(c)

# Split cost (lower=better): size-weighted mean of var
def score(here, there):
  a, b = size(here), size(there)
  return (var(here)*a + var(there)*b) / (a + b + 1e-32)

# Yield (cost,at,v) bins; sides >= the.leaf; accum=Num|Sym
def bins(tbl,rows,at,Y,accum=Num):
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), accum())
  bin = lambda here,k: (score(here, mix(tot,here,-1)), at,k)
  big = lambda lo: the.leaf <= lo <= n-the.leaf
  if is_sym(tbl.cols[at]):
    for k in {x for x,_ in xy}:
      ys = [y for x,y in xy if x==k]
      if big(len(ys)): yield bin(adds(ys, accum()), k)
  else:
    xy.sort(); me=accum()
    for j,(x,y) in enumerate(xy):
      me = add(me, y)
      if j+1 < n and x != xy[j+1][0] and big(j+1):
        yield bin(me, x)
