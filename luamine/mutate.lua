-- Mutate. Mutators for the optimizer apps: `pick` samples
-- one column (Sym by frequency, Num by gauss +-3sd);
-- `picks` mutates n random x cells; `extrapolate` is DE's
-- a + F*(b - c), wrapped to mu +- 4sd.
local m, l, the = ...

local min,max,rand = math.min, math.max, math.random

-- sample new value: Sym by freq, Num gauss+-3sd
function m.pick(col,v,    tmp,lo,hi,new)
  if not col.mu then return l.pickDict(col.has) end
  tmp = (v and v ~= "?") and v or col.mu
  lo, hi = col:lohi(3)
  new = tmp + col:spread() * l.irwinHall()
  return max(lo, min(hi, new)) end

-- copy row; mutate n random x cols via pick
function m.picks(data,row,n,    out,xs,col)
  out, xs = l.copy(row), {}
  for _,col in ipairs(data.cols.x) do xs[1+#xs] = col end
  l.shuffle(xs)
  for j = 1, min(n, #xs) do
    col = xs[j]; out[col.at] = m.pick(col, out[col.at]) end
  return out end

-- DE blend a+F*(b-c) per dim, prob CR; wraps
-- to mu+-4sd; Syms flip to b with prob F; "?" keeps a
function m.extrapolate(cols,a,b,c,F,CR,
                       out,va,vb,vc,v,lo,hi,span,keep)
  F, CR = F or the.F, CR or the.cr
  out  = l.copy(a)
  keep = cols[rand(#cols)]
  for _,col in ipairs(cols) do
    if col ~= keep and rand() < CR then
      va,vb,vc = a[col.at], b[col.at], c[col.at]
      if va == "?" then out[col.at] = "?"
      elseif not col.mu then
        out[col.at] = (rand() < F) and vb or va
      elseif vb=="?" or vc=="?" then out[col.at] = va
      else
        v = va + F*(vb-vc)
        lo, hi = col:lohi(4)
        span = hi - lo + 1E-32
        out[col.at] = lo + (v - lo) % span end end end
  return out end
