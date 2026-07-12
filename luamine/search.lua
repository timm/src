-- Search, (1+1) style. `oneplus1` is the shared stepper:
-- mutate s, accept(e,d,h,b), restart on stagnation, nil
-- after the eval budget. `sa` = simulated annealing
-- (metropolis accept); `ls` = greedy local search with
-- restarts.
local a, m, l, the = ...

local floor,max,rand = math.floor, math.max, math.random
local exp,huge = math.exp, math.huge

-- (1+1) stepper: mutate s, accept(e,d,h,b),
-- restart on stagnation; nil after budget evals
function a.oneplus1(data,mutate,accept,oracle,budget,restart,
                    s,e,h,imp,bd)
  budget  = budget  or the.budget1
  restart = restart or 0
  oracle  = oracle  or a.oracle(data)
  s, e    = l.copy(data.rows[rand(#data.rows)]), huge
  h, imp, bd = 0, 0, huge
  return function(    kids,d)
    if h >= budget then return end
    kids = mutate(s)
    for _,kid in ipairs(kids) do
      h = h + 1
      d = oracle(kid)
      if accept(e, d, h, budget) then s, e = kid, d end
      if d < bd then bd, imp = d, h end
      if restart > 0 and h - imp > restart then
        s, e, imp =
          l.copy(data.rows[rand(#data.rows)]), huge, h end
      if h >= budget then break end end
    return "", kids end end

-- simulated annealing via oneplus1 (metropolis)
function a.sa(data,oracle,budget,restart,    n)
  n = max(1, floor(the.mut * #data.cols.x))
  return a.oneplus1(data,
    function(s) return { m.picks(data, s, n) } end,
    function(e,d,h,b)
      return d < e
          or rand() < exp((e-d) / (1 - h/b + 1E-32)) end,
    oracle, budget, restart) end

-- greedy local search via oneplus1 + restarts
function a.ls(data,oracle,budget,restart,    p,tries)
  p, tries = 0.5, 20
  return a.oneplus1(data,
    function(s,    out,c,kid,reps)
      out, c = {}, data.cols.x[rand(#data.cols.x)]
      reps = (rand() < p) and tries or 1
      for _=1,reps do
        kid = l.copy(s); kid[c.at] = m.pick(c, kid[c.at])
        out[1+#out] = kid end
      return out end,
    function(e,d) return d < e end,
    oracle, budget, restart or 100) end
