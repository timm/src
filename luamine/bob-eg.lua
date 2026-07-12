-- Tutorial and tests for bob.lua.
local eg, h, a, m, l, the = ...

local Num = m.Num

--[[
## Someplace cool: the whole rig

`bob` is the pipeline: split the rows, acquire labels on
the train half, tree the labels, rank the unseen test half,
check the top few. `--acq` batches it: one csv in, one
"win disty file" line out.

| call | returns | what |
|------|---------|------|
| `a.bob(data,score)` | row,dxdy | best unseen test row |
]]

eg["--bob"] = function(    data,best,d)
  data = h.pickData()
  the.budget = 20
  the.start = 10
  best, d = a.bob(data)
  return l.chk({"bob is row",best ~= nil,true},
               {"win number",type(d.win(best)),"number"}) end

eg["--acq"] = function(    data,win,dy,best,d,ok,err)
  ok, err = pcall(function()
    data = h.loadCsv(the.train)
    if not data then error("missing file") end
    win, dy = Num.new(), Num.new()
    for _=1,the.repeats do
      best, d = a.bob(data)
      win:add(d.win(best))
      dy:add(m.disty(data.cols, best, the.p)) end
    print(string.format("%4.0f  %.4f  %s",
                        win.mu, dy.mu, the.train)) end)
  if not ok then print(string.format("ERR   ---     %s  # %s",
                                     the.train, err)) end
  return true end
