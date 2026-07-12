-- Classify. Incremental naive bayes, test-then-train:
-- predict each row's klass from the models so far, score
-- the guess in a Confuse matrix, then train on the truth.
local a, m, l, the = ...

local huge = math.huge

-- incremental NB: predict, score, then train
function a.classify(data,wait,    h,cf,nKl,want,best,bs,s)
  wait = wait or the.wait
  h, cf, nKl = {}, l.Confuse.new(), 0
  for i,row in ipairs(data.rows) do
    want = row[data.cols.klass.at]
    if i >= wait and nKl > 0 then
      best, bs = nil, -huge
      for _,klass in ipairs(
          l.sort(l.kap(h, function(k,_) return k end))) do
        s = m.likes(h[klass], row, #data.rows, nKl)
        if s > bs then bs, best = s, klass end end
      cf:add(want, best) end
    if not h[want] then h[want] = data:clone(); nKl = nKl+1 end
    h[want]:add(row) end
  return cf end
