-- Tutorial and tests for dist.lua.
local eg, h, a, m, l, the = ...

local Data = m.Data

--[[
## Distance

Two distances, two jobs. `distx` reads only x columns: how
far apart two rows are before we know their goals. `disty`
reads only y columns: distance to the ideal goals, 0 =
best. In the goals table below, the row (1,40,1500) -- high
mpg, low weight -- must sit nearer heaven than (4,10,3000).
Notice `near`: 1-nearest-neighbour is one keysort away.

| call | returns | what |
|------|---------|------|
| `m.distx(cols,r1,r2,p)` | 0..1 | over x cols |
| `m.disty(cols,row,p)` | 0..1 | 0 = ideal goals |
| `m.near(cols,query,rows)` | rows | sorted by distx |
]]

eg["--dist"] = function(    data,goals)
  data = Data.new{{"X1","X2"},{1,1},{5,5},{9,9}}
  goals = Data.new{{"X1","Mpg+","Wt-"},
    {1,40,1500},{2,30,2000},{3,20,2500},{4,10,3000}}
  return l.chk(
    {"self=0",m.distx(data.cols,{1,1},{1,1},the.p),0},
    {"far>near",m.distx(data.cols,{1,1},{9,9},the.p)
              > m.distx(data.cols,{1,1},{5,5},the.p),true},
    {"1-NN",m.near(data.cols,{4,4},data.rows,the.p)[1][1],5},
    {"dBest<dWorst",m.disty(goals.cols,{1,40,1500},the.p)
                  < m.disty(goals.cols,{4,10,3000},the.p),
     true})
  end
