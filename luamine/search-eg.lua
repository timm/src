-- Tutorial and tests for search.lua.
local eg, h, a, m, l, the = ...

--[[
## (1+1) search

One current solution, one mutant at a time. `sa` accepts
worse kids early (metropolis, cooling); `ls` is greedy with
restarts. Both ride the same `oneplus1` stepper.

| call | returns | what |
|------|---------|------|
| `a.sa(data)` | stepper | simulated annealing |
| `a.ls(data)` | stepper | greedy local search |
]]

eg["--sa"] = function(    data)
  data = h.pickData()
  return h.runRace(data, {{"sa", a.sa(data)}}) end

eg["--ls"] = function(    data)
  data = h.pickData()
  return h.runRace(data, {{"ls", a.ls(data)}}) end
