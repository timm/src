-- Tutorial and tests for data.lua.
local eg, h, a, m, l, the = ...

local Data = m.Data

--[[
## Tables

Five rows, two columns, all visible below. `Data` holds the
rows plus one summary per column; `clone` copies the header
into an empty twin; the centroid is each column's mid.
Notice `dxdy`: it bakes the Minkowski p into x, y and win
functions so later code never threads p around.

| call | returns | what |
|------|---------|------|
| `Data.new(src)` | data | src = rows, iterator, or file |
| `d:clone(rows)` | data | same header, new rows |
| `d.cols:mid()` | list | centroid, cached |
| `d:dxdy(p)` | {x,y,win} | distance views, p baked in |
]]

eg["--data"] = function(    data,b,d,r1,r2)
  data = Data.new{{"X1","X2"},{1,1},{2,2},{3,3},{4,4},{5,5}}
  b = data:clone()
  d = data:dxdy()
  r1,r2 = data.rows[1], data.rows[5]
  return l.chk({"#rows",#data.rows,5},
    {"clone empty",#b.rows,0},
    {"clone hdr",b.cols.all[1].txt,"X1"},
    {"names kept",b.cols.names[2],"X2"},
    {"centroid",data.cols:mid()[1],3},
    {"symmetric",d.x(r1,r2)==d.x(r2,r1),true}) end

--[[
## Streaming rows

Sometimes we want the rows without the header. `body`
returns an iterator that has already consumed line one.
The demo writes a three-row csv, streams it back, counts.

| call | returns | what |
|------|---------|------|
| `m.body(file)` | iterator | csv rows, header skipped |
]]

eg["--body"] = function(    tmp,f,n)
  tmp = os.tmpname()
  f = io.open(tmp,"w")
  f:write("a,b\n1,2\n3,4\n5,6\n"); f:close()
  n = 0; for _ in m.body(tmp) do n=n+1 end; os.remove(tmp)
  return l.chk({"body rows", n, 3}) end
