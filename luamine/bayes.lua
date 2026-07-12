-- Bayes. `like` = P(v|col): m-estimate for Syms, gaussian
-- pdf for Nums. `likes` = log-sum likelihood of one row
-- given one class's data. Enough for naive bayes (see the
-- classify app).
local m, l, the = ...

local exp,log,sqrt,pi = math.exp, math.log, math.sqrt, math.pi

-- P(v|col): Sym m-estimate, Num gaussian pdf
function m.like(col,v,prior,    sd,z)
  if not col.mu then
    return ((col.has[v] or 0) + the.k*prior)
           / (col.n + the.k) end
  sd = col:spread() + 1E-32; z = 2 * sd * sd
  return exp(-(v-col.mu)^2 / z) / sqrt(pi * z) end

-- log-sum likelihood of row given class data
function m.likes(data,row,nRows,nKlasses,  prior,out,v)
  prior = (#data.rows + the.m) / (nRows + the.m * nKlasses)
  out = log(prior)
  for _,c in ipairs(data.cols.x) do
    v = row[c.at]
    if v ~= "?" and v ~= nil then
      v = m.like(c,v,prior)
      if v > 0 then out = out + log(v) end end end
  return out end
