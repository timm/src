-- Data. Rows + `Cols`; the first row is the header.
-- `clone` reuses a header over new rows. `dxdy` bakes p
-- into x,y,win distance views (win: 100=best, 0=median).
-- `body` iterates a csv's rows, skipping the header.
local m, l, the = ...

local floor,max = math.floor, math.max
local Data = {}

-- rows + cols from iterator or list-of-lists
function Data.new(src)
  return m.adds(src, l.new(Data, {cols=nil, rows={}})) end

-- first row builds cols; later rows stored+added
function Data.add(i,row)
  if not i.cols then i.cols = m.Cols.new(row)
  else i.cols:add(row); l.push(i.rows, row) end
  return row end

-- empty Data, same header; rows optional seed
function Data.clone(i,rows)
  return m.adds(rows or {}, Data.new{i.cols.names}) end

-- dist views x,y,win with p baked in; win 0..100
function Data.dxdy(i,p,    y,lo,mid,sd,prep)
  p = p or the.p
  y = function(r) return m.disty(i.cols,r,p) end
  prep = function(    t,n,ten)
    if lo then return end
    t   = l.sort(l.map(i.rows, y))
    n   = #t; ten = floor(n/10)
    lo, mid = t[1], t[max(1, floor(n/2))]
    sd  = ten>0
          and (t[max(1,9*ten)] - t[max(1,ten)])/2.56 or 0 end
  return {
    x   = function(r1,r2) return m.distx(i.cols,r1,r2,p) end,
    y   = y,
    win = function(r,    x,rng)
      prep()
      x = y(r)
      if x < lo + 0.35*sd then x = lo end
      rng = mid - lo
      if rng == 0 then return 100 end
      return max(-100, floor(100*(1-(x-lo)/rng))) end } end

-- iter csv rows after header
function m.body(file,    iter)
  iter = l.csv(file); iter()
  return iter end

m.Data = Data
