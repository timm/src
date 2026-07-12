-- Dist. `distx` = Minkowski over x cols (pessimistic on
-- "?"); `disty` = distance to ideal y goals (0 = best);
-- `better` = Zitzler domination; `near` sorts rows by
-- distx from a query row.
local m, l, the = ...

local abs,exp = math.abs, math.exp

-- Minkowski dist over x cols; pessimistic "?"
function m.distx(cols,r1,r2,  p,    d,n,v1,v2)
  d,n,p = 0,0,p or the.p
  for _,c in ipairs(cols.x) do
    n = n+1
    v1, v2 = r1[c.at], r2[c.at]
    if v1=="?" and v2=="?" then d=d+1
    elseif c.mu then
      v1, v2 = c:norm(v1), c:norm(v2)
      if v1=="?" then v1 = v2 > 0.5 and 0 or 1 end
      if v2=="?" then v2 = v1 > 0.5 and 0 or 1 end
      d = d + abs(v1-v2)^p
    else
      d = d + (v1==v2 and 0 or 1)^p end end
  return (d/n)^(1/p) end

-- distance to ideal over y goals (0=best)
function m.disty(cols,row,  p,    d,n)
  d,n,p = 0,0,p or the.p
  for _,c in ipairs(cols.y) do
    n,d = n+1, d + abs(c:norm(row[c.at]) - c.goal)^p end
  return (d/n)^(1/p) end

-- Zitzler continuous domination: a betters b?
function m.better(data,row1,row2,    s1,s2,n,w,a,b)
  s1, s2, n = 0, 0, #data.cols.y
  for _,col in ipairs(data.cols.y) do
    a, b = col:norm(row1[col.at]), col:norm(row2[col.at])
    w    = col.goal==1 and 1 or -1
    s1   = s1 - exp(w * (a - b) / n)
    s2   = s2 - exp(w * (b - a) / n) end
  return s1/n < s2/n end

-- rows sorted by distx to query; self parked last
function m.near(cols,query,rows,  p)
  return l.keysort(rows, function(r)
    return r==query and 2 or m.distx(cols,query,r,p) end) end
