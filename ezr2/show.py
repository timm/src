# Tree show. `show` prints win, n, per-goal means, then
# indented branch conditions (best leaf marked with an up
# triangle, worst down); `branch` recurses best-kid-first;
# `cond` renders one test as text.

# One branch as text, e.g. 'Volume <= 108'
def cond(data, t, yes):
  op = (("==" if yes else "!=") if is_sym(data.cols[t.at])
        else ("<=" if yes else ">"))
  v  = round(t.v, the.round) if type(t.v)==float else t.v
  return "%s %s %s" % (data.names[t.at], op, v)

# Pretty-print a tree: win, n, goal means, then branches
def show(data, t):
  W   = wins(data, t.rows)
  win = lambda rows: int(mu_(adds(map(W, rows))))
  ws  = [win(x.rows) for x in leaves(t)]
  print("%s %4s %5s  %s" % (" ", "win", "n",
    " ".join("%8s" % data.names[a] for a in data.y)))
  branch(data, t, win, min(ws), max(ws))

# One line per node, then recurse (best kid first)
def branch(data, t, win, lo, hi, pad="", edge=""):
  w = win(t.rows)
  m = " " if t.at is not None else (              # mark leaves:
      chr(0x25B2) if w==hi else                   # best=up,
      chr(0x25BC) if w==lo else " ")              # worst=down
  mids = " ".join("%8.*f" % (the.round, mid(adds(r[a]
         for r in t.rows))) for a in data.y)
  print(("%s %4d %5d  %s  %s%s" % (
         m,w,t.n,mids,pad,edge)).rstrip())
  if t.at is not None:
    pad += "|  " if edge else ""
    for kid, yes in sorted([(t.yes,True), (t.no,False)],
                           key=lambda kb: kb[0].mid):
      branch(data, kid, win, lo, hi, pad, cond(data, t, yes))
