-- Bob. The whole pipeline: split, acquire labels on the
-- train half, tree the labels, rank the unseen test half
-- by leaf disty, check the top few; returns the best test
-- row plus a dxdy view for grading.
local a, m, l, the = ...

local floor = math.floor

-- pipeline: split, acquire, tree, check top few;
-- returns best test row + dxdy view
function a.bob(data,score,
               d,rows,h,trH,teH,lab,tree,sorted,best)
  score = score or a.acquireBayes
  d     = data:dxdy()
  rows  = l.shuffle(l.copy(data.rows))
  h     = floor(#rows/2)
  trH   = l.slice(l.slice(rows, 1, h), 1, the.few)
  teH   = l.slice(rows, h+1)
  lab   = a.acquire(data:clone(trH), score)
  tree  = lab:tree()
  sorted = l.keysort(teH, function(r)
    return m.mu_disty(
      lab.cols, m.relevant(tree,r), the.p) end)
  best = l.keysort(l.slice(sorted, 1, the.check), d.y)[1]
  return best, d end
