#!/usr/bin/env lua
-- abc.lua: explainable multi-objective optimization, tiny-ly.
-- Polymorphic Num/Sym summaries feed distance, labelling,
-- binning and tree code that never asks a column its type.
local help = [[

abc: explainable multi-objective optimization, tiny-ly
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

Samples a data landscape under a small labelling budget,
grows a regression tree over the labels, then picks good
rows and shows which x-ranges explain them.
USAGE: local abc = require"abc"
(demos and tests: lua abc-eg.lua [OPTIONS] [eg ...])
       
OPTIONS:
  --acquire=active  labelling: active or random
  --budget=50       labelling cap
  --check=5         rows checked by the tree
  --depth=4         tree max depth
  --file=$MOOT/optimize/misc/auto93.csv  data
  --keepf=0.66      rows kept per cull
  --leaf=3          tree min leaf size
  --more=4          labels added per round
  --p=2             minkowski exponent
  --seed=1          random seed 
  -h                show this help ]]

local abs,exp,floor,log =
      math.abs, math.exp, math.floor, math.log
local max,min,fmt = math.max, math.min, string.format
local BIG,the     = 1e32, {}
local lst,rnd,str = {},{},{}       -- lib; at end of file
local Num,Sym,Cols,Tbl,Tree = {},{},{},{},{}
local acquire,bins,stats    = {},{},{}

-- new makes instances; shared metatables give polymorphism
local function new(mt,t)
  mt.__index = mt; return setmetatable(t,mt) end


-- ## Num
-- One numeric column, summarized by Welford (n,mu,m2).
-- `mid`/`spread` = mean/sd; `norm` squashes to 0..1 via a
-- logistic z-score; `sub` = i's data without j's. A name
-- ending "-" sets w=0 (minimize); else w=1 (maximize).

-- ctor; goal w=0 if the name ends "-", else w=1
function Num.new(txt,at)
  txt = txt or " "
  return new(Num, {txt=txt, at=at or 1, n=0, mu=0, m2=0,
                   w = txt:find"-$" and 0 or 1}) end

-- fold v in (w=1) or out (w<0) by Welford; return v
function Num.add(i,v,w,    d)
  w   = w or 1
  i.n = i.n + w
  if i.n >= 1 then
    d    = v - i.mu
    i.mu = i.mu + w*d/i.n
    i.m2 = i.m2 + w*d*(v - i.mu) end
  return v end

-- mid of a Num = its mean
function Num.mid(i) return i.mu end

-- spread of a Num = its standard deviation
function Num.spread(i)
  return i.n < 2 and 0 or (max(0, i.m2)/(i.n - 1))^0.5 end

-- map v to 0..1 via a logistic over its z-score
function Num.norm(i,v,    z)
  z = (v - i.mu)/(i:spread() + 1E-32)
  return 1/(1 + exp(-1.7*max(-3, min(3, z)))) end

-- Num summarizing i's data without j's: weighted add of
-- -j.n values at j.mu, then j's own spread comes off m2
function Num.sub(i,j,    k)
  k = Num.new(i.txt, i.at)
  if j.n < i.n then
    k.n, k.mu, k.m2 = i.n, i.mu, i.m2
    k:add(j.mu, -j.n)
    k.m2 = max(0, k.m2 - j.m2) end
  return k end


-- ## Sym
-- One symbolic column: counts in has{}. `mid` = mode;
-- `spread` = entropy; `sub` as per Num.

-- ctor; value counts kept in has{}
function Sym.new(txt,at)
  return new(Sym, {txt=txt or " ", at=at or 1,
                   n=0, has={}}) end

-- count v in (w=1) or out (w<0); dead keys deleted
function Sym.add(i,v,w,    c)
  w   = w or 1
  i.n = i.n + w
  c   = w + (i.has[v] or 0)
  i.has[v] = c > 0 and c or nil
  return v end

-- mid of a Sym = its mode
function Sym.mid(i,    most,out)
  most = 0
  for k,n in pairs(i.has) do
    if n > most then most,out = n,k end end
  return out end

-- spread of a Sym = entropy of its counts
function Sym.spread(i,    e)
  e = 0
  for _,n in pairs(i.has) do
    e = e - n/i.n * log(n/i.n, 2) end
  return e end

-- Sym summarizing i's data without j's
function Sym.sub(i,j,    k)
  k = Sym.new(i.txt, i.at)
  for v,n in pairs(i.has) do k:add(v,  n) end
  for v,n in pairs(j.has) do k:add(v, -n) end
  return k end

-- fold a list into a summary (Num unless told otherwise)
local function adds(t,i)
  i = i or Num.new()
  for _,v in ipairs(t) do i:add(v) end
  return i end


-- ## Cols
-- Header names typed into columns: leading uppercase =
-- Num; trailing -,+,! = y goals; X = skip; else x.
-- `add` routes one row's cells to their cols ("?" skipped).

-- header names -> {names, all, x, y} typed columns
function Cols.new(names,    i,col)
  i = new(Cols, {names=names, all={}, x={}, y={}})
  for at,s in ipairs(names) do
    col = (s:find"^%u" and Num or Sym).new(s,at)
    lst.push(i.all, col)
    if not s:find"X$" then
      lst.push(s:find"[-+!]$" and i.y or i.x, col) end end
  return i end

-- route one row's cells to their columns ("?" skipped)
function Cols.add(i,row)
  for _,c in ipairs(i.all) do
    if row[c.at] ~= "?" then c:add(row[c.at]) end end
  return row end


-- ## Tbl
-- Rows plus a Cols. First row makes the cols; later rows
-- update them. `clone` reuses a header over new rows.

-- table from a csv file name or a list of rows
function Tbl.new(src,    i)
  i = new(Tbl, {cols=nil, rows={}})
  if type(src) == "string"
  then for row in str.csv(src) do i:add(row) end
  else adds(src or {}, i) end
  return i end

-- first row makes the cols; later rows update them
function Tbl.add(i,row)
  if i.cols
  then lst.push(i.rows, i.cols:add(row))
  else i.cols = Cols.new(row) end
  return row end

-- fresh Tbl, same header, over new rows
function Tbl.clone(i,rows)
  return adds(rows or {}, Tbl.new{i.cols.names}) end


-- ## Dist
-- `dist` = gap 0..1 between two values of one column (each
-- class owns its pessimistic "?" rules). `distx` = p-norm
-- over the x cols; `disty` = distance to the ideal y goals
-- (0 = best possible row).

-- gap between two sym values (0 = same, 1 = not)
function Sym.dist(i,u,v)
  if u == "?" and v == "?" then return 1 end
  return u == v and 0 or 1 end

-- gap between two num values; missing = far pole
function Num.dist(i,u,v)
  if u == "?" and v == "?" then return 1 end
  if u ~= "?" then u = i:norm(u) end
  if v ~= "?" then v = i:norm(v) end
  if u == "?" then u = v < 0.5 and 1 or 0 end
  if v == "?" then v = u < 0.5 and 1 or 0 end
  return abs(u - v) end

-- p-norm of fn(col) over cols; nil results are skipped
local function minkowski(cols,fn,    d,n,v)
  d, n = 0, 0
  for _,c in ipairs(cols) do
    v = fn(c)
    if v then n, d = n + 1, d + v^the.p end end
  return (d/max(1, n))^(1/the.p) end

-- distance between two rows over the x columns
function Tbl.distx(i,r1,r2)
  return minkowski(i.cols.x, function(c)
    return c:dist(r1[c.at], r2[c.at]) end) end

-- row's distance to the ideal y goals (0 = best)
function Tbl.disty(i,row)
  return minkowski(i.cols.y, function(c)
    if row[c.at] ~= "?" then
      return abs(c:norm(row[c.at]) - c.w) end end) end


-- ## Score
-- `wins` grades a row: 100 = best seen, 0 = no better
-- than the median. `holdout` is the evaluation rig: label
-- half the rows via acquire, grow a tree, let it rank the
-- unseen half, check only the top few, return the best.
-- (Both lean on acquire and Tree, defined below.)

-- grader: row -> % of the median-to-best gap closed
function Tbl.wins(i,rows,    ys,lo,b4)
  ys = lst.sort(lst.map(rows or i.rows,
                function(r) return i:disty(r) end))
  lo, b4 = ys[1], ys[floor((#ys + 1)/2)]
  return function(r)
    return max(-100, min(100, floor(100 *
      (1 - (i:disty(r) - lo)/(b4 - lo + 1E-32))))) end end

-- budget rig: acquire train -> tree -> best test row
function Tbl.holdout(i,    rows,half,got,t,top)
  rows = rnd.shuffle(lst.slice(i.rows))
  half = floor(#rows/2)
  got  = acquire.top(i:clone(lst.slice(rows, 1, half)))
  t    = Tree.grow(i, got)
  top  = lst.slice(
           lst.keysort(lst.slice(rows, half + 1),
             function(r) return t:leaf(r) end),
           1, the.check)
  return lst.keysort(top,
           function(r) return i:disty(r) end)[1] end


-- ## Acquire
-- The active learner (after ezr2.py). `project` maps rows
-- onto the line joining two far labelled poles; `sway3`
-- labels a few, culls the slice nearest the bad pole,
-- repeats; if the pool dries with budget unspent, redo on
-- a fresh shuffle, anchored at the best and worst labels
-- so far. `acquire` returns the labels, best first.

-- row -> position on the line east-west (x=dist, y=goal)
function acquire.project(rows,x,y,east,west,    far,c)
  far  = function(r)
           return lst.argmax(rows,
                    function(z) return x(z,r) end) end
  east = east or far(rows[1])
  west = west or far(east)
  if y(east) > y(west) then east,west = west,east end
  c = x(east,west) + 1E-32
  return function(r)
    return (x(east,r)^2 + c*c - x(west,r)^2)/(2*c) end end

-- lab doubles as set (lab[row]) and list (lab[1..n])
function acquire.sway3(rows,y,x,cap,lab,east,west,
                       b4,more,fresh,seen)
  lab, b4 = lab or {}, rows
  while #rows >= 2*the.leaf do
    more, fresh = min(the.more, cap - #lab), {}
    for _,r in ipairs(rows) do
      if lab[r] then lst.push(fresh,r)
      elseif more > 0 then
        more   = more - 1
        lab[r] = true
        lst.push(lab, lst.push(fresh,r)) end end
    if #lab >= cap then return lab end    -- budget spent
    rows = lst.slice(
             lst.keysort(rows,
               acquire.project(fresh,x,y,east,west)),
             1, max(1, floor(the.keepf * #rows))) end
  if #lab < #b4 then                      -- redo, anchored
    seen = lst.keysort(lst.slice(lab), y)
    return acquire.sway3(rnd.shuffle(lst.slice(b4)), y, x,
                         cap, lab, seen[1], seen[#seen]) end
  return lab end

-- label at most budget-check rows; best first
function acquire.top(tbl,    y,x,cap,rows)
  y    = function(r)   return tbl:disty(r)   end
  x    = function(a,b) return tbl:distx(a,b) end
  cap  = the.budget - the.check
  rows = the.acquire == "random" and rnd.some(tbl.rows, cap)
         or acquire.sway3(rnd.shuffle(lst.slice(tbl.rows)),
                          y, x, cap)
  return lst.keysort(rows, y) end


-- ## Bins
-- One split = cheapest bin over all x cols; cost = size-
-- weighted spread of the two halves, the far half found by
-- `sub`, never a second pass. `bins.keep` (after
-- tiny-xai.lisp) is a closure holding the running best:
-- offer it (this,ys,at,v); call it bare for the winner.
-- sum = Num.new regresses; sum = Sym.new classifies.

-- closure: offer (this,ys,at,v); call bare -> best bin
function bins.keep(    lo,kept)
  lo = BIG
  return function(this,ys,at,v,    there,c)
    if this and the.leaf <= this.n
            and this.n <= ys.n - the.leaf then
      there = ys:sub(this)
      c = (this:spread()*this.n + there:spread()*there.n)
          / (ys.n + 1E-32)
      if c < lo then lo,kept = c,{c,at,v} end end
    return kept end end

-- offer each value's y summary as a candidate bin
function Sym.bins(i,rows,y,sum,keep,    ys,has,x)
  ys, has = sum(), {}
  for _,r in ipairs(rows) do
    x = r[i.at]
    if x ~= "?" then
      has[x] = has[x] or sum()
      has[x]:add(ys:add(y(r))) end end
  for v,this in pairs(has) do keep(this, ys, i.at, v) end end

-- offer a candidate bin at each change in sorted x
function Num.bins(i,rows,y,sum,keep,    xy,ys,this)
  xy, ys = {}, sum()
  for _,r in ipairs(rows) do
    if r[i.at] ~= "?" then
      lst.push(xy, {r[i.at], ys:add(y(r))}) end end
  lst.sort(xy, function(a,b) return a[1] < b[1] end)
  this = sum()
  for j,p in ipairs(xy) do
    this:add(p[2])
    if xy[j+1] and p[1] ~= xy[j+1][1] then
      keep(this, ys, i.at, p[1]) end end end

-- cheapest {cost,at,v} bin over all the x columns
function bins.split(tbl,rows,y,sum,keep)
  keep = keep or bins.keep()
  for _,col in ipairs(tbl.cols.x) do
    col:bins(rows, y, sum, keep) end
  return keep() end


-- ## Tree
-- `Tree.grow` recurses on the best bin while rows and
-- depth allow; nodes keep their split col, their rows and
-- a `mid` prediction. `holds` picks a row's side of a bin
-- ("?" = yes); `leaf` routes a row down; `show` prints
-- branch conditions via each class's `ops`.

-- does w sit on the yes-side of bin v? ("?" = yes)
function Sym.holds(i,w,v) return w == "?" or w == v end
function Num.holds(i,w,v) return w == "?" or w <= v end

-- printable ops: [1] = yes side, [2] = no side
Sym.ops = {"==", "~="}
Num.ops = {"<=", ">"}

-- recursively split rows on the cheapest bin
function Tree.grow(tbl,rows,y,sum,lvl,  i,bin,col,yes,no)
  y   = y or function(r) return tbl:disty(r) end
  sum = sum or Num.new
  lvl = lvl or 0
  i   = new(Tree, {n=#rows, rows=rows, col=nil,
                   mid=adds(lst.map(rows,y), sum()):mid()})
  if #rows >= 2*the.leaf and lvl < the.depth then
    bin = bins.split(tbl, rows, y, sum)
    if bin then
      col, yes, no = tbl.cols.all[bin[2]], {}, {}
      for _,r in ipairs(rows) do
        lst.push(col:holds(r[col.at], bin[3]) and yes or no,
                 r) end
      if #yes > 0 and #no > 0 then
        i.col, i.v = col, bin[3]
        i.yes = Tree.grow(tbl, yes, y, sum, lvl + 1)
        i.no  = Tree.grow(tbl, no,  y, sum, lvl + 1) end end end
  return i end

-- walk a row down to its leaf; return the leaf's mid
function Tree.leaf(i,row)
  while i.col do
    i = i.col:holds(row[i.col.at], i.v) and i.yes or i.no end
  return i.mid end

-- print tree: n, mid, indented branch conditions
function Tree.show(i,pad,edge)
  pad, edge = pad or "", edge or ""
  print(fmt("%5d %8s  %s%s", i.n, str.o(i.mid), pad, edge))
  if i.col then
    pad = edge == "" and pad or pad .. "|  "
    i.yes:show(pad, fmt("%s %s %s",
      i.col.txt, i.col.ops[1], str.o(i.v)))
    i.no:show(pad, fmt("%s %s %s",
      i.col.txt, i.col.ops[2], str.o(i.v))) end end


-- ## Stats
-- `same` = conservative equality: `cohen` AND `cliffs`
-- AND `ks` must all agree before two sets are equal.

-- Cliff's delta effect size in 0..1 (0 = identical)
function stats.cliffs(xs,ys,    m,gt,lt)
  ys, m  = lst.sort(lst.slice(ys)), #ys
  gt, lt = 0, 0
  for _,x in ipairs(xs) do
    gt = gt + lst.bisect(ys, x, true) - 1    -- # ys < x
    lt = lt + m - lst.bisect(ys, x) + 1 end  -- # ys > x
  return abs(gt - lt)/(#xs * m + 1E-32) end

-- Kolmogorov-Smirnov: max gap between the two CDFs
function stats.ks(xs,ys,    cdf,d)
  xs = lst.sort(lst.slice(xs))
  ys = lst.sort(lst.slice(ys))
  cdf = function(v,t) return (lst.bisect(t,v) - 1)/#t end
  d = 0
  for _,t in ipairs{xs,ys} do
    for _,v in ipairs(t) do
      d = max(d, abs(cdf(v,xs) - cdf(v,ys))) end end
  return d end

-- small effect: |mean gap| <= 0.35 * pooled sd
function stats.cohen(xs,ys,    a,b,sd)
  a, b = adds(xs), adds(ys)
  sd = (((a.n - 1)*a:spread()^2 + (b.n - 1)*b:spread()^2)
        / (a.n + b.n - 2))^0.5
  return abs(a.mu - b.mu) <= 0.35*(sd + 1E-32) end

-- true if xs,ys are statistically indistinguishable
function stats.same(xs,ys,    n,m)
  n, m = #xs, #ys
  return stats.cohen(xs,ys) and stats.cliffs(xs,ys)<=0.195
     and stats.ks(xs,ys) <= 1.36*((n + m)/(n*m))^0.5 end


-- ## Lst
-- List basics. Lib (lst, rnd, str) comes last so the AI
-- code above reads unobstructed.

-- append x to t; return x
function lst.push(t,x) t[1 + #t] = x; return x end

-- sort t in place; return t
function lst.sort(t,fn) table.sort(t,fn); return t end

-- copy of t, each item passed through fn
function lst.map(t,fn,    u)
  u = {}
  for _,v in ipairs(t) do u[1 + #u] = fn(v) end
  return u end

-- copy of items lo..hi of t (defaults: all)
function lst.slice(t,lo,hi,    u)
  u = {}
  for j = lo or 1, min(hi or #t, #t) do
    lst.push(u, t[j]) end
  return u end

-- sort a copy of t by fn(item), computing fn once per item
function lst.keysort(t,fn,    u)
  u = lst.map(t, function(v) return {fn(v), v} end)
  lst.sort(u, function(a,b) return a[1] < b[1] end)
  return lst.map(u, function(p) return p[2] end) end

-- t ascending; smallest j with v < t[j] (eq: v <= t[j]).
-- So count(t <= v) = bisect(t,v)-1; count(t < v) via eq.
function lst.bisect(t,v,eq,    lo,hi,mid)
  lo, hi = 1, #t + 1
  while lo < hi do
    mid = floor((lo + hi)/2)
    if eq and v <= t[mid] or v < t[mid]
    then hi = mid
    else lo = mid + 1 end end
  return lo end

-- item of t maximizing fn(item)
function lst.argmax(t,fn,    hi,v,out)
  hi = -BIG
  for _,z in ipairs(t) do
    v = fn(z)
    if v > hi then hi,out = v,z end end
  return out end


-- ## Rnd
-- Seeded random, so runs reproduce on any lua.

local Seed = 1
-- reset the generator (0 nudged to 1)
function rnd.seed(n)
  Seed = (n or 1) % 2147483647
  if Seed == 0 then Seed = 1 end end

-- 16807 Lehmer generator: same runs on any lua.
-- rnd.n() = float 0..1; rnd.n(n) = integer 1..n
function rnd.n(n,    r)
  Seed = (16807 * Seed) % 2147483647
  r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end

-- Fisher-Yates, in place; return t
function rnd.shuffle(t,    j)
  for i = #t, 2, -1 do
    j = rnd.n(i); t[i],t[j] = t[j],t[i] end
  return t end

-- k items picked at random (t untouched)
function rnd.some(t,k)
  return lst.slice(rnd.shuffle(lst.slice(t)), 1, k) end

-- weighted sampler over a dict of key -> weight
function rnd.pick(dct,    keys,s)
  keys, s = {}, 0
  for k,w in pairs(dct) do lst.push(keys, k); s = s + w end
  return function(    r)
    r = s * rnd.n()
    for _,k in ipairs(keys) do
      r = r - dct[k]; if r <= 0 then return k end end
    return keys[#keys] end end

-- Irwin-Hall bell: mean mu, sd sd (tails clip at 3 sd)
function rnd.gauss(mu,sd)
  mu, sd = mu or 0, sd or 1
  return mu + sd*2*(rnd.n() + rnd.n() + rnd.n() - 1.5) end


-- ## Str
-- Strings and files.

-- strip leading and trailing whitespace
function str.trim(s) return s:match"^%s*(.-)%s*$" end

-- string -> true | false | number | trimmed string
function str.what(s)
  s = str.trim(s)
  return s == "true" or
         (s ~= "false" and (tonumber(s) or s)) end

-- set `the` from any "--key=val" patterns in s
function str.settings(s)
  for k,v in s:gmatch"%-%-(%w+)=(%S+)" do
    the[k] = str.what(v) end end

-- expand a leading $MOOT (env, else ~/gits/moot)
function str.filename(s)
  return (s:gsub("^%$MOOT", os.getenv"MOOT" or
                 os.getenv"HOME" .. "/gits/moot")) end

-- iterate a csv's rows, cells trimmed and typed
function str.csv(file,    f)
  f = assert(io.open(str.filename(file)), "no " .. file)
  return function(    u)
    for s in f:lines() do
      if s:find"%S" then
        u = {}
        for x in s:gmatch"[^,]+" do
          lst.push(u, str.what(x)) end
        return u end end
    f:close() end end

-- pretty print: numbers rounded, lists spaced, dicts sorted
function str.o(x,    u)
  if type(x) == "number" then
    return x == floor(x) and tostring(x)
           or fmt("%.3f", x) end
  if type(x) ~= "table" then return tostring(x) end
  u = {}
  for _,v in ipairs(x) do lst.push(u, str.o(v)) end
  if #u == 0 then
    for k,v in pairs(x) do
      lst.push(u, k .. "=" .. str.o(v)) end
    lst.sort(u) end
  return "{" .. table.concat(u, " ") .. "}" end

-- ## Start
-- Parse help's --key=val defaults into `the`, seed, and
-- hand back the module (demos and cli live in abc-eg.lua).

str.settings(help)
rnd.seed(the.seed)

return {the=the, help=help, new=new, adds=adds,
        Num=Num, Sym=Sym, Cols=Cols, Tbl=Tbl, Tree=Tree,
        acquire=acquire, bins=bins, stats=stats,
        lst=lst, rnd=rnd, str=str}
