-- Ga. Genetic algorithm stepper: mutate, tournament
-- select, crossover; one call = one generation; nil when
-- gens done.
local a, m, l, the = ...

local floor,max,rand = math.floor, math.max, math.random

-- GA stepper: mutate, tournament select, crossover
function a.ga(data, better,
              mutate,selects,good,crossOver,pop,ref,gen)
  better= better or a.betters(data)
  mutate= function(row)
    return m.picks(data, row,
      max(1, floor(the.mut*(#data.cols.x)))) end
  selects= function(t,    u)
    u={}; for _=1,#t do u[1+#u]=good(t) end; return u end
  good= function(t,    x,y)
    x = t[rand(#t)]
    for _ = 2,the.tour do
      y = t[rand(#t)]
      if better(y,x,ref) then x=y end end
    return x end
  crossOver= function(n,parents,    u,mum,dad,cut)
    u={}
    while #u < n do
      mum = parents[rand(#parents)]
      dad = parents[rand(#parents)]
      u[1+#u] = l.copy(mum)
      if rand() < the.cr then
        cut = rand((#data.cols.x) - 1)
        for j,c in ipairs(data.cols.x) do
          u[#u][c.at] =
            (j <= cut and mum or dad)[c.at] end end end
    return u end
  l.shuffle(data.rows)
  pop = l.slice(data.rows, 1, the.np)
  ref = l.slice(data.rows, the.np+1, the.budget - the.np)
  return function()
    gen = (gen or 0) + 1
    if gen <= the.gens then
      pop = crossOver(#pop, selects(l.map(pop,mutate)))
      return gen, pop, ref end end end
