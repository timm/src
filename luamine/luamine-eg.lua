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

-- The tutorial, one -eg file per engine file, reading order
local eg = {}
local here = debug.getinfo(1,"S").source
             :match"^@(.-)[^/\\]*$" or ""
for _,f in ipairs{"list-eg", "rand-eg", "stats-eg",
                  "confuse-eg", "str-eg", "cli-eg",
                  "cols-eg", "data-eg", "dist-eg", "cut-eg",
                  "tree-eg", "bayes-eg", "mutate-eg",
                  "cluster-eg", "classify-eg", "acquire-eg",
                  "sample-eg", "bob-eg", "ga-eg", "de-eg",
                  "search-eg", "race-eg"} do
  assert(loadfile(here..f..".lua"))(eg, h, a, m, l, the) end

-- seed the from this help's options; dispatch if main
for k,v in l.section(help,"options"):gmatch"%-%-(%w+)=(%S+)" do
  the[k] = l.thing(v) end
if (arg[0] or ""):find("luamine-eg.lua", 1, true) then
  l.main(eg, b4, "luamine-eg", help) end
