-- Tutorial and tests for str.lua.
local eg, h, a, m, l, the = ...

--[[
## Strings and files

`thing` coerces csv cells (bool, number, else string); `o`
pretty-prints anything with sorted dict keys; `csv` streams
typed rows from a file, `path` expanding a leading $MOOT.

| call | returns | what |
|------|---------|------|
| `l.thing(s)` | bool,num,str | coerce one cell |
| `l.o(x)` | str | pretty print |
| `l.csv(file)` | iterator | typed rows |
]]

eg["--str"] = function()
  return l.chk(
    {"int",l.thing"42",42},   {"bool",l.thing"true",true},
    {"str",l.thing"hi","hi"}, {"float",l.o(1.5),"1.50"},
    {"dict",l.o{a=1,b=2},"{a=1, b=2}"},
    {"list",l.o{1,2,3},"{1, 2, 3}"}) end

eg["--csv"] = function(    tmp,f,rows)
  tmp = os.tmpname()
  f = io.open(tmp,"w"); f:write("a,b,c\n1,2,3\n"); f:close()
  rows = {}
  for r in l.csv(tmp) do rows[1+#rows]=r end
  os.remove(tmp)
  return l.chk({"#rows",#rows,2},
    {"head",rows[1][1],"a"}, {"cell",rows[2][3],3}) end
