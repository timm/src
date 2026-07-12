# Acquire labels. The active learner. `project` maps rows
# onto the line joining two far labelled poles; `acquire`
# labels a few, culls the third nearest the bad pole,
# repeats -- spending at most budget-check labels, returned
# best first.

# Row -> position on the line east-west (x=dist, y=goal);
# poles default to the two far rows, else the given anchors
def project(rows, x, y, east=None, west=None):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = east or far(rows[0])
  west = west or far(east)
  if y(east) > y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def acquire(tbl):
  y   = lambda r: disty(tbl, r)
  x   = lambda r1, r2: distx(tbl, r1, r2)
  cap = the.budget - the.check
  if the.acquire == "random":
    return sorted(some(tbl.rows, cap), key=y)
  return sorted(sway3(shuffle(tbl.rows), y, x, cap), key=y)

def sway3(rows, y, x, cap, lab=None, east=None, west=None):
  b4  = rows[:]
  lab = lab or {}
  while len(rows) >= 2*the.leaf:
    more = min(the.more, cap - len(lab))
    less = int(max(1, the.keepf * len(rows)))
    new  = []
    for r in rows:
      if   id(r) in lab         : new += [r]
      elif (more := more-1) >= 0: new += [r]; lab[id(r)]=r
    if len(lab) >= cap: return lab.values()  # budget spent
    rows = sorted(rows,
                  key=project(new, x, y, east, west))[:less]
  if len(lab) < len(b4):                     # redo: reshuffle,
    seen = sorted(lab.values(), key=y)       # anchored at the
    return sway3(shuffle(b4), y, x, cap,
                 lab, seen[0], seen[-1])     # best+worst seen
  return lab.values()
