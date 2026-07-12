-- Cuts. A `cut` is one test: op(row[at], val). `eq` and
-- `le` are the two ops; `cut` packs one with its yes/no
-- print names and an imputation `mid`. Using cuts: `apply`
-- splits rows ("?" imputed via mid), returning both sides
-- plus their y summaries; `score` = size-weighted
-- y-spread; `bestCut` = min score over every cut of every
-- x column.
local m, l, the = ...

local huge = math.huge
local Cut = {}

-- cut op: equality
function m.eq(a,b) return a==b end
-- cut op: less-or-equal
function m.le(a,b) return a<=b end

-- build one Cut on col c: op(row[c.at], val)
function m.cut(c,op,val,yes,no)
  return l.new(Cut, {at=c.at, op=op, val=val, yes=yes, no=no,
                     mid=c:mid(), txt=c.txt}) end

-- split rows on cut; "?" imputed via cut.mid;
-- also returns y-summaries of both sides
function Cut.apply(i,rows,y,Sumr,    ls,rs,lsum,rsum,x)
  Sumr = Sumr or m.Sym.new
  ls,rs,lsum,rsum = {},{},Sumr(),Sumr()
  for _,r in ipairs(rows) do x = r[i.at]
    if x=="?" then x = i.mid end
    if i.op(x, i.val)
    then ls[1+#ls]=r; lsum:add(y(r))
    else rs[1+#rs]=r; rsum:add(y(r)) end end
  return ls,rs,lsum,rsum end

-- size-weighted y-spread after applying cut
function Cut.score(i,rows,y,Sumr,    ls,rs,lsum,rsum)
  ls,rs,lsum,rsum = i:apply(rows,y,Sumr)
  if #ls==0 or #rs==0 then return huge end
  return (lsum.n*lsum:spread() + rsum.n*rsum:spread())
       / (lsum.n + rsum.n) end

-- min-score cut across all x cols, all cuts
function m.bestCut(cols,rows,y,Sumr,    best,score,s)
  best,score = nil, huge
  for _,c in ipairs(cols.x) do
    for _,cut in ipairs(c:cuts(rows)) do
      s = cut:score(rows,y,Sumr)
      if s<score then best,score = cut,s end end end
  return best end

m.Cut = Cut
