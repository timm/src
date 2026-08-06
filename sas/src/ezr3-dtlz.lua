#!/usr/bin/env lua
local help = [[
ezr3-dtlz.lua: drive ezr3 with an EXTERNAL MODEL, no csv.
DTLZ1-7 rows are born with "?" goals; disty computes them
on demand, folding each new label into the column summaries
so normalization sharpens as spending grows. This file is
the seam where outsiders plug in their own (maybe very
expensive) models. Demos at the bottom; run with --all.

options:
  model=dtlz2   one of dtlz1..dtlz7
  M=2           objectives, all minimized
  Nx=6          decision variables, all in 0..1
  pool=1000     rows per fresh pool]]

local abs,cos,sin,pi = math.abs, math.cos, math.sin, math.pi
local rand           = math.random

-- find ezr3.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
local _ENV = setmetatable({}, {__index = require"ezr3"})
if setfenv then setfenv(1, _ENV) end

the = the:also(help)

--## models ----------------------------------------------------
-- Each maps x in [0,1]^Nx to M objectives to minimize. The
-- last Nx-M+1 x's (xm) set distance from the true front;
-- the first M-1 shape position along it.
function g1(xm) -- multi-modal distance (dtlz1, dtlz3)
  return 100 * (#xm + sum(xm, function(v)
    return (v-.5)^2 - cos(20*pi*(v-.5)) end)) end

function g2(xm) -- unimodal distance (dtlz2, dtlz4, dtlz5)
  return sum(xm, function(v) return (v-.5)^2 end) end

function g6(xm) -- biased distance (dtlz6)
  return sum(xm, function(v) return v^0.1 end) end

function sphere(M,g,th,    f,v) -- cos/sin product, dtlz2-6
  f = {}
  for i = 0, M-1 do
    v = 1 + g
    for j = 1, M-1-i do v = v * cos(th[j]) end
    if i > 0 then v = v * sin(th[M-i]) end
    push(f, v) end
  return f end

function dtlz1(x,M,    g,f,v) -- linear front: sum f = .5
  g, f = g1(sub(x, M)), {}
  for i = 0, M-1 do
    v = 0.5 * (1 + g)
    for j = 1, M-1-i do v = v * x[j] end
    if i > 0 then v = v * (1 - x[M-i]) end
    push(f, v) end
  return f end

function dtlz2(x,M) -- spherical front
  return sphere(M, g2(sub(x, M)),
           map(sub(x, 1, M-1), function(v)
             return v * pi/2 end)) end

function dtlz3(x,M) -- spherical, multi-modal
  return sphere(M, g1(sub(x, M)),
           map(sub(x, 1, M-1), function(v)
             return v * pi/2 end)) end

function dtlz4(x,M) -- spherical, biased sampling
  return sphere(M, g2(sub(x, M)),
           map(sub(x, 1, M-1), function(v)
             return v^100 * pi/2 end)) end

function degen(x,M,g,    th) -- dtlz5/6: degenerate curve
  th = {x[1] * pi/2}
  for i = 2, M-1 do
    th[i] = pi/(4*(1+g)) * (1 + 2*g*x[i]) end
  return sphere(M, g, th) end

function dtlz5(x,M) return degen(x, M, g2(sub(x, M))) end
function dtlz6(x,M) return degen(x, M, g6(sub(x, M))) end

function dtlz7(x,M,    k,g,f,h) -- disconnected front
  k = #x - M + 1
  g = 1 + 9/k * sum(sub(x, M), function(v) return v end)
  f = sub(x, 1, M-1)
  h = M - sum(f, function(fi)
        return fi/(1+g) * (1 + sin(3*pi*fi)) end)
  push(f, (1+g) * h)
  return f end

--## seam ------------------------------------------------------
-- Pools of unlabelled rows; goals appear only when disty
-- asks. TBL.label folds new goals into the y summaries.
function Dtlz(    u,r) -- a Tbl over one fresh, blank pool
  u = {names()}
  for _ = 1, the.pool do
    r = {}
    for _ = 1, the.Nx do push(r, rand()) end
    for _ = 1, the.M  do push(r, "?") end
    push(u, r) end
  u = Tbl(u)
  u.model = _ENV[the.model]
  return u end

function names(    u) -- X1..XNx, then F1-..FM- (minimize)
  u = {}
  for j = 1, the.Nx do push(u, "X"..j) end
  for m = 1, the.M  do push(u, "F"..m.."-") end
  return u end

function TBL.label(i,row,    f) -- ask the model; fold in
  f = i.model(map(i.cols.x,
        function(c) return row[c.at] end), #i.cols.y)
  for j, y in ipairs(i.cols.y) do
    row[y.at] = y:add(f[j]) end
  return row end

local disty0 = TBL.disty
function TBL.disty(i,row) -- the seam: goals on demand
  if i.model and row[i.cols.y[1].at] == "?" then
    i:label(row) end
  return disty0(i, row) end

local clone0 = TBL.clone
function TBL.clone(i,rows,    u) -- clones stay live models
  u = clone0(i, rows)
  u.model = i.model
  return u end

function instance(t,row) -- one row: x, then f, then disty
  print("  x  " .. show(sub(row, 1, the.Nx)))
  print(("  f  %s   (disty %.3f, lower=better)"):format(
    show(sub(row, the.Nx + 1)), t:disty(row))) end

--## demos -----------------------------------------------------
eg = {}

eg["--all"] = function(    bad) -- all demos; fail if any do
  bad = 0
  for _,k in ipairs(keys(eg)) do
    if k ~= "--all" and run(eg, k) == false then
      bad = bad + 1 end end
  print("failures: " .. bad)
  assert(bad == 0) end

eg["--fronts"] = function(    x,f,s,g) -- known geometry:
  for _ = 1, 100 do        -- dtlz1 leaves sum f = .5(1+g);
    x = {}                 -- dtlz2 leaves sum f^2 = (1+g)^2
    for j = 1, 6 do x[j] = rand() end
    g = g1(sub(x, 2))
    f = dtlz1(x, 2)
    s = sum(f, function(v) return v end)
    assert(abs(s - 0.5*(1+g)) < 1e-9 * (1+g))
    g = g2(sub(x, 2))
    f = dtlz2(x, 2)
    s = sum(f, function(v) return v*v end)
    assert(abs(s - (1+g)^2) < 1e-9 * (1+g)^2) end
  print"100 rounds: dtlz1 linear, dtlz2 spherical: ok" end

eg["--label"] = function(    t,r) -- goals appear on demand
  t = Dtlz()
  r = t.rows[1]
  assert(r[t.cols.y[1].at] == "?")     -- born blank
  t:disty(r)                           -- the seam fires
  assert(r[t.cols.y[1].at] ~= "?")     -- now labelled
  print("labelled: " .. show(sub(r, the.Nx + 1)))
  assert(t.cols.y[1].n == 1) end       -- and folded in

eg["--models"] = function(    t,d,lo,hi,best) -- all 7
  for _,m in ipairs{"dtlz1","dtlz2","dtlz3","dtlz4", -- run;
                    "dtlz5","dtlz6","dtlz7"} do -- 50 labels
    the.model = m                     -- each; ruler sharpens
    t = Dtlz()
    for j = 1, 50 do t:disty(t.rows[j]) end -- label 50, then
    lo, hi = 2, -1        -- rescore all on the warmed ruler
    for j = 1, 50 do
      d = t:disty(t.rows[j])
      if d < lo then lo, best = d, t.rows[j] end
      if d > hi then hi = d end end
    print(("%-6s disty %.3f .. %.3f  best f %s"):format(
      m, lo, hi, show(sub(best, the.Nx + 1))))
    for _,y in ipairs(t.cols.y) do          -- finite, and
      assert(best[y.at] == best[y.at]       -- not negative
             and best[y.at] >= 0) end
    assert(0 <= lo and lo < hi and hi <= 1) -- real spread
    assert(t.cols.y[1].n == 50) end         -- 50 labels in
  the.model = "dtlz2" end -- restore the default

eg["--pure"] = function(    t,lab) -- rank whole pool, no
  t   = Dtlz()                     -- train/test split
  lab = t:acquirer(the.budget - the.check)
  print("best found (one instance):")
  instance(t, lab[1])
  assert(t:disty(lab[1]) <= t:disty(lab[#lab])) end

eg["--why"] = function(    t,lab) -- which x-ranges reach
  t   = Dtlz()                    -- the good goals?
  lab = t:acquirer(the.budget - the.check)
  Tree(t, lab):show(t)
  assert(#lab <= the.budget) end

eg["--generalize"] = function(    t,best) -- best pick on
  t    = Dtlz()                           -- unseen rows
  best = t:holdout()
  instance(t, best)
  assert(t:disty(best) <= 1) end

eg["--wins"] = function(    t,lab,W,w) -- grade each search
  for _,m in ipairs{"dtlz1","dtlz2","dtlz3","dtlz4", -- vs
                    "dtlz5","dtlz6","dtlz7"} do -- the fully
    the.model = m           -- labelled pool: 100=true best,
    t   = Dtlz()            -- 0=median row, negative=worse
    lab = t:acquirer(the.budget - the.check)
    W   = t:wins()          -- labels the whole pool
    w   = W(lab[1])
    print(("%-6s win %4.0f  (%s labels vs %s)"):format(
      m, w, #lab, #t.rows))
    assert(-100 <= w and w <= 100) end
  the.model = "dtlz2" end -- restore the default

--## start-up --------------------------------------------------
go(eg)


return _ENV
