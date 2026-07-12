-- Cols. Types header names into columns: leading uppercase
-- = `Num`; trailing -,+,! = y goals (! = klass); X = skip.
-- `add` routes one row's cells; `mid` = cached centroid.
-- `adds` folds a list or iterator into any summary.
local m, l, the = ...

local Cols = {}

-- fold list or iterator into summary it (or Num)
function m.adds(src,it,fn)
  it = it or m.Num.new()
  if   type(src)=="function"
  then for x in src do it:add(fn and fn(x) or x) end
  else for _,x in ipairs(src or {}) do
         it:add(fn and fn(x) or x) end end
  return it end

-- header names -> {all,x,y,klass} typed columns
function Cols.new(names,    i,col)
  i = l.new(Cols, {names=names, all={}, x={}, y={},
                   klass=nil, mids=nil})
  for at,s in ipairs(names) do
    col = (s:match"^[A-Z]" and m.Num or m.Sym).new(s,at)
    l.push(i.all, col)
    if not s:find"X$" then
      l.push(s:find"[-+!]$" and i.y or i.x, col)
      if s:find"!$" then i.klass = col end end end
  return i end

-- update every column with row; wipe mid cache
function Cols.add(i,row)
  i.mids = nil
  for _,c in ipairs(i.all) do c:add(row[c.at]) end
  return row end

-- centroid = mid of each column (cached)
function Cols.mid(i)
  i.mids = i.mids or l.map(i.all,function(c) return c:mid() end)
  return i.mids end

m.Cols = Cols
