-- Tutorial and tests for bayes.lua.
local eg, h, a, m, l, the = ...

local huge = math.huge
local Sym,Num,Data = m.Sym, m.Num, m.Data

--[[
## Bayes

Two functions make a naive bayes classifier: `like` scores
one value against one column (frequency for Syms, gaussian
for Nums); `likes` log-sums a whole row against one class's
data. Six visible rows, two obvious classes; the row
(1,1,?) must look "lo". Notice the log-space sums: products
of tiny probabilities underflow, sums of logs do not.

| call | returns | what |
|------|---------|------|
| `m.like(col,v,prior)` | prob | P(v given col) |
| `m.likes(data,row,n,k)` | log prob | row given class |
]]

eg["--bayes"] = function(    s,n,data,got)
  s = m.adds({"a","a","b"}, Sym.new"k")
  n = m.adds({1,2,3,4,5}, Num.new"Y")
  data = Data.new{{"X1","X2","class!"},
    {1,1,"lo"},{1,2,"lo"},{2,1,"lo"},
    {9,9,"hi"},{9,8,"hi"},{8,9,"hi"}}
  got = m.likes(data, {1,1,"?"}, 6, 2)
  return l.chk({"sym like>0",m.like(s,"a",0.5) > 0,true},
    {"num like>0",m.like(n,3,0.5) > 0,true},
    {"finite",got==got and got > -huge,true}) end
