#!/usr/bin/env lua
--[[
y.lua: multi-objective active learning, one file. MIT.
usage: lua y.lua [-Key val ..] [--demo ..] [file.csv]

Read a table of rows, spend a tiny labelling budget on the
rows naive bayes finds promising, then grow a tree over
what you learned and print which x-ranges explain the good
rows. Same story as ezr in one file with no requires, and
251 lines of code against y.lisp's 286, on six bets:

1. No classes, no metatables. A column is a plain table
   and `add` branches once on `num`.
2. `add(c,v,-1)` UNDOES an add. That one primitive buys
   both the O(1) spill of a labelled row from `best` to
   `rest` and the single-pass tree sweep.
3. Every split is numeric. Symbols are ranked by their
   mean y INSIDE the node (Breiman's trick, and optimal
   for variance), so one sweep serves both column kinds.
4. `cut` returns the PARTITION, not a predicate. The tree
   is a report, not a classifier, so `selects?` and the
   re-scan it needs both vanish -- as do `liked` and the
   entropy arm of `div`, which nothing ever called.
5. Guessing takes the ARGMAX of a `Few`-row sample, not a
   sort of it. `acquire` pops one row per step, so the
   rest of that sort was always thrown away -- and a
   sample redrawn every step sees the whole pool, where a
   fixed prefix stares at the same third of it forever.
6. Settings are globals in this module's env, so the cli
   sets one with `_ENV[key]=val` and `--help` lists them
   by scanning for non-functions. No settings table, and
   no help text that can drift from what the code reads.

Locals are the parameters after the wide gap: `f(a,   b,c)`
takes ONE argument, and b,c are scratch. The only `local`
in the file is the _ENV capture, which makes every
`function name` both a definition and an export.
--]]
local _ENV = setmetatable({}, {__index=_G})
if setfenv then setfenv(1, _ENV) end

P, Start, Stop, Few, M, K, Leaf, Seed =
  2, 4, 24, 128, 1, 2, 8, 1234567891
File = "$MOOT/optimize/misc/auto93.csv"

--## lib ------------------------------------------------
-- Strings, csv, $MOOT paths, one shuffle. Nothing here
-- knows what a column is.

fmt = string.format

-- Expand a leading $MOOT: the env var, else ~/gits/moot
function path(s)
  return (s:gsub("%$MOOT", os.getenv"MOOT" or
                 os.getenv"HOME" .. "/gits/moot")) end

-- Text to number, else to trimmed text
function thing(s)
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s end

-- Round to n decimals (0 by default); never printf a float
function rnd(v,n)
  n = 10 ^ (n or 0)
  return math.floor(v*n + 0.5) / n end

-- Csv file to a list of rows of numbers and strings
function csv(f,    t,r)
  t = {}
  for s in io.lines(path(f)) do
    r = {}
    for x in (s..","):gmatch"([^,]*)," do
      r[#r+1] = thing(x) end
    t[#t+1] = r end
  return t end

-- Copy, then Fisher-Yates it; `Seed` makes runs repeat
function shuffle(t,    u,j)
  math.randomseed(Seed)
  u = {}
  for _,x in ipairs(t) do u[#u+1] = x end
  for i = #u,2,-1 do
    j = math.random(i)
    u[i],u[j] = u[j],u[i] end
  return u end

--## columns and tables ----------------------------------
-- Header names carry the whole schema: leading uppercase
-- means numeric, a trailing `+` or `-` marks a goal to
-- maximize or minimize, a trailing `X` says ignore me.
-- Goals are assumed complete; x cells may hold "?".

-- New column, its role read off its header name
function col(s,at)
  return {txt=s, at=at, n=0, mu=0, m2=0, has={},
          w = s:find"%-$" and -1 or 1,
          num = s:find"^%u"} end

-- Rows in, table out; row 1 names the columns
function data(src,    d,c)
  d = {rows={}, all={}, x={}, y={}, nr=0}
  for i,row in ipairs(src) do
    if i > 1 then adds(d,row) else
      d.names = row
      for at,s in ipairs(row) do
        c = col(s,at)
        d.all[at] = c
        if not s:find"X$" then
          table.insert(s:find"[%+%-]$" and d.y or d.x, c)
          end end end end
  return d end

-- Empty table wearing d's columns
function clone(d) return data{d.names} end

-- Update col c with v; inc=-1 undoes an earlier add
function add(c,v,inc,    d)
  if v == "?" then return v end
  inc = inc or 1
  c.n = c.n + inc
  if not c.num then c.has[v] = (c.has[v] or 0) + inc else
    d = v - c.mu
    c.mu = c.mu + inc*d / math.max(1,c.n)
    c.m2 = c.m2 + inc*d * (v - c.mu) end
  return v end

-- Add a row; with inc=-1, pop the last row and return it
function adds(d,row,inc)
  inc = inc or 1
  d.nr = d.nr + inc
  if inc > 0 then d.rows[#d.rows+1] = row
             else row = table.remove(d.rows) end
  for at,c in ipairs(d.all) do add(c,row[at],inc) end
  return row end

--## distance --------------------------------------------
-- One number per row: how far its goals sit from the best
-- corner of goal space. Everything downstream sorts on it.

-- Standard deviation
function sd(c)
  return c.n < 2 and 0
         or (math.max(0,c.m2) / (c.n - 1)) ^ 0.5 end

-- Z-score, squashed into 0..1 by a logistic
function norm(c,v,   z)
  z = math.max(-3, math.min(3,
        (v - c.mu) / (1e-32 + sd(c))))
  return 1 / (1 + math.exp(-1.7*z)) end

-- Distance from a row to heaven (every goal at its best)
function ydist(d,row,    s)
  s = 0
  for _,c in ipairs(d.y) do
    s = s + math.abs(norm(c,row[c.at])
                     - (c.w < 0 and 0 or 1)) ^ P end
  return (s / #d.y) ^ (1/P) end

-- Mean ydist over rows
function ymu(d,rows,    s)
  s = 0
  for _,r in ipairs(rows) do s = s + ydist(d,r) end
  return s / #rows end

-- Mean raw value of each goal over rows
function ymids(d,rows,    t,s)
  t = {}
  for _,c in ipairs(d.y) do
    s = 0
    for _,r in ipairs(rows) do s = s + r[c.at] end
    t[#t+1] = s / #rows end
  return t end

--## acquire ---------------------------------------------
-- Label `Start` random rows, keep the good ones in `best`
-- and the others in `rest`, then repeatedly ask naive
-- bayes which unlabelled row `best` likes most and `rest`
-- likes least. Stop after `Stop` labels.

-- Likelihood of value v in column c
function like(c,v,prior,    s)
  if not c.num then
    return ((c.has[v] or 0) + M*prior) / (c.n + M) end
  s = 1e-32 + sd(c)
  return math.exp(-(v - c.mu)^2 / (2*s*s)) / (2.5066*s) end

-- Log-likelihood that row was drawn from table d
function likes(d,row,nall,nh,    prior,s,v)
  prior = (d.nr + K) / (nall + K*nh)
  s = math.log(prior)
  for _,c in ipairs(d.x) do
    v = row[c.at]
    if v ~= "?" then
      s = s + math.log(math.max(1e-32,
                                like(c,v,prior))) end end
  return s end

-- Pop the row a fresh `Few`-row sample likes best
function pop(d,best,rest,todo,    hi,at,s,i)
  hi = -1e30
  for _ = 1,math.min(#todo,Few) do
    i = math.random(#todo)
    s = likes(best,todo[i],d.nr,2)
        - likes(rest,todo[i],d.nr,2)
    if s > hi then hi,at = s,i end end
  todo[at],todo[#todo] = todo[#todo],todo[at]
  return table.remove(todo) end

-- Row joins `best`, sorted; if best overflows, worst goes
function label(d,best,rest,row,    k)
  adds(best,row)
  table.sort(best.rows,
    function(a,b) return ydist(d,a) < ydist(d,b) end)
  k = math.floor(math.sqrt(1 + best.nr + rest.nr))
  if best.nr > k then adds(rest, adds(best,nil,-1)) end end

-- Spend `Stop` labels; return those rows, best first
function acquire(d,    best,rest,todo,out)
  best, rest = clone(d), clone(d)
  todo = shuffle(d.rows)
  for _ = 1,Start do
    label(d,best,rest,table.remove(todo)) end
  while #todo > 0 and best.nr + rest.nr < Stop do
    label(d,best,rest,pop(d,best,rest,todo)) end
  out = {}
  for _,r in ipairs(best.rows) do out[#out+1] = r end
  for _,r in ipairs(rest.rows) do out[#out+1] = r end
  return out end

--## tree ------------------------------------------------
-- One sweep per x column finds the split that most shrinks
-- the sd of ydist. Ranking symbols by their mean y first
-- means the sweep never has to ask a column its type.

-- Expected sd once rows split into a and b
function xpect(a,b)
  return (sd(a)*a.n + sd(b)*b.n) / (a.n + b.n + 1e-32) end

-- Key each row by col c: its value, or its symbol's mean y
function keys(c,rows,ys,    t,mu,v,z)
  t, mu = {}, {}
  if not c.num then
    for _,r in ipairs(rows) do
      v = r[c.at]
      z = mu[v] or {0,0}
      z[1],z[2] = z[1] + ys[r], z[2] + 1
      mu[v] = z end end
  for _,r in ipairs(rows) do
    v = r[c.at]
    t[#t+1] = {r = r, y = ys[r],
               k = c.num and (v ~= "?" and v or c.mu)
                   or mu[v][1] / mu[v][2]} end
  table.sort(t, function(a,b) return a.k < b.k end)
  return t end

-- Sweep sorted keys; best score, and the index it cuts at
function sweep(xy,    lhs,rhs,b,at,s)
  lhs, rhs, b = col("N",0), col("N",0), 1e30
  for _,p in ipairs(xy) do add(rhs,p.y) end
  for i = 1,#xy - 1 do
    add(lhs, xy[i].y)
    add(rhs, xy[i].y, -1)
    if xy[i].k ~= xy[i+1].k then
      s = xpect(lhs,rhs)
      if s < b then b,at = s,i end end end
  return b,at end

-- Best split over every x col: {score, col, keys, index}
function cut(d,rows,    ys,z,xy,s,at)
  ys, z = {}, {1e30}
  for _,r in ipairs(rows) do ys[r] = ydist(d,r) end
  for _,c in ipairs(d.x) do
    xy = keys(c,rows,ys)
    s,at = sweep(xy)
    if at and s < z[1] then z = {s,c,xy,at} end end
  return z end

-- The two edge labels naming a cut at xy[i]
function edges(c,xy,i,    v,t,u,seen)
  if c.num then
    v = rnd(xy[i].k, 2)
    return c.txt.." <= "..v, c.txt.." > "..v end
  t, u, seen = {}, {}, {}
  for j,p in ipairs(xy) do
    v = tostring(p.r[c.at])
    if not seen[v] then
      seen[v] = 1
      table.insert(j <= i and t or u, v) end end
  table.sort(t)
  table.sort(u)
  return c.txt.." = "..table.concat(t,"|"),
         c.txt.." = "..table.concat(u,"|") end

-- Recurse; a node is {edge, n, ymu, ymids, kid, kid}
function grow(d,rows,edge,    z,c,xy,i,yes,no,e1,e2)
  z = #rows > Leaf and cut(d,rows)
  if z and z[2] then
    c,xy,i = z[2], z[3], z[4]
    yes, no = {}, {}
    for j,p in ipairs(xy) do
      if j <= i then yes[#yes+1] = p.r
                else no[#no+1] = p.r end end
    e1,e2 = edges(c,xy,i)
    return {edge, #rows, ymu(d,rows), ymids(d,rows),
            grow(d,yes,e1), grow(d,no,e2)} end
  return {edge, #rows, ymu(d,rows), ymids(d,rows)} end

--## report ----------------------------------------------
-- The tree exists to be read, so printing it is the whole
-- api: d2h as a percent, then the raw goal means, then
-- the branch that got you here.

-- Every leaf of a tree, left to right
function leafs(t,out,    j)
  out = out or {}
  if #t < 5 then out[#out+1] = t
  else for j = 5,#t do leafs(t[j],out) end end
  return out end

-- Print a tree; + and - flag its best and worst leaf
function show(d,tree,    ls,s,walk)
  ls = leafs(tree)
  table.sort(ls, function(a,b) return a[3] < b[3] end)
  s = "  d2h   n"
  for _,c in ipairs(d.y) do s = s .. fmt("%7s", c.txt) end
  print(s)
  walk = function(t,pre,    j)
    s = fmt("%s %3s %3s", t == ls[1] and "+"
              or t == ls[#ls] and "-" or " ",
            rnd(100*t[3]), t[2])
    for _,v in ipairs(t[4]) do
      s = s .. fmt("%7s", rnd(v)) end
    print(((s.."   "..pre..t[1]):gsub("%s+$","")))
    for j = 5,#t do walk(t[j], pre.."|  ") end end
  walk(tree,"") end

--## start-up --------------------------------------------
-- `main` is the whole app and `go` holds the demos, which
-- `--help` lists. Every `-Key` it prints is a live setting
-- because the help text and the settings are one table.

-- Read f, spend labels, grow the tree, print it
function main(f,    d,lab)
  d = data(csv(f))
  lab = acquire(d)
  print(fmt("%s n=%s mid=%s ezr=%s", f, d.nr,
            rnd(ymu(d,d.rows), 3),
            rnd(ydist(d,lab[1]), 3)))
  show(d, grow(d,lab,"")) end

go = {}

-- Show usage; settings are the non-functions in this env
function go.help(    t,u,k,v)
  t, u = {}, {}
  for k,v in pairs(_ENV) do
    if type(v) ~= "function" and type(v) ~= "table" then
      t[#t+1] = fmt("  -%-6s %s", k, v) end end
  for k in pairs(go) do u[#u+1] = "  --" .. k end
  table.sort(t)
  table.sort(u)
  print("usage: lua y.lua [-Key val ..] [--demo ..]" ..
        " [file.csv]\n\nsettings:\n" ..
        table.concat(t,"\n") .. "\n\ndemos:\n" ..
        table.concat(u,"\n")) end

-- Per-goal n, mu and sd of the whole table
function go.data()
  for _,c in ipairs(data(csv(File)).y) do
    print(fmt("%s n %s mu %s sd %s", c.txt, c.n,
              rnd(c.mu,2), rnd(sd(c),2))) end end

-- Best labelled row's ydist, after spending `Stop` labels
function go.acquire(    d)
  d = data(csv(File))
  print(fmt("ezr %s", rnd(ydist(d, acquire(d)[1]), 3))) end

-- Acquire, grow and show the default table
function go.tree() main(File) end

-- '-Key val' sets a setting, '--demo' runs one, else csv
function cli(    i,s)
  i = 1
  while i <= #arg do
    s = arg[i]
    if s:sub(1,2) == "--" then
      (go[s:sub(3)] or go.help)()
    elseif s:sub(1,1) == "-" then
      _ENV[s:sub(2)] = thing(arg[i+1])
      i = i + 1
    else main(s) end
    i = i + 1 end
  if #arg == 0 then go.help() end end

cli()
