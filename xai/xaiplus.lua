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
  --few=128     sample pool for kmeans++ seeding ]]

local xai = require"xai"
local the,lst,rnd,str = xai.the, xai.lst, xai.rnd, xai.str
local Sym,adds = xai.Sym, xai.adds
local BIG,min = 1E32, math.min

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
    function(r) return data:distx(r0,r) end), 1, k or the.knn) end

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
  return argmini(cents, function(c) return data:distx(c,r) end) end

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


-- ## Start
xp.help = help
return xp
