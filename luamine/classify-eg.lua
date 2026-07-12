-- Tutorial and tests for classify.lua.
local eg, h, a, m, l, the = ...

local Data = m.Data

--[[
## Classify

Incremental naive bayes, test-then-train: guess each row's
klass from the models so far, score the guess, then learn
the truth. Notice the honesty: every prediction is made
before that row is seen.

| call | returns | what |
|------|---------|------|
| `a.classify(data,wait)` | confuse | scored predictions |
]]

eg["--classify"] = function(    data,cf,n)
  data = h.loadCsv(the.train)
  if not (data and data.cols.klass) then
    data = Data.new{{"X1","X2","klass!"},
      {1,1,"a"},{1,2,"a"},{2,1,"a"},{2,2,"a"},
      {9,9,"b"},{9,8,"b"},{8,9,"b"},{8,8,"b"},
      {1,2,"a"},{9,9,"b"},{2,1,"a"},{8,8,"b"}} end
  cf = a.classify(data)
  cf:show()
  n = 0
  for _,gs in pairs(cf.t) do
    for _,c in pairs(gs) do n = n + c end end
  return l.chk({"cf nonempty", n > 0, true}) end
