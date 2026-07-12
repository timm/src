-- Sym. Summarizes one symbolic column: counts in has{}.
-- `mid` = mode, `spread` = entropy; `cuts` emits one ==cut
-- per value seen (one-vs-rest).
local m, l, the = ...

local Sym = {}

-- ctor: symbol counts in has{}
function Sym.new(s,at)
  return l.new(Sym, {at=at or 0, txt=s or "", n=0, has={}}) end

-- bump count for v, weight w; skip "?" and nil
function Sym.add(i,v,    w)
  if v=="?" or v==nil then return end
  w = w or 1
  i.n, i.has[v] = i.n + w, w + (i.has[v] or 0) end

-- mid of Sym = mode
function Sym.mid(i) return l.mode(i.has) end
-- spread of Sym = entropy
function Sym.spread(i) return l.ent(i.has) end

-- one ==cut per value seen in rows (one-vs-rest)
function Sym.cuts(i,rows,    seen,cuts,x)
  seen,cuts = {},{}
  for _,r in ipairs(rows) do
    x = r[i.at]; if x~="?" then seen[x]=true end end
  seen = l.sort(l.kap(seen, function(k,_) return k end))
  for _,v in ipairs(seen) do
    l.push(cuts, m.cut(i,m.eq,v,"==","~=")) end
  return cuts end

m.Sym = Sym
