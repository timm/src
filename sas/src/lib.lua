#!/usr/bin/env lua
-- lib.lua: lib.py said in Lua, function for function.
-- Cells, columns, tables, distance, and the statistics
-- that police every claim in this book. One file: the
-- about.py knobs live in `the` below. Columns index from
-- 1, not 0; everything else mirrors the Python.
local abs,exp,log,sqrt = math.abs,math.exp,math.log,math.sqrt
local max,min,floor    = math.max,math.min,math.floor
local TINY, slice      = 1e-32, table.unpack or unpack

-- All defs below land in this fresh table (which _G backs for
-- reads), so `function name` both defines and exports: the
-- last line returns _ENV as the module. The local works on
-- Lua 5.2+; the setfenv line is the same trick for 5.1 and
-- LuaJIT (where it is a plain local and setfenv is nil).
local _ENV = setmetatable({}, {__index = _G})
if setfenv then setfenv(1, _ENV) end

the = {
  seed   = 1234567891,     -- every random stream starts here
  p      = 2,              -- minkowski coefficient
  few    = 128,            -- sample size for cheap guesses
  stop   = 32,             -- min rows before a split halts
  round  = 2,              -- decimals printed by show
  leaf   = 3,              -- tree: min rows in one leaf
  maxd   = 4,              -- tree: max depth
  budget = 32,             -- acquire: max labels
  more   = 4,              -- acquire: labels per round
  keepf  = 0.66,           -- acquire: pool kept per cull
  DATA   = "data/",        -- where tables live; $VARS ok
  file   = "auto93.csv" }  -- default table

--## columns ----------------------------------------------------
NUM, SYM, COLS, TBL, NODE, TREE = -- metatables (see new)
  {},{},{},{},{},{}

function Col(name,at) -- column kind from first letter
  return (name:find"^%l" and Sym or Num)(name,at) end

function Num(name,at) -- summary of a numeric column
  name = name or ""
  return new(NUM, {at=at or 1, name=name, n=0, mu=0, m2=0,
                   heaven = name:find"-$" and 0 or 1}) end

function Sym(name,at) -- summary of a symbolic column
  return new(SYM, {at=at or 1, name=name or "", n=0, has={}}) end

function SYM.add(i,v) -- update symbol counts
  if v == "?" then return v end
  i.n = i.n + 1; i.has[v] = 1 + (i.has[v] or 0); return v end

function NUM.add(i,v,    d) -- one-pass update of mu and m2
  if v == "?" then return v end
  i.n  = i.n + 1
  d    = v - i.mu
  i.mu = i.mu + d / i.n
  i.m2 = i.m2 + d * (v - i.mu); return v end

function SYM.mid(i,    hi,out) -- center: the mode
  hi = -1
  for k, n in pairs(i.has) do
    if n > hi then hi, out = n, k end end
  return out end

function NUM.mid(i) return i.mu end -- center: the mean

function SYM.div(i) -- diversity: entropy of the counts
  return sum(i.has, function(n,    p)
    p = n / i.n; return -p * log(p, 2) end) end

function NUM.div(i) -- diversity: standard deviation
  return i.n < 2 and 0 or sqrt(max(i.m2,0) / (i.n-1)) end

function SYM.norm(i,v) return v end -- syms have no cdf

function NUM.norm(i,v,    z) -- v's cdf, via logistic; 0..1
  if v == "?" then return v end
  z = (v - i.mu) / (i.div(i) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z)))) end

function NUM.without(i,j,    n,d) -- i minus j, as new NUM
  n = i.n - j.n
  if n < 1 then return Num(i.name, i.at) end
  d = j.mu - i.mu
  return new(NUM, {name=i.name, at=i.at, heaven=i.heaven,
                   n=n, mu=(i.n*i.mu - j.n*j.mu) / n,
                   m2=max(0, i.m2 - j.m2
                             - d*d*i.n*j.n/n)}) end

function SYM.without(i,j,    out,n) -- i minus j's counts
  out = Sym(i.name, i.at)
  for k,v in pairs(i.has) do
    n = v - (j.has[k] or 0)
    if n > 0 then out.has[k] = n; out.n = out.n + n end end
  return out end

function SYM.holds(i,x,v) return x == "?" or x == v  end
function NUM.holds(i,x,v) return x == "?" or x <= v  end

--## tables -----------------------------------------------------
function Tbl(src,    names,all,x,y) -- row 1 names columns
  src = iter(src)
  names, all, x, y = src(), {}, {}, {}
  for at, s in ipairs(names) do
    all[at] = Col(s, at)
    if s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end end
  return adds(src, new(TBL, {rows={}, mid=nil,
                 cols=new(COLS,
                   {names=names, all=all, x=x, y=y})})) end

function COLS.add(i,row) -- fold a row into every column
  for _, c in ipairs(i.all) do c.add(c, row[c.at]) end
  return row end

function TBL.add(i,row) -- keep the row; update summaries
  i.rows[#i.rows+1] = i.cols.add(i.cols, row)
  i.mid = nil
  return row end

function adds(src,i) -- fold list or iterator; Num default
  i = i or Num()
  for v in iter(src or {}) do i.add(i, v) end
  return i end

function TBL.clone(i,rows) -- same header, fresh summaries
  return adds(rows, Tbl{i.cols.names}) end

function TBL.mids(i) -- return centroid of this tbl
  i.mid = i.mid or map(i.cols.all,function(c) return c.mid(c)end)
  return i.mid end

--## distance ---------------------------------------------------
function SYM.dist(i,a,b) -- gap between two syms; 0..1
  if a == "?" and b == "?" then return 1 end
  return a ~= b and 1 or 0 end

function NUM.dist(i,a,b) -- gap between two nums; 0..1
  if a == "?" and b == "?" then return 1 end
  a, b = i.norm(i,a), i.norm(i,b)
  if a == "?" then a = b > 0.5 and 0 or 1 end
  if b == "?" then b = a > 0.5 and 0 or 1 end
  return abs(a - b) end

function minkowski(cols,f,    d,n) -- p-norm mean of f(col)
  d, n = 0, TINY
  for _, c in ipairs(cols) do n, d = n+1, d + f(c) ^ the.p end
  return (d / n) ^ (1 / the.p) end

function TBL.distx(i,row1,row2) -- gap over x cols; 0..1
  return minkowski(i.cols.x, function(c)
           return c.dist(c, row1[c.at], row2[c.at]) end) end

function TBL.disty(i,row) -- gap to heaven; 0=best
  return minkowski(i.cols.y, function(y)
           return abs(y.norm(y, row[y.at]) - y.heaven) end) end

--## clusters ---------------------------------------------------
function TBL.projx(i,row,a,b,c) -- onto the a-b line
  return (i.distx(i,a,row)^2 + c*c
          - i.distx(i,b,row)^2) / (2*c + TINY) end

function TBL.halve(i,rows,    far,a,b,c,n)
  rows = rows or i.rows     -- split on far poles, best first
  far = function(r) return argmax(some(rows, the.few),
          function(r2) return i.distx(i, r, r2) end) end
  a = far(rows[math.random(#rows)])
  b = far(a)
  c = i.distx(i, a, b)
  if i.disty(i, b) < i.disty(i, a) then a, b = b, a end
  rows = keysort(rows, function(r) return i.projx(i,r,a,b,c) end)
  n = floor(#rows / 2)
  return a, b, {slice(rows, 1, n)}, {slice(rows, n + 1)} end

function Node(tbl,rows,    i,a,b,lo,hi) -- tree of halves
  rows = rows or tbl.rows
  node = new(NODE,{here = tbl.clone(tbl,rows),
                   a=nil, b=nil, lo=nil, hi=nil})
  if #rows >= 2 * the.stop then
    a, b, lo, hi = tbl.halve(tbl, rows)
    node.a, node.b = a, b
    if #lo > 0 and #hi > 0 then
      node.lo, node.hi = Node(tbl,lo), Node(tbl,hi) end end
  return node end

function NODE.leaf(i,row,    t) -- walk row down to its leaf
  while i.lo do
    t = i.here
    i = t.distx(t, row, i.a) <= t.distx(t, row, i.b)
        and i.lo or i.hi end
  return i end

--## acquire ---------------------------------------------------
-- Label few rows, cull the pool toward the good pole, loop.
-- Rows are table refs, so lab doubles as set (lab[row]) and
-- ordered list (lab[1..n]); the labelled members of any
-- culled subset fall out of one lab[r] filter.
function TBL.poles(i,rows,    x,t,lo,hi,c) -- projector on
  x  = function(a,b) return i.distx(i, a, b) end -- the line
  t  = keysort(rows, function(r) return i.disty(i, r) end)
  lo, hi = t[1], t[#t]     -- from the y-best to the y-worst
  c  = x(lo, hi) + TINY    -- (keysort: one disty per row)
  return function(r)
    return (x(lo,r)^2 + c*c - x(hi,r)^2) / (2*c) end end

function TBL.acquire(i,rows,cap,lab,    more,at,r)
  while #rows >= 2*the.leaf and #lab < cap do
    at, more = 0, min(the.more, cap - #lab)
    while more > 0 and at < #rows do     -- advance till they
      at = at + 1                        -- are issued or the
      r  = rows[at]                      -- pool ends
      if not lab[r] then
        more, lab[r] = more - 1, true
        push(lab, r) end end
    rows = {slice(keysort(rows, i.poles(i, lab)),
                  1, max(1, floor(the.keepf * #rows)))} end
  return lab end

function TBL.acquirer(i,cap,    rows,lab) -- seed a few
  rows = shuffle(i.rows)  -- (once: kills file-order bias)
  lab  = {slice(rows, 1, the.more)}
  for _,r in ipairs(lab) do lab[r] = true end
  while #lab < cap and #lab < #rows do
    lab = i.acquire(i, rows, cap, lab) end
  return keysort(lab, function(r) return i.disty(i,r) end) end

--## discretize -------------------------------------------------
-- Find good cuts: places where splitting the x values most
-- purifies some y summary. All candidates feed one `least`
-- reducer; no cut lists are ever built.
function val(a,b) -- mean diversity of two summaries
  return (a.div(a)*a.n + b.div(b)*b.n) / (a.n + b.n + TINY) end

function SYM.cuts(c,xy,tot,acc,best,    d,b) -- one cut per
  d = {}                                       -- key; feed best
  for _,p in ipairs(xy) do
    b = d[p[1]] or acc()
    b.add(b, p[2]); d[p[1]] = b end
  if #keys(d) > 1 then
    for k,b in pairs(d) do
      best{val(b, tot.without(tot,b)), c.at, k} end end end

function NUM.cuts(c,xy,tot,acc,best,    here) -- cuts between
  table.sort(xy, function(a,b) return a[1] < b[1] end)
  here = acc()                   -- each distinct, sorted x
  for j,p in ipairs(xy) do
    here.add(here, p[2])
    if j < #xy and p[1] ~= xy[j+1][1] then
      best{val(here,tot.without(tot,here)),c.at,p[1]} end end end

function TBL.cuts(i,rows,c,Y,acc,best,    xy,tot) -- col c
  xy = {}                        -- feeds its splits to best
  for _,r in ipairs(rows) do
    if r[c.at] ~= "?" then push(xy, {r[c.at], Y(r)}) end end
  tot = adds(map(xy, function(p) return p[2] end), acc())
  c.cuts(c, xy, tot, acc, best) end

function TBL.bestcut(i,rows,Y,acc,best) -- champion x-col cut
  for _,c in ipairs(i.cols.x) do i.cuts(i,rows,c,Y,acc,best) end
  return best() end

function TBL.divide(i,rows,c,v,    yes,no) -- rows into holds
  yes, no = {}, {}                         -- c<=v, or not
  for _,r in ipairs(rows) do
    push(c.holds(c, r[c.at], v) and yes or no, r) end
  return yes, no end

--## trees ------------------------------------------------------
-- Recursive best-cut trees over the discretizer above, plus
-- walk/sides: visit every pruning of a grown tree.
function Tree(tbl,rows,Y,acc,lvl,    ys,t,b,c,yes,no)
  Y   = Y or function(r) return tbl.disty(tbl, r) end
  acc, lvl = acc or Num, lvl or 0
  ys  = adds(map(rows, Y), acc())
  t   = new(TREE, {at=nil, v=nil, n=#rows, mu=ys.mid(ys),
                   leafs=1, ys=ys,
                   goals = map(tbl.cols.y, function(y,    g)
                     g = Col(y.name, y.at)
                     for _,r in ipairs(rows) do
                       g.add(g, r[y.at]) end
                     return g end),
                   here=ys.has and ys.div(ys) or ys.mid(ys)})
  t.val = t.here
  if #rows >= 2*the.leaf and lvl < the.maxd then
    b = tbl.bestcut(tbl, rows, Y, acc, least())
    if b then
      c = tbl.cols.all[b[2]]
      yes, no = tbl.divide(tbl, rows, c, b[3])
      if #yes > 0 and #no > 0 then
        t.at, t.v = b[2], b[3]
        t.yes   = Tree(tbl, yes, Y, acc, lvl+1)
        t.no    = Tree(tbl, no,  Y, acc, lvl+1)
        t.val   = min(t.yes.val, t.no.val)
        t.leafs = t.yes.leafs + t.no.leafs end end end
  return t end

function TREE.leafed(x) -- x, collapsed to one leaf
  return new(TREE, {at=nil, n=x.n, mu=x.mu, here=x.here,
                    val=x.here, leafs=1, ys=x.ys,
                    goals=x.goals}) end

function TREE.walk(t,fun) -- fun on every pruning of tree t
  if t.at == nil then return fun(t) end
  t.yes.sides(t.yes, function(yes)
    t.no.sides(t.no, function(no)
      fun(new(TREE, {at=t.at, v=t.v, n=t.n,
                     yes=yes, no=no,
                     val=min(yes.val, no.val),
                     leafs=yes.leafs + no.leafs})) end) end) end

function TREE.sides(t,fun) -- t as leaf; then t's prunings
  fun(t.leafed(t))
  if t.at ~= nil then t.walk(t, fun) end end

function TREE.leaf(t,tbl,row,    c) -- row's leaf, its guess
  while t.at do
    c = tbl.cols.all[t.at]
    t = c.holds(c, row[t.at], t.v) and t.yes or t.no end
  return t.mu end

--## tree show -------------------------------------------------
-- One row per node: n, d2h, then each goal's mean under its
-- own header column; tree structure trails on the right.
function TREE.leaves(t,fun) -- fun on every leaf below t
  if t.at then t.yes.leaves(t.yes, fun)
               t.no.leaves(t.no, fun)
  else fun(t) end end

function TREE.gstr(t) -- goal means, as aligned columns
  return table.concat(map(t.goals, function(g,    v)
    v = g.mid(g)
    if type(v) == "number" and v % 1 ~= 0 then
      v = ("%."..the.round.."f"):format(v) end
    return ("%9s"):format(v) end)) end

function TREE.show(t,tbl,pre,txt,lo,hi,    c,say,m)
  pre, txt = pre or "", txt or ""    -- print: stats left,
  if not lo then                     -- root: leaf extremes,
    lo, hi = math.huge, -math.huge   -- then a header
    t.leaves(t, function(l)
      lo, hi = min(lo, l.mu), max(hi, l.mu) end)
    print((" %4s %5s"):format("n", "d2h") ..
      table.concat(map(t.goals, function(g)
        return ("%9s"):format(g.name) end))) end
  m = (t.at == nil and t.mu == lo and "*") or  -- best leaf
      (t.at == nil and t.mu == hi and "!") or " " -- worst
  print(("%s%4d %5.2f%s  %s"):format(
    m, t.n, t.mu, t.gstr(t), pre .. txt))
  if t.at then                       -- structure right
    c   = tbl.cols.all[t.at]
    say = function(op)
            return c.name .. op .. tostring(t.v) end
    pre = pre .. (txt == "" and "" or "|  ")
    t.yes.show(t.yes, tbl, pre,
               say(c.has and " == " or " <= "), lo, hi)
    t.no.show(t.no, tbl, pre,
              say(c.has and " ~= " or " >  "), lo, hi)
  end end

--## statistics -------------------------------------------------
function cohen(xs,ys,    m,spd) -- mid gap, in spread units
  m   = function(a) return a[floor(#a / 2) + 1] end
  spd = function(a)
    return (a[floor(#a*9/10)+1] - a[floor(#a/10)+1])/2.56 end
  return abs(m(xs) - m(ys)) / ((spd(xs)+spd(ys))/2 + TINY) end

function ks(xs,ys,    nx,ny,d,p,q) -- max cdf gap, in
  nx, ny  = #xs, #ys                 -- critical units
  d, p, q = 0, 0, 0
  while p < nx and q < ny do
    if xs[p+1] <= ys[q+1] then p = p + 1 else q = q + 1 end
    d = max(d, abs(p / nx - q / ny)) end
  return d / ((nx + ny) / (nx * ny)) ^ 0.5 end

function cliffs(xs,ys,    gt,lt,j,k) -- rank imbalance; 0..1
  gt, lt, j, k = 0, 0, 0, 0   -- j,k: #ys sitting <x, <=x
  for _, x in ipairs(xs) do   -- x ascends: j,k only advance
    while j < #ys and ys[j+1] <  x do j = j + 1; k = j end
    while k < #ys and ys[k+1] == x do k = k + 1 end
    gt = gt + j; lt = lt + #ys - k end
  return abs(gt - lt) / (#xs * #ys) end

function same(xsort,ysort,Cohen,Ks,Cliffs) -- sorted in!
  return cohen(xsort,ysort)   < (Cohen  or 0.2)
      or ks(xsort,ysort)      < (Ks     or 1.36)
      or cliffs(xsort,ysort) <= (Cliffs or 0.197) end

function ranks(d,big,    mid,dd,sign,out,win,rank,best)
  mid = function(t) return t[floor(#t / 2) + 1] end
  dd  = {}; for k,v in pairs(d) do dd[k] = sorted(v) end
  sign = big and -1 or 1
  out, win, rank, best = {}, {}, -1, nil
  for _, k in ipairs(keysort(keys(dd),
                function(k) return sign * mid(dd[k]) end)) do
    if best == nil or not same(dd[best], dd[k]) then
      rank, best = rank + 1, k end
    if rank == 0 then win[1+#win] = k end
    out[k] = rank end
  return {winners=win, ranks=out} end

--## batteries --------------------------------------------------
function new(kl,t) -- class table is also its metatable
  kl.__index=kl;kl.__tostring=show; return setmetatable(t,kl) end

function iter(src,    at) -- iterate a list or a function
  if type(src) == "function" then return src end
  at = 0; return function() at = at + 1; return src[at] end end

function thing(s) -- string to number, bool, or string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s=="True" or (s~="False" and s) end

function csv(file,    f) -- stream rows of coerced cells;
  f = io.lines((file:gsub("%$(%w+)",os.getenv))) --env expansion 
  return function(    t,l)
    for line in f do
      l = line:gsub("%%.*",""):match"^%s*(.-)%s*$"
      if l ~= "" then
        t={}; for s in l:gmatch"[^,]+" do t[#t+1] = thing(s) end
        return t end end end end

function map(t,f,    u) -- f over the list part, in order
  u = {}; for _,v in ipairs(t) do u[1+#u]=f(v) end; return u end

function kap(t,f,    u) -- f(k,v) over all pairs, any order.
  u = {}                -- nil results vanish: kap also filters
  for k,v in pairs(t) do u[1+#u] = f(k,v) end; return u end

function copy(t) -- shallow copy of the list part
  return map(t, function(v) return v end) end

function push(t,v) t[1+#t] = v; return v end


function sum(t,f,    n) -- add f(v) over values
  n = 0; for _, v in pairs(t) do n = n + f(v) end; return n end

function sorted(t,f,    s) -- sorted copy; f optional
  s = copy(t); table.sort(s, f); return s end

function keysort(t,f,    px,ix) -- sort by f(v); stable,
  px, ix = {}, {}               -- so ties keep input order
  for at, v in ipairs(t) do px[v], ix[v] = f(v), at end
  return sorted(t, function(u,v)
           if px[u] == px[v] then return ix[u] < ix[v] end
           return px[u] < px[v] end) end

function keys(t,skip,    u) -- sorted keys; skip prefix?
  u = kap(t, function(k) return
        not (skip and tostring(k):sub(1,1) == skip) and k end)
  return keysort(u, tostring) end

function med(t,    s) -- median (sorts a copy first)
  s = sorted(t); return s[floor(#s / 2) + 1] end

function argmax(t,f,    hi,n,x) -- the v w/ biggest f(v)
  hi = -math.huge                 -- first winner keeps ties
  for _,v in ipairs(t) do n=f(v); if n>hi then hi,x=n,v end end
  return x end

function least(    lo) -- min-so-far reducer: call f{val,..}
  return function(x)   -- to offer, f() to read; the champion
    if x and (lo == nil or x[1] < lo[1]) then lo = x end
    return lo end end  -- rides in the closure

function shuffle(lst,    t,j) -- random re-order; copies first
  t = copy(lst)
  for at = #t, 2, -1 do
    j = math.random(at); t[at],t[j] = t[j],t[at] end
  return t end

function some(lst,k,    t) -- k items at random (all, if k big)
  t = shuffle(lst)
  for at = #t, min(k, #t) + 1, -1 do t[at] = nil end
  return t end

function round(v,n) -- round to n (default the.round) places
  if v % 1 == 0 then return floor(v) end 
  n = 10 ^ (n or the.round)
  return floor(v * n + 0.5) / n end

function show(t,    u) -- render anything. tables recurse:
  if type(t) ~= "table" then  -- lists keyless, dicts ":k v"
    return tostring(type(t) == "number" and round(t) or t) end
  u = #t > 0 and map(t,show) or sorted(kap(t,function(k,v) return
                                   tostring(k):sub(1,1) ~= "_"
                                   and ":"..k.." "..show(v) end))
  return "{"..table.concat(u, " ").."}" end

--## demos p ----------------------------------------------------
eg = {}

function run(eg,w,    ok,msg) -- one seeded example
  math.randomseed(the.seed)   
  if eg[w] then
    ok, msg = xpcall(eg[w], debug.traceback)
    if not ok then print(msg) end
    return ok end end

eg["--tree"] = function(    t,tr,n,best) -- prune, keep best
  t  = Tbl(csv(the.DATA .. the.file))
  tr = Tree(t, t.rows)
  n  = 0
  tr.walk(tr, function(w)
    n = n + 1
    if not best or w.val < best.val or
       (w.val == best.val and w.leafs < best.leafs) then
      best = w end end)
  print(("tree: %s leafs. prunings: %s. best: %s leafs,"
         .." val %s"):format(tr.leafs, n, best.leafs,
                               show(best.val)))
  assert(best.val <= tr.val and best.leafs <= tr.leafs) end

eg["--all"] = function ()
  for _,k in ipairs(keys(eg)) do
    if k ~= "--all" then run(eg, k) end end end

eg["--the"] = function() print(show(the)) end

eg["--csv"] = function(    t) -- cells coerced, header named
  t = Tbl(csv(the.DATA .. the.file))
  print(#t.rows, show(t.cols.names))
  assert(#t.rows == 398 and t.rows[1][1] == 8) end

eg["--col"] = function(    n,s) -- Num and Sym summaries
  n = adds{1,2,3,4,5}
  s = adds({"a","a","b"}, Sym())
  print(show{mu=n.mid(n), sd=n.div(n),
             mode=s.mid(s), ent=s.div(s)})
  assert(n.mid(n) == 3 and s.mid(s) == "a") end

eg["--without"] = function(    a,b,w) -- (a+b) minus b == a
  a, b = adds{1,2,3,4,5}, adds{10,20,30}
  w = adds({10,20,30}, adds{1,2,3,4,5}).without(
        adds({10,20,30}, adds{1,2,3,4,5}), b)
  print(show{mu=w.mu, sd=w.div(w)})
  assert(abs(w.mu - a.mu) < 1e-9) end

eg["--distx"] = function(    t,d) -- self=0; far pair > near
  t = Tbl(csv(the.DATA .. the.file))
  d = function(a,b) return t.distx(t, a, b) end
  print(show{self=d(t.rows[1], t.rows[1]),
             near=d(t.rows[1], t.rows[2]),
             far =d(t.rows[1], t.rows[398])})
  assert(d(t.rows[1], t.rows[1]) == 0) end

eg["--half"] = function(    t,a,b,lo,hi) -- far-pole split
  t = Tbl(csv(the.DATA .. the.file))
  a, b, lo, hi = t.halve(t, t.rows)
  print(show{lo=#lo, hi=#hi,
             a=t.disty(t,a), b=t.disty(t,b)})
  assert(#lo + #hi == #t.rows)
  assert(t.disty(t,a) <= t.disty(t,b)) end

eg["--cuts"] = function(    t,b,c) -- champion cut, named
  t = Tbl(csv(the.DATA .. the.file))
  b = t.bestcut(t, t.rows, function(r)
        return t.disty(t, r) end, Num, least())
  c = t.cols.all[b[2]]
  print(("best cut: %s <= %s (val %.3f)")
        :format(c.name, b[3], b[1]))
  assert(b[1] >= 0 and c) end

eg["--show"] = function(    t,tr) -- tree, goal mean columns
  t  = Tbl(csv(the.DATA .. the.file))
  tr = Tree(t, t.rows)
  tr.show(tr, t)
  assert(tr.leafs > 1) end

eg["--acquire"] = function(    t,y,lab,best,truth)
  t     = Tbl(csv(the.DATA .. the.file))
  y     = function(r) return t.disty(t, r) end
  lab   = t.acquirer(t, the.budget)
  best  = y(lab[1])
  truth = y(keysort(t.rows, y)[1])
  print(show{labels=#lab, best=best, truth=truth})
  assert(#lab <= the.budget and best < 0.35) end

eg["--ranks"] = function(    g,d,r) -- ties share a rank
  g = function(mu,    u) u = {}
        for j = 1, 20 do
          u[j] = mu + math.random() + math.random() - 1 end
        return u end
  d = {a=g(0), b=g(0.05), c=g(2), e=g(4)}
  r = ranks(d)
  print(show(r.ranks), show(r.winners))
  assert(r.ranks.a == 0 and r.ranks.e > r.ranks.c) end

eg["--disty"] = function(    t,d,rows) -- sort rows by disty
  t = Tbl(csv(the.DATA .. the.file))
  d = function(r) return t.disty(t, r) end
  rows = keysort(t.rows, d)
  for at, r in ipairs(rows) do
    if at <= 3 or at > #rows - 3 then
      print(("%.3f  %s"):format(d(r), show(r)))
    elseif at == 4 then print"..." end end
  assert(d(rows[1]) <= d(rows[#rows])) end

--## start-up ---------------------------------------------------
function cli(d,    v) -- --key=val flags update settings
  for _, s in ipairs(arg) do
    for k in pairs(d) do
      v = s:match("^%-%-" .. k .. "=(.*)")
      if v then d[k] = thing(v) end end end
  return d end

if arg and arg[0] and arg[0]:find"lib%.lua$" then 
  cli(the); for _,w in ipairs(arg) do run(eg, w) end end 

return _ENV
