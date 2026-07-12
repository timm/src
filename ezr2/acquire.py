# Acquire labels. The active learner. `project` maps rows
# onto the line joining two far labelled poles; `acquire`
# labels a few, culls the third nearest the bad pole,
# repeats -- spending at most budget-check labels, returned
# best first.

# Row -> position on the line east-west (x=dist, y=goal);
# poles default to the two far rows, else the given anchors
def project(rows, x, y, east=None, west=None):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = far(rows[0]) if east is None else east
  west = far(east)    if west is None else west
  if y(east) > y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def acquire(data):
  y   = lambda r: disty(data, r)
  cap = the.budget - the.check
  if the.acquire == "random":
    return sorted(some(data.rows, cap), key=y)
  return sorted(sway3(data, shuffle(data.rows), y, cap),
                key=y)

def sway3(data, pool, y, cap, lab=None, east=None, west=None):
  x   = lambda r1, r2: distx(data, r1, r2)
  lab = {} if lab is None else lab
  while len(pool) >= 2*the.leaf:
    more = min(the.more, cap - len(lab))
    less = int(max(1, the.keepf * len(pool)))
    new  = []
    for r in pool:
      if   id(r) in lab         : new += [r]
      elif (more := more-1) >= 0: new += [r]; lab[id(r)]=r
    if len(lab) >= cap: return lab.values()  # budget spent
    pool = sorted(pool,
                  key=project(new, x, y, east, west))[:less]
  if not lab or len(lab) >= len(data.rows):
    return lab.values()                      # nothing left
  seen = sorted(lab.values(), key=y)         # redo: fresh pool,
  return sway3(data, shuffle(data.rows), y, cap,  # anchored at
               lab, seen[0], seen[-1])       # best+worst seen
