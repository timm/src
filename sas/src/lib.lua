#!/usr/bin/env lua
-- lib.lua: lib.py said in Lua, function for function.
-- Cells, columns, tables, distance, and the statistics
-- that police every claim in this book. One file: the
-- about.py knobs live in `the` below. Columns index from
-- 1, not 0; everything else mirrors the Python.
local abs,exp,log,sqrt = math.abs,math.exp,math.log,math.sqrt
local max,min,floor    = math.max,math.min,math.floor
local slice = table.unpack     -- {slice(t,a,b)} = t[a..b]
local TINY  = 1e-32

-- All defs below land in this fresh table (which _G backs for
-- reads), so `function name` both defines and exports: the
-- last line returns _ENV as the module.
local _ENV = setmetatable({}, {__index = _G})

the = {
  seed   = 1234567891,     -- every random stream starts here
  p      = 2,              -- minkowski coefficient
  few    = 128,            -- sample size for cheap guesses
  stop   = 32,             -- min rows before a split halts
  round  = 2,              -- decimals printed by show
  file = "data/auto93.csv" } -- default table (via MOOT)

--## cells ------------------------------------------------------
function thing(s) -- string to number, bool, or string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s=="True" or (s~="False" and s) end

function csv(file,    f) -- stream rows of coerced cells
  f = io.lines(file)
  return function(    t,l)
    for line in f do
      l = line:gsub("%%.*",""):match"^%s*(.-)%s*$"
      if l ~= "" then
        t={}; for s in l:gmatch"[^,]+" do t[#t+1] = thing(s) end
        return t end end end end

--## columns ----------------------------------------------------
NUM, SYM, TBL, NODE = {},{},{},{} -- metatables (see new)

function Col(name,at) -- column kind from first letter
  return (name:sub(1,1):match"%l" and Sym or Num)(name,at) end

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

--## tables -----------------------------------------------------
function Tbl(src,    names,all,x,y) -- row 1 names columns
  src = iter(src)
  names, all, x, y = src(), {}, {}, {}
  for at, s in ipairs(names) do
    all[at] = Col(s, at)
    if s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end end
  return adds(src, new(TBL, {rows={}, mid=nil,
                 cols={names=names, all=all, x=x, y=y}})) end

function TBL.add(i,row) -- fold a row into every column
  i.rows[#i.rows+1] = row
  i.mid = nil
  for _, c in ipairs(i.cols.all) do c.add(c, row[c.at]) end
  return row end

function adds(src,i) -- fold list or iterator; Num default
  i = i or Num()
  for v in iter(src or {}) do i.add(i, v) end
  return i end

function TBL.clone(i,rows) -- same header, fresh summaries
  return adds(rows, Tbl{i.cols.names}) end

function TBL.mids(i) -- return centroid of this tbl
  i.mid = i.mid or
          map(i.cols.all, function(c) return c.mid(c) end)
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

function TBL.distx(i,row1,row2,    d,n) -- gap over x; 0..1
  d, n = 0, TINY
  for _, c in ipairs(i.cols.x) do
    d = d + c.dist(c, row1[c.at], row2[c.at]) ^ the.p
    n = n + 1 end
  return (d / n) ^ (1 / the.p) end

function TBL.disty(i,row,    d) -- gap to heaven; 0=best
  d = sum(i.cols.y, function(y)
        return abs(y.norm(y, row[y.at]) - y.heaven) ^ the.p end)
  return (d / #i.cols.y) ^ (1 / the.p) end

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
  rows = keysort(rows,
           function(r) return i.projx(i,r,a,b,c) end)
  n = floor(#rows / 2)
  return a, b, {slice(rows, 1, n)}, {slice(rows, n + 1)} end

function Node(tbl,rows,    i,a,b,west,east) -- tree of halves
  rows = rows or tbl.rows
  i = new(NODE, {here=tbl.clone(tbl, rows),
                 a=nil, b=nil, west=nil, east=nil})
  if #rows >= 2 * the.stop then
    a, b, west, east = tbl.halve(tbl, rows)
    i.a, i.b = a, b
    if #west > 0 and #east > 0 then
      i.west, i.east = Node(tbl,west), Node(tbl,east) end end
  return i end

function NODE.leaf(i,row,    t) -- walk row down to its leaf
  while i.west do
    t = i.here
    i = t.distx(t, row, i.a) <= t.distx(t, row, i.b)
        and i.west or i.east end
  return i end

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
    while j < #ys and ys[j+1] <  x do j = j + 1 end
    while k < #ys and ys[k+1] <= x do k = k + 1 end
    gt = gt + j; lt = lt + #ys - k end
  return abs(gt - lt) / (#xs * #ys) end

function same(xs,ys,Cohen,Ks,Cliffs) -- similar evidence?
  xs, ys = sorted(xs), sorted(ys)
  return cohen(xs, ys)    < (Cohen or 0.2) 
         or ks(xs, ys)    < (Ks or 1.36)
         or cliffs(xs,ys) <= (Cliffs or 0.197) end

function ranks(d,big,    sign,out,win,rank,best)
  sign = big and -1 or 1        -- same-as-champion share
  out, win, rank, best = {}, {}, -1, nil
  for _, k in ipairs(keysort(keys(d),
                function(k) return sign * med(d[k]) end)) do
    if best == nil or not same(d[best], d[k]) then
      rank, best = rank + 1, k end
    if rank == 0 then win[1+#win] = k end
    out[k] = rank end
  return {winners=win, ranks=out} end

--## lists ------------------------------------------------------
function map(t,f,    u) -- f over values; keeps order
  u = {}; for _, v in pairs(t) do u[1+#u]=f(v) end; return u end

function sum(t,f,    n) -- add f(v) over values
  n = 0; for _, v in pairs(t) do n = n + f(v) end; return n end

function keys(t,skip,    u) -- sorted keys; skip prefix?
  u = {}
  for k in pairs(t) do
    if not (skip and tostring(k):sub(1,1) == skip) then
      u[1+#u] = k end end
  return keysort(u, tostring) end

function med(t,    s) -- median (sorts a copy first)
  s = sorted(t); return s[#s // 2 + 1] end

function sorted(t,f,    s) -- sorted copy; f optional
  s = {}; for at, v in ipairs(t) do s[at] = v end
  table.sort(s, f); return s end

function keysort(t,f,    px,ix) -- sort by f(v); stable,
  px, ix = {}, {}               -- so ties keep input order
  for at, v in ipairs(t) do px[v], ix[v] = f(v), at end
  return sorted(t, function(u,v)
           if px[u] == px[v] then return ix[u] < ix[v] end
           return px[u] < px[v] end) end

function argmax(t,f,    hi,n,x) -- the v w/ biggest f(v)
  hi = -math.huge                 -- first winner keeps ties
  for _,v in ipairs(t) do n=f(v); if n>hi then hi,x=n,v end end
  return x end

function iter(src,    at) -- iterate a list or a function
  if type(src) == "function" then return src end
  at = 0; return function() at = at + 1; return src[at] end end

function shuffle(lst,    t,j) -- random re-order; copies first
  t = {}; for at, v in ipairs(lst) do t[at] = v end
  for at = #t, 2, -1 do
    j = math.random(at); t[at],t[j] = t[j],t[at] end
  return t end

function some(lst,k,    t) -- k items at random (all, if k big)
  t = shuffle(lst)
  for at = #t, min(k, #t) + 1, -1 do t[at] = nil end
  return t end

function show(t,    u,v) -- ":k v" pairs, sorted, no _keys
  u = {}
  for _,k in ipairs(keys(t, "_")) do
    v = t[k]
    if type(v) == "table" then v = show(v) end
    if type(v) == "number" and v % 1 ~= 0 then
      v = ("%."..the.round.."f"):format(v) end
    u[#u+1] = ":"..tostring(k).." "..tostring(v) end
  return "{"..table.concat(u, " ").."}" end

function new(kl,t) -- class table is also its metatable
  kl.__index = kl; kl.__tostring = show
  return setmetatable(t, kl) end

--## start-up ---------------------------------------------------
function cli(d,    v) -- --key=val flags update settings
  for k in pairs(d) do
    for _, s in ipairs(arg or {}) do
      v = s:match("^%-%-" .. k .. "=(.*)")
      if v then d[k] = thing(v) end end end
  return d end

function main(g,    run,todo) -- run test_w per bare word w
  cli(the)
  run = function(w)
    math.randomseed(the.seed)
    return (g["test_" .. w] or function()
              print("?", w, "(no such test)") end)() end
  todo = map(arg or {}, function(s)
           if not s:find"^%-" then return s end end)
  map(#todo > 0 and todo or {"all"}, run) end

return _ENV
