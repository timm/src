-- Tutorial and tests for acquire.lua.
local eg, h, a, m, l, the = ...

--[[
## Active learning

Labels are dear: `acquire` warm-starts on a few labeled
rows, splits them best/rest, then repeatedly labels the
unlabeled row the Bayes score likes most.

| call | returns | what |
|------|---------|------|
| `a.acquire(data,score)` | data | the labeled few |
| `a.acquireBayes(b,r,row)` | num | like(best)-like(rest) |
]]

eg["--acquire"] = function(    data,lab,was)
  data = h.pickData()
  was, the.start = the.start, 10
  the.budget = 20
  lab = a.acquire(data, a.acquireBayes)
  the.start = was
  return l.chk({"labeled grew", #lab.rows > 10, true}) end
