-- Tutorial and tests for sample.lua.
local eg, h, a, m, l, the = ...

--[[
## Synthesis and anomalies

`sample` invents rows by DE-blending three real rows per
ftree leaf; `anomalyDetector` calibrates a 1-NN-in-leaf
distance CDF, so tails mark anomalies. Notice the cross
check: most synthetic rows should NOT look anomalous.

| call | returns | what |
|------|---------|------|
| `a.sample(data,N)` | rows | N synthetic rows |
| `a.anomalyDetector(data)` | fn | row -> CDF 0..1 |
]]

eg["--sample"] = function(    data,synth,det,bad)
  data  = h.pickData()
  synth = a.sample(data, 50)
  det   = a.anomalyDetector(data)
  bad   = 0
  for _,r in ipairs(synth) do
    local cdf = det(r)
    if cdf < 0.1 or cdf > 0.9 then bad = bad + 1 end end
  l.say(("anomalous synth: %d/%d\n"):format(bad, #synth))
  return l.chk({"n synth",#synth,50},
               {"row len",#synth[1],#data.cols.all},
               {"mostly sane",bad < #synth/2,true}) end

eg["--anomaly"] = function(    data,det,known,outlier)
  data  = h.pickData()
  det   = a.anomalyDetector(data)
  known = data.rows[1]
  outlier = l.copy(known)
  for _,c in ipairs(data.cols.x) do
    if c.mu then outlier[c.at] = 1E6 end end
  return l.chk({"known in body",
                det(known) > 0.1 and det(known) < 0.9, true},
               {"outlier tail", det(outlier) > 0.9, true}) end
