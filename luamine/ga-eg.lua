-- Tutorial and tests for ga.lua.
local eg, h, a, m, l, the = ...

--[[
## Genetic algorithm

Mutate, tournament select, crossover; the tracker snaps
every kid to its nearest real row and logs each new global
best.

| call | returns | what |
|------|---------|------|
| `a.ga(data,better)` | stepper | one call = one gen |
]]

eg["--ga"] = function(    data)
  data = h.pickData()
  the.budget = 512
  the.np, the.cr, the.gens = 50, 0.25, 50
  return h.runRace(data, {{"ga", a.ga(data, a.knn(data))}}) end
