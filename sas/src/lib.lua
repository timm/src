#!/usr/bin/env lua
-- lib.lua: lib.py said in Lua, function for function.
-- Cells, columns, tables, distance, and the statistics
-- that police every claim in this book. One file: the
-- about.py knobs live in `the` below. Columns index from
-- 1, not 0; everything else mirrors the Python.
local abs,exp,log,sqrt = math.abs,math.exp,math.log,math.sqrt
local max,min,floor    = math.max,math.min,math.floor
local cos,pi,huge      = math.cos,math.pi,math.huge
local rand,srand       = math.random,math.randomseed
local TINY             = 1e-32

-- All defs below land in this fresh table (which _G backs for
-- reads), so `function name` both defines and exports: the
-- last line returns _ENV as the module. The local works on
-- Lua 5.2+; the setfenv line is the same trick for 5.1 and
-- LuaJIT (where it is a plain local and setfenv is nil).
local _ENV = setmetatable({}, {__index = _G})
if setfenv then setfenv(1, _ENV) end

the = {
  budget = 32,             -- acquire: max labels
  cap    = 1024,           -- holdout: max rows kept
  check  = 5,              -- holdout: test rows labelled
  DATA   = (arg and arg[0] or ""):gsub("[^/]*$","")
           .. "../data/", -- tables, besides lib.lua; $VARS ok
  few    = 128,            -- sample size for cheap guesses
  file   = "auto93.csv",   -- default table
  keepf  = 0.66,           -- acquire: pool kept per cull
  leaf   = 3,              -- tree: min rows in one leaf
  maxd   = 4,              -- tree: max depth
  more   = 4,              -- acquire: labels per round
  p      = 2,              -- minkowski coefficient
  round  = 2,              -- decimals printed by show
  seed   = 1234567891,     -- every random stream starts here
  stop   = 32}             -- min rows before a split halts

--## columns ---------------------------------------------------
NUM, SYM, COLS, TBL, NODE, TREE = {},{},{},{},{},{}

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
  z = (v - i.mu) / (i:div() + TINY)
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

--## tables ----------------------------------------------------
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
  for _, c in ipairs(i.all) do c:add(row[c.at]) end
  return row end

function TBL.add(i,row) -- keep the row; update summaries
  i.rows[#i.rows+1] = i.cols:add(row)
  i.mid = nil
  return row end

function adds(src,i) -- fold list or iterator; Num default
  i = i or Num()
  for v in iter(src or {}) do i:add(v) end
  return i end

function TBL.clone(i,rows) -- same header, fresh summaries
  return adds(rows, Tbl{i.cols.names}) end

function TBL.mids(i) -- return centroid of this tbl
  i.mid = i.mid or map(i.cols.all,function(c) return c:mid()end)
  return i.mid end

--## distance --------------------------------------------------
function SYM.dist(i,a,b) -- gap between two syms; 0..1
  if a == "?" and b == "?" then return 1 end
  return a ~= b and 1 or 0 end

function NUM.dist(i,a,b) -- gap between two nums; 0..1
  if a == "?" and b == "?" then return 1 end
  a, b = i:norm(a), i:norm(b)
  if a == "?" then a = b > 0.5 and 0 or 1 end
  if b == "?" then b = a > 0.5 and 0 or 1 end
  return abs(a - b) end

function minkowski(cols,f,    d,n) -- p-norm mean of f(col)
  d, n = 0, TINY
  for _, c in ipairs(cols) do n, d = n+1, d + f(c) ^ the.p end
  return (d / n) ^ (1 / the.p) end

function TBL.distx(i,row1,row2) -- gap over x cols; 0..1
  return minkowski(i.cols.x, function(c)
           return c:dist(row1[c.at], row2[c.at]) end) end

function TBL.disty(i,row) -- gap to heaven; 0=best
  return minkowski(i.cols.y, function(y)
           return abs(y:norm(row[y.at]) - y.heaven) end) end

--## clusters --------------------------------------------------
function TBL.projx(i,row,a,b,c) -- onto the a-b line
  return (i:distx(a,row)^2 + c*c
          - i:distx(b,row)^2) / (2*c + TINY) end

function TBL.halve(i,rows,    far,a,b,c,n)
  rows = rows or i.rows     -- split on far poles, best first
  far = function(r,    t)
          t = keysort(some(rows, the.few),
                function(r2) return i:distx(r, r2) end)
          return t[#t] end
  a = far(rows[rand(#rows)])
  b = far(a)
  c = i:distx(a, b)
  if i:disty(b) < i:disty(a) then a, b = b, a end
  rows = keysort(rows, function(r) return i:projx(r,a,b,c) end)
  n = floor(#rows / 2)
  return a, b, sub(rows, 1, n), sub(rows, n + 1) end

function Node(tbl,rows,    recurse) -- tree of halves
  function recurse(rows,    node,a,b,lo,hi)
    node = new(NODE, {here=tbl:clone(rows),
                      a=nil, b=nil, lo=nil, hi=nil})
    if #rows >= 2 * the.stop then
      a, b, lo, hi = tbl:halve(rows)
      node.a, node.b = a, b
      if #lo > 0 and #hi > 0 then
        node.lo, node.hi = recurse(lo), recurse(hi) end end
    return node 
  end -- recurse
  return recurse(rows or tbl.rows) end

function NODE.leaf(i,row,    t) -- walk row down to its leaf
  while i.lo do
    t = i.here
    i = t:distx(row, i.a) <= t:distx(row, i.b)
        and i.lo or i.hi end
  return i end

--## acquire ---------------------------------------------------
-- Label few rows, cull the pool toward the good pole, loop.
-- lab is a plain list of labelled rows; acquire rebuilds its
-- private seen set (keyed by row ref) on each entry.
function TBL.poles(i,rows,    x,t,lo,hi,c) -- projector on
  x  = function(a,b) return i:distx(a, b) end -- the line
  t  = keysort(rows, function(r) return i:disty(r) end)
  lo, hi = t[1], t[#t]     -- from the y-best to the y-worst
  c  = x(lo, hi) + TINY    -- (keysort: one disty per row)
  return function(r)
    return (x(lo,r)^2 + c*c - x(hi,r)^2) / (2*c) end end

function TBL.acquire(i,rows,cap,lab,    seen,more)
  seen = {}
  for _,r in ipairs(lab) do seen[r] = true end
  while #rows >= 2*the.leaf and #lab < cap do
    more = min(the.more, cap - #lab)
    for _,r in ipairs(rows) do -- issue `more` new labels
      if more < 1 then break end
      if not seen[r] then
        more, seen[r] = more - 1, true
        push(lab, r) end end
    rows = sub(keysort(rows, i:poles(lab)),
               1, max(1, floor(the.keepf * #rows))) end
  return lab end

function TBL.acquirer(i,cap,    rows,lab) -- seed a few
  rows = shuffle(i.rows)  -- (once: kills file-order bias)
  lab  = i:acquire(rows, the.more, {})
  while #lab < cap and #lab < #rows do
    lab = i:acquire(rows, cap, lab) end
  return keysort(lab, function(r) return i:disty(r) end) end

function TBL.wins(i,rows,    ys,lo,b4) -- grader: row ->
  ys = sorted(map(rows or i.rows,      -- % gap to best
         function(r) return i:disty(r) end)) -- closed,
  lo, b4 = ys[1], ys[floor(#ys/2)+1]         -- [-100,100]
  return function(r)
    return max(-100, min(100,
      100*(1 - (i:disty(r)-lo) / (b4-lo+TINY)))) end end

function TBL.holdout(i,how,    rows,n,train,test,lab,t,top)
  how  = how or function(t2,cap) return t2:acquirer(cap) end
  rows = shuffle(i.rows)     -- label train via `how`, grow
  n    = floor(#rows/2)      -- tree, use it to sort unseen
  train= sub(rows, 1, n)     -- test half, label the first
  test = sub(rows, n+1)      -- the.check, return their best
  lab  = how(i:clone(train), the.budget - the.check)
  t    = Tree(i, lab)
  top  = sub(keysort(test,
           function(r) return t:leaf(i, r) end),
           1, the.check)
  return keysort(top,
           function(r) return i:disty(r) end)[1] end

--## discretize ------------------------------------------------
-- Find good cuts: places where splitting the x values most
-- purifies some y summary. All candidates feed one `least`
-- reducer; no cut lists are ever built.
function val(a,b) -- mean diversity of two summaries
  return (a:div()*a.n + b:div()*b.n) / (a.n + b.n + TINY) end

function SYM.cuts(c,xy,tot,acc,best,    d,b) -- one cut per
  d = {}                                       -- key; feed best
  for _,p in ipairs(xy) do
    b = d[p[1]] or acc()
    b:add(p[2]); d[p[1]] = b end
  if #keys(d) > 1 then
    for k,b in pairs(d) do
      best{val(b, tot:without(b)), c.at, k} end end end

function NUM.cuts(c,xy,tot,acc,best,    here) -- cuts between
  table.sort(xy, function(a,b) return a[1] < b[1] end)
  here = acc()                   -- each distinct, sorted x
  for j,p in ipairs(xy) do
    here:add(p[2])
    if j < #xy and p[1] ~= xy[j+1][1] then
      best{val(here,tot:without(here)),c.at,p[1]} end end end

function TBL.cuts(i,rows,c,Y,acc,best,    xy,tot) -- col c
  xy = {}                        -- feeds its splits to best
  for _,r in ipairs(rows) do
    if r[c.at] ~= "?" then push(xy, {r[c.at], Y(r)}) end end
  tot = adds(map(xy, function(p) return p[2] end), acc())
  c:cuts(xy, tot, acc, best) end

function TBL.bestcut(i,rows,Y,acc,best) -- champion x-col cut
  for _,c in ipairs(i.cols.x) do i:cuts(rows,c,Y,acc,best) end
  return best() end

function TBL.divide(i,rows,c,v,    yes,no) -- rows into holds
  yes, no = {}, {}                         -- c<=v, or not
  for _,r in ipairs(rows) do
    push(c:holds(r[c.at], v) and yes or no, r) end
  return yes, no end

--## trees -----------------------------------------------------
-- Recursive best-cut trees over the discretizer above, plus
-- walk/sides: visit every pruning of a grown tree.
function Tree(tbl,rows,Y,acc,    recurse)
  function recurse(rows,lvl,    ys,t,b,c,yes,no)
    ys = adds(map(rows, Y), acc())
    t  = new(TREE, {at=nil, v=nil, mu=ys:mid(), leafs=1,
                    here = tbl:clone(rows),
                    loss = ys.has and ys:div() or ys:mid()})
    t.val = t.loss
    if #rows >= 2*the.leaf and lvl < the.maxd then
      b = tbl:bestcut(rows, Y, acc, least())
      if b then
        c = tbl.cols.all[b[2]]
        yes, no = tbl:divide(rows, c, b[3])
        if #yes > 0 and #no > 0 then
          t.at, t.v = b[2], b[3]
          t.yes   = recurse(yes, lvl+1)
          t.no    = recurse(no,  lvl+1)
          t.val   = min(t.yes.val, t.no.val)
          t.leafs = t.yes.leafs + t.no.leafs end end end
    return t 
  end -- recurse
  Y   = Y or function(r) return tbl:disty(r) end
  acc = acc or Num
  return recurse(rows, 0) end

function TREE.leafed(x) -- x, collapsed to one leaf
  return new(TREE, {at=nil, mu=x.mu, loss=x.loss,
                    val=x.loss, leafs=1, here=x.here}) end

function TREE.walk(t,fun) -- fun on every pruning of tree t
  if t.at == nil then return fun(t) end
  t.yes:sides(function(yes)
    t.no:sides(function(no)
      fun(new(TREE, {at=t.at, v=t.v, here=t.here,
                     yes=yes, no=no,
                     val=min(yes.val, no.val),
                     leafs=yes.leafs + no.leafs})) end) end) end

function TREE.sides(t,fun) -- t as leaf; then t's prunings
  fun(t:leafed())
  if t.at ~= nil then t:walk(fun) end end

function TREE.leaf(t,tbl,row,    c) -- row's leaf, its guess
  while t.at do
    c = tbl.cols.all[t.at]
    t = c:holds(row[t.at], t.v) and t.yes or t.no end
  return t.mu end

--## tree show -------------------------------------------------
-- One row per node: n, d2h, then each goal's mean under its
-- own header column; tree structure trails on the right.
function TREE.leaves(t,fun) -- fun on every leaf below t
  if t.at then t.yes:leaves(fun)
               t.no:leaves(fun)
  else fun(t) end end

function TREE.gstr(t) -- goal means, as aligned columns
  return table.concat(map(t.here.cols.y, function(g,    v)
    v = g:mid()
    if type(v) == "number" and v % 1 ~= 0 then
      v = ("%."..the.round.."f"):format(v) end
    return ("%9s"):format(v) end)) end

function TREE.show(t,tbl,    lo,hi,recurse)
  function recurse(t,pre,txt,    c,say,m)
    m = (t.at == nil and t.mu == lo and "*") or -- best leaf
        (t.at == nil and t.mu == hi and "!") or " " -- worst
    print(("%s%4d %5.2f%s  %s"):format(
      m, #t.here.rows, t.mu, t:gstr(), pre .. txt))
    if t.at then                     -- structure right
      c   = tbl.cols.all[t.at]
      say = function(op)
              return c.name .. op .. tostring(t.v) end
      pre = pre .. (txt == "" and "" or "|  ")
      recurse(t.yes, pre, say(c.has and " == " or " <= "))
      recurse(t.no,  pre, say(c.has and " ~= " or " >  "))
    end 
  end -- recurse
  lo, hi = huge, -huge     -- leaf extremes,
  t:leaves(function(l)               -- then a header
    lo, hi = min(lo, l.mu), max(hi, l.mu) end)
  print((" %4s %5s"):format("n", "d2h") ..
    table.concat(map(t.here.cols.y, function(g)
      return ("%9s"):format(g.name) end)))
  recurse(t, "", "") end

--## statistics ------------------------------------------------
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

--## batteries -------------------------------------------------
function new(kl,t) -- class table is also its metatable
  kl.__index=kl;kl.__tostring=show; return setmetatable(t,kl) end

function iter(src,    at) -- iterate a list or a function
  if type(src) == "function" then return src end
  at = 0; return function() at = at + 1; return src[at] end end

function thing(s) -- string to number, bool, or string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s=="True" or (s~="False" and s) end

function csv(file,    f) -- stream rows of coerced cells;
  file = file or the.DATA .. the.file
  f = io.lines((file:gsub("%$(%w+)",os.getenv))) --env expansion
  return function(    t,l)
    for line in f do
      l = line:gsub("\239\187\191","")   -- strip any BOM
              :gsub("%%.*",""):match"^%s*(.-)%s*$"
      if l ~= "" then
        t={}                        -- (.-), keeps empty cells
        for s in (l..","):gmatch"(.-)," do t[#t+1]=thing(s) end
        return t end end end end

function map(t,f,    u) -- f over the list part, in order
  u = {}; for _,v in ipairs(t) do u[1+#u]=f(v) end; return u end

function kap(t,f,    u) -- f(k,v) over all pairs, any order.
  u = {}                -- nil results vanish: kap also filters
  for k,v in pairs(t) do u[1+#u] = f(k,v) end; return u end

function sub(t,lo,hi,    u) -- copy t[lo..hi]; any size
  u, hi = {}, min(hi or #t, #t)
  for j = max(lo or 1, 1), hi do u[1+#u] = t[j] end
  return u end

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

function least(    lo) -- min-so-far reducer: call f{val,..}
  return function(x)   -- to offer, f() to read; the champion
    if x and (lo == nil or x[1] < lo[1]) then lo = x end
    return lo end end  -- rides in the closure

function shuffle(lst,    t,j) -- random re-order; copies first
  t = copy(lst)
  for at = #t, 2, -1 do
    j = rand(at); t[at],t[j] = t[j],t[at] end
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

--## demos p ---------------------------------------------------
eg = {}

eg["--tree"] = function(    t,tr,n,best) -- prune, keep best
  t  = Tbl(csv())
  tr = Tree(t, t.rows)
  n  = 0
  tr:walk(function(w)
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
  t = Tbl(csv())
  print(#t.rows, show(t.cols.names))
  assert(#t.rows == 398 and t.rows[1][1] == 8) end

eg["--col"] = function(    n,s) -- Num and Sym summaries
  n = adds{1,2,3,4,5}
  s = adds({"a","a","b"}, Sym())
  print(show{mu=n:mid(), sd=n:div(),
             mode=s:mid(), ent=s:div()})
  assert(n:mid() == 3 and s:mid() == "a") end

eg["--without"] = function(    a,b,w) -- (a+b) minus b == a
  a, b = adds{1,2,3,4,5}, adds{10,20,30}
  w = adds({10,20,30}, adds{1,2,3,4,5}):without(b)
  print(show{mu=w.mu, sd=w:div()})
  assert(abs(w.mu - a.mu) < 1e-9) end

eg["--distx"] = function(    t,d) -- self=0; far pair > near
  t = Tbl(csv())
  d = function(a,b) return t:distx(a, b) end
  print(show{self=d(t.rows[1], t.rows[1]),
             near=d(t.rows[1], t.rows[2]),
             far =d(t.rows[1], t.rows[398])})
  assert(d(t.rows[1], t.rows[1]) == 0) end

eg["--half"] = function(    t,a,b,lo,hi) -- far-pole split
  t = Tbl(csv())
  a, b, lo, hi = t:halve(t.rows)
  print(show{lo=#lo, hi=#hi,
             a=t:disty(a), b=t:disty(b)})
  assert(#lo + #hi == #t.rows)
  assert(t:disty(a) <= t:disty(b)) end

eg["--node"] = function(    t,nd,n,leafs,walk) -- rows
  t  = Tbl(csv())  -- conserved in leafs
  nd = Node(t)
  n, leafs = 0, 0
  walk = function(x)
    if x.lo then walk(x.lo); walk(x.hi)
    else n = n + #x.here.rows; leafs = leafs + 1 end end
  walk(nd)
  print(show{leafs=leafs, rows=n,
             leaf1=t:disty(nd:leaf(t.rows[1]).here.rows[1])})
  assert(n == #t.rows and leafs > 1) end

eg["--cuts"] = function(    t,b,c) -- champion cut, named
  t = Tbl(csv())
  b = t:bestcut(t.rows, function(r)
        return t:disty(r) end, Num, least())
  c = t.cols.all[b[2]]
  print(("best cut: %s <= %s (val %.3f)")
        :format(c.name, b[3], b[1]))
  assert(b[1] >= 0 and c) end

eg["--show"] = function(    t,tr) -- tree, goal mean columns
  t  = Tbl(csv())
  tr = Tree(t, t.rows)
  tr:show(t)
  assert(tr.leafs > 1) end

eg["--acquire"] = function(    t,y,lab,best,truth)
  t     = Tbl(csv())
  y     = function(r) return t:disty(r) end
  lab   = t:acquirer(the.budget)
  best  = y(lab[1])
  truth = y(keysort(t.rows, y)[1])
  print(show{labels=#lab, best=best, truth=truth})
  assert(#lab <= the.budget and best < 0.35) end

eg["--holdout"] = function(    t,b,w) -- train half, test half
  t = Tbl(csv())
  t.rows = some(t.rows, the.cap)
  b = t:holdout()
  w = t:wins()
  print(show{disty=t:disty(b), win=w(b)})
  assert(-100 <= w(b) and w(b) <= 100) end

eg["--holdouts"] = function(    t,W,go,L,R,ml,mr,v) -- 20
  t  = Tbl(csv())                 -- runs: active vs random
  t.rows = some(t.rows, the.cap)
  W  = t:wins()
  go = function(how,    u) u = {}
         for j = 1, 20 do
           srand(the.seed + j)
           u[1+#u] = W(t:holdout(how)) end
         return sorted(u) end
  L  = go()                       -- active acquire
  R  = go(function(t2,cap)        -- random: first cap rows
         return sub(t2.rows, 1, cap) end)
  ml = sum(L, function(x) return x end) / 20
  mr = sum(R, function(x) return x end) / 20
  v  = same(L, R) and "tie" or (ml > mr and "land" or "rand")
  print(show{active=ml, random=mr, verdict=v})
  assert(#L == 20 and #R == 20) end

eg["--ranks"] = function(    g,d,r) -- ties share a rank
  g = function(mu,    u) u = {}
        for j = 1, 20 do
          u[j] = mu + rand() + rand() - 1 end
        return u end
  d = {a=g(0), b=g(0.05), c=g(2), e=g(4)}
  r = ranks(d)
  print(show(r.ranks), show(r.winners))
  assert(r.ranks.a == 0 and r.ranks.e > r.ranks.c) end

eg["--same"] = function(    g,x,y,c,k,cl,s,n) -- 3 tests
  g = function(    u) u = {}        -- vote; same() ORs them
        for j = 1, 100 do           -- box-muller gaussians
          u[j] = sqrt(-2*log(1 - rand()))
                 * cos(2*pi*rand()) end
        return sorted(u) end
  x, n = g(), 0    -- y = x + shift: pure effect, no noise
  print("shift  cohen     ks cliffs |  same")
  for _, mu in ipairs{0,.1,.2,.3,.4,.5,.75,1,1.5,2} do
    y  = map(x, function(v) return v + mu end)
    c  = cohen(x, y)   < 0.2
    k  = ks(x, y)      < 1.36
    cl = cliffs(x, y) <= 0.197
    s  = same(x, y)
    if s ~= (c and k and cl) then n = n + 1 end -- split vote
    print(("%5.2f  %5s  %5s  %5s | %5s"):format(mu,
      tostring(c), tostring(k), tostring(cl), tostring(s)))
  end
  print("split votes: " .. n)
  assert(n >= 1)                  -- OR beats AND somewhere
  assert(same(x, x) and not same(x, map(x,
    function(v) return v + 4 end))) end

eg["--disty"] = function(    t,d,rows) -- sort rows by disty
  t = Tbl(csv())
  d = function(r) return t:disty(r) end
  rows = keysort(t.rows, d)
  for at, r in ipairs(rows) do
    if at <= 3 or at > #rows - 3 then
      print(("%.3f  %s"):format(d(r), show(r)))
    elseif at == 4 then print"..." end end
  assert(d(rows[1]) <= d(rows[#rows])) end

--## start-up --------------------------------------------------
function cli(d,    v) -- --key=val flags update settings
  for _, s in ipairs(arg) do
    for k in pairs(d) do
      v = s:match("^%-%-" .. k .. "=(.*)")
      if v then d[k] = thing(v) end end end
  return d end

function run(funs,w,    ok,msg) -- one seeded example
  srand(the.seed)   
  if funs[w] then
    ok, msg = xpcall(funs[w], debug.traceback)
    if not ok then print(msg) end
    return ok end end

if arg and arg[0] and arg[0]:find"lib%.lua$" then 
  cli(the); for _,w in ipairs(arg) do run(eg, w) end end 

return _ENV
