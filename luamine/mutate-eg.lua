-- Tutorial and tests for mutate.lua.
local eg, h, a, m, l, the = ...

local Data = m.Data

--[[
## Mutation

Optimizers (the app files) need to invent new rows. `pick`
samples one column's distribution; `picks` mutates n random
x cells of a copied row; `extrapolate` is differential
evolution's a + F*(b - c), wrapped back into mu +- 4sd.
Notice what never changes: the y cell of a mutant -- goals
are computed, not guessed.

| call | returns | what |
|------|---------|------|
| `m.pick(col,v)` | value | sample near v (or mid) |
| `m.picks(data,row,n)` | row | mutate n x cells |
| `m.extrapolate(cols,a,b,c,F)` | row | DE blend |
]]

eg["--mutate"] = function(    data,n,row,out,kid)
  data = Data.new{{"X1","X2","Y-"},
    {1,1,10},{2,2,20},{3,3,30},{4,4,40},{5,5,50}}
  n = data.cols.x[1]
  row = {3,3,30}
  out = m.picks(data, row, 2)
  kid = m.extrapolate(data.cols.x,
          data.rows[1], data.rows[3], data.rows[5], the.F)
  return l.chk(
    {"pick in range",m.pick(n,3) <= n.mu+4*n:spread(),true},
    {"picks len",#out,#row}, {"y kept",out[3],row[3]},
    {"kid len",#kid,3}) end
