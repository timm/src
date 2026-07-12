-- Tutorial and tests for race.lua.
local eg, h, a, m, l, the = ...

--[[
## Race them all

Run ga, de, sa and ls under one eval budget; merge their
logs into one global-best timeline. The printed table is
the story: who found what, when, and how good.

| call | returns | what |
|------|---------|------|
| `a.race(data,opts)` | log | merged best timeline |
| `a.report(data,log)` | dists | print + return distys |
]]

eg["--race"] = function(    data)
  data = h.pickData()
  the.np, the.cr, the.gens, the.de_iter = 50, 0.25, 50, 30
  return h.runRace(data, {
    {"ga", a.ga(data, a.knn(data))},
    {"de", a.de(data)},
    {"sa", a.sa(data)},
    {"ls", a.ls(data)}}) end
