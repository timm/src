#!/usr/bin/env lua
-- ezr-eg.lua: demos/tests for ezr.lua. Every demo
-- reseeds, prints, then asserts. Run one with --tree etc;
-- all with --all; set knobs with --key=val.
local abs,log,sqrt = math.abs, math.log, math.sqrt
local cos,pi       = math.cos, math.pi

-- find ezr.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
-- all defs below land here; reads fall through to ezr3
-- (and, through it, to lib and _G)
local _ENV = setmetatable({}, {__index = require"ezr"})
if setfenv then setfenv(1, _ENV) end

--## demos p ---------------------------------------------------
eg = {}

eg["--tree"] = function(    t,tr,n,best) -- prune, keep best
  t  = Tbl(csv())
  tr = Tree(t, t.rows)
  n  = 0
  tr:walk(function(w)
    n = n + 1
    if not best or w.val < best.val or
       (w.val == best.val and w.leafs < best.leafs) then
      best = w end end)
  print(("tree: %s leafs. prunings: %s. best: %s leafs,"
         .." val %s"):format(tr.leafs, n, best.leafs,
                               show(best.val)))
  assert(best.val <= tr.val and best.leafs <= tr.leafs) end

eg["--all"] = function(    bad) -- all demos; fail if any do
  bad = 0
  for _,k in ipairs(keys(eg)) do
    if k ~= "--all" and k ~= "--repl" and run(eg, k) == false then
      bad = bad + 1 end end
  print("failures: " .. bad)
  assert(bad == 0) end

eg["--repl"] = function() repl(_ENV) end -- interactive prompt,
                                         -- bare names (Tbl, csv..)

eg["--the"] = function() print(show(the)) end

eg["--csv"] = function(    t) -- cells coerced, header named
  t = Tbl(csv())
  print(#t.rows, show(t.cols.names))
  assert(#t.rows == 398 and t.rows[1][1] == 8) end

eg["--col"] = function(    n,s) -- Num and Sym summaries
  n = adds{1,2,3,4,5}
  s = adds({"a","a","b"}, Sym())
  print(show{mu=n:mid(), sd=n:div(),
             mode=s:mid(), ent=s:div()})
  assert(n:mid() == 3 and s:mid() == "a") end

eg["--without"] = function(    a,b,w) -- (a+b) minus b == a
  a, b = adds{1,2,3,4,5}, adds{10,20,30}
  w = adds({10,20,30}, adds{1,2,3,4,5}) - b
  print(show{mu=w.mu, sd=w:div()})
  assert(abs(w.mu - a.mu) < 1e-9) end

eg["--sub"] = function(    t,c,n1,mu1,xtra) -- add then
  t  = Tbl(csv())            -- forget: stats round-trip
  c  = t.cols.all[1]
  n1, mu1 = c.n, c.mu
  xtra = some(t.rows, 50)
  for _,r in ipairs(xtra) do t:add(r) end
  for _,r in ipairs(xtra) do t:sub(r) end
  print(show{n=c.n, mu=c.mu, was=mu1})
  assert(c.n == n1 and abs(c.mu - mu1) < 1e-9) end

eg["--distx"] = function(    t,d) -- self=0; far pair > near
  t = Tbl(csv())
  d = function(a,b) return t:distx(a, b) end
  print(show{self=d(t.rows[1], t.rows[1]),
             near=d(t.rows[1], t.rows[2]),
             far =d(t.rows[1], t.rows[398])})
  assert(d(t.rows[1], t.rows[1]) == 0) end

eg["--laws"] = function(    t,a,b,c,v,x,yes,no) -- 100
  t = Tbl(csv())          -- random probes of the invariants
  for _ = 1, 100 do
    a = t.rows[rand(#t.rows)]
    b = t.rows[rand(#t.rows)]
    assert(t:distx(a, a) == 0)               -- self is zero
    assert(t:distx(a, b) == t:distx(b, a))   -- symmetry
    v = t:distx(a, b)
    assert(0 <= v and v <= 1)                -- bounded x gap
    v = t:disty(a)
    assert(0 <= v and v <= 1)                -- bounded y gap
    c = t.cols.x[rand(#t.cols.x)]
    yes, no = t:divide(t.rows, c, a[c.at])
    assert(#yes + #no == #t.rows)            -- rows conserved
    x = sorted(map(some(t.rows, 32), t:Y()))
    assert(same(x, x)) end                   -- x is like x
  print"100 rounds, 6 laws: ok" end

eg["--half"] = function(    t,a,b,lo,hi) -- far-pole split
  t = Tbl(csv())
  a, b, lo, hi = t:halve(t.rows)
  print(show{lo=#lo, hi=#hi,
             a=t:disty(a), b=t:disty(b)})
  assert(#lo + #hi == #t.rows)
  assert(t:disty(a) <= t:disty(b)) end

eg["--node"] = function(    t,nd,n,leafs,walk) -- rows
  t  = Tbl(csv())  -- conserved in leafs
  nd = Node(t)
  n, leafs = 0, 0
  walk = function(x)
    if x.lo then walk(x.lo); walk(x.hi)
    else n = n + #x.here.rows; leafs = leafs + 1 end end
  walk(nd)
  print(show{leafs=leafs, rows=n,
             leaf1=t:disty(nd:leaf(t.rows[1]).here.rows[1])})
  assert(n == #t.rows and leafs > 1) end

eg["--cuts"] = function(    t,b,c) -- champion cut, named
  t = Tbl(csv())
  b = t:bestcut(t.rows, t:Y(), Num, least())
  c = t.cols.all[b[2]]
  print(("best cut: %s <= %s (val %.3f)")
        :format(c.name, b[3], b[1]))
  assert(b[1] >= 0 and c) end

eg["--show"] = function(    t,tr) -- tree, goal mean columns
  t  = Tbl(csv())
  tr = Tree(t, t.rows)
  tr:show(t)
  assert(tr.leafs > 1) end

eg["--acquire"] = function(    t,y,lab,best,truth)
  t     = Tbl(csv())
  y     = t:Y()
  lab   = t:acquirer(the.budget)
  best  = y(lab[1])
  truth = y(keysort(t.rows, y)[1])
  print(show{labels=#lab, best=best, truth=truth})
  assert(#lab <= the.budget and best < 0.35) end

eg["--holdout"] = function(    t,b,w) -- train half, test half
  t = Tbl(csv())
  t.rows = some(t.rows, the.cap)
  b = t:holdout()
  w = t:wins()
  print(show{disty=t:disty(b), win=w(b)})
  assert(-100 <= w(b) and w(b) <= 100) end

eg["--holdouts"] = function(    t,W,go,L,R,ml,mr,v) -- 20
  t  = Tbl(csv())                 -- runs: active vs random
  t.rows = some(t.rows, the.cap)
  W  = t:wins()
  go = function(how,    u) u = {}
         for j = 1, 20 do
           srand(the.seed + j)
           u[1+#u] = W(t:holdout(how)) end
         return sorted(u) end
  L  = go()                       -- active acquire
  R  = go(function(t2,cap)        -- random: first cap rows
         return sub(t2.rows, 1, cap) end)
  ml = sum(L, function(x) return x end) / 20
  mr = sum(R, function(x) return x end) / 20
  v  = same(L, R) and "tie" or (ml > mr and "land" or "rand")
  print(show{active=ml, random=mr, verdict=v})
  assert(#L == 20 and #R == 20) end

eg["--ranks"] = function(    g,d,r) -- ties share a rank
  g = function(mu,    u) u = {}
        for j = 1, 20 do
          u[j] = mu + rand() + rand() - 1 end
        return u end
  d = {a=g(0), b=g(0.05), c=g(2), e=g(4)}
  r = ranks(d)
  print(show(r.ranks), show(r.winners))
  assert(r.ranks.a == 0 and r.ranks.e > r.ranks.c) end

eg["--same"] = function(    g,x,y,c,k,cl,s,n) -- 3 tests
  g = function(    u) u = {}       -- vote; same() ANDs them
        for j = 1, 100 do           -- box-muller gaussians
          u[j] = sqrt(-2*log(1 - rand()))
                 * cos(2*pi*rand()) end
        return sorted(u) end
  x, n = g(), 0    -- y = x + shift: pure effect, no noise
  print("shift  cohen     ks cliffs |  same    any")
  for _, mu in ipairs{0, .1, .2, .3, .34, .36, .38,
                      .4, .44, .5, .75, 1, 1.5, 2} do
    y  = map(x, function(v) return v + mu end)
    c  = cohen(x, y)  <= 0.35
    k  = ks(x, y)     <= 1.36
    cl = cliffs(x, y) <= 0.195
    s  = same(x, y)
    if s ~= (c or k or cl) then n = n + 1 end -- split vote
    print(("%5.2f  %5s  %5s  %5s | %5s  %5s"):format(mu,
      tostring(c), tostring(k), tostring(cl),
      tostring(s), tostring(c or k or cl)))
  end
  print("split votes: " .. n)
  assert(n >= 1)          -- AND stricter than OR somewhere
  assert(same(x, x) and not same(x, map(x,
    function(v) return v + 4 end))) end

eg["--disty"] = function(    t,d,rows) -- sort rows by disty
  t = Tbl(csv())
  d = t:Y()
  rows = keysort(t.rows, d)
  for at, r in ipairs(rows) do
    if at <= 3 or at > #rows - 3 then
      print(("%.3f  %s"):format(d(r), show(r)))
    elseif at == 4 then print"..." end end
  assert(d(rows[1]) <= d(rows[#rows])) end

--## start-up --------------------------------------------------
go(eg)

return _ENV
