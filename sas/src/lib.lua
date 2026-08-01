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
  cohen  = 0.2,            -- same if mid gap under this
  ks     = 1.36,           -- ks 5% critical multiplier
  cliffs = 0.197,          -- small rank effect ceiling
  file = "data/auto93.csv" } -- default table (via MOOT)

function show(t,    u,v) -- ":k v" pairs, sorted; skips _keys
  u = {}
  for _,k in ipairs(keysort(keys(t), tostring)) do
    if tostring(k):sub(1,1) ~= "_" then
      v = t[k]
      if type(v) == "function" then
        for n,f in pairs(_ENV) do if f==v then v=n end end end
      if type(v) == "table" then v = show(v) end
      u[#u+1] = ":"..tostring(k).." "..tostring(v) end end
  return "{"..table.concat(u, " ").."}" end

o = {__tostring = show}   -- setmetatable(t,o): print(t) works

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

--## random -----------------------------------------------------
function shuffle(lst,    t,j) -- random re-order; copies first
  t = {}; for at, v in ipairs(lst) do t[at] = v end
  for at = #t, 2, -1 do
    j = math.random(at); t[at],t[j] = t[j],t[at] end
  return t end

function some(lst,k,    t) -- k items at random (all, if k big)
  t = shuffle(lst)
  for at = #t, min(k, #t) + 1, -1 do t[at] = nil end
  return t end

--## columns ----------------------------------------------------
function Col(name,at) -- column kind from first letter
  return (name:sub(1,1):match"%l" and Sym or Num)(name,at) end

function Num(name,at) -- summary of a numeric column
  name = name or ""
  return setmetatable({it=Num, at=at or 1, name=name, n=0,
    mu=0, m2=0, heaven = name:find"-$" and 0 or 1}, o) end

function Sym(name,at) -- summary of a symbolic column
  return setmetatable({it=Sym, at=at or 1, name=name or "",
                       n=0, has={}}, o) end

function count(sym,v) -- update symbol counts
  sym.n = sym.n + 1; sym.has[v] = 1 + (sym.has[v] or 0) end

function welford(num,v,    d) -- one-pass update of mu and m2
  num.n  = num.n + 1
  d      = v - num.mu
  num.mu = num.mu + d / num.n
  num.m2 = num.m2 + d * (v - num.mu) end

function entropy(sym) -- diversity of symbolic counts
  return sum(sym.has, function(n,    p)
    p = n / sym.n; return -p * log(p, 2) end) end

function mid(col,    hi,out) -- center: mean or mode
  if col.it == Num then return col.mu end
  hi = -1
  for k, n in pairs(col.has) do
    if n > hi then hi, out = n, k end end
  return out end

function div(col) -- diversity: sd (Num) or entropy (Sym)
  if col.it == Sym then return entropy(col) end
  return col.n < 2 and 0 or sqrt(max(col.m2,0) / (col.n-1)) end

function norm(col,v,    z) -- v's cdf, via logistic; 0..1
  if v == "?" or col.it == Sym then return v end
  z = (v - col.mu) / (div(col) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z)))) end

--## tables -----------------------------------------------------
function Tbl(src,    names,all,x,y) -- row 1 names the columns
  src = iter(src)
  names, all, x, y = src(), {}, {}, {}
  for at, s in ipairs(names) do
    all[at] = Col(s, at)
    if s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end end
  return adds(src, {it=Tbl, rows={}, mid=nil,
                    cols={names=names, all=all, x=x, y=y}}) end

function add(i,v) -- fold value into col, row into tbl
  if i.it == Tbl then
    i.rows[#i.rows+1] = v; i.mid = nil
    for _, col in ipairs(i.cols.all) do add(col, v[col.at]) end
  elseif v ~= "?" then
    (i.it == Sym and count or welford)(i, v) end
  return v end

function adds(src,col) -- fold list or iterator; Num default
  col = col or Num()
  for v in iter(src or {}) do add(col, v) end
  return col end

function clone(tbl,rows) -- same header, fresh summaries
  return adds(rows, Tbl{tbl.cols.names}) end

function mids(tbl) -- return centroid of this tbl
  tbl.mid = tbl.mid or map(tbl.cols.all, mid)
  return tbl.mid end

--## distance ---------------------------------------------------
function distx(tbl,row1,row2,    d,n,a,b,g) -- gap over x; 0..1
  d, n = 0, TINY
  for _, col in ipairs(tbl.cols.x) do
    a, b = row1[col.at], row2[col.at]
    if a == "?" and b == "?" then g = 1
    elseif col.it == Sym then g = a ~= b and 1 or 0
    else
      a, b = norm(col, a), norm(col, b)
      if a == "?" then a = b > 0.5 and 0 or 1 end
      if b == "?" then b = a > 0.5 and 0 or 1 end
      g = abs(a - b) end
    d, n = d + g ^ the.p, n + 1 end
  return (d / n) ^ (1 / the.p) end

function disty(tbl,row,    d) -- gap to heaven; 0=best
  d = sum(tbl.cols.y, function(y)
        return abs(norm(y, row[y.at]) - y.heaven) ^ the.p end)
  return (d / #tbl.cols.y) ^ (1 / the.p) end

--## clusters ---------------------------------------------------
function projx(tbl,row,a,b,c) -- onto the a-b line
  return (distx(tbl,a,row)^2 + c*c
          - distx(tbl,b,row)^2) / (2*c + TINY) end

function halve(tbl,rows,    far,a,b,c,n)
  rows = rows or tbl.rows   -- split on far poles, best first
  far = function(r) return most(some(rows, the.few),
          function(r2) return distx(tbl, r, r2) end) end
  a = far(rows[math.random(#rows)])
  b = far(a)
  c = distx(tbl, a, b)
  if disty(tbl, b) < disty(tbl, a) then a, b = b, a end
  rows = keysort(rows, function(r) return projx(tbl,r,a,b,c) end)
  n = floor(#rows / 2)
  return a, b, {slice(rows, 1, n)}, {slice(rows, n + 1)} end

function Node(tbl,rows,    i,a,b,west,east) -- tree of halves
  rows = rows or tbl.rows
  i = {it=Node, here=clone(tbl, rows),
       a=nil, b=nil, west=nil, east=nil}
  if #rows >= 2 * the.stop then
    a, b, west, east = halve(tbl, rows)
    i.a, i.b = a, b
    if #west > 0 and #east > 0 then
      i.west, i.east = Node(tbl,west), Node(tbl,east) end end
  return i end

function leaf(node,row) -- walk row down to its leaf
  while node.west do
    node = distx(node.here, row, node.a)
           <= distx(node.here, row, node.b)
           and node.west or node.east end
  return node end

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

function same(xs,ys) -- any judge under threshold? lazy or
  xs, ys = sorted(xs), sorted(ys)
  return cohen(xs, ys) < the.cohen
         or ks(xs, ys) < the.ks
         or cliffs(xs, ys) <= the.cliffs end

function top(d,big,    sign,out) -- winners; best = least
  sign, out = big and -1 or 1, {}  -- medians, unless big
  for _, k in ipairs(keysort(keys(d),
                function(k) return sign * med(d[k]) end)) do
    if #out > 0 and not same(d[out[1]], d[k]) then break end
    out[#out+1] = k end
  return out end

--## lists ------------------------------------------------------
function map(t,f,    u) -- f over values; keeps order
  u = {}; for _, v in pairs(t) do u[1+#u]=f(v) end; return u end

function sum(t,f,    n) -- add f(v) over values
  n = 0; for _, v in pairs(t) do n = n + f(v) end; return n end

function keys(t,    u) -- the keys, as a list
  u = {}; for k in pairs(t) do u[1+#u] = k end; return u end

function med(t,    s) -- median (sorts a copy first)
  s = sorted(t); return s[#s // 2 + 1] end

function sorted(t,f,    s) -- sorted copy; f optional
  s = {}; for at, v in ipairs(t) do s[at] = v end
  table.sort(s, f); return s end

function keysort(t,f,    px) -- Schwartzian: sort by f(v),
  px = {}; for _, v in pairs(t) do px[v] = f(v) end
  return sorted(t, function(u,v) return px[u] < px[v] end) end

function most(t,f,    hi,n,x) -- v with the biggest f(v)
  hi = -math.huge
  for _, v in pairs(t) do n=f(v); if n>hi then hi, x=n,v end end
  return x end

function iter(src,    at) -- iterate a list or a function
  if type(src) == "function" then return src end
  at = 0; return function() at = at + 1; return src[at] end end

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

setmetatable(the, o)
return _ENV
