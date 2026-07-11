#!/usr/bin/env lua
-- style: https://github.com/aiez/luamine/blob/main/docs/style.md
local help = [[
# Apps: cluster, classify, acquire, bob, ga, de, sa, ls, race
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
      --seed=1     RNG seed
  --k_cluster=20   #clusters for kmeans/kpp
  --iter=10        kmeans iterations
  --few=128        active-pool cap (kpp + bob)
  --start=10       acquire warm-start labels
  --wait=10        classify warm-up before scoring
  --np=20           GA/DE population
  --gens=100        GA generations
  --tour=5         GA tournament size
  --mut=0.8        GA mutation rate (frac of x-cols)
  --de_iter=30     DE iterations
  --budget=512     label/eval budget (acquire + ga ref pool)
  --budget1=1000   oneplus1/sa/ls eval budget
  --dot=25         evals per progress letter
  --repeats=20     acq shuffle+bob repeats per file
  --check=4        post-acquire top-N to evaluate
  -
## egs
  --kmeans     kmeans cluster
  --kpp        kmeans++ centroid pick
  --classify   incremental NB test-then-train
  --acquire    active learning (Bayes scorer)
  --ga         genetic algorithm
  --de         differential evolution
  --sa         simulated annealing (1+1)
  --ls         local search (1+1)
  --race       race ga+de+sa+ls -> merged best-trace table
  --bob        split + acquire + tree + check -> best row
  --acq        batch CLI: 1 csv -> "win disty file"
  --sample     gen N synth rows via ftree + DE per leaf
  --anomaly    ftree + 1-NN-in-leaf dist CDF (tail=anomaly)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local m    = {}
local l    = require"lib"
local luamine = require"luamine"
local the  = l.the
local floor,min,max = math.floor, math.min, math.max
local rand,huge     = math.random, math.huge
local sqrt,exp      = math.sqrt, math.exp
local Num, Data     = luamine.Num, luamine.Data

-- ## helpers
-- Data from CSV if file exists, else nil
local function loadCsv(file,    f)
  f = io.open(l.path(file))
  if not f then return nil end
  f:close()
  return Data.new(l.csv(file)) end

-- synthetic regression Data: n rows, nx X, 1 Y-
local function mock(n,nx,    k,gen)
  k = 0
  gen = function(    t)
    k = k + 1
    if k == 1 then
      t={}; for i=1,nx do t[i]="X"..i end
      t[nx+1]="Y-"; return t end
    if k <= n+1 then
      t={}; for i=1,nx do t[i]=rand() end
      t[nx+1]=rand(); return t end end
  return Data.new(gen) end

-- the.train CSV if present, else mock
local function pickData(nRow,nx)
  return loadCsv(the.train) or mock(nRow or 200, nx or 6) end

-- ## cluster
-- k clusters around centroids; errs per iter
function m.kmeans(data,k,iter,cents,    out,errs,err)
  k,iter = k or the.k_cluster, iter or the.iter
  cents  = cents or l.anys(data.rows, k)
  errs   = {}
  for _=1,iter do
    out = l.map(cents, function() return data:clone() end)
    for _,r in ipairs(data.rows) do
      out[l.argmin(cents, function(c)
        return luamine.distx(data.cols,c,r,the.p) end)]:add(r) end
    err = 0
    for j,kid in ipairs(out) do
      for _,r in ipairs(kid.rows) do
        err = err + luamine.distx(data.cols,cents[j],r,the.p) end
    end
    errs[1+#errs] = err / #data.rows
    cents = {}
    for _,kid in ipairs(out) do
      if #kid.rows>0 then
        cents[1+#cents] = kid.cols:mid() end end end
  return out, errs end

-- kmeans++ seeding: d^2-weighted far centroids
function m.kpp(data,k,few,    rows,out,t,ws,d,mn)
  rows = data.rows
  k, few = k or the.k_cluster, few or the.few
  out  = { rows[rand(#rows)] }
  while #out < k do
    t, ws = l.anys(rows, min(few, #rows)), {}
    for j=1,#t do
      mn = huge
      for _,c in ipairs(out) do
        d = luamine.distx(data.cols, t[j], c, the.p)
        if d*d < mn then mn = d*d end end
      ws[j] = mn end
    out[1+#out] = t[l.pickDict(ws)] end
  return out end

-- ## classify
-- incremental NB: predict, score, then train
function m.classify(data,wait,    h,cf,nKl,want,best,bs,s)
  wait = wait or the.wait
  h, cf, nKl = {}, l.Confuse.new(), 0
  for i,row in ipairs(data.rows) do
    want = row[data.cols.klass.at]
    if i >= wait and nKl > 0 then
      best, bs = nil, -huge
      for _,klass in ipairs(
          l.sort(l.kap(h, function(k,_) return k end))) do
        s = luamine.likes(h[klass], row, #data.rows, nKl)
        if s > bs then bs, best = s, klass end end
      cf:add(want, best) end
    if not h[want] then h[want] = data:clone(); nKl = nKl+1 end
    h[want]:add(row) end
  return cf end

-- ## acquire
-- acquisition score: like(best) - like(rest)
function m.acquireBayes(best,rest,row,    n)
  n = #best.rows + #rest.rows
  return luamine.likes(best,row,n,2) - luamine.likes(rest,row,n,2) end

-- acquisition score: dist to rest mid - best mid
function m.acquireCentroid(data,best,rest,row)
  return luamine.distx(data.cols,row,rest.cols:mid(),the.p)
       - luamine.distx(data.cols,row,best.cols:mid(),the.p) end

-- rows sorted ascending by disty (best first)
local function byDisty(data,rs)
  return l.keysort(rs,
    function(r) return luamine.disty(data.cols,r,the.p) end) end

-- label first start rows; split best/rest by sqrt
local function warmStart(data,rows,start,    lab,sorted,cap)
  lab    = data:clone(l.slice(rows, 1, start))
  sorted = byDisty(lab, lab.rows)
  cap    = floor(sqrt(#lab.rows))
  return lab,
         data:clone(l.slice(sorted, 1,     cap)),
         data:clone(l.slice(sorted, cap+1)),
         l.slice(rows, start+1) end

-- evict best's worst row when |best|>sqrt(|lab|)
local function capBest(best,rest,lab)
  if #best.rows > floor(sqrt(#lab.rows)) then
    best.rows = byDisty(lab, best.rows)
    rest:add(table.remove(best.rows)) end end

-- active learning: label top-scored unlabeled,
-- recap best, repeat to budget; returns labeled Data
function m.acquire(data,score,budget,start,
                   rows,lab,best,rest,unlab,top)
  score  = score  or m.acquireBayes
  budget = budget or the.budget
  start  = start  or the.start
  rows   = l.shuffle(l.slice(data.rows))
  lab, best, rest, unlab = warmStart(data, rows, start)
  for _=1,budget do
    if #unlab == 0 then break end
    top = l.keysort(unlab,
      function(r) return score(data,best,rest,r) end, l.gt)
    lab:add(top[1]); best:add(top[1])
    unlab = l.slice(top, 2)
    capBest(best, rest, lab) end
  return lab end

-- ## sample / anomaly
-- collect leaf nodes of a tree
local function leaves(node,out)
  out = out or {}
  if node.leaf then out[1+#out] = node
  else leaves(node.left, out); leaves(node.right, out) end
  return out end

-- N synthetic rows: DE-blend 3 rows per ftree leaf
function m.sample(data,N,    tree,leafs,out,leaf,rs)
  N      = N or 100
  tree   = data:ftree()
  leafs  = leaves(tree)
  out    = {}
  while #out < N do
    leaf = leafs[rand(#leafs)]
    if #leaf.rows >= 3 then
      rs = l.anys(leaf.rows, 3)
      out[1+#out] = luamine.extrapolate(
        data.cols.x, rs[1], rs[2], rs[3], the.F) end end
  return out end

-- closure row->CDF of 1-NN-in-leaf dist;
-- calibrated on train rows; tails = anomalies
function m.anomalyDetector(data,    tree,dn,d1)
  tree = data:ftree()
  dn   = Num.new()
  d1   = function(row,    leaf,nn)
    leaf = luamine.relevant(tree, row)
    nn   = luamine.near(data.cols, row, leaf, the.p)[1]
    return nn and luamine.distx(data.cols,row,nn,the.p) or huge end
  for _,row in ipairs(data.rows) do dn:add(d1(row)) end
  return function(row) return dn:norm(d1(row)) end end

-- ## bob
-- pipeline: split, acquire, tree, check top few;
-- returns best test row + dxdy view
function m.bob(data,score,
               d,rows,h,trH,teH,lab,tree,sorted,best)
  score = score or m.acquireBayes
  d     = data:dxdy()
  rows  = l.shuffle(l.copy(data.rows))
  h     = floor(#rows/2)
  trH   = l.slice(l.slice(rows, 1, h), 1, the.few)
  teH   = l.slice(rows, h+1)
  lab   = m.acquire(data:clone(trH), score)
  tree  = lab:tree()
  sorted = l.keysort(teH, function(r)
    return luamine.mu_disty(
      lab.cols, luamine.relevant(tree,r), the.p) end)
  best = l.keysort(l.slice(sorted, 1, the.check), d.y)[1]
  return best, d end

-- ## oracles + Pareto predicates
-- score row by disty of nearest labeled row
local function defaultOracle(data,    ref)
  ref = data.rows
  return function(r)
    return luamine.disty(data.cols,
      luamine.near(data.cols, r, ref, the.p)[1], the.p) end end

-- predicate: direct Zitzler compare (ignores ref)
function m.betters(data)
  return function(a,b,_) return luamine.better(data,a,b) end end

-- predicate: snap a,b to nearest in ref, compare
function m.knn(data)
  return function(a,b,ref)
    return luamine.better(data,
      luamine.near(data.cols,a,ref,the.p)[1],
      luamine.near(data.cols,b,ref,the.p)[1]) end end

-- ## ga
-- GA stepper: mutate, tournament select, crossover;
-- one call = one generation; nil when gens done
function m.ga(data, better,
              mutate,selects,good,crossOver,pop,ref,gen)
  better= better or m.betters(data)
  mutate= function(row)
    return luamine.picks(data, row,
      max(1, floor(the.mut*(#data.cols.x)))) end
  selects= function(t,    u)
    u={}; for _=1,#t do u[1+#u]=good(t) end; return u end
  good= function(t,    a,b)
    a = t[rand(#t)]
    for _ = 2,the.tour do
      b = t[rand(#t)]
      if better(b,a,ref) then a=b end end
    return a end
  crossOver= function(n,parents,    u,mum,dad,cut)
    u={}
    while #u < n do
      mum = parents[rand(#parents)]
      dad = parents[rand(#parents)]
      u[1+#u] = l.copy(mum)
      if rand() < the.cr then
        cut = rand((#data.cols.x) - 1)
        for j,c in ipairs(data.cols.x) do
          u[#u][c.at] =
            (j <= cut and mum or dad)[c.at] end end end
    return u end
  l.shuffle(data.rows)
  pop = l.slice(data.rows, 1, the.np)
  ref = l.slice(data.rows, the.np+1, the.budget - the.np)
  return function()
    gen = (gen or 0) + 1
    if gen <= the.gens then
      pop = crossOver(#pop, selects(l.map(pop,mutate)))
      return gen, pop, ref end end end

-- ## track / race / report
-- drive stepper; snap kids to nearest real row;
-- log each new global best as {who,eval,gen,disty,nbr}
function m.track(name, step, cols, rows,
                 bob,bd,lob,h,mark,nbr,d)
  bob, bd, lob, h, mark = nil, huge, {}, 0, 0
  for gen,kids in step do
    for _,kid in ipairs(kids) do
      h = h + 1
      if h-mark >= the.dot then mark=h; l.say(name:sub(1,1)) end
      nbr = luamine.near(cols, kid, rows, the.p)[1]
      d   = luamine.disty(cols, nbr, the.p)
      if d < bd then
        bd, bob = d, nbr
        lob[1+#lob] = {who=name, eval=h, gen=gen,
                       disty=d, nbr=nbr} end end end
  l.say("\n")
  return bob, lob end

-- run optimizers; merge logs to global-best timeline
function m.race(data, opts,    all, lob, bd)
  all = {}
  for _,o in ipairs(opts) do
    local _, lb = m.track(o[1], o[2], data.cols, data.rows)
    for _,e in ipairs(lb) do all[1+#all] = e end end
  all = l.keysort(all, function(e) return e.eval end)
  lob, bd = {}, huge
  for _,e in ipairs(all) do
    if e.disty < bd then bd = e.disty; lob[1+#lob] = e end end
  return lob end

-- print race table: who/eval/gen/disty + y goals
function m.report(data, lob,    ys,rows,row,dists,mu)
  ys   = data.cols.y
  rows = {{"who","eval","gen","disty"}}
  for _,c in ipairs(ys) do rows[1][1+#rows[1]] = c.txt end
  mu = {}; for _,c in ipairs(ys) do mu[c.at] = c.mu end
  row = {"average","-","-",l.o(luamine.disty(data.cols,mu,the.p))}
  for _,c in ipairs(ys) do row[1+#row] = l.o(c.mu) end
  rows[1+#rows] = row
  dists = {}
  for _,e in ipairs(lob) do
    dists[1+#dists] = e.disty
    row = {e.who, e.eval, l.o(e.gen), l.o(e.disty)}
    for _,c in ipairs(ys) do row[1+#row] = l.o(e.nbr[c.at]) end
    rows[1+#rows] = row end
  l.tabulate(rows, {"<"}, "  ")
  return dists end

-- ## de
-- DE/rand/1 stepper: kid replaces parent if better
function m.de(data,oracle,    y,pop,es,gen)
  y   = oracle or defaultOracle(data)
  pop = l.slice(l.shuffle(l.copy(data.rows)), 1, the.np)
  es  = l.map(pop, y)
  return function(    kids,kid,d,a)
    gen = (gen or 0) + 1
    if gen > the.de_iter then return end
    kids = {}
    for i=1,#pop do
      repeat a = l.anys(pop,3)
      until a[1]~=a[2] and a[1]~=a[3] and a[2]~=a[3]
      kid = luamine.extrapolate(data.cols.x, a[1],a[2],a[3], the.F)
      d = y(kid); kids[1+#kids] = kid
      if d < es[i] then pop[i],es[i] = kid,d end end
    return gen, kids end end

-- ## (1+1) search
-- (1+1) stepper: mutate s, accept(e,d,h,b),
-- restart on stagnation; nil after budget evals
function m.oneplus1(data,mutate,accept,oracle,budget,restart,
                    s,e,h,imp,bd)
  budget  = budget  or the.budget1
  restart = restart or 0
  oracle  = oracle  or defaultOracle(data)
  s, e    = l.copy(data.rows[rand(#data.rows)]), huge
  h, imp, bd = 0, 0, huge
  return function(    kids,d)
    if h >= budget then return end
    kids = mutate(s)
    for _,kid in ipairs(kids) do
      h = h + 1
      d = oracle(kid)
      if accept(e, d, h, budget) then s, e = kid, d end
      if d < bd then bd, imp = d, h end
      if restart > 0 and h - imp > restart then
        s, e, imp =
          l.copy(data.rows[rand(#data.rows)]), huge, h end
      if h >= budget then break end end
    return "", kids end end

-- simulated annealing via oneplus1 (metropolis)
function m.sa(data,oracle,budget,restart,    n)
  n = max(1, floor(the.mut * #data.cols.x))
  return m.oneplus1(data,
    function(s) return { luamine.picks(data, s, n) } end,
    function(e,d,h,b)
      return d < e
          or rand() < exp((e-d) / (1 - h/b + 1E-32)) end,
    oracle, budget, restart) end

-- greedy local search via oneplus1 + restarts
function m.ls(data,oracle,budget,restart,    p,tries)
  p, tries = 0.5, 20
  return m.oneplus1(data,
    function(s,    out,c,kid,reps)
      out, c = {}, data.cols.x[rand(#data.cols.x)]
      reps = (rand() < p) and tries or 1
      for _=1,reps do
        kid = l.copy(s); kid[c.at] = luamine.pick(c, kid[c.at])
        out[1+#out] = kid end
      return out end,
    function(e,d) return d < e end,
    oracle, budget, restart or 100) end

-- ## egs
-- race opts, print table, assert improvement
local function runRace(data, opts,    d)
  d = m.report(data, m.race(data, opts))
  return l.chk({"some rows",#d > 0,true},
               {"improved",#d>0 and d[#d]<=d[1],true}) end

local eg = {}

eg["--kmeans"] = function(    data,clusters,errs,n)
  data = pickData()
  clusters, errs = m.kmeans(data, 5, 8)
  n = 0; for _,c in ipairs(clusters) do n = n + #c.rows end
  for i,e in ipairs(errs) do
    print(("iter %d  err=%.4f"):format(i,e)) end
  return l.chk({"k clusters",#clusters,5},
               {"all rows kept",n,#data.rows},
               {"err shrinks",errs[#errs] <= errs[1],true}) end

eg["--kpp"] = function(    data,cents)
  data = pickData()
  cents = m.kpp(data, 5, 64)
  return l.chk({"k cents", #cents, 5}) end

eg["--classify"] = function(    data,cf,n)
  data = loadCsv(the.train)
  if not (data and data.cols.klass) then
    data = Data.new{{"X1","X2","klass!"},
      {1,1,"a"},{1,2,"a"},{2,1,"a"},{2,2,"a"},
      {9,9,"b"},{9,8,"b"},{8,9,"b"},{8,8,"b"},
      {1,2,"a"},{9,9,"b"},{2,1,"a"},{8,8,"b"}} end
  cf = m.classify(data)
  cf:show()
  n = 0
  for _,gs in pairs(cf.t) do
    for _,c in pairs(gs) do n = n + c end end
  return l.chk({"cf nonempty", n > 0, true}) end

eg["--acquire"] = function(    data,lab,was)
  data = pickData()
  was, the.start = the.start, 10
  the.budget = 20
  lab = m.acquire(data, m.acquireBayes)
  the.start = was
  return l.chk({"labeled grew", #lab.rows > 10, true}) end

eg["--sample"] = function(    data,synth,det,bad)
  data  = pickData()
  synth = m.sample(data, 50)
  det   = m.anomalyDetector(data)
  bad   = 0
  for _,r in ipairs(synth) do
    local cdf = det(r)
    if cdf < 0.1 or cdf > 0.9 then bad = bad + 1 end end
  l.say(("anomalous synth: %d/%d\n"):format(bad, #synth))
  return l.chk({"n synth",#synth,50},
               {"row len",#synth[1],#data.cols.all},
               {"mostly sane",bad < #synth/2,true}) end

eg["--anomaly"] = function(    data,det,known,outlier)
  data  = pickData()
  det   = m.anomalyDetector(data)
  known = data.rows[1]
  outlier = l.copy(known)
  for _,c in ipairs(data.cols.x) do
    if c.mu then outlier[c.at] = 1E6 end end
  return l.chk({"known in body",
                det(known) > 0.1 and det(known) < 0.9, true},
               {"outlier tail", det(outlier) > 0.9, true}) end

eg["--bob"] = function(    data,best,d)
  data = pickData()
  the.budget = 20
  the.start = 10
  best, d = m.bob(data)
  return l.chk({"bob is row",best ~= nil,true},
               {"win number",type(d.win(best)),"number"}) end

eg["--acq"] = function(    data,win,dy,best,d,ok,err)
  ok, err = pcall(function()
    data = loadCsv(the.train)
    if not data then error("missing file") end
    win, dy = Num.new(), Num.new()
    for _=1,the.repeats do
      best, d = m.bob(data)
      win:add(d.win(best))
      dy:add(luamine.disty(data.cols, best, the.p)) end
    print(string.format("%4.0f  %.4f  %s",
                        win.mu, dy.mu, the.train)) end)
  if not ok then print(string.format("ERR   ---     %s  # %s",
                                     the.train, err)) end
  return true end

eg["--ga"] = function(    data)
  data = pickData()
  the.np, the.cr, the.gens = 50, 0.25, 50
  return runRace(data, {{"ga", m.ga(data, m.knn(data))}}) end

eg["--sa"] = function(    data)
  data = pickData()
  return runRace(data, {{"sa", m.sa(data)}}) end

eg["--ls"] = function(    data)
  data = pickData()
  return runRace(data, {{"ls", m.ls(data)}}) end

eg["--race"] = function(    data)
  data = pickData()
  the.np, the.cr, the.gens, the.de_iter = 50, 0.25, 50, 30
  return runRace(data, {
    {"ga", m.ga(data, m.knn(data))},
    {"de", m.de(data)},
    {"sa", m.sa(data)},
    {"ls", m.ls(data)}}) end

eg["--de"] = function(    data)
  data = pickData()
  the.de_iter, the.np = 30, 20
  return runRace(data, {{"de", m.de(data)}}) end

m.Data = Data
l.boot(eg,b4,"lapps",help)
return m
