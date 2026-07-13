#!/usr/bin/env lua
-- abc-eg.lua: demos and tests for abc.lua, one eg per
-- library section. --name args run egs; --key=val args set
-- options; each eg is reseeded. E.g.
--   lua abc-eg.lua --seed=2 --tree --holdout
local abc = require"abc"
local the,lst,rnd,str = abc.the, abc.lst, abc.rnd, abc.str
local Tbl,Tree        = abc.Tbl, abc.Tree
local acquire         = abc.acquire
local eg = {}

eg["--the"] = function() print(str.o(the)) end

eg["--tbl"] = function(    t)
  t = Tbl.new(the.file)
  print(#t.rows, str.o(lst.map(t.cols.y,
                  function(c) return c.txt end))) end

eg["--disty"] = function(    t,rows)
  t    = Tbl.new(the.file)
  rows = lst.keysort(t.rows,
                     function(r) return t:disty(r) end)
  for j = 1, 5 do print(str.o(rows[j])) end
  print""
  for j = #rows - 4, #rows do print(str.o(rows[j])) end end

eg["--acquire"] = function(    t,got)
  t   = Tbl.new(the.file)
  got = acquire.top(t)
  print(#got, str.o(t:disty(got[1]))) end

eg["--tree"] = function(    t)
  t = Tbl.new(the.file)
  Tree.grow(t, acquire.top(t)):show() end

eg["--same"] = function(    a,b,c)
  a, b, c = {}, {}, {}
  for _ = 1, 32 do
    lst.push(a, rnd.n())
    lst.push(b, rnd.n())
    lst.push(c, 2 + rnd.n()) end
  print(abc.stats.same(a,b), abc.stats.same(a,c)) end

eg["--holdout"] = function(    t)
  t = Tbl.new(the.file)
  print("win", t:wins()(t:holdout())) end

eg["--all"] = function()
  for _,k in ipairs{"--the","--tbl","--disty","--acquire",
                    "--tree","--same","--holdout"} do
    print("\n-- " .. k)
    rnd.seed(the.seed)
    eg[k]() end end

for _,s in ipairs(arg) do str.settings(s) end
for _,s in ipairs(arg) do
  if eg[s] then rnd.seed(the.seed); eg[s]() end end
