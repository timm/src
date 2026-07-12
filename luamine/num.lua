-- Num. Summarizes one numeric column by Welford (n,mu,m2):
-- `mid`/`spread` = mean/sd; `norm` squashes to 0..1 via a
-- logistic z-score; `cuts` emits bins-1 percentile <=cuts.
-- A name ending "-" sets goal 0 (minimize).
local m, l, the = ...

local floor,exp = math.floor, math.exp
local min,max = math.min, math.max
local Num = {}

-- ctor: welford state; goal 0 if name ends "-"
function Num.new(s,at)
  return l.new(Num, {at=at or 0, txt=s or "", n=0, mu=0, m2=0,
                     goal=(s or ""):find"-$" and 0 or 1}) end

-- welford update; skip "?" and nil
function Num.add(i,v,w)
  if v=="?" or v==nil then return v end
  i.n,i.mu,i.m2 = l.welford(v, i.n, i.mu, i.m2, w)
  return v end

-- mid of Num = mean
function Num.mid(i) return i.mu end
-- spread of Num = stdev
function Num.spread(i) return l.sd(i.n, i.m2) end
-- mu +- k spreads (legal range for mutants)
function Num.lohi(i,k)
  return i.mu - k*i:spread(), i.mu + k*i:spread() end

-- sigmoid-normalize v to 0..1; "?" passes through
function Num.norm(i,v)
  if v=="?" then return v end
  v = (v - i.mu) / (i:spread() + 1E-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, v)))) end

-- bins-1 percentile-spaced <=cuts, deduped
function Num.cuts(i,rows,    vs,n,cuts,v,prev)
  vs = {}
  for _,r in ipairs(rows) do
    if r[i.at]~="?" then l.push(vs, r[i.at]) end end
  if #vs < 2 then return {} end
  l.sort(vs); n,cuts = #vs, {}
  for j = 1, the.bins-1 do
    v = vs[max(1, floor(j * n / the.bins + 0.5))]
    if v ~= prev then
      l.push(cuts, m.cut(i,m.le,v,"<=",">")); prev = v end end
  return cuts end

m.Num = Num
