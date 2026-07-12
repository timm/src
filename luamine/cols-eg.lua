-- Tutorial and tests for sym.lua, num.lua and cols.lua.
local eg, h, a, m, l, the = ...

local Sym,Cols = m.Sym, m.Cols

--[[
## Columns: the atoms

In any table of data there are columns of numbers and
columns of symbols: numbers we can add and average; symbols
we can only count and compare. Fold "a a b a c" into a
`Sym`: mode a. Fold 1..5 into a `Num`: mean 3, sd 1.58.
Then parse a header: uppercase leads make Nums, trailing
+/- mark goals, trailing X is ignored. Notice "?" cells
pass through untouched.

| call | returns | what |
|------|---------|------|
| `Sym.new(s,at)` | sym | counts in has{} |
| `Num.new(s,at)` | num | Welford n,mu,m2 |
| `i:add(v)` | v | fold one value in |
| `i:mid()`, `i:spread()` | value | mode/mean, ent/sd |
| `Cols.new(names)` | cols | typed columns from header |
]]

eg["--cols"] = function(    sym,num,cols)
  sym  = m.adds({"a","a","b","a","c"}, Sym.new())
  num  = m.adds{1,2,3,4,5}
  cols = Cols.new{"Age","name","Mpg+","Wt-","statusX"}
  return l.chk({"sym mid",sym:mid(),"a"},
    {"sym spread>0",sym:spread()>0,true},
    {"num mid",num:mid(),3},
    {"num sd",num:spread(),1.5811,1E-3},
    {"? skip",num:add("?"),"?"},
    {"#x",#cols.x,2}, {"#y",#cols.y,2},
    {"goal+",cols.all[3].goal,1}, {"goal-",cols.all[4].goal,0},
    {"skipX",cols.all[5].goal,nil}) end
