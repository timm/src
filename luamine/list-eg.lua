-- Tutorial and tests for list.lua.
local eg, h, a, m, l, the = ...

--[[
## Lists

Tiny functional helpers underneath everything else: sort,
slice, copy, shuffle, keysort (decorate-sort-undecorate),
argmin, and an aligned-table printer. Notice keysort: one
call turns "sort by any feature" into a one-liner.

| call | returns | what |
|------|---------|------|
| `l.keysort(t,fn)` | list | sorted by fn-derived key |
| `l.slice(t,lo,hi)` | list | negatives count from end |
| `l.argmin(t,fn)` | index | min-by-fn item |
]]

eg["--lists"] = function(    t,u)
  t = l.shuffle{3,1,2,5,4}
  u = l.sort(l.list{a=1,b=2,c=3})
  return l.chk({"shuffle",#t,5},
    {"sort",l.sort(l.copy(t))[1],1},
    {"list",u[1]..","..u[3],"1,3"},
    {"slice",l.slice({10,20,30,40,50},2,-2)[3],40},
    {"keysort",l.keysort({{1},{0},{2}},l.nth(1))[1][1],0},
    {"argmin",
      l.argmin({30,10,50},function(x) return x end),2}) end

eg["--tabulate"] = function()
  l.tabulate({{"name","age","note"}, {"Alice","30","short"},
              {"Bob","9","longer note here"}}, {"<",">","<"})
  return true end
