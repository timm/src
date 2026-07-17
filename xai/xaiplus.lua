#!/usr/bin/env lua
-- xaiplus.lua: an applications layer over xai.lua (which it
-- never edits). Each learner and optimizer -- knn, kmeans,
-- naive bayes, GA, DE, SA, local search, racing, synthesis,
-- anomaly -- is a plain self-contained function over a xai
-- Tbl. require"xai" for the engine; require"xaiplus" here.
local help = [[

xaiplus: learners and optimizers layered on xai
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

USAGE: local xp = require"xaiplus"
(demos and tests: lua xaiplus-eg.lua [OPTIONS] [eg ...])

OPTIONS (added to xai's `the`):
  --knn=3       neighbors for the knn classifier
  --kluster=8   clusters for kmeans / kmeans++
  --iter=10     kmeans passes
  --few=128     sample pool for kmeans++ seeding
  --k=1         naive-bayes Laplace smoothing
  --m=2         naive-bayes m-estimate prior weight
  --wait=10     rows seen before naive bayes scores
  --F=0.5       DE extrapolation factor
  --cr=0.3      DE crossover rate
  --np=20       DE/GA population size
  --gens=20     DE/GA generations
  --tour=5      GA tournament size
  --budget1=300 SA/LS eval budget
  --restart=40  LS restart-on-stagnation gap
  --start=20    acquire warm-start labels ]]

local xai = require"xai"
local the,lst,rnd,str = xai.the, xai.lst, xai.rnd, xai.str
local Sym,Num,adds,new = xai.Sym, xai.Num, xai.adds, xai.new
local Tree = xai.Tree
local BIG = 1E32
local exp,log,pi = math.exp, math.log, math.pi
local min,max,floor,sqrt = math.min,math.max,math.floor,math.sqrt

-- add my --key=val defaults to xai's `the`, erroring if one
-- would shadow a key xai already set (new fields, never old)
local function addopts(s)
  for k,v in s:gmatch"%-%-(%w+)=(%S+)" do
    assert(the[k] == nil, "xaiplus reuses xai option: " .. k)
    the[k] = str.what(v) end end
addopts(help)

local xp = {}


-- ## Lib
-- The two list verbs xai does not already export.

-- index of t minimizing fn(item) (mirror of lst.argmax)
local function argmini(t,fn,    lo,v,out)
  lo = BIG
  for i,z in ipairs(t) do
    v = fn(z); if v < lo then lo,out = v,i end end
  return out end

-- index of ws, chance proportional to its weight
local function wpick(ws,    s,r)
  s = 0; for _,w in ipairs(ws) do s = s + w end
  r = rnd.n() * s
  for i,w in ipairs(ws) do
    r = r - w; if r <= 0 then return i end end
  return #ws end


-- ## Knn
-- k-nearest-neighbor classifier: a row's klass is the mode
-- of its k closest rows' klasses (distx from xai). No fit
-- step -- the data IS the model. Needs a "!" klass column.

-- the k rows of data nearest r0, by distx
local function near(data,r0,k)
  return lst.slice(lst.keysort(data.rows,
    function(r) return data:distx(r0,r) end),
    1, k or the.knn) end

-- predict r0's klass = mode of its k neighbors' klasses
function xp.knn(data,r0,k,    at)
  at = data.cols.klass.at
  return adds(lst.map(near(data,r0,k),
    function(r) return r[at] end), Sym.new()):mid() end


-- ## Kmeans
-- k clusters: drop each row into its nearest centroid, move
-- the centroids to their members' middle, repeat. A centroid
-- is just a `mids` row; a cluster is a xai Tbl clone.

-- index of the centroid nearest row r
local function nearest(data,cents,r)
  return argmini(cents,
    function(c) return data:distx(c,r) end) end

-- one pass: each row into its nearest centroid's clone
local function assign(data,cents,    out)
  out = lst.map(cents, function() return data:clone() end)
  for _,r in ipairs(data.rows) do
    out[nearest(data,cents,r)]:add(r) end
  return out end

-- centroids = the middle of each non-empty cluster
local function recentre(clusters,    cents)
  cents = {}
  for _,c in ipairs(clusters) do
    if #c.rows > 0 then lst.push(cents, c:mids()) end end
  return cents end

-- k clusters: iter rounds of assign then recentre
function xp.kmeans(data,k,iter,    cents)
  cents = rnd.some(data.rows, k or the.kluster)
  for _ = 1, iter or the.iter do
    cents = recentre(assign(data, cents)) end
  return assign(data, cents) end


-- ## Kmeanspp
-- kmeans++ seeding: centroids far apart. Each new centroid is
-- drawn from a small random pool, with chance proportional to
-- its squared distance to the nearest centroid so far (the
-- d^2 trick). Returns the seed rows, not clusters.

-- squared distance from r to its nearest centroid in cents
local function d2(data,cents,r,    lo,d)
  lo = BIG
  for _,c in ipairs(cents) do
    d = data:distx(r,c); lo = min(lo, d*d) end
  return lo end

-- one more centroid: d^2-weighted pick from a random pool
local function farther(data,cents,few,    pool,ws)
  pool = rnd.some(data.rows, min(few or the.few, #data.rows))
  ws   = lst.map(pool, function(r) return d2(data,cents,r) end)
  return pool[wpick(ws)] end

-- k centroids by kmeans++ seeding
function xp.kpp(data,k,few,    cents)
  cents = {rnd.some(data.rows, 1)[1]}
  while #cents < (k or the.kluster) do
    lst.push(cents, farther(data, cents, few)) end
  return cents end


-- ## Bayes
-- naive Bayes likelihoods. `like` = P(v | col): a Sym
-- m-estimate, or a Num gaussian pdf. `likes` = the log-sum
-- likelihood of a whole row under one klass's model (a xai
-- Tbl holding just that klass's rows). Enough for the
-- classifier in the next section.

xp.bayes = {}

-- P(v | col): Sym m-estimate, else Num gaussian pdf
function xp.bayes.like(col,v,prior,    z)
  if not col.mu then
    return ((col.has[v] or 0)+the.k*prior)/(col.n+the.k) end
  z = 2*(col:spread() + 1E-32)^2
  return exp(-(v - col.mu)^2/z)/(pi*z)^0.5 end

-- log-likelihood of a row under klass model h (a xai Tbl)
function xp.bayes.likes(h,row,nrows,nh,    prior,out,v)
  prior = (#h.rows + the.m)/(nrows + the.m*nh)
  out   = log(prior)
  for _,c in ipairs(h.cols.x) do
    v = row[c.at]
    if v ~= "?" then
      v = xp.bayes.like(c, v, prior)
      if v > 0 then out = out + log(v) end end end
  return out end


-- ## Classify
-- Incremental naive Bayes, test-then-train: for each row,
-- predict its klass from the models seen so far, score the
-- guess in a Confuse matrix, then train the true klass's
-- model. One pass, no held-out split needed.

-- confusion matrix: add(want,got) tallies each cell;
-- `acc` = the fraction landing on the diagonal
local Confuse = {}
function Confuse.new()
  return new(Confuse, {n=0, ok=0, cells={}}) end
function Confuse.add(i,want,got,    key)
  i.n = i.n + 1
  if want == got then i.ok = i.ok + 1 end
  key = want .. "|" .. got
  i.cells[key] = (i.cells[key] or 0) + 1
  return got end
function Confuse.acc(i) return i.ok/(i.n + 1E-32) end

-- test-then-train naive Bayes; returns the Confuse matrix
function xp.classify(data,wait,    h,cf,nh,at,want,best,bs,s)
  wait, at  = wait or the.wait, data.cols.klass.at
  h, cf, nh = {}, Confuse.new(), 0
  for i,row in ipairs(data.rows) do
    want = row[at]
    if i >= wait and nh > 0 then
      best, bs = nil, -BIG
      for k,hk in lst.items(h) do
        s = xp.bayes.likes(hk, row, #data.rows, nh)
        if s > bs then bs,best = s,k end end
      cf:add(want, best) end
    if not h[want] then h[want]=data:clone(); nh=nh+1 end
    h[want]:add(row) end
  return cf end


-- ## Mutate
-- Mutators for the optimizers. `pick` samples one fresh
-- value for a column (Sym by frequency, Num a gaussian nudge
-- clamped to mu +-3sd); `picks` mutates n random x cells;
-- `extrapolate` is DE's a + F*(b - c), with one column always
-- kept from a, so a kid never fully forgets its base.

xp.mutate = {}

-- lo,hi = mu -+ k spreads of a Num column
local function lohi(col,k,    s)
  s = col:spread(); return col.mu - k*s, col.mu + k*s end

-- fresh value for col: Sym by frequency, Num gaussian nudge
function xp.mutate.pick(col,v,    lo,hi,val)
  if not col.mu then return rnd.pick(col.has)() end
  v      = (v ~= "?" and v) or col.mu
  lo, hi = lohi(col, 3)
  val    = v + col:spread()*rnd.gauss(0,1)
  return max(lo, min(hi, val)) end

-- copy row; mutate n of its x columns via pick
function xp.mutate.picks(data,row,n,    out,xs)
  out, xs = lst.slice(row), rnd.shuffle(lst.slice(data.cols.x))
  for j = 1, min(n, #xs) do
    out[xs[j].at] = xp.mutate.pick(xs[j], out[xs[j].at]) end
  return out end

-- DE blend a + F*(b - c) per x col with chance cr; one col
-- always kept from a; Nums wrap to mu +-4sd, Syms flip to b
-- with chance F, and "?" in a is left as "?"
function xp.mutate.extrapolate(cols,a,b,c,F,cr,
                        out,keep,va,vb,vc,v,lo,hi,span)
  F, cr     = F or the.F, cr or the.cr
  out, keep = lst.slice(a), cols[rnd.n(#cols)]
  for _,col in ipairs(cols) do
    if col ~= keep and rnd.n() < cr then
      va,vb,vc = a[col.at], b[col.at], c[col.at]
      if     va == "?" then out[col.at] = "?"
      elseif not col.mu then
        out[col.at] = (rnd.n() < F) and vb or va
      elseif vb == "?" or vc == "?" then out[col.at] = va
      else
        v      = va + F*(vb - vc)
        lo, hi = lohi(col, 4)
        span   = hi - lo + 1E-32
        out[col.at] = lo + (v - lo) % span end end end
  return out end


-- ## Optimize
-- Shared gear for the optimizers. `oracle` scores any row --
-- even a synthetic one -- by the disty of its nearest real
-- row: a cheap surrogate for the true, expensive objective.
-- Every optimizer below MINIMIZES it and returns its best row.

-- score a row by the disty of its nearest real row
local function oracle(data)
  return function(r)
    return data:disty(near(data, r, 1)[1]) end end


-- ## De
-- Differential evolution. A population of rows; each
-- generation every parent spawns a DE kid (blend three random
-- pop rows via extrapolate) that replaces the parent when the
-- oracle scores the kid better.

-- differential evolution; returns the best row found
function xp.de(data,    y,pop,t,kid)
  y   = oracle(data)
  pop = rnd.some(data.rows, the.np)
  for _ = 1, the.gens do
    for i,parent in ipairs(pop) do
      t   = rnd.some(pop, 3)
      kid = xp.mutate.extrapolate(data.cols.x, t[1], t[2], t[3])
      if y(kid) < y(parent) then pop[i] = kid end end end
  return lst.keysort(pop, y)[1] end


-- ## Ga
-- Genetic algorithm. Each generation: mutate the whole pop
-- (one cell each), then refill by one-point crossover of two
-- tournament-picked parents.

-- lowest-oracle row among `tour` random pop rows
local function tourney(pop,y,    x,z)
  x = pop[rnd.n(#pop)]
  for _ = 2, the.tour do
    z = pop[rnd.n(#pop)]; if y(z) < y(x) then x = z end end
  return x end

-- one-point crossover of two rows over the x columns
local function cross(data,mum,dad,    kid,cut)
  kid, cut = lst.slice(mum), rnd.n(#data.cols.x)
  for j,c in ipairs(data.cols.x) do
    if j > cut then kid[c.at] = dad[c.at] end end
  return kid end

-- genetic algorithm; returns the best row found
function xp.ga(data,    y,pop,kids)
  y   = oracle(data)
  pop = rnd.some(data.rows, the.np)
  for _ = 1, the.gens do
    pop  = lst.map(pop,
             function(r) return xp.mutate.picks(data, r, 1) end)
    kids = {}
    for _ = 1, the.np do
      lst.push(kids,
        cross(data, tourney(pop,y), tourney(pop,y))) end
    pop = kids end
  return lst.keysort(pop, y)[1] end


-- ## Sa
-- Simulated annealing, (1+1). From one row, repeatedly mutate
-- one cell; always keep a better kid, and sometimes a worse
-- one (metropolis, cooling as the budget spends).

-- simulated annealing; returns the best row seen
function xp.sa(data,    y,s,es,best,eb,kid,e)
  y  = oracle(data)
  s  = data.rows[rnd.n(#data.rows)]
  es = y(s); best, eb = s, es
  for h = 1, the.budget1 do
    kid = xp.mutate.picks(data, s, 1)
    e   = y(kid)
    if e < es or
       rnd.n() < exp((es-e)/(1 - h/the.budget1 + 1E-32)) then
      s, es = kid, e end
    if e < eb then best, eb = kid, e end end
  return best end


-- ## Ls
-- Greedy local search, (1+1) with restarts. Keep only strict
-- improvements; after `restart` steps with no new best, jump
-- to a fresh random row.

-- greedy local search; returns the best row found
function xp.ls(data,    y,s,es,best,eb,imp,kid,e)
  y   = oracle(data)
  s   = data.rows[rnd.n(#data.rows)]
  es  = y(s); best, eb, imp = s, es, 0
  for h = 1, the.budget1 do
    kid = xp.mutate.picks(data, s, 1)
    e   = y(kid)
    if e < es then s, es = kid, e end
    if e < eb then best, eb, imp = kid, e, h end
    if h - imp > the.restart then
      s = data.rows[rnd.n(#data.rows)]
      es, imp = y(s), h end end
  return best end


-- ## Race
-- Race the optimizers head to head: run each on one dataset,
-- score its best row by the oracle, return them ranked best
-- first. A cheap answer to "which search wins here?".
function xp.race(data,    y,opts,out)
  y    = oracle(data)
  opts = {de=xp.de, ga=xp.ga, sa=xp.sa, ls=xp.ls}
  out  = {}
  for name,opt in lst.items(opts) do
    lst.push(out, {name, y(opt(data))}) end
  return lst.keysort(out, function(o) return o[2] end) end


-- ## Sample
-- Synthesize new rows. Grow a tree, then for each new row
-- pick a leaf and DE-blend three of its rows -- so synthetic
-- rows land inside real, coherent regions, not in the voids
-- between them.
function xp.sample(data,n,    tree,big,out,rs)
  tree = Tree.grow(data, data.rows)
  big  = {}
  for _,leaf in ipairs(tree:leaves()) do
    if #leaf.rows >= 3 then lst.push(big, leaf) end end
  out = {}
  while #big > 0 and #out < (n or 100) do
    rs = rnd.some(big[rnd.n(#big)].rows, 3)
    lst.push(out, xp.mutate.extrapolate(
      data.cols.x, rs[1], rs[2], rs[3])) end
  return out end


-- ## Acquire
-- The HISTORIC active learner, kept for comparison (xai's own
-- acquire uses poles; this one does not). Label a warm-start,
-- split it best/rest by sqrt(N), then repeatedly label the
-- top-scored unlabeled row and re-cap best. Two scorers:
-- Bayes likelihood, or centroid distance.

xp.acquire = {}

-- score: like(best) - like(rest) (higher = likelier good)
function xp.acquire.bayes(_,best,rest,row,    n)
  n = #best.rows + #rest.rows
  return xp.bayes.likes(best,row,n,2)
       - xp.bayes.likes(rest,row,n,2) end

-- score: dist to rest mid - dist to best mid
function xp.acquire.centroid(data,best,rest,row)
  return data:distx(row, rest:mids())
       - data:distx(row, best:mids()) end

-- rows sorted best-first by disty
local function byDisty(data,rs)
  return lst.keysort(rs,
    function(r) return data:disty(r) end) end

-- warm-start `start` labels, split best/rest by sqrt, then
-- label the top-scored unlabeled row and re-cap best to
-- budget. Returns the labeled Tbl.
function xp.acquire.top(data,score,budget,start,    rows,lab,
    best,rest,cap,unlab,sorted,worst)
  score  = score  or xp.acquire.bayes
  budget = budget or the.budget
  start  = start  or the.start
  rows   = rnd.shuffle(lst.slice(data.rows))
  lab    = data:clone(lst.slice(rows, 1, start))
  sorted = byDisty(data, lab.rows)
  cap    = floor(sqrt(#lab.rows))
  best   = data:clone(lst.slice(sorted, 1, cap))
  rest   = data:clone(lst.slice(sorted, cap+1))
  unlab  = lst.slice(rows, start+1)
  for _ = 1, budget do
    if #unlab == 0 then break end
    unlab = lst.keysort(unlab,
              function(r) return -score(data,best,rest,r) end)
    lab:add(unlab[1]); best:add(unlab[1])
    unlab = lst.slice(unlab, 2)
    if #best.rows > floor(sqrt(#lab.rows)) then
      worst = byDisty(data, best.rows)[#best.rows]
      best:add(worst, -1); rest:add(worst) end end
  return lab end


-- ## Anomaly
-- Calibrate a 1-nearest-neighbor distance on the training
-- rows (a Num of every row's gap to its nearest OTHER row),
-- then score any row's gap against that spread: a high
-- normalized score = a lonely row = an anomaly.
function xp.anomaly(data,    dn,gap)
  gap = function(r,    nn)
    nn = lst.keysort(data.rows,
      function(z) return r==z and BIG or data:distx(r,z) end)[1]
    return data:distx(r, nn) end
  dn  = Num.new()
  for _,r in ipairs(data.rows) do dn:add(gap(r)) end
  return function(r) return dn:norm(gap(r)) end end


-- ## Start
xp.help = help
return xp
