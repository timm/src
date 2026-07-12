-- Sample / anomaly. `sample` invents N synthetic rows by
-- DE-blending 3 rows per ftree leaf; `anomalyDetector`
-- calibrates a 1-NN-in-leaf distance CDF on the training
-- rows (tails = anomalies).
local a, m, l, the = ...

local rand,huge = math.random, math.huge

-- collect leaf nodes of a tree
local function leaves(node,out)
  out = out or {}
  if node.leaf then out[1+#out] = node
  else leaves(node.left, out); leaves(node.right, out) end
  return out end

-- N synthetic rows: DE-blend 3 rows per ftree leaf
function a.sample(data,N,    tree,leafs,out,leaf,rs)
  N      = N or 100
  tree   = data:ftree()
  leafs  = leaves(tree)
  out    = {}
  while #out < N do
    leaf = leafs[rand(#leafs)]
    if #leaf.rows >= 3 then
      rs = l.anys(leaf.rows, 3)
      out[1+#out] = m.extrapolate(
        data.cols.x, rs[1], rs[2], rs[3], the.F) end end
  return out end

-- closure row->CDF of 1-NN-in-leaf dist;
-- calibrated on train rows; tails = anomalies
function a.anomalyDetector(data,    tree,dn,d1)
  tree = data:ftree()
  dn   = m.Num.new()
  d1   = function(row,    leaf,nn)
    leaf = m.relevant(tree, row)
    nn   = m.near(data.cols, row, leaf, the.p)[1]
    return nn and m.distx(data.cols,row,nn,the.p) or huge end
  for _,row in ipairs(data.rows) do dn:add(d1(row)) end
  return function(row) return dn:norm(d1(row)) end end
