#!/usr/bin/env lua
-- Tutorial and tests for luamine (library: luamine.lua).
-- Prose lives in --[[ markdown ]] blocks; each demo is one
-- eg["--name"] function returning chk cases (tag,got,want).
-- Run any demo by flag:  lua luamine-eg.lua --all --tree

local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local l    = require"lib"
local mine = require"luamine"
local the  = l.the
local Sym,Num,Data,Cols = mine.Sym,mine.Num,mine.Data,mine.Cols
local floor,rand,huge = math.floor, math.random, math.huge

local help = [[
# luamine-eg: tutorial and tests for luamine
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
      --seed=1     RNG seed
## egs
  --cols    Sym/Num/adds + header parse
  --data    Data ctor, clone, centroid, dxdy
  --dist    distx/disty/near
  --cuts    cut emit/apply + bestCut
  --tree    bi-tree build/show/relevant/leafStats
  --ftree   fastmap bi-tree + poles
  --bayes   like/likes
  --mutate  pick/picks/extrapolate
  --body    iter csv rows (skip header)
]]

local eg = {}

--[[
# luamine: AI primitives, from columns to trees

Same ideas as tiny-xai and ezr2, in Lua: summarize columns,
learn distances, cut, grow trees, mutate. Two kinds of data
below: tables tiny enough to check by eye (their rows sit
right in the demo code), and auto93 -- 398 cars, read via
$MOOT -- for the tree demos. Every demo returns chk cases:
tag, got, want; `--all` runs the lot.
]]

-- synthetic Data: nx X cols + class!/numeric y
local function mock64(rows,nx,ylabel,    n,gen)
  rows, nx, ylabel = rows or 64, nx or 2, ylabel or "class!"
  gen = function(    t,s)
    n = (n or 0) + 1
    if n == 1 then
      t = {}
      for i=1,nx do t[i] = "X"..i end
      t[nx+1] = ylabel
      return t end
    if n <= rows+1 then
      t,s = {},0
      for i=1,nx do t[i] = rand(); s = s + t[i] end
      t[nx+1] = ylabel=="class!"
                  and (s<nx/2 and "lo" or "hi") or rand()
      return t end end
  return Data.new(gen) end

-- train CSV if readable, else mock64
local function egData(    f)
  f = io.open(l.path(the.train))
  if not f then return mock64() end
  f:close()
  return Data.new(l.csv(the.train)) end


--[[
## Columns: the atoms

In any table of data there are columns of numbers and
columns of symbols: numbers we can add and average; symbols
we can only count and compare. Fold "a a b a c" into a
`Sym`: mode a. Fold 1..5 into a `Num`: mean 3, sd 1.58.
Then parse a header: uppercase leads make Nums, trailing
+/- mark goals, trailing X is ignored. Notice "?" cells
pass through untouched.

| call | returns | what |
|------|---------|------|
| `Sym.new(s,at)` | sym | counts in has{} |
| `Num.new(s,at)` | num | Welford n,mu,m2 |
| `i:add(v)` | v | fold one value in |
| `i:mid()`, `i:spread()` | value | mode/mean, ent/sd |
| `Cols.new(names)` | cols | typed columns from header |
]]

eg["--cols"] = function(    sym,num,cols)
  sym  = mine.adds({"a","a","b","a","c"}, Sym.new())
  num  = mine.adds{1,2,3,4,5}
  cols = Cols.new{"Age","name","Mpg+","Wt-","statusX"}
  return l.chk({"sym mid",sym:mid(),"a"},
    {"sym spread>0",sym:spread()>0,true},
    {"num mid",num:mid(),3},
    {"num sd",num:spread(),1.5811,1E-3},
    {"? skip",num:add("?"),"?"},
    {"#x",#cols.x,2}, {"#y",#cols.y,2},
    {"goal+",cols.all[3].goal,1}, {"goal-",cols.all[4].goal,0},
    {"skipX",cols.all[5].goal,nil}) end


--[[
## Tables

Five rows, two columns, all visible below. `Data` holds the
rows plus one summary per column; `clone` copies the header
into an empty twin; the centroid is each column's mid.
Notice `dxdy`: it bakes the Minkowski p into x, y and win
functions so later code never threads p around.

| call | returns | what |
|------|---------|------|
| `Data.new(src)` | data | src = rows, iterator, or file |
| `d:clone(rows)` | data | same header, new rows |
| `d.cols:mid()` | list | centroid, cached |
| `d:dxdy(p)` | {x,y,win} | distance views, p baked in |
]]

eg["--data"] = function(    data,b,d,r1,r2)
  data = Data.new{{"X1","X2"},{1,1},{2,2},{3,3},{4,4},{5,5}}
  b = data:clone()
  d = data:dxdy()
  r1,r2 = data.rows[1], data.rows[5]
  return l.chk({"#rows",#data.rows,5},
    {"clone empty",#b.rows,0},
    {"clone hdr",b.cols.all[1].txt,"X1"},
    {"names kept",b.cols.names[2],"X2"},
    {"centroid",data.cols:mid()[1],3},
    {"symmetric",d.x(r1,r2)==d.x(r2,r1),true}) end


--[[
## Distance

Two distances, two jobs. `distx` reads only x columns: how
far apart two rows are before we know their goals. `disty`
reads only y columns: distance to the ideal goals, 0 =
best. In the goals table below, the row (1,40,1500) -- high
mpg, low weight -- must sit nearer heaven than (4,10,3000).
Notice `near`: 1-nearest-neighbour is one keysort away.

| call | returns | what |
|------|---------|------|
| `mine.distx(cols,r1,r2,p)` | 0..1 | over x cols |
| `mine.disty(cols,row,p)` | 0..1 | 0 = ideal goals |
| `mine.near(cols,query,rows)` | rows | sorted by distx |
]]

eg["--dist"] = function(    data,goals)
  data = Data.new{{"X1","X2"},{1,1},{5,5},{9,9}}
  goals = Data.new{{"X1","Mpg+","Wt-"},
    {1,40,1500},{2,30,2000},{3,20,2500},{4,10,3000}}
  return l.chk(
    {"self=0",mine.distx(data.cols,{1,1},{1,1},the.p),0},
    {"far>near",mine.distx(data.cols,{1,1},{9,9},the.p)
              > mine.distx(data.cols,{1,1},{5,5},the.p),true},
    {"1-NN",mine.near(data.cols,{4,4},data.rows,the.p)[1][1],5},
    {"dBest<dWorst",mine.disty(goals.cols,{1,40,1500},the.p)
                  < mine.disty(goals.cols,{4,10,3000},the.p),
     true})
  end

--[[
## Cuts

To explain anything we need splits. A cut is one test:
op(row[at], val). Five visible rows split at X1 <= 3; then
1000 noisy rows where class flips at X1 > 67 -- and
`bestCut` recovers that boundary (~67) without being told.
Notice: the cut search reads only x summaries and a y
function; it never needs to know what y means.

| call | returns | what |
|------|---------|------|
| `col:cuts(rows)` | cuts | candidate tests, one col |
| `cut:apply(rows,y)` | ls,rs,+sums | split both ways |
| `mine.bestCut(cols,rows,y)` | cut | min size-wtd spread |
]]

eg["--cuts"] = function(    data,cuts,ls,rs,best,v,was)
  was, the.bins = the.bins, 2
  data = Data.new{{"X1","name"},
    {1,"a"},{2,"a"},{3,"b"},{4,"b"},{5,"c"}}
  cuts = data.cols.x[1]:cuts(data.rows)
  ls,rs = cuts[1]:apply(data.rows, function(r) return r[1] end)
  the.bins = 10
  data = {{"X1","X2","class!"}}
  for _=1,1000 do
    v = floor(100*rand())
    l.push(data, {v, rand(), v>67 and "a" or "b"}) end
  data = Data.new(data)
  best = mine.bestCut(data.cols, data.rows,
                      function(r) return r[#r] end)
  the.bins = was
  return l.chk({"cut val",cuts[1].val,3}, {"split",#ls+#rs,5},
    {"finds X1",best.txt,"X1"}, {"cut ~67",best.val,67,8}) end


--[[
## Trees, supervised

Recurse the cuts: a tree. Here the running example goes
real: auto93 (via $MOOT), budget-sampled, tree'd on its
last column, printed as an aligned if/else table with the
best (+) and worst (-) leaves marked. Notice the checks:
every row lands in exactly one leaf, and `relevant` routes
a row back to its leaf's rows.

| call | returns | what |
|------|---------|------|
| `d:tree(y,Sumr,leaf)` | node | greedy bi-tree on y |
| `mine.show(node,cols)` | -- | print aligned table |
| `mine.relevant(node,row)` | rows | that row's leaf |
| `mine.leafStats(node,fn)` | num | fold over leaves |
]]

eg["--tree"] = function(    data,root,y,count,ls)
  data = egData()
  data = data:clone(l.slice(l.shuffle(l.copy(data.rows)),
                            1, the.budget))
  y = function(r) return r[#r] end
  root = data:tree(y, Sym.new, the.leaf)
  mine.show(root, data.cols)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  ls = mine.leafStats(root)
  return l.chk({"#rows",count(root),#data.rows},
    {"leaves>0",ls.n>0,true},
    {"relevant",#mine.relevant(root,data.rows[1])>0,true}) end


--[[
## Trees, unsupervised

`ftree` grows the same shape of tree without ever reading a
y column: find two far rows (`poles`, via fastmap), project
everything onto the line between them, split on that.
Notice the promise this makes: structure gets found for
free; labels are only spent later, on the leaves we like.

| call | returns | what |
|------|---------|------|
| `mine.poles(d,rows)` | a,b | two far rows |
| `d:ftree(leaf,p,cap)` | node | y never consulted |
]]

eg["--ftree"] = function(    data,a,b,root,count)
  data = egData()
  a,b = mine.poles(data:dxdy(), data.rows)
  root = data:ftree(the.leaf, the.p, #data.rows)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  return l.chk({"poles differ",a ~= b,true},
    {"#rows",count(root),#data.rows},
    {"is tree",root.at~=nil or root.leaf,true}) end


--[[
## Bayes

Two functions make a naive bayes classifier: `like` scores
one value against one column (frequency for Syms, gaussian
for Nums); `likes` log-sums a whole row against one class's
data. Six visible rows, two obvious classes; the row
(1,1,?) must look "lo". Notice the log-space sums: products
of tiny probabilities underflow, sums of logs do not.

| call | returns | what |
|------|---------|------|
| `mine.like(col,v,prior)` | prob | P(v given col) |
| `mine.likes(data,row,n,k)` | log prob | row given class |
]]

eg["--bayes"] = function(    s,n,data,a)
  s = mine.adds({"a","a","b"}, Sym.new"k")
  n = mine.adds({1,2,3,4,5}, Num.new"Y")
  data = Data.new{{"X1","X2","class!"},
    {1,1,"lo"},{1,2,"lo"},{2,1,"lo"},
    {9,9,"hi"},{9,8,"hi"},{8,9,"hi"}}
  a = mine.likes(data, {1,1,"?"}, 6, 2)
  return l.chk({"sym like>0",mine.like(s,"a",0.5) > 0,true},
    {"num like>0",mine.like(n,3,0.5) > 0,true},
    {"finite",a==a and a > -huge,true}) end


--[[
## Mutation

Optimizers (see lapps.lua) need to invent new rows. `pick`
samples one column's distribution; `picks` mutates n random
x cells of a copied row; `extrapolate` is differential
evolution's a + F*(b - c), wrapped back into mu +- 4sd.
Notice what never changes: the y cell of a mutant -- goals
are computed, not guessed.

| call | returns | what |
|------|---------|------|
| `mine.pick(col,v)` | value | sample near v (or mid) |
| `mine.picks(data,row,n)` | row | mutate n x cells |
| `mine.extrapolate(cols,a,b,c,F)` | row | DE blend |
]]

eg["--mutate"] = function(    data,n,row,out,kid)
  data = Data.new{{"X1","X2","Y-"},
    {1,1,10},{2,2,20},{3,3,30},{4,4,40},{5,5,50}}
  n = data.cols.x[1]
  row = {3,3,30}
  out = mine.picks(data, row, 2)
  kid = mine.extrapolate(data.cols.x,
          data.rows[1], data.rows[3], data.rows[5], the.F)
  return l.chk(
    {"pick in range",mine.pick(n,3) <= n.mu+4*n:spread(),true},
    {"picks len",#out,#row}, {"y kept",out[3],row[3]},
    {"kid len",#kid,3}) end


--[[
## Streaming rows

Sometimes we want the rows without the header. `body`
returns an iterator that has already consumed line one.
The demo writes a three-row csv, streams it back, counts.

| call | returns | what |
|------|---------|------|
| `mine.body(file)` | iterator | csv rows, header skipped |
]]

eg["--body"] = function(    tmp,f,n)
  tmp = os.tmpname()
  f = io.open(tmp,"w")
  f:write("a,b\n1,2\n3,4\n5,6\n"); f:close()
  n = 0; for _ in mine.body(tmp) do n=n+1 end; os.remove(tmp)
  return l.chk({"body rows", n, 3}) end


--[[
## Runner

Seed `the` from this file's options, then dispatch flags --
but only when run as main; a require stays silent.
]]

for k,v in l.section(help,"options"):gmatch"%-%-(%w+)=(%S+)" do
  the[k] = l.thing(v) end
if (arg[0] or ""):find("luamine-eg.lua", 1, true) then
  l.main(eg, b4, "luamine-eg", help) end
