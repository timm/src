#!/usr/bin/env lua
-- abc-eg.lua: demos and tests for abc.lua, one eg per
-- library section. --name args run egs; --key=val (or
-- -k val) args set options; each eg is reseeded. E.g.
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
  Tree.grow(t, acquire.top(t)):show(t) end

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

eg["-h"] = function() 
  print(abc.help,"\n\nExamples:\n")
  for k,_ in lst.items(eg) do print("  lua abc-eg.lua "..k) end end

eg["--doc"] = function(    f,b,s,i)
  os.execute(
    "pycco -d ~/tmp abc.lua && echo '" ..
    "p {text-align:right;} " ..
    "h2 {border-top:1px solid #ddd; margin-top:2.5em; " ..
    "padding-top:.5em;}' >> ~/tmp/pycco.css")
  b = io.open"badges.html"
  if b then
    f = io.open(str.filename"~/tmp/abc.html","r+"); s = f:read"*a"
    i = s:find("<h1",1,true)
    f:seek("set", i-1); f:write(b:read"*a", s:sub(i)):close()
    b:close() end end

eg["--all"] = function()
  for _,k in ipairs{"--the","--tbl","--disty","--acquire",
                    "--tree","--same","--holdout"} do
    print("\n-- " .. k)
    rnd.seed(the.seed)
    eg[k]() end end

-- args run left to right: --key=val (or "-x v", x = an
-- option's first letter) sets options; eg names run. So
-- flags steer only the egs that follow them.
for i,s in ipairs(arg) do
  local k,v = s:match"^%-%-(%w+)=(%S+)$"
  if v then
    if the[k] == nil then error("unknown --" .. k) end
    the[k] = str.what(v) end
  for k,_ in pairs(the) do
    if s == "-" .. k:sub(1,1) then
      if not arg[i+1] or eg[arg[i+1]] then error(s.." arg?") end
      the[k] = str.what(arg[i+1]) end end
  if eg[s] then rnd.seed(the.seed); eg[s]() end end
