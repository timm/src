#!/usr/bin/env lua
local help = [[
ezr3-apps.lua: skills built on the ezr3 substrate, one
short function per book chapter. First resident: knn
prediction (the Fortune Teller). Waiting rooms, cribbing
from ezr-lua/xaiplus.lua: anomaly (Bouncer), naive bayes
(ER Nurse), kmeans/kpp (Curator), de/ga/sa/race (the ch22
dragrace). Demos at the bottom; run with --all.

options:
  k=5    knn: neighbours polled per guess]]

local abs  = math.abs
local rand = math.random

-- find ezr3.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
local _ENV = setmetatable({}, {__index = require"ezr3"})
if setfenv then setfenv(1, _ENV) end

the = the:also(help)

--## predict ---------------------------------------------------
function TBL.around(i,row,rows) -- rows, nearest row first
  return keysort(rows or i.rows,
           function(r) return i:distx(row, r) end) end

function TBL.knn(i,row,k,    t) -- guess row's disty from
  t = i:around(row)             -- its k nearest neighbours
  return adds(map(sub(t, 1, k or the.k), i:Y())).mu end

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

--## start-up --------------------------------------------------
go(eg)


return _ENV
