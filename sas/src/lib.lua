#!/usr/bin/env lua
-- lib.lua: lib.py said in Lua, function for function.
-- Cells, columns, tables, distance, and the statistics
-- that police every claim in this book. One file: the
-- about.py knobs live in `the` below. Columns index from
-- 1, not 0; everything else mirrors the Python.
local abs,exp,log,sqrt = math.abs,math.exp,math.log,math.sqrt
local max,min,floor    = math.max,math.min,math.floor
local thing,csv,shuffle,some,count,welford,entropy,mid
local div,norm,add,adds,Num,Sym,Col,Tbl,Node,distx,disty
local TINY = 1e-32
local lib  = {}

local the = {
  seed   = 1234567891,     -- every random stream starts here
  p      = 2,              -- minkowski coefficient
  few    = 128,            -- sample size for cheap guesses
  stop   = 32,             -- min rows before a split halts
  cohen  = 0.2,            -- same if mid gap under this
  ks     = 1.36,           -- ks 5% critical multiplier
  cliffs = 0.197,          -- small rank effect ceiling
  file = "data/auto93.csv" } -- default table (via MOOT)

--## lists -----------------------------------------------------
local function map(t, f,   u) -- f over values; keeps order
  u = {}; for _, v in pairs(t) do u[1+#u] = f(v) end
  return u end

local function sum(t, f,   n) -- add f(v) over values
  n = 0; for _, v in pairs(t) do n = n + f(v) end
  return n end

--## cells ------------------------------------------------------
function thing(s) -- string to number, bool, or string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s=="True" or (s~="False" and s) end

function csv(file,    f) -- stream rows of coerced cells
  f = io.lines(file)
  return function(    t)
    for line in f do
      local l = line:gsub("%%.*",""):match"^%s*(.-)%s*$"
      if l ~= "" then
        t={}; for s in l:gmatch"[^,]+" do t[#t+1] = thing(s) end
        return t end end end end

--## random -----------------------------------------------------
function shuffle(lst,   t,j) -- random re-order; copies first
  t={}; for i, v in ipairs(lst) do t[i] = v end
  for i = #t, 2, -1 do
    j = math.random(i); t[i],t[j] = t[j],t[i] end
  return t end

function some(lst,  k,   t) -- k items at random (all, if k big)
  t = shuffle(lst)
  for i = #t, min(k, #t) + 1, -1 do t[i] = nil end
  return t end

--## columns ----------------------------------------------------
function Num(name, at) -- summary of a numeric column
  name = name or ""
  return {it=Num, at=at or 1, name=name, n=0, mu=0, m2=0,
          heaven = name:find"-$" and 0 or 1} end

function Sym(name, at) -- summary of a symbolic column
  return {it=Sym, at=at or 1, name=name or "", n=0, has={}} end

function Col(name, at) -- column kind from first letter
  return (name:sub(1,1):match"%l" and Sym or Num)(name,at) end

function count(sym, v) -- update symbol counts
  sym.n = sym.n + 1; sym.has[v] = 1 + (sym.has[v] or 0) end

function welford(num, v,    d) -- one-pass update of mu and m2
  num.n = num.n + 1
  d = v - num.mu
  num.mu = num.mu + d / num.n
  num.m2 = num.m2 + d * (v - num.mu) end

function entropy(sym) -- diversity of symbolic counts
  return sum(sym.has, function(n,   p)
    p = n / sym.n; return -p * log(p, 2) end) end

function mid(col) -- center: mean (Num) or mode (Sym)
  if col.it == Num then return col.mu end
  local most, out = -1, nil
  for k, n in pairs(col.has) do
    if n > most then most, out = n, k end end
  return out end

function div(col) -- diversity: sd (Num) or entropy (Sym)
  if col.it == Sym then return entropy(col) end
  return col.n < 2 and 0 or sqrt(max(col.m2,0) / (col.n-1)) end

function norm(col, v) -- v's cdf, via logistic; 0..1
  if v == "?" or col.it == Sym then return v end
  local z = (v - col.mu) / (div(col) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z)))) end

--## tables -----------------------------------------------------
local function iter(src,   i) -- iterate a list or a function
  if type(src) == "function" then return src end
  i=0; return function() i = i + 1; return src[i] end end

function Tbl(src) -- first row names columns; rest is data
  src = iter(src)
  local names, all, x, y = src(), {}, {}, {}
  for at, s in ipairs(names) do
    all[at] = Col(s, at)
    if s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end end
  return adds(src, {it=Tbl, rows={}, mid=nil,
                    cols={names=names, all=all, x=x, y=y}}) end

function add(i, v) -- fold value into col, row into tbl
  if i.it == Tbl then
    i.rows[#i.rows+1] = v; i.mid = nil
    for _, col in ipairs(i.cols.all) do add(col, v[col.at]) end
  elseif v ~= "?" then
    (i.it == Sym and count or welford)(i, v) end
  return v end

function adds(src, col) -- fold list or iterator; Num default
  col = col or Num()
  for v in iter(src or {}) do add(col, v) end
  return col end

local function clone(tbl, rows) -- same header, fresh summaries
  return adds(rows, Tbl{tbl.cols.names}) end

local function mids(tbl) -- return centroid of this tbl
  tbl.mid = tbl.mid or map(tbl.cols.all, mid)
  return tbl.mid end

--## distance ---------------------------------------------------
function distx(tbl,row1,row2,    d,n,a,b,g) --row gap over x;0..1
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
  d= sum(tbl.cols.y, function(y)
           return abs(norm(y, row[y.at]) - y.heaven) ^ the.p end)
  return (d / #tbl.cols.y) ^ (1 / the.p) end

--## clusters ---------------------------------------------------
local function project(tbl, row, a, b, c) -- onto the a-b line
  return (distx(tbl,a,row)^2 + c*c
          - distx(tbl,b,row)^2) / (2*c + TINY) end

local function halve(tbl, rows) -- split on far poles, best 1st
  rows = rows or tbl.rows
  local function far(r)
    local out, most = r, -1
    for _, r2 in ipairs(some(rows, the.few)) do
      local d = distx(tbl, r, r2)
      if d > most then most, out = d, r2 end end
    return out end
  local a = far(rows[math.random(#rows)])
  local b = far(a)
  local c = distx(tbl, a, b)
  if disty(tbl, b) < disty(tbl, a) then a, b = b, a end
  local order = {}
  for _, r in ipairs(rows) do
    order[#order+1] = {project(tbl, r, a, b, c), r} end
  table.sort(order, function(u, v) return u[1] < v[1] end)
  local west, east, n = {}, {}, floor(#order / 2)
  for i, pair in ipairs(order) do
    local t = i <= n and west or east; t[#t+1] = pair[2] end
  return a, b, west, east end

function Node(tbl, rows) -- tree of halves
  rows = rows or tbl.rows
  local node = {it=Node, here=clone(tbl, rows),
                a=nil, b=nil, west=nil, east=nil}
  if #rows >= 2 * the.stop then
    local a, b, west, east = halve(tbl, rows)
    node.a, node.b = a, b
    if #west > 0 and #east > 0 then
      node.west, node.east = Node(tbl,west), Node(tbl,east)
    end end
  return node end

local function leaf(node, row) -- walk row down to its leaf
  while node.west do
    node = distx(node.here, row, node.a)
           <= distx(node.here, row, node.b)
           and node.west or node.east end
  return node end

--## statistics -------------------------------------------------
local function sorted(t)
  local s = {}
  for i, v in ipairs(t) do s[i] = v end
  table.sort(s); return s end

local function cohen(xs, ys) -- mid gap, in units of spread
  local function m(a) return a[floor(#a / 2) + 1] end
  local function spd(a)
    return (a[floor(#a*9/10)+1] - a[floor(#a/10)+1])/2.56 end
  return abs(m(xs) - m(ys)) / ((spd(xs)+spd(ys))/2 + TINY) end

local function ks(xs, ys) -- max cdf gap, in critical units
  local nx, ny = #xs, #ys
  local d, i, j = 0, 0, 0
  while i < nx and j < ny do
    if xs[i+1] <= ys[j+1] then i = i + 1 else j = j + 1 end
    d = max(d, abs(i / nx - j / ny)) end
  return d / ((nx + ny) / (nx * ny)) ^ 0.5 end

local function cliffs(xs, ys) -- rank imbalance; 0..1
  local gt, lt, j, k = 0, 0, 0, 0  -- j,k: #ys sitting <x, <=x
  for _, x in ipairs(xs) do        -- x ascends: j,k only advance
    while j < #ys and ys[j+1] <  x do j = j + 1 end
    while k < #ys and ys[k+1] <= x do k = k + 1 end
    gt = gt + j; lt = lt + #ys - k end
  return abs(gt - lt) / (#xs * #ys) end

local function same(xs, ys) -- any judge under threshold?
  xs, ys = sorted(xs), sorted(ys)
  return cohen(xs, ys) < the.cohen
         or ks(xs, ys) < the.ks
         or cliffs(xs, ys) <= the.cliffs end

local function top(d, big) -- winners; best = least, or most
  local function m(a) local s=sorted(a)
    return s[floor(#s / 2) + 1] end
  local ks_ = {}
  for k in pairs(d) do ks_[#ks_+1] = k end
  table.sort(ks_, function(u, v)
    if big then return m(d[u]) > m(d[v]) end
    return m(d[u]) < m(d[v]) end)
  local out = {}
  for _, k in ipairs(ks_) do
    if #out > 0 and not same(d[out[1]], d[k]) then break end
    out[#out+1] = k end
  return out end

--## start-up ---------------------------------------------------
local function cli(d) -- --key=val flags update settings
  for k in pairs(d) do
    for _, s in ipairs(arg or {}) do
      local v = s:match("^%-%-" .. k .. "=(.*)")
      if v then d[k] = thing(v) end end end
  return d end

local function main(g) -- for each bare word w, run test_w
  cli(the)
  local todo = {}
  for _, s in ipairs(arg or {}) do
    if not s:find"^%-" then todo[#todo+1] = s end end
  if #todo == 0 then todo = {"all"} end
  for _, word in ipairs(todo) do
    math.randomseed(the.seed);
    (g["test_" .. word] or function()
       print("?", word, "(no such test)") end)() end end

for k, v in pairs{the=the, thing=thing, csv=csv,
  shuffle=shuffle, some=some, Col=Col, Num=Num, Sym=Sym,
  count=count, welford=welford, entropy=entropy, mid=mid,
  div=div, norm=norm, Tbl=Tbl, add=add, adds=adds,
  clone=clone, mids=mids, distx=distx, disty=disty,
  project=project, halve=halve, Node=Node, leaf=leaf,
  cohen=cohen, ks=ks, cliffs=cliffs, same=same, top=top,
  cli=cli, main=main} do lib[k] = v end
return lib
