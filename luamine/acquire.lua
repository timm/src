-- Acquire. Active learning: label the top-scored unlabeled
-- row, re-cap best, repeat to budget. Two acquisition
-- scores: Bayes (like best minus like rest) and centroid
-- distance.
local a, m, l, the = ...

local floor,sqrt = math.floor, math.sqrt

-- acquisition score: like(best) - like(rest)
function a.acquireBayes(best,rest,row,    n)
  n = #best.rows + #rest.rows
  return m.likes(best,row,n,2) - m.likes(rest,row,n,2) end

-- acquisition score: dist to rest mid - best mid
function a.acquireCentroid(data,best,rest,row)
  return m.distx(data.cols,row,rest.cols:mid(),the.p)
       - m.distx(data.cols,row,best.cols:mid(),the.p) end

-- rows sorted ascending by disty (best first)
local function byDisty(data,rs)
  return l.keysort(rs,
    function(r) return m.disty(data.cols,r,the.p) end) end

-- label first start rows; split best/rest by sqrt
local function warmStart(data,rows,start,    lab,sorted,cap)
  lab    = data:clone(l.slice(rows, 1, start))
  sorted = byDisty(lab, lab.rows)
  cap    = floor(sqrt(#lab.rows))
  return lab,
         data:clone(l.slice(sorted, 1,     cap)),
         data:clone(l.slice(sorted, cap+1)),
         l.slice(rows, start+1) end

-- evict best's worst row when |best|>sqrt(|lab|)
local function capBest(best,rest,lab)
  if #best.rows > floor(sqrt(#lab.rows)) then
    best.rows = byDisty(lab, best.rows)
    rest:add(table.remove(best.rows)) end end

-- active learning: label top-scored unlabeled,
-- recap best, repeat to budget; returns labeled Data
function a.acquire(data,score,budget,start,
                   rows,lab,best,rest,unlab,top)
  score  = score  or a.acquireBayes
  budget = budget or the.budget
  start  = start  or the.start
  rows   = l.shuffle(l.slice(data.rows))
  lab, best, rest, unlab = warmStart(data, rows, start)
  for _=1,budget do
    if #unlab == 0 then break end
    top = l.keysort(unlab,
      function(r) return score(data,best,rest,r) end, l.gt)
    lab:add(top[1]); best:add(top[1])
    unlab = l.slice(top, 2)
    capBest(best, rest, lab) end
  return lab end
