#!/usr/bin/env lua
-- abc-eg.lua: demos and tests for abc.lua, one eg per
-- library section. Bare names run egs; --key=val args set
-- options; each eg is reseeded. E.g.
--   lua abc-eg.lua --seed=2 tree holdout
local abc = require"abc"
local the,lst,rnd,str = abc.the, abc.lst, abc.rnd, abc.str
local Tbl,Tree        = abc.Tbl, abc.Tree
local acquire         = abc.acquire
local eg = {}

function eg.the() print(str.o(the)) end

function eg.tbl(    t)
  t = Tbl.new(the.file)
  print(#t.rows, str.o(lst.map(t.cols.y,
                  function(c) return c.txt end))) end

function eg.disty(    t,rows)
  t    = Tbl.new(the.file)
  rows = lst.keysort(t.rows,
                     function(r) return t:disty(r) end)
  for j = 1, 5 do print(str.o(rows[j])) end
  print""
  for j = #rows - 4, #rows do print(str.o(rows[j])) end end

function eg.acquire(    t,got)
  t   = Tbl.new(the.file)
  got = acquire.top(t)
  print(#got, str.o(t:disty(got[1]))) end

function eg.tree(    t)
  t = Tbl.new(the.file)
  Tree.grow(t, acquire.top(t)):show() end

function eg.same(    a,b,c)
  a, b, c = {}, {}, {}
  for _ = 1, 32 do
    lst.push(a, rnd.n())
    lst.push(b, rnd.n())
    lst.push(c, 2 + rnd.n()) end
  print(abc.stats.same(a,b), abc.stats.same(a,c)) end

function eg.holdout(    t)
  t = Tbl.new(the.file)
  print("win", t:wins()(t:holdout())) end

function eg.all()
  for _,k in ipairs{"the","tbl","disty","acquire",
                    "tree","same","holdout"} do
    print("\n-- " .. k)
    rnd.seed(the.seed)
    eg[k]() end end

for _,s in ipairs(arg) do
  str.settings(s)
  if eg[s] then rnd.seed(the.seed); eg[s]() end end
