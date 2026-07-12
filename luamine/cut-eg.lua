-- Tutorial and tests for cut.lua.
local eg, h, a, m, l, the = ...

local floor,rand = math.floor, math.random
local Data = m.Data

--[[
## Cuts

To explain anything we need splits. A cut is one test:
op(row[at], val). Five visible rows split at X1 <= 3; then
1000 noisy rows where class flips at X1 > 67 -- and
`bestCut` recovers that boundary (~67) without being told.
Notice: the cut search reads only x summaries and a y
function; it never needs to know what y means.

| call | returns | what |
|------|---------|------|
| `col:cuts(rows)` | cuts | candidate tests, one col |
| `cut:apply(rows,y)` | ls,rs,+sums | split both ways |
| `m.bestCut(cols,rows,y)` | cut | min size-wtd spread |
]]

eg["--cuts"] = function(    data,cuts,ls,rs,best,v,was)
  was, the.bins = the.bins, 2
  data = Data.new{{"X1","name"},
    {1,"a"},{2,"a"},{3,"b"},{4,"b"},{5,"c"}}
  cuts = data.cols.x[1]:cuts(data.rows)
  ls,rs = cuts[1]:apply(data.rows, function(r) return r[1] end)
  the.bins = 10
  data = {{"X1","X2","class!"}}
  for _=1,1000 do
    v = floor(100*rand())
    l.push(data, {v, rand(), v>67 and "a" or "b"}) end
  data = Data.new(data)
  best = m.bestCut(data.cols, data.rows,
                   function(r) return r[#r] end)
  the.bins = was
  return l.chk({"cut val",cuts[1].val,3}, {"split",#ls+#rs,5},
    {"finds X1",best.txt,"X1"}, {"cut ~67",best.val,67,8}) end
