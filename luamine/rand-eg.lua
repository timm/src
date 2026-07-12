-- Tutorial and tests for rand.lua.
local eg, h, a, m, l, the = ...

--[[
## Reproducible randomness

A portable Park-Miller generator replaces Lua's stock RNG,
so seeded runs match across machines (and across languages:
ezr2 carries a python twin). `pickDict` rolls a weighted
roulette wheel; `irwinHall` fakes a normal sample from
three uniforms.

| call | returns | what |
|------|---------|------|
| `l.rand(n)` | 0..1 or 1..n | seeded random |
| `l.pickDict(d)` | key | weighted by d's counts |
| `l.irwinHall()` | float | ~normal, mean 0, sd 1 |
]]

eg["--rand"] = function(    d,c,k,n,mu,m2)
  d,c = {a=1,b=10,c=100}, {a=0,b=0,c=0}
  for _=1,1000 do k=l.pickDict(d); c[k]=c[k]+1 end
  n,mu,m2 = 0,0,0
  for _=1,2000 do n,mu,m2 = l.welford(l.irwinHall(),n,mu,m2) end
  return l.chk({"pickDict",c.c>c.b and c.b>c.a,true},
               {"irwin mu~0",mu,0,0.1},
               {"irwin sd~1",l.sd(n,m2),1,0.1}) end
