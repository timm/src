#!/usr/bin/env lua
-- Tutorial and tests for luamine (modules: lib, luamine,
-- lapps). One -eg file per engine file, loaded below in
-- tutorial order; prose lives in --[[ markdown ]] blocks;
-- each demo is one eg["--name"] returning chk cases.
-- Run any demo by flag:  lua luamine-eg.lua --all --tree

local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local l    = require"lib"
local m    = require"luamine"
local a    = require"lapps"
local the  = l.the
local rand = math.random

local help = [[
# luamine-eg: tutorial and tests for luamine
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
      --seed=1     RNG seed
      --labels=32  tree demo: rows sampled before build
## egs
  --lists     sort/list/slice/copy/shuffle/keysort/argmin
  --tabulate  aligned table demo
  --rand      pickDict/irwinHall
  --stats     welford/sd/mode/ent/bisect
  --sames     cliffs/ks/pooledSd/same/topTier
  --confuse   confusion matrix demo
  --str       thing coercion, o pretty-print
  --csv       stream csv rows
  --cli       help-text mining
  --cols      Sym/Num/adds + header parse
  --data      Data ctor, clone, centroid, dxdy
  --body      iter csv rows (skip header)
  --dist      distx/disty/near
  --cuts      cut emit/apply + bestCut
  --tree      bi-tree build/show/relevant/leafStats
  --ftree     fastmap bi-tree + poles
  --bayes     like/likes
  --mutate    pick/picks/extrapolate
  --kmeans    kmeans cluster
  --kpp       kmeans++ centroid pick
  --classify  incremental NB test-then-train
  --acquire   active learning (Bayes scorer)
  --sample    gen N synth rows via ftree + DE per leaf
  --anomaly   ftree + 1-NN-in-leaf dist CDF (tail=anomaly)
  --bob       split + acquire + tree + check -> best row
  --acq       batch CLI: 1 csv -> "win disty file"
  --ga        genetic algorithm
  --de        differential evolution
  --sa        simulated annealing (1+1)
  --ls        local search (1+1)
  --race      race ga+de+sa+ls -> merged best-trace table
]]

-- shared demo helpers, passed to every -eg file
local h = {}

-- Data from CSV if file exists, else nil
function h.loadCsv(file,    f)
  f = io.open(l.path(file))
  if not f then return nil end
  f:close()
  return m.Data.new(l.csv(file)) end

-- synthetic regression Data: n rows, nx X, 1 Y-
function h.mock(n,nx,    k,gen)
  k = 0
  gen = function(    t)
    k = k + 1
    if k == 1 then
      t={}; for i=1,nx do t[i]="X"..i end
      t[nx+1]="Y-"; return t end
    if k <= n+1 then
      t={}; for i=1,nx do t[i]=rand() end
      t[nx+1]=rand(); return t end end
  return m.Data.new(gen) end

-- the.train CSV if present, else mock
function h.pickData(nRow,nx)
  return h.loadCsv(the.train) or h.mock(nRow or 200, nx or 6) end

-- synthetic Data: nx X cols + class!/numeric y
function h.mock64(rows,nx,ylabel,    n,gen)
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
  return m.Data.new(gen) end

-- train CSV if readable, else mock64
function h.egData(    f)
  f = io.open(l.path(the.train))
  if not f then return h.mock64() end
  f:close()
  return m.Data.new(l.csv(the.train)) end

-- race opts, print table, assert improvement
function h.runRace(data, opts,    d)
  d = a.report(data, a.race(data, opts))
  return l.chk({"some rows",#d > 0,true},
               {"improved",#d>0 and d[#d]<=d[1],true}) end

local eg = {}

-- ## list-eg
--[[
## Lists

Tiny functional helpers underneath everything else: sort,
slice, copy, shuffle, keysort (decorate-sort-undecorate),
argmin, and an aligned-table printer. Notice keysort: one
call turns "sort by any feature" into a one-liner.

| call | returns | what |
|------|---------|------|
| `l.keysort(t,fn)` | list | sorted by fn-derived key |
| `l.slice(t,lo,hi)` | list | negatives count from end |
| `l.argmin(t,fn)` | index | min-by-fn item |
]]

eg["--lists"] = function(    t,u)
  t = l.shuffle{3,1,2,5,4}
  u = l.sort(l.list{a=1,b=2,c=3})
  return l.chk({"shuffle",#t,5},
    {"sort",l.sort(l.copy(t))[1],1},
    {"list",u[1]..","..u[3],"1,3"},
    {"slice",l.slice({10,20,30,40,50},2,-2)[3],40},
    {"keysort",l.keysort({{1},{0},{2}},l.nth(1))[1][1],0},
    {"argmin",
      l.argmin({30,10,50},function(x) return x end),2}) end

eg["--tabulate"] = function()
  l.tabulate({{"name","age","note"}, {"Alice","30","short"},
              {"Bob","9","longer note here"}}, {"<",">","<"})
  return true end

-- ## rand-eg
--[[
## Reproducible randomness

A portable Park-Miller generator replaces Lua's stock RNG,
so seeded runs match across machines (and across languages:
ezr2 carries a python twin). `pickDict` rolls a weighted
roulette wheel; `irwinHall` fakes a normal sample from
three uniforms.

| call | returns | what |
|------|---------|------|
| `l.rand(n)` | 0..1 or 1..n | seeded random |
| `l.pickDict(d)` | key | weighted by d's counts |
| `l.irwinHall()` | float | ~normal, mean 0, sd 1 |
]]

eg["--rand"] = function(    d,c,k,n,mu,m2)
  d,c = {a=1,b=10,c=100}, {a=0,b=0,c=0}
  for _=1,1000 do k=l.pickDict(d); c[k]=c[k]+1 end
  n,mu,m2 = 0,0,0
  for _=1,2000 do n,mu,m2 = l.welford(l.irwinHall(),n,mu,m2) end
  return l.chk({"pickDict",c.c>c.b and c.b>c.a,true},
               {"irwin mu~0",mu,0,0.1},
               {"irwin sd~1",l.sd(n,m2),1,0.1}) end

-- ## stats-eg
local rand = math.random

--[[
## Stats, and when do two results differ?

Welford folds values one at a time (no list kept); mode and
entropy summarize counts. Then the conservative equality:
`same` needs median-gap AND cliffs AND ks to agree, and
`topTier` keeps every treatment statistically level with
the best. Notice the demo: two same-distribution samples
tier together; the shifted one drops out.

| call | returns | what |
|------|---------|------|
| `l.welford(v,n,mu,m2)` | n,mu,m2 | online update |
| `l.same(xs,ys,...)` | bool | all three tests agree |
| `l.topTier(dict)` | dict | keys level with the best |
]]

eg["--stats"] = function(    n,mu,m2)
  n,mu,m2 = 0,0,0
  for _,v in ipairs{1,2,3,4,5} do
    n,mu,m2 = l.welford(v,n,mu,m2) end
  return l.chk({"mu",mu,3}, {"sd",l.sd(n,m2),1.5811,1E-3},
    {"mode",l.mode{a=1,b=5,c=2},"b"},
    {"ent",l.ent{a=1,b=1,c=1,d=1},2,1E-9},
    {"bisect",l.bisect({1,2,2,3,5,8},2),3}) end

eg["--sames"] = function(    mk,x,y,z,tier)
  mk = function(off,    u) u={}
    for _=1,50 do u[1+#u]=rand()+off end; return u end
  x,y,z = mk(0), mk(0), mk(5)
  tier = l.topTier({a=x,b=y,c=z}, nil,
                   the.eps, the.cliffs, the.ksconf)
  return l.chk(
    {"cliffs",l.cliffsDelta({1,2,3},{10,11,12}),1},
    {"ks",l.ks({1,2,3},{10,11,12}),1},
    {"pooledSd",l.pooledSd({1,2,3,4,5},{1,2,3,4,5}),1.5811,1E-3},
    {"same",l.same(x,y,the.eps*l.pooledSd(x,y),
                   the.cliffs,the.ksconf),true},
    {"diff",l.same(x,z,the.eps*l.pooledSd(x,z),
                   the.cliffs,the.ksconf),false},
    {"tier a+b",tier.a~=nil and tier.b~=nil,true},
    {"tier no c",tier.c,nil}) end

-- ## confuse-eg
--[[
## Scoring a classifier

Count (want,got) pairs into a confusion matrix; read back
per-klass accuracy, precision, false alarm and recall.

| call | returns | what |
|------|---------|------|
| `Confuse.new(file)` | cf | empty matrix |
| `cf:add(want,got)` | -- | count one prediction |
| `cf:show()` | -- | tn/fn/fp/tp + derived stats |
]]

eg["--confuse"] = function(    cf)
  cf = l.Confuse.new("data.csv")
  for _=1,50 do cf:add("yes","yes") end
  for _=1, 5 do cf:add("yes","no")  end
  for _=1, 3 do cf:add("no","yes")  end
  for _=1,40 do cf:add("no","no")   end
  cf:show(); return true end

-- ## str-eg
--[[
## Strings and files

`thing` coerces csv cells (bool, number, else string); `o`
pretty-prints anything with sorted dict keys; `csv` streams
typed rows from a file, `path` expanding a leading $MOOT.

| call | returns | what |
|------|---------|------|
| `l.thing(s)` | bool,num,str | coerce one cell |
| `l.o(x)` | str | pretty print |
| `l.csv(file)` | iterator | typed rows |
]]

eg["--str"] = function()
  return l.chk(
    {"int",l.thing"42",42},   {"bool",l.thing"true",true},
    {"str",l.thing"hi","hi"}, {"float",l.o(1.5),"1.50"},
    {"dict",l.o{a=1,b=2},"{a=1, b=2}"},
    {"list",l.o{1,2,3},"{1, 2, 3}"}) end

eg["--csv"] = function(    tmp,f,rows)
  tmp = os.tmpname()
  f = io.open(tmp,"w"); f:write("a,b,c\n1,2,3\n"); f:close()
  rows = {}
  for r in l.csv(tmp) do rows[1+#rows]=r end
  os.remove(tmp)
  return l.chk({"#rows",#rows,2},
    {"head",rows[1][1],"a"}, {"cell",rows[2][3],3}) end

-- ## cli-eg
--[[
## The command line

Help text is the single source of truth: `section` pulls a
"## name" block out of it; `boot` seeds `the` from the
options found there; `main` maps --flag val onto `the` and
runs egs by name.

| call | returns | what |
|------|---------|------|
| `l.section(text,name)` | str | body of "## name" |
| `l.boot(eg,b4,name,help)` | -- | seed the; maybe CLI |
]]

eg["--cli"] = function(    txt,opts)
  txt = "# t\n## options\n  --zz=23  a knob\n## egs\n  --x  y"
  opts = l.section(txt,"options")
  return l.chk({"section",opts:find"zz" ~= nil,true},
               {"egs",l.section(txt,"egs"):find"%-%-x" ~= nil,
                true},
               {"the seeded",the.seed ~= nil,true}) end

-- ## cols-eg
local Sym,Cols = m.Sym, m.Cols

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
  sym  = m.adds({"a","a","b","a","c"}, Sym.new())
  num  = m.adds{1,2,3,4,5}
  cols = Cols.new{"Age","name","Mpg+","Wt-","statusX"}
  return l.chk({"sym mid",sym:mid(),"a"},
    {"sym spread>0",sym:spread()>0,true},
    {"num mid",num:mid(),3},
    {"num sd",num:spread(),1.5811,1E-3},
    {"? skip",num:add("?"),"?"},
    {"#x",#cols.x,2}, {"#y",#cols.y,2},
    {"goal+",cols.all[3].goal,1}, {"goal-",cols.all[4].goal,0},
    {"skipX",cols.all[5].goal,nil}) end

-- ## data-eg
local Data = m.Data

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
## Streaming rows

Sometimes we want the rows without the header. `body`
returns an iterator that has already consumed line one.
The demo writes a three-row csv, streams it back, counts.

| call | returns | what |
|------|---------|------|
| `m.body(file)` | iterator | csv rows, header skipped |
]]

eg["--body"] = function(    tmp,f,n)
  tmp = os.tmpname()
  f = io.open(tmp,"w")
  f:write("a,b\n1,2\n3,4\n5,6\n"); f:close()
  n = 0; for _ in m.body(tmp) do n=n+1 end; os.remove(tmp)
  return l.chk({"body rows", n, 3}) end

-- ## dist-eg
local Data = m.Data

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
| `m.distx(cols,r1,r2,p)` | 0..1 | over x cols |
| `m.disty(cols,row,p)` | 0..1 | 0 = ideal goals |
| `m.near(cols,query,rows)` | rows | sorted by distx |
]]

eg["--dist"] = function(    data,goals)
  data = Data.new{{"X1","X2"},{1,1},{5,5},{9,9}}
  goals = Data.new{{"X1","Mpg+","Wt-"},
    {1,40,1500},{2,30,2000},{3,20,2500},{4,10,3000}}
  return l.chk(
    {"self=0",m.distx(data.cols,{1,1},{1,1},the.p),0},
    {"far>near",m.distx(data.cols,{1,1},{9,9},the.p)
              > m.distx(data.cols,{1,1},{5,5},the.p),true},
    {"1-NN",m.near(data.cols,{4,4},data.rows,the.p)[1][1],5},
    {"dBest<dWorst",m.disty(goals.cols,{1,40,1500},the.p)
                  < m.disty(goals.cols,{4,10,3000},the.p),
     true})
  end

-- ## cut-eg
local floor,rand = math.floor, math.random
local Data = m.Data

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
| `m.bestCut(cols,rows,y)` | cut | min size-wtd spread |
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
  best = m.bestCut(data.cols, data.rows,
                   function(r) return r[#r] end)
  the.bins = was
  return l.chk({"cut val",cuts[1].val,3}, {"split",#ls+#rs,5},
    {"finds X1",best.txt,"X1"}, {"cut ~67",best.val,67,8}) end

-- ## tree-eg
local Sym = m.Sym

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
| `m.show(node,cols)` | -- | print aligned table |
| `m.relevant(node,row)` | rows | that row's leaf |
| `m.leafStats(node,fn)` | num | fold over leaves |
]]

eg["--tree"] = function(    data,root,y,count,ls)
  data = h.egData()
  data = data:clone(l.slice(l.shuffle(l.copy(data.rows)),
                            1, the.labels))
  y = function(r) return r[#r] end
  root = data:tree(y, Sym.new, the.leaf)
  m.show(root, data.cols)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  ls = m.leafStats(root)
  return l.chk({"#rows",count(root),#data.rows},
    {"leaves>0",ls.n>0,true},
    {"relevant",#m.relevant(root,data.rows[1])>0,true}) end

--[[
## Trees, unsupervised

`ftree` grows the same shape of tree without ever reading a
y column: find two far rows (`poles`, via fastmap), project
everything onto the line between them, split on that.
Notice the promise this makes: structure gets found for
free; labels are only spent later, on the leaves we like.

| call | returns | what |
|------|---------|------|
| `m.poles(d,rows)` | a,b | two far rows |
| `d:ftree(leaf,p,cap)` | node | y never consulted |
]]

eg["--ftree"] = function(    data,p1,p2,root,count)
  data = h.egData()
  p1,p2 = m.poles(data:dxdy(), data.rows)
  root = data:ftree(the.leaf, the.p, #data.rows)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  return l.chk({"poles differ",p1 ~= p2,true},
    {"#rows",count(root),#data.rows},
    {"is tree",root.at~=nil or root.leaf,true}) end

-- ## bayes-eg
local huge = math.huge
local Sym,Num,Data = m.Sym, m.Num, m.Data

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
| `m.like(col,v,prior)` | prob | P(v given col) |
| `m.likes(data,row,n,k)` | log prob | row given class |
]]

eg["--bayes"] = function(    s,n,data,got)
  s = m.adds({"a","a","b"}, Sym.new"k")
  n = m.adds({1,2,3,4,5}, Num.new"Y")
  data = Data.new{{"X1","X2","class!"},
    {1,1,"lo"},{1,2,"lo"},{2,1,"lo"},
    {9,9,"hi"},{9,8,"hi"},{8,9,"hi"}}
  got = m.likes(data, {1,1,"?"}, 6, 2)
  return l.chk({"sym like>0",m.like(s,"a",0.5) > 0,true},
    {"num like>0",m.like(n,3,0.5) > 0,true},
    {"finite",got==got and got > -huge,true}) end

-- ## mutate-eg
local Data = m.Data

--[[
## Mutation

Optimizers (the app files) need to invent new rows. `pick`
samples one column's distribution; `picks` mutates n random
x cells of a copied row; `extrapolate` is differential
evolution's a + F*(b - c), wrapped back into mu +- 4sd.
Notice what never changes: the y cell of a mutant -- goals
are computed, not guessed.

| call | returns | what |
|------|---------|------|
| `m.pick(col,v)` | value | sample near v (or mid) |
| `m.picks(data,row,n)` | row | mutate n x cells |
| `m.extrapolate(cols,a,b,c,F)` | row | DE blend |
]]

eg["--mutate"] = function(    data,n,row,out,kid)
  data = Data.new{{"X1","X2","Y-"},
    {1,1,10},{2,2,20},{3,3,30},{4,4,40},{5,5,50}}
  n = data.cols.x[1]
  row = {3,3,30}
  out = m.picks(data, row, 2)
  kid = m.extrapolate(data.cols.x,
          data.rows[1], data.rows[3], data.rows[5], the.F)
  return l.chk(
    {"pick in range",m.pick(n,3) <= n.mu+4*n:spread(),true},
    {"picks len",#out,#row}, {"y kept",out[3],row[3]},
    {"kid len",#kid,3}) end

-- ## cluster-eg
--[[
## Clustering

`kmeans` around sampled centroids, error per iteration
(watch it shrink); `kpp` picks smarter starting centroids,
d^2-weighted far from each other.

| call | returns | what |
|------|---------|------|
| `a.kmeans(data,k,iter)` | clusters,errs | k Data + errs |
| `a.kpp(data,k,few)` | rows | k far centroids |
]]

eg["--kmeans"] = function(    data,clusters,errs,n)
  data = h.pickData()
  clusters, errs = a.kmeans(data, 5, 8)
  n = 0; for _,c in ipairs(clusters) do n = n + #c.rows end
  for i,e in ipairs(errs) do
    print(("iter %d  err=%.4f"):format(i,e)) end
  return l.chk({"k clusters",#clusters,5},
               {"all rows kept",n,#data.rows},
               {"err shrinks",errs[#errs] <= errs[1],true}) end

eg["--kpp"] = function(    data,cents)
  data = h.pickData()
  cents = a.kpp(data, 5, 64)
  return l.chk({"k cents", #cents, 5}) end

-- ## classify-eg
local Data = m.Data

--[[
## Classify

Incremental naive bayes, test-then-train: guess each row's
klass from the models so far, score the guess, then learn
the truth. Notice the honesty: every prediction is made
before that row is seen.

| call | returns | what |
|------|---------|------|
| `a.classify(data,wait)` | confuse | scored predictions |
]]

eg["--classify"] = function(    data,cf,n)
  data = h.loadCsv(the.train)
  if not (data and data.cols.klass) then
    data = Data.new{{"X1","X2","klass!"},
      {1,1,"a"},{1,2,"a"},{2,1,"a"},{2,2,"a"},
      {9,9,"b"},{9,8,"b"},{8,9,"b"},{8,8,"b"},
      {1,2,"a"},{9,9,"b"},{2,1,"a"},{8,8,"b"}} end
  cf = a.classify(data)
  cf:show()
  n = 0
  for _,gs in pairs(cf.t) do
    for _,c in pairs(gs) do n = n + c end end
  return l.chk({"cf nonempty", n > 0, true}) end

-- ## acquire-eg
--[[
## Active learning

Labels are dear: `acquire` warm-starts on a few labeled
rows, splits them best/rest, then repeatedly labels the
unlabeled row the Bayes score likes most.

| call | returns | what |
|------|---------|------|
| `a.acquire(data,score)` | data | the labeled few |
| `a.acquireBayes(b,r,row)` | num | like(best)-like(rest) |
]]

eg["--acquire"] = function(    data,lab,was)
  data = h.pickData()
  was, the.start = the.start, 10
  the.budget = 20
  lab = a.acquire(data, a.acquireBayes)
  the.start = was
  return l.chk({"labeled grew", #lab.rows > 10, true}) end

-- ## sample-eg
--[[
## Synthesis and anomalies

`sample` invents rows by DE-blending three real rows per
ftree leaf; `anomalyDetector` calibrates a 1-NN-in-leaf
distance CDF, so tails mark anomalies. Notice the cross
check: most synthetic rows should NOT look anomalous.

| call | returns | what |
|------|---------|------|
| `a.sample(data,N)` | rows | N synthetic rows |
| `a.anomalyDetector(data)` | fn | row -> CDF 0..1 |
]]

eg["--sample"] = function(    data,synth,det,bad)
  data  = h.pickData()
  synth = a.sample(data, 50)
  det   = a.anomalyDetector(data)
  bad   = 0
  for _,r in ipairs(synth) do
    local cdf = det(r)
    if cdf < 0.1 or cdf > 0.9 then bad = bad + 1 end end
  l.say(("anomalous synth: %d/%d\n"):format(bad, #synth))
  return l.chk({"n synth",#synth,50},
               {"row len",#synth[1],#data.cols.all},
               {"mostly sane",bad < #synth/2,true}) end

eg["--anomaly"] = function(    data,det,known,outlier)
  data  = h.pickData()
  det   = a.anomalyDetector(data)
  known = data.rows[1]
  outlier = l.copy(known)
  for _,c in ipairs(data.cols.x) do
    if c.mu then outlier[c.at] = 1E6 end end
  return l.chk({"known in body",
                det(known) > 0.1 and det(known) < 0.9, true},
               {"outlier tail", det(outlier) > 0.9, true}) end

-- ## bob-eg
local Num = m.Num

--[[
## Someplace cool: the whole rig

`bob` is the pipeline: split the rows, acquire labels on
the train half, tree the labels, rank the unseen test half,
check the top few. `--acq` batches it: one csv in, one
"win disty file" line out.

| call | returns | what |
|------|---------|------|
| `a.bob(data,score)` | row,dxdy | best unseen test row |
]]

eg["--bob"] = function(    data,best,d)
  data = h.pickData()
  the.budget = 20
  the.start = 10
  best, d = a.bob(data)
  return l.chk({"bob is row",best ~= nil,true},
               {"win number",type(d.win(best)),"number"}) end

eg["--acq"] = function(    data,win,dy,best,d,ok,err)
  ok, err = pcall(function()
    data = h.loadCsv(the.train)
    if not data then error("missing file") end
    win, dy = Num.new(), Num.new()
    for _=1,the.repeats do
      best, d = a.bob(data)
      win:add(d.win(best))
      dy:add(m.disty(data.cols, best, the.p)) end
    print(string.format("%4.0f  %.4f  %s",
                        win.mu, dy.mu, the.train)) end)
  if not ok then print(string.format("ERR   ---     %s  # %s",
                                     the.train, err)) end
  return true end

-- ## ga-eg
--[[
## Genetic algorithm

Mutate, tournament select, crossover; the tracker snaps
every kid to its nearest real row and logs each new global
best.

| call | returns | what |
|------|---------|------|
| `a.ga(data,better)` | stepper | one call = one gen |
]]

eg["--ga"] = function(    data)
  data = h.pickData()
  the.np, the.cr, the.gens = 50, 0.25, 50
  return h.runRace(data, {{"ga", a.ga(data, a.knn(data))}}) end

-- ## de-eg
--[[
## Differential evolution

DE/rand/1: blend three distinct rows per parent; the kid
replaces its parent when the oracle scores it better.

| call | returns | what |
|------|---------|------|
| `a.de(data,oracle)` | stepper | one call = one gen |
]]

eg["--de"] = function(    data)
  data = h.pickData()
  the.de_iter, the.np = 30, 20
  return h.runRace(data, {{"de", a.de(data)}}) end

-- ## search-eg
--[[
## (1+1) search

One current solution, one mutant at a time. `sa` accepts
worse kids early (metropolis, cooling); `ls` is greedy with
restarts. Both ride the same `oneplus1` stepper.

| call | returns | what |
|------|---------|------|
| `a.sa(data)` | stepper | simulated annealing |
| `a.ls(data)` | stepper | greedy local search |
]]

eg["--sa"] = function(    data)
  data = h.pickData()
  return h.runRace(data, {{"sa", a.sa(data)}}) end

eg["--ls"] = function(    data)
  data = h.pickData()
  return h.runRace(data, {{"ls", a.ls(data)}}) end

-- ## race-eg
--[[
## Race them all

Run ga, de, sa and ls under one eval budget; merge their
logs into one global-best timeline. The printed table is
the story: who found what, when, and how good.

| call | returns | what |
|------|---------|------|
| `a.race(data,opts)` | log | merged best timeline |
| `a.report(data,log)` | dists | print + return distys |
]]

eg["--race"] = function(    data)
  data = h.pickData()
  the.np, the.cr, the.gens, the.de_iter = 50, 0.25, 50, 30
  return h.runRace(data, {
    {"ga", a.ga(data, a.knn(data))},
    {"de", a.de(data)},
    {"sa", a.sa(data)},
    {"ls", a.ls(data)}}) end

-- seed the from this help's options; dispatch if main
for k,v in l.section(help,"options"):gmatch"%-%-(%w+)=(%S+)" do
  the[k] = l.thing(v) end
if (arg[0] or ""):find("luamine-eg.lua", 1, true) then
  l.main(eg, b4, "luamine-eg", help) end
