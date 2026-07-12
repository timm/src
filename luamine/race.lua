-- Race. Oracles and Pareto predicates for the optimizers,
-- plus the harness: `track` drives one stepper, snapping
-- kids to their nearest real row and logging each new
-- global best; `race` merges logs; `report` prints the
-- best-trace table.
local a, m, l, the = ...

local huge = math.huge

-- score row by disty of nearest labeled row
function a.oracle(data,    ref)
  ref = data.rows
  return function(r)
    return m.disty(data.cols,
      m.near(data.cols, r, ref, the.p)[1], the.p) end end

-- predicate: direct Zitzler compare (ignores ref)
function a.betters(data)
  return function(x,y,_) return m.better(data,x,y) end end

-- predicate: snap a,b to nearest in ref, compare
function a.knn(data)
  return function(x,y,ref)
    return m.better(data,
      m.near(data.cols,x,ref,the.p)[1],
      m.near(data.cols,y,ref,the.p)[1]) end end

-- drive stepper; snap kids to nearest real row;
-- log each new global best as {who,eval,gen,disty,nbr}
function a.track(name, step, cols, rows,
                 bob,bd,lob,h,mark,nbr,d)
  bob, bd, lob, h, mark = nil, huge, {}, 0, 0
  for gen,kids in step do
    for _,kid in ipairs(kids) do
      h = h + 1
      if h-mark >= the.dot then mark=h; l.say(name:sub(1,1)) end
      nbr = m.near(cols, kid, rows, the.p)[1]
      d   = m.disty(cols, nbr, the.p)
      if d < bd then
        bd, bob = d, nbr
        lob[1+#lob] = {who=name, eval=h, gen=gen,
                       disty=d, nbr=nbr} end end end
  l.say("\n")
  return bob, lob end

-- run optimizers; merge logs to global-best timeline
function a.race(data, opts,    all, lob, bd)
  all = {}
  for _,o in ipairs(opts) do
    local _, lb = a.track(o[1], o[2], data.cols, data.rows)
    for _,e in ipairs(lb) do all[1+#all] = e end end
  all = l.keysort(all, function(e) return e.eval end)
  lob, bd = {}, huge
  for _,e in ipairs(all) do
    if e.disty < bd then bd = e.disty; lob[1+#lob] = e end end
  return lob end

-- print race table: who/eval/gen/disty + y goals
function a.report(data, lob,    ys,rows,row,dists,mu)
  ys   = data.cols.y
  rows = {{"who","eval","gen","disty"}}
  for _,c in ipairs(ys) do rows[1][1+#rows[1]] = c.txt end
  mu = {}; for _,c in ipairs(ys) do mu[c.at] = c.mu end
  row = {"average","-","-",l.o(m.disty(data.cols,mu,the.p))}
  for _,c in ipairs(ys) do row[1+#row] = l.o(c.mu) end
  rows[1+#rows] = row
  dists = {}
  for _,e in ipairs(lob) do
    dists[1+#dists] = e.disty
    row = {e.who, e.eval, l.o(e.gen), l.o(e.disty)}
    for _,c in ipairs(ys) do row[1+#row] = l.o(e.nbr[c.at]) end
    rows[1+#rows] = row end
  l.tabulate(rows, {"<"}, "  ")
  return dists end
