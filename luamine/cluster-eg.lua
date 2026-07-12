-- Tutorial and tests for cluster.lua.
local eg, h, a, m, l, the = ...

--[[
## Clustering

`kmeans` around sampled centroids, error per iteration
(watch it shrink); `kpp` picks smarter starting centroids,
d^2-weighted far from each other.

| call | returns | what |
|------|---------|------|
| `a.kmeans(data,k,iter)` | clusters,errs | k Data + errs |
| `a.kpp(data,k,few)` | rows | k far centroids |
]]

eg["--kmeans"] = function(    data,clusters,errs,n)
  data = h.pickData()
  clusters, errs = a.kmeans(data, 5, 8)
  n = 0; for _,c in ipairs(clusters) do n = n + #c.rows end
  for i,e in ipairs(errs) do
    print(("iter %d  err=%.4f"):format(i,e)) end
  return l.chk({"k clusters",#clusters,5},
               {"all rows kept",n,#data.rows},
               {"err shrinks",errs[#errs] <= errs[1],true}) end

eg["--kpp"] = function(    data,cents)
  data = h.pickData()
  cents = a.kpp(data, 5, 64)
  return l.chk({"k cents", #cents, 5}) end
