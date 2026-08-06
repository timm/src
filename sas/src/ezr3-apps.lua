#!/usr/bin/env lua
local help = [[
ezr3-apps.lua: skills built on the ezr3 substrate, one
short function per book chapter. Residents: knn prediction
(Fortune Teller), anomaly (Bouncer), naive bayes (ER
Nurse), kmeans/kpp (Curator). Waiting rooms, cribbing from
ezr-lua/xaiplus.lua: de/ga/sa/race (the ch22 dragrace).
Demos at the bottom; run with --all.

options:
  k=5         knn: neighbours polled per guess
  kluster=8   kmeans, kpp: clusters wanted
  iter=10     kmeans: assign/recentre passes
  L=1         nb: Laplace smoothing on syms
  m=2         nb: m-estimate prior weight
  wait=10     nb: rows seen before scoring starts]]

local abs,exp,log,pi = math.abs, math.exp, math.log, math.pi
local min,floor      = math.min, math.floor
local rand           = math.random

-- find ezr3.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
local _ENV = setmetatable({}, {__index = require"ezr3"})
if setfenv then setfenv(1, _ENV) end

the = the:also(help)

--## predict (the Fortune Teller) ------------------------------
function TBL.around(i,row,rows) -- rows, nearest row first
  return keysort(rows or i.rows,
           function(r) return i:distx(row, r) end) end

function TBL.knn(i,row,k,    t) -- guess row's disty from
  t = i:around(row)             -- its k nearest neighbours
  return adds(map(sub(t, 1, k or the.k), i:Y())).mu end

--## anomaly (the Bouncer) -------------------------------------
function TBL.anomaly(i,    dn,gap) -- score rows 0..1;
  gap = function(r,    lo,d)       -- 1 = loneliest. gap =
    lo = 1e32                      -- dist to nearest other
    for _,z in ipairs(i.rows) do
      if z ~= r then
        d = i:distx(r, z); if d < lo then lo = d end end end
    return lo end
  dn = Num()
  for _,r in ipairs(i.rows) do dn:add(gap(r)) end
  return function(r) return dn:norm(gap(r)) end end

--## bayes (the ER Nurse) --------------------------------------
function like(col,v,prior,    z) -- P(v|col): sym m-estimate,
  if not col.mu then             -- else num gaussian pdf
    return ((col.has[v] or 0) + the.L*prior)
           / (col.n + the.L) end
  z = 2 * col:div()^2 + 1e-32
  return exp(-(v - col.mu)^2 / z) / (pi * z)^0.5 end

function TBL.likes(h,row,nrows,nh,    prior,out,v) -- log
  prior = (#h.rows + the.m) / (nrows + the.m*nh)   -- like of
  out   = log(prior)             -- row under klass-tbl h
  for _,c in ipairs(h.cols.x) do
    v = row[c.at]
    if v ~= "?" then
      v = like(c, v, prior)
      if v > 0 then out = out + log(v) end end end
  return out end

function mostlikes(h,row,nrows,nh,    best,bs,s) -- which
  bs = -1e32                  -- klass-tbl likes row most?
  for k,hk in pairs(h) do
    s = hk:likes(row, nrows, nh)
    if s > bs then bs, best = s, k end end
  return best end

function TBL.classify(i,wait,    at,h,seen,nh,want) -- test,
  wait, at = wait or the.wait, i.cols.klass.at -- then train;
  h, seen, nh = {}, {}, 0                  -- one pass, no
  for j,row in ipairs(i.rows) do           -- held-out split
    want = row[at]
    if j >= wait and nh > 0 then
      push(seen, {mostlikes(h, row, #i.rows, nh), want}) end
    if not h[want] then h[want] = i:clone(); nh = nh + 1 end
    h[want]:add(row) end
  return seen end

function acc(seen,    n) -- fraction of {got,want} that agree
  n = 0
  for _,p in ipairs(seen) do
    if p[1] == p[2] then n = n + 1 end end
  return n / (#seen + 1e-32) end

--## cluster (the Curator) -------------------------------------
local function nearest(i,cents,r,    lo,d,at) -- index of
  lo = 1e32                        -- r's closest centroid
  for j,c in ipairs(cents) do
    d = i:distx(c, r)
    if d < lo then lo, at = d, j end end
  return at end

local function assign(i,cents,    out) -- each row into its
  out = map(cents, function() return i:clone() end)
  for _,r in ipairs(i.rows) do          -- centroid's clone
    out[nearest(i, cents, r)]:add(r) end
  return out end

local function recentre(clusters,    cents) -- middles of
  cents = {}                       -- the non-empty clusters
  for _,c in ipairs(clusters) do
    if #c.rows > 0 then push(cents, c:mids()) end end
  return cents end

function TBL.kmeans(i,k,iter,    cents) -- k clusters: iter
  cents = some(i.rows, k or the.kluster) -- rounds of assign
  for _ = 1, iter or the.iter do         -- then recentre
    cents = recentre(assign(i, cents)) end
  return assign(i, cents) end

local function d2(i,cents,r,    lo,d) -- squared dist from r
  lo = 1e32                    -- to its nearest centroid
  for _,c in ipairs(cents) do
    d = i:distx(r, c); lo = min(lo, d*d) end
  return lo end

local function wpick(ws,    all,r,c) -- index j, with chance
  all = sum(ws, function(w) return w end)  -- ws[j]/sum(ws)
  r, c = rand() * all, 0
  for j,w in ipairs(ws) do
    c = c + w
    if r <= c then return j end end
  return #ws end

function TBL.kpp(i,k,    cents,pool,ws) -- k centroids, far
  cents = {some(i.rows, 1)[1]}   -- apart: d^2-weighted picks
  while #cents < (k or the.kluster) do   -- from random pools
    pool = some(i.rows, min(the.few, #i.rows))
    ws   = map(pool, function(r) return d2(i, cents, r) end)
    push(cents, pool[wpick(ws)]) end
  return cents end

--## demos -----------------------------------------------------
eg = {}

eg["--all"] = function(    bad) -- all demos; fail if any do
  bad = 0
  for _,k in ipairs(keys(eg)) do
    if k ~= "--all" and run(eg, k) == false then
      bad = bad + 1 end end
  print("failures: " .. bad)
  assert(bad == 0) end

eg["--knn"] = function(    t,y,mu,e1,e2,r) -- neighbours
  t  = Tbl(csv())        -- beat the global mean as a guess
  y  = t:Y()
  mu = adds(map(t.rows, y)).mu
  e1, e2 = 0, 0
  for _ = 1, 32 do
    r  = t.rows[rand(#t.rows)]
    e1 = e1 + abs(t:knn(r) - y(r))
    e2 = e2 + abs(mu       - y(r)) end
  print(("knn err %.3f  vs mean-guess err %.3f")
        :format(e1/32, e2/32))
  assert(e1 < e2) end

eg["--detect"] = function(    t,det,ss) -- anomaly scores:
  t   = Tbl(csv())                      -- someone is lonely
  det = t:anomaly()
  ss  = sorted(map(t.rows, det))
  print(show{lo=ss[1], mid=ss[floor(#ss/2)+1], hi=ss[#ss]})
  assert(0 <= ss[1] and ss[#ss] <= 1)
  assert(ss[#ss] > 0.5) end

eg["--nb"] = function(    t,seen,a) -- test-then-train naive
  t    = Tbl(csv"$MOOT/classify/diabetes.csv") -- bayes
  seen = t:classify()
  a    = acc(seen)
  print(("diabetes: acc %.2f over %s guesses"):format(
    a, #seen))
  assert(a > 0.65) end

eg["--kmeans"] = function(    t,cs,n) -- rows conserved
  t  = Tbl(csv())
  cs = t:kmeans()
  n  = 0
  for _,c in ipairs(cs) do n = n + #c.rows end
  print("cluster sizes " ..
    show(sorted(map(cs, function(c) return #c.rows end))))
  assert(n == #t.rows and #cs <= the.kluster) end

eg["--kpp"] = function(    t,cents,d) -- seeds, spread out
  t     = Tbl(csv())
  cents = t:kpp()
  d = 1e32
  for j = 1, #cents do
    for k = j+1, #cents do
      d = min(d, t:distx(cents[j], cents[k])) end end
  print(("%s kpp seeds, min gap %.3f"):format(#cents, d))
  assert(#cents == the.kluster and d > 0) end

--## start-up --------------------------------------------------
go(eg)

return _ENV
