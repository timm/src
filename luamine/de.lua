-- De. Differential evolution, DE/rand/1 stepper: blend
-- three distinct rows per parent; the kid replaces its
-- parent when the oracle scores it better.
local a, m, l, the = ...

-- DE/rand/1 stepper: kid replaces parent if better
function a.de(data,oracle,    y,pop,es,gen)
  y   = oracle or a.oracle(data)
  pop = l.slice(l.shuffle(l.copy(data.rows)), 1, the.np)
  es  = l.map(pop, y)
  return function(    kids,kid,d,t)
    gen = (gen or 0) + 1
    if gen > the.de_iter then return end
    kids = {}
    for i=1,#pop do
      repeat t = l.anys(pop,3)
      until t[1]~=t[2] and t[1]~=t[3] and t[2]~=t[3]
      kid = m.extrapolate(data.cols.x, t[1],t[2],t[3], the.F)
      d = y(kid); kids[1+#kids] = kid
      if d < es[i] then pop[i],es[i] = kid,d end end
    return gen, kids end end
