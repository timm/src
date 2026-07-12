-- Tutorial and tests for de.lua.
local eg, h, a, m, l, the = ...

--[[
## Differential evolution

DE/rand/1: blend three distinct rows per parent; the kid
replaces its parent when the oracle scores it better.

| call | returns | what |
|------|---------|------|
| `a.de(data,oracle)` | stepper | one call = one gen |
]]

eg["--de"] = function(    data)
  data = h.pickData()
  the.de_iter, the.np = 30, 20
  return h.runRace(data, {{"de", a.de(data)}}) end
