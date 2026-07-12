#!/usr/bin/env lua
-- Apps: cluster, classify, acquire, bob, ga, de, sa, ls,
-- race -- the loader. Loads each app file into this one
-- module, merges this help's options into the shared `the`
-- and returns the assembled module. require"lapps" as
-- before.
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
  --budget=512     acquire label budget (active learning)
  --pool=512       ga reference-pool cap
  --budget1=1000   oneplus1/sa/ls eval budget
  --dot=25         evals per progress letter
  --repeats=20     acq shuffle+bob repeats per file
  --check=4        post-acquire top-N to evaluate
  -
## egs
  (see luamine-eg.lua)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local a = {}
local l = require"lib"
local m = require"luamine"
local the = l.the
a.help, a.Data = help, m.Data

-- ## cluster
-- Cluster. `kmeans` = k clusters around centroids, errs
-- per iteration; `kpp` = kmeans++ seeding, d^2-weighted
-- far centroids from a small sampled pool.


local min,rand,huge = math.min, math.random, math.huge

-- k clusters around centroids; errs per iter
function a.kmeans(data,k,iter,cents,    out,errs,err)
  k,iter = k or the.k_cluster, iter or the.iter
  cents  = cents or l.anys(data.rows, k)
  errs   = {}
  for _=1,iter do
    out = l.map(cents, function() return data:clone() end)
    for _,r in ipairs(data.rows) do
      out[l.argmin(cents, function(c)
        return m.distx(data.cols,c,r,the.p) end)]:add(r) end
    err = 0
    for j,kid in ipairs(out) do
      for _,r in ipairs(kid.rows) do
        err = err + m.distx(data.cols,cents[j],r,the.p) end
    end
    errs[1+#errs] = err / #data.rows
    cents = {}
    for _,kid in ipairs(out) do
      if #kid.rows>0 then
        cents[1+#cents] = kid.cols:mid() end end end
  return out, errs end

-- kmeans++ seeding: d^2-weighted far centroids
function a.kpp(data,k,few,    rows,out,t,ws,d,mn)
  rows = data.rows
  k, few = k or the.k_cluster, few or the.few
  out  = { rows[rand(#rows)] }
  while #out < k do
    t, ws = l.anys(rows, min(few, #rows)), {}
    for j=1,#t do
      mn = huge
      for _,c in ipairs(out) do
        d = m.distx(data.cols, t[j], c, the.p)
        if d*d < mn then mn = d*d end end
      ws[j] = mn end
    out[1+#out] = t[l.pickDict(ws)] end
  return out end

-- ## classify
-- Classify. Incremental naive bayes, test-then-train:
-- predict each row's klass from the models so far, score
-- the guess in a Confuse matrix, then train on the truth.


local huge = math.huge

-- incremental NB: predict, score, then train
function a.classify(data,wait,    h,cf,nKl,want,best,bs,s)
  wait = wait or the.wait
  h, cf, nKl = {}, l.Confuse.new(), 0
  for i,row in ipairs(data.rows) do
    want = row[data.cols.klass.at]
    if i >= wait and nKl > 0 then
      best, bs = nil, -huge
      for _,klass in ipairs(
          l.sort(l.kap(h, function(k,_) return k end))) do
        s = m.likes(h[klass], row, #data.rows, nKl)
        if s > bs then bs, best = s, klass end end
      cf:add(want, best) end
    if not h[want] then h[want] = data:clone(); nKl = nKl+1 end
    h[want]:add(row) end
  return cf end

-- ## acquire
-- Acquire. Active learning: label the top-scored unlabeled
-- row, re-cap best, repeat to budget. Two acquisition
-- scores: Bayes (like best minus like rest) and centroid
-- distance.


local floor,sqrt = math.floor, math.sqrt

-- acquisition score: like(best) - like(rest)
function a.acquireBayes(best,rest,row,    n)
  n = #best.rows + #rest.rows
  return m.likes(best,row,n,2) - m.likes(rest,row,n,2) end

-- acquisition score: dist to rest mid - best mid
function a.acquireCentroid(data,best,rest,row)
  return m.distx(data.cols,row,rest.cols:mid(),the.p)
       - m.distx(data.cols,row,best.cols:mid(),the.p) end

-- rows sorted ascending by disty (best first)
local function byDisty(data,rs)
  return l.keysort(rs,
    function(r) return m.disty(data.cols,r,the.p) end) end

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
function a.acquire(data,score,budget,start,
                   rows,lab,best,rest,unlab,top)
  score  = score  or a.acquireBayes
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

-- ## sample
-- Sample / anomaly. `sample` invents N synthetic rows by
-- DE-blending 3 rows per ftree leaf; `anomalyDetector`
-- calibrates a 1-NN-in-leaf distance CDF on the training
-- rows (tails = anomalies).


local rand,huge = math.random, math.huge

-- collect leaf nodes of a tree
local function leaves(node,out)
  out = out or {}
  if node.leaf then out[1+#out] = node
  else leaves(node.left, out); leaves(node.right, out) end
  return out end

-- N synthetic rows: DE-blend 3 rows per ftree leaf
function a.sample(data,N,    tree,leafs,out,leaf,rs)
  N      = N or 100
  tree   = data:ftree()
  leafs  = leaves(tree)
  out    = {}
  while #out < N do
    leaf = leafs[rand(#leafs)]
    if #leaf.rows >= 3 then
      rs = l.anys(leaf.rows, 3)
      out[1+#out] = m.extrapolate(
        data.cols.x, rs[1], rs[2], rs[3], the.F) end end
  return out end

-- closure row->CDF of 1-NN-in-leaf dist;
-- calibrated on train rows; tails = anomalies
function a.anomalyDetector(data,    tree,dn,d1)
  tree = data:ftree()
  dn   = m.Num.new()
  d1   = function(row,    leaf,nn)
    leaf = m.relevant(tree, row)
    nn   = m.near(data.cols, row, leaf, the.p)[1]
    return nn and m.distx(data.cols,row,nn,the.p) or huge end
  for _,row in ipairs(data.rows) do dn:add(d1(row)) end
  return function(row) return dn:norm(d1(row)) end end

-- ## bob
-- Bob. The whole pipeline: split, acquire labels on the
-- train half, tree the labels, rank the unseen test half
-- by leaf disty, check the top few; returns the best test
-- row plus a dxdy view for grading.


local floor = math.floor

-- pipeline: split, acquire, tree, check top few;
-- returns best test row + dxdy view
function a.bob(data,score,
               d,rows,h,trH,teH,lab,tree,sorted,best)
  score = score or a.acquireBayes
  d     = data:dxdy()
  rows  = l.shuffle(l.copy(data.rows))
  h     = floor(#rows/2)
  trH   = l.slice(l.slice(rows, 1, h), 1, the.few)
  teH   = l.slice(rows, h+1)
  lab   = a.acquire(data:clone(trH), score)
  tree  = lab:tree()
  sorted = l.keysort(teH, function(r)
    return m.mu_disty(
      lab.cols, m.relevant(tree,r), the.p) end)
  best = l.keysort(l.slice(sorted, 1, the.check), d.y)[1]
  return best, d end

-- ## race
-- Race. Oracles and Pareto predicates for the optimizers,
-- plus the harness: `track` drives one stepper, snapping
-- kids to their nearest real row and logging each new
-- global best; `race` merges logs; `report` prints the
-- best-trace table.


local huge = math.huge

-- score row by disty of nearest labeled row
function a.oracle(data,    ref)
  ref = data.rows
  return function(r)
    return m.disty(data.cols,
      m.near(data.cols, r, ref, the.p)[1], the.p) end end

-- predicate: direct Zitzler compare (ignores ref)
function a.betters(data)
  return function(x,y,_) return m.better(data,x,y) end end

-- predicate: snap a,b to nearest in ref, compare
function a.knn(data)
  return function(x,y,ref)
    return m.better(data,
      m.near(data.cols,x,ref,the.p)[1],
      m.near(data.cols,y,ref,the.p)[1]) end end

-- drive stepper; snap kids to nearest real row;
-- log each new global best as {who,eval,gen,disty,nbr}
function a.track(name, step, cols, rows,
                 bob,bd,lob,h,mark,nbr,d)
  bob, bd, lob, h, mark = nil, huge, {}, 0, 0
  for gen,kids in step do
    for _,kid in ipairs(kids) do
      h = h + 1
      if h-mark >= the.dot then mark=h; l.say(name:sub(1,1)) end
      nbr = m.near(cols, kid, rows, the.p)[1]
      d   = m.disty(cols, nbr, the.p)
      if d < bd then
        bd, bob = d, nbr
        lob[1+#lob] = {who=name, eval=h, gen=gen,
                       disty=d, nbr=nbr} end end end
  l.say("\n")
  return bob, lob end

-- run optimizers; merge logs to global-best timeline
function a.race(data, opts,    all, lob, bd)
  all = {}
  for _,o in ipairs(opts) do
    local _, lb = a.track(o[1], o[2], data.cols, data.rows)
    for _,e in ipairs(lb) do all[1+#all] = e end end
  all = l.keysort(all, function(e) return e.eval end)
  lob, bd = {}, huge
  for _,e in ipairs(all) do
    if e.disty < bd then bd = e.disty; lob[1+#lob] = e end end
  return lob end

-- print race table: who/eval/gen/disty + y goals
function a.report(data, lob,    ys,rows,row,dists,mu)
  ys   = data.cols.y
  rows = {{"who","eval","gen","disty"}}
  for _,c in ipairs(ys) do rows[1][1+#rows[1]] = c.txt end
  mu = {}; for _,c in ipairs(ys) do mu[c.at] = c.mu end
  row = {"average","-","-",l.o(m.disty(data.cols,mu,the.p))}
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

-- ## ga
-- Ga. Genetic algorithm stepper: mutate, tournament
-- select, crossover; one call = one generation; nil when
-- gens done.


local floor,max,rand = math.floor, math.max, math.random

-- GA stepper: mutate, tournament select, crossover
function a.ga(data, better,
              mutate,selects,good,crossOver,pop,ref,gen)
  better= better or a.betters(data)
  mutate= function(row)
    return m.picks(data, row,
      max(1, floor(the.mut*(#data.cols.x)))) end
  selects= function(t,    u)
    u={}; for _=1,#t do u[1+#u]=good(t) end; return u end
  good= function(t,    x,y)
    x = t[rand(#t)]
    for _ = 2,the.tour do
      y = t[rand(#t)]
      if better(y,x,ref) then x=y end end
    return x end
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
  ref = l.slice(data.rows, the.np+1, the.pool - the.np)
  return function()
    gen = (gen or 0) + 1
    if gen <= the.gens then
      pop = crossOver(#pop, selects(l.map(pop,mutate)))
      return gen, pop, ref end end end

-- ## de
-- De. Differential evolution, DE/rand/1 stepper: blend
-- three distinct rows per parent; the kid replaces its
-- parent when the oracle scores it better.


-- DE/rand/1 stepper: kid replaces parent if better
function a.de(data,oracle,    y,pop,es,gen)
  y   = oracle or a.oracle(data)
  pop = l.slice(l.shuffle(l.copy(data.rows)), 1, the.np)
  es  = l.map(pop, y)
  return function(    kids,kid,d,t)
    gen = (gen or 0) + 1
    if gen > the.de_iter then return end
    kids = {}
    for i=1,#pop do
      repeat t = l.anys(pop,3)
      until t[1]~=t[2] and t[1]~=t[3] and t[2]~=t[3]
      kid = m.extrapolate(data.cols.x, t[1],t[2],t[3], the.F)
      d = y(kid); kids[1+#kids] = kid
      if d < es[i] then pop[i],es[i] = kid,d end end
    return gen, kids end end

-- ## search
-- Search, (1+1) style. `oneplus1` is the shared stepper:
-- mutate s, accept(e,d,h,b), restart on stagnation, nil
-- after the eval budget. `sa` = simulated annealing
-- (metropolis accept); `ls` = greedy local search with
-- restarts.


local floor,max,rand = math.floor, math.max, math.random
local exp,huge = math.exp, math.huge

-- (1+1) stepper: mutate s, accept(e,d,h,b),
-- restart on stagnation; nil after budget evals
function a.oneplus1(data,mutate,accept,oracle,budget,restart,
                    s,e,h,imp,bd)
  budget  = budget  or the.budget1
  restart = restart or 0
  oracle  = oracle  or a.oracle(data)
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
function a.sa(data,oracle,budget,restart,    n)
  n = max(1, floor(the.mut * #data.cols.x))
  return a.oneplus1(data,
    function(s) return { m.picks(data, s, n) } end,
    function(e,d,h,b)
      return d < e
          or rand() < exp((e-d) / (1 - h/b + 1E-32)) end,
    oracle, budget, restart) end

-- greedy local search via oneplus1 + restarts
function a.ls(data,oracle,budget,restart,    p,tries)
  p, tries = 0.5, 20
  return a.oneplus1(data,
    function(s,    out,c,kid,reps)
      out, c = {}, data.cols.x[rand(#data.cols.x)]
      reps = (rand() < p) and tries or 1
      for _=1,reps do
        kid = l.copy(s); kid[c.at] = m.pick(c, kid[c.at])
        out[1+#out] = kid end
      return out end,
    function(e,d) return d < e end,
    oracle, budget, restart or 100) end
l.boot({}, b4, "lapps", help)
return a
