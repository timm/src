#!/usr/bin/env lua
local help = [[
ezr3.lua: multi-goal trees, XAI, active learning, optimization.
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license.

A holdout score rig, and the stats
that police it. Demos live next door in ezr3-eg.lua; the
batteries below, in lib.lua. 

usage:
  lua ezr3-eg.lua [-h] [--key=val ..] [--demo ..]

or, adding demos from your own script:
  local ezr = require"ezr3-eg"
  ezr.eg["--myDemo"] = function() print(ezr.the.seed) end
  ezr.go(ezr.eg)

inference options:
  budget=50    acquire: max labels
  cap=1024     holdout: max rows kept
  check=5      holdout: test rows labelled
  few=128      sample size for cheap guesses
  keepf=0.66   acquire: pool kept per cull
  leaf=3       tree: min rows in one leaf
  maxd=4       tree: max depth
  more=4       acquire: labels per round
  p=2          minkowski coefficient
  stop=32      min rows before a split halts]]

local abs,exp,log,sqrt = math.abs,math.exp,math.log,math.sqrt
local max,min,floor    = math.max,math.min,math.floor
local huge,rand        = math.huge,math.random
local TINY             = 1e-32

-- find lib.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
-- all defs below land here; reads fall through to lib
-- (and, through lib, to _G)
local _ENV = setmetatable({}, {__index = require"lib"})
if setfenv then setfenv(1, _ENV) end

the = the:also(help)
NUM, SYM, COLS, TBL, NODE, TREE = {},{},{},{},{},{}

--## columns ---------------------------------------------------
function Col(name,at) -- column kind from first letter
  return (name:find"^%l" and Sym or Num)(name,at) end

function Num(name,at) -- summary of a numeric column
  name = name or ""
  return new(NUM, {at=at or 1, name=name, n=0, mu=0, m2=0,
                   heaven = name:find"-$" and 0 or 1}) end

function Sym(name,at) -- summary of a symbolic column
  return new(SYM, {at=at or 1, name=name or "", n=0, has={}}) end

function SYM.add(i,v,inc) -- update symbol counts; inc can
  if v == "?" then return v end -- be -1 (forget v)
  inc = inc or 1
  i.n = i.n + inc
  i.has[v] = inc + (i.has[v] or 0)
  if i.has[v] <= 0 then i.has[v] = nil end
  return v end

function NUM.add(i,v,inc,    d) -- one-pass update of mu and
  if v == "?" then return v end -- m2, forwards (inc=1) or in
  inc  = inc or 1               -- reverse (inc=-1)
  i.n  = i.n + inc
  d    = v - i.mu
  i.mu = i.mu + inc * d / i.n
  i.m2 = i.m2 + inc * d * (v - i.mu); return v end

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

--## Columns test ----------------------------------------------
function SYM.holds(i,x,v) return x == "?" or x == v  end
function NUM.holds(i,x,v) return x == "?" or x <= v  end

--## tables ----------------------------------------------------
function Tbl(src) -- fold rows (row 1 is the header) into
  src = iter(src) -- fresh columns
  return adds(src, new(TBL, {rows={}, mid=nil,
                             cols=Cols(src())})) end

function Cols(names,    all,x,y,klass) -- names, sorted
  all, x, y = {}, {}, {}               -- into their roles
  for at, s in ipairs(names) do
    all[at] = Col(s, at)
    if s:find"!$" then klass = all[at]
    elseif s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end end
  return new(COLS, {names=names,all=all,x=x,y=y,klass=klass}) end

function COLS.add(i,row,inc) -- fold a row into every column
  for _, c in ipairs(i.all) do c:add(row[c.at], inc) end
  return row end

function TBL.add(i,row) -- keep the row; update summaries
  i.rows[#i.rows+1] = i.cols:add(row)
  i.mid = nil
  return row end

function TBL.clone(i,rows,    u) -- same header, fresh
  u = adds(rows, Tbl{i.cols.names}) -- summaries; clones of
  u.model = i.model                 -- live models stay live
  return u end

function TBL.mids(i) -- return centroid of this tbl
  i.mid = i.mid or map(i.cols.all, "mid")
  return i.mid end

--## Forgetting -----------------------------------------------
function NUM.__sub(i,j,    n,d) -- tot - v: new NUM
  n = i.n - j.n
  if n < 1 then return Num(i.name, i.at) end
  d = j.mu - i.mu
  return new(NUM, {name=i.name, at=i.at, heaven=i.heaven,
                   n=n, mu=(i.n*i.mu - j.n*j.mu) / n,
                   m2=max(0, i.m2 - j.m2
                             - d*d*i.n*j.n/n)}) end

function SYM.__sub(i,j,    out,n) -- tot - v: new counts
  out = Sym(i.name, i.at)
  for k,v in pairs(i.has) do
    n = v - (j.has[k] or 0)
    if n > 0 then out.has[k] = n; out.n = out.n + n end end
  return out end

function NUM.reset(i) i.n, i.mu, i.m2 = 0, 0, 0 end
function SYM.reset(i) i.n, i.has = 0, {} end

function TBL.sub(i,row) -- forget a row. All resets happen
  i.cols:add(row, -1)   -- here: empty tbl = fresh columns
  i.mid = nil
  for j,r in ipairs(i.rows) do
    if r == row then table.remove(i.rows, j); break end end
  if #i.rows == 0 then map(i.cols.all, "reset") end
  return row end
function adds(src,i) -- fold list or iterator; Num default
  i = i or Num()
  for v in iter(src or {}) do i:add(v) end
  return i end


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

function TBL.label(i,row,    f) -- ask i.model for goals;
  f = i.model(map(i.cols.x,     -- fold them in
        function(c) return row[c.at] end), #i.cols.y)
  for j, y in ipairs(i.cols.y) do
    row[y.at] = y:add(f[j]) end
  return row end

function TBL.disty(i,row) -- gap to heaven; 0=best. Rows
  if i.model and row[i.cols.y[1].at] == "?" then -- born "?"
    i:label(row) end       -- get labelled on demand, here
  return minkowski(i.cols.y, function(y)
           return abs(y:norm(row[y.at]) - y.heaven) end) end

function TBL.Y(i) -- disty as a first-class key function
  return function(r) return i:disty(r) end end

--## clusters --------------------------------------------------
function TBL.poles(i,rows,lo,hi,    far,c) -- rows ->
  far = function(r,    t) -- projector (and poles) on the
          t = keysort(rows, function(z) return i:distx(z, r) end)
          return t[#t] end
  lo = lo or far(rows[rand(#rows)])
  hi = hi or far(lo)
  if i:disty(lo) > i:disty(hi) then lo, hi = hi, lo end
  c = i:distx(lo, hi) + TINY
  return function(r) return (i:distx(lo,r)^2 + c*c
                              - i:distx(hi,r)^2) / (2*c) end,
         lo, hi end

function TBL.halve(i,rows,    fun,a,b,n)
  rows = rows or i.rows   -- split on far poles, best first
  fun, a, b = i:poles(some(rows, the.few))
  rows = keysort(rows, fun)
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
-- private seen set (keyed by row ref) on each entry. When a
-- pool dries with budget left, acquirer reshuffles and goes
-- again, anchored at the best and worst labels seen so far.
function TBL.acquire(i,rows,cap,lab,lo,hi,
                     seen,more,new)
  seen = {}
  for _,r in ipairs(lab) do seen[r] = true end
  while #rows >= 2*the.leaf do
    more, new = min(the.more, cap - #lab), {}
    for _,r in ipairs(rows) do -- new = labels in this pool
      if seen[r] then push(new, r)
      elseif more > 0 then
        more, seen[r] = more - 1, true
        push(new, push(lab, r)) end end
    if #lab >= cap then return lab end -- budget spent
    rows = sub(keysort(rows, (i:poles(new, lo, hi))),
               1, max(1, floor(the.keepf * #rows))) end
  return lab end

function TBL.acquirer(i,cap,    lab,lo,hi,t,b4)
  lab = {}
  while true do
    b4  = #lab
    lab = i:acquire(shuffle(i.rows), cap, lab, lo, hi)
    if #lab >= cap or #lab >= #i.rows or
       #lab == b4 then break end -- full, or no progress
    t = keysort(lab, i:Y())
    lo, hi = t[1], t[#t] end -- best+worst seen
  return keysort(lab, i:Y()) end
  --

--## discretize ------------------------------------------------
-- Find good cuts: places where splitting the x values most
-- purifies some y summary. All candidates feed one `least`
-- reducer; no cut lists are ever built.
function val(a,b) -- mean diversity of two summaries
  return (a:div()*a.n + b:div()*b.n) / (a.n + b.n + TINY) end

function big(lo,n) -- both sides of a cut hold >= the.leaf
  return the.leaf <= lo and lo <= n - the.leaf end

function SYM.cuts(c,xy,tot,acc,best,    d,b) -- one cut per
  d = {}                                       -- key; feed best
  for _,p in ipairs(xy) do
    b = d[p[1]] or acc()
    b:add(p[2]); d[p[1]] = b end
  if #keys(d) > 1 then
    for k,v in pairs(d) do
      if big(v.n, #xy) then
        best{val(v, tot - v), c.at, k} end end end end

function NUM.cuts(c,xy,tot,acc,best,    here) -- cuts between
  table.sort(xy, function(a,b) return a[1] < b[1] end)
  here = acc()                   -- each distinct, sorted x
  for j,p in ipairs(xy) do
    here:add(p[2])
    if j < #xy and p[1] ~= xy[j+1][1] and big(j, #xy) then
      best{val(here, tot - here),c.at,p[1]} end end end

function TBL.cuts(i,rows,c,Y,acc,best,    xy,tot) -- col c
  xy = {}                        -- feeds its splits to best
  for _,r in ipairs(rows) do
    if r[c.at] ~= "?" then push(xy, {r[c.at], Y(r)}) end end
  tot = adds(map(xy, 2), acc())
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
  Y   = Y or tbl:Y()
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
  return table.concat(map(t.here.cols.y, function(g)
    return ("%9s"):format(show(g:mid())) end)) end

function TREE.show(t,tbl,    lo,hi,recurse)
  function recurse(t,pre,txt,    c,say,m)
    m = (t.at == nil and t.mu == lo and "*") or -- best leaf
        (t.at == nil and t.mu == hi and "!") or " " -- worst
    print(("%s%4d %5.2f%s  %s"):format(
      m, #t.here.rows, t.mu, t:gstr(), pre .. txt))
    if t.at then                     -- structure right
      c   = tbl.cols.all[t.at]
      say = function(op)
              return c.name .. op .. show(t.v) end
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

--## score -------------------------------------------------
function TBL.wins(i,rows,    ys,lo,b4) -- grader: row ->
  ys = sorted(map(rows or i.rows, i:Y())) -- % gap to best
  lo, b4 = ys[1], ys[floor(#ys/2)+1] -- closed, [-100,100]
  return function(r)
    return max(-100, min(100,
      100*(1 - (i:disty(r)-lo) / (b4-lo+TINY)))) end end

function TBL.holdout(i,how,    rows,n,train,test,lab,t,top)
  how  = how or function(t2,cap) return t2:acquirer(cap) end
  rows = shuffle(i.rows)     -- label train via `how`, grow
  n    = floor(#rows/2)      -- tree, use it to rank the
  train= sub(rows, 1, n)     -- unseen test half; label the
  test = sub(rows, n+1)      -- best the.check of that rank
  lab  = how(i:clone(train), the.budget - the.check)
  assert(#lab + the.check <= the.budget) -- spend, counted
  t    = Tree(i, lab)
  top  = sub(keysort(test, function(r) return t:leaf(i, r) end),
           1, the.check)
  return keysort(top, i:Y())[1] end

--## statistics ------------------------------------------------
function cohen(xs,ys,    x,y,n,m,sd) -- mean gap, in
  x, y = adds(xs), adds(ys)          -- pooled-sd units
  n, m = x.n, y.n
  sd = sqrt(((n-1)*x:div()^2 + (m-1)*y:div()^2)/(n+m-2))
  return abs(x.mu - y.mu) / (sd + TINY) end

function ks(xs,ys,    nx,ny,d,p,q,v) -- max cdf gap, in
  nx, ny  = #xs, #ys                  -- critical units
  d, p, q = 0, 0, 0
  while p < nx and q < ny do -- walk both cdfs one distinct
    v = min(xs[p+1], ys[q+1])              -- value at a time
    while p < nx and xs[p+1] == v do p = p + 1 end
    while q < ny and ys[q+1] == v do q = q + 1 end
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
  return cohen( xsort,ysort) <= (Cohen  or .35)  -- `and` is
     and cliffs(xsort,ysort) <= (Cliffs or .195) -- lazy: all
     and ks(    xsort,ysort) <= (Ks     or 1.36) end -- agree

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

--## the end  ---------------------------------------------------
return _ENV
