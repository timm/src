# Acquire labels. The active learner. `project` maps rows
# onto the line joining two far labelled poles; `acquire`
# labels a few, culls the third nearest the bad pole,
# repeats -- spending at most budget-check labels, returned
# best first.

# Row -> position on the east-west line (x=dist, y=goal)
def project(rows, x, y):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = far(rows[0]); west = far(east)
  if y(east) < y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

# Label <=budget-check rows, best first; --acquire picks how
def acquire(data):
  y   = lambda r: disty(data, r)
  cap = the.budget - the.check
  if the.acquire == "random":
    return sorted(some(data.rows, cap), key=y)
  x   = lambda r1, r2: distx(data, r1, r2)
  pool, lab = shuffle(data.rows), {}
  known = lambda r: id(r) in lab
  while len(lab) < cap and len(pool) >= 2*the.leaf:
    grow = min(the.grow, cap - len(lab))
    for r in pool:
      if not known(r):
        lab[id(r)] = r
        if (grow := grow-1) < 1: break
    if len(lab) < cap:
      here = [r for r in pool if known(r)]  # labelled & pool
      n    = max(1, int((1-the.keepf)*len(pool)))
      pool = sorted(pool, key=project(here, x, y))[n:]
  return sorted(lab.values(), key=y)
