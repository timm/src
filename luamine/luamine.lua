#!/usr/bin/env lua
-- AI primitives: Num, Sym, Cols, dist, tree -- the loader.
-- Loads each topic file into this one module (cut first:
-- Sym/Num emit cuts via m.cut), merges this help's options
-- into the shared `the` (from lib), then returns the
-- assembled module. require"luamine" as before.
local help = [[
# AI primitives: Num, Sym, Cols, dist, tree
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
  -T  --test=$MOOT/optimize/misc/auto93.csv   test CSV
      --seed=1     RNG seed
  --bins=2     Num cut count (percentile-spaced)
  --leaf=3     stop recursion when #rows < leaf
  --p=2        default Minkowski exponent for dist
  --cap=2048   ftree row-sample size before build
  --budget=32  label budget for active acquire loop
  --k=1        Bayes Laplace/Lidstone smoothing
  --m=2        Bayes m-estimate prior weight
  --F=0.5      DE extrapolate scale
  --cr=0.9     DE crossover rate (per dim)
## egs
  (see luamine-eg.lua)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local m = {}
local l = require"lib"
local the = l.the
m.help = help

local here = debug.getinfo(1,"S").source
             :match"^@(.-)[^/\\]*$" or ""
for _,f in ipairs{"cut", "sym", "num", "cols", "data",
                  "dist", "bayes", "mutate", "tree",
                  "show"} do
  assert(loadfile(here..f..".lua"))(m, l, the) end

l.boot({}, b4, "luamine", help)
return m
