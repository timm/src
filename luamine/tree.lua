-- Tree (build). `bitree` grows a greedy binary tree; its
-- pick(rows) callback returns y,Sumr to keep splitting, or
-- nil to leaf. `Data.tree` supervises on y (default:
-- disty). `Data.ftree` is unsupervised fastmap over pole
-- projections: y columns never consulted.
local m, l, the = ...

local floor,rand = math.floor, math.random
local Data = m.Data

-- generic greedy bi-tree; pick(rows)->y,Sumr|nil
function m.bitree(cols,rows,leaf,pick,    y,Sumr,cut,ls,rs)
  y,Sumr = pick(rows)
  if y then
    cut = m.bestCut(cols,rows,y,Sumr)
    if cut then
      ls,rs = cut:apply(rows,y,Sumr)
      if #ls>=leaf and #rs>=leaf then
        cut.rows  = rows
        cut.left  = m.bitree(cols,ls,leaf,pick)
        cut.right = m.bitree(cols,rs,leaf,pick)
        return cut end end end
  return {rows=rows, leaf=true} end

-- supervised bi-tree on y (default disty)
function Data.tree(i,y,Sumr,leaf,  p)
  leaf, Sumr = leaf or the.leaf, Sumr or m.Num.new
  y = y or i:dxdy(p).y
  return m.bitree(i.cols, i.rows, leaf, function(rs)
    if #rs>=leaf then return y,Sumr end end) end

-- 2 far rows via fastmap: rand->far->far(far)
function m.poles(d,rows,    far,a,b)
  far = function(piv) return l.keysort(rows, function(r)
          return d.x(piv,r) end)[1 + floor(0.9 * #rows)] end
  a = far(rows[rand(#rows)])
  b = far(a)
  return a, b end

-- fastmap bi-tree: split on pole projection;
-- y cols never consulted; rows cap-sampled first
function Data.ftree(i,leaf,p,cap,    d)
  cap, leaf, p = cap or the.cap, leaf or the.leaf, p or the.p
  d = i:dxdy(p)
  return m.bitree(i.cols, l.anys(i.rows,cap), leaf,
    function(rs,    a,b,y)
      if #rs < 2*leaf then return end
      a,b = m.poles(d,rs)
      y = function(r) return d.x(r,a) - d.x(r,b) end
      return y, m.Num.new end) end
