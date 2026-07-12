-- Cluster. `kmeans` = k clusters around centroids, errs
-- per iteration; `kpp` = kmeans++ seeding, d^2-weighted
-- far centroids from a small sampled pool.
local a, m, l, the = ...

local min,rand,huge = math.min, math.random, math.huge

-- k clusters around centroids; errs per iter
function a.kmeans(data,k,iter,cents,    out,errs,err)
  k,iter = k or the.k_cluster, iter or the.iter
  cents  = cents or l.anys(data.rows, k)
  errs   = {}
  for _=1,iter do
    out = l.map(cents, function() return data:clone() end)
    for _,r in ipairs(data.rows) do
      out[l.argmin(cents, function(c)
        return m.distx(data.cols,c,r,the.p) end)]:add(r) end
    err = 0
    for j,kid in ipairs(out) do
      for _,r in ipairs(kid.rows) do
        err = err + m.distx(data.cols,cents[j],r,the.p) end
    end
    errs[1+#errs] = err / #data.rows
    cents = {}
    for _,kid in ipairs(out) do
      if #kid.rows>0 then
        cents[1+#cents] = kid.cols:mid() end end end
  return out, errs end

-- kmeans++ seeding: d^2-weighted far centroids
function a.kpp(data,k,few,    rows,out,t,ws,d,mn)
  rows = data.rows
  k, few = k or the.k_cluster, few or the.few
  out  = { rows[rand(#rows)] }
  while #out < k do
    t, ws = l.anys(rows, min(few, #rows)), {}
    for j=1,#t do
      mn = huge
      for _,c in ipairs(out) do
        d = m.distx(data.cols, t[j], c, the.p)
        if d*d < mn then mn = d*d end end
      ws[j] = mn end
    out[1+#out] = t[l.pickDict(ws)] end
  return out end
