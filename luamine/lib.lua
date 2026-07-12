#!/usr/bin/env lua
-- Library of useful lua functions: the loader. Owns the
-- shared settings table `the`, loads each topic file into
-- this one module (rand first: it replaces Lua's RNG with
-- a portable Park-Miller twin), then seeds `the` from the
-- help options. require"lib" returns the assembled module.
local help = [[
# library of useful lua functions
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
  -T  --test=$MOOT/optimize/misc/auto93.csv   test CSV
      --seed=1         RNG seed
      --cliffs=0.195   Cliff's delta threshold
      --eps=0.35       Cohen's threshold (x sd)
      --ksconf=1.36    KS test threshold
## egs
  (see luamine-eg.lua)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local m, the = {}, {}
m.the, m.helpLib = the, help

local here = debug.getinfo(1,"S").source
             :match"^@(.-)[^/\\]*$" or ""
for _,f in ipairs{"rand", "list", "stats", "confuse",
                  "str", "cli"} do
  assert(loadfile(here..f..".lua"))(m, the) end

m.boot({}, b4, "lib", help)
return m
