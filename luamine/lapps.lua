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

local here = debug.getinfo(1,"S").source
             :match"^@(.-)[^/\\]*$" or ""
for _,f in ipairs{"cluster", "classify", "acquire",
                  "sample", "bob", "race", "ga", "de",
                  "search"} do
  assert(loadfile(here..f..".lua"))(a, m, l, the) end

l.boot({}, b4, "lapps", help)
return a
