local floor = math.floor
local Seed,rand,list,bin.tree = 0,{},{},{},{}

function new(mt,t) mt.__index=mt; return setmetatable(t,mt) end

-- ## Lists 
list.sort = function(t,fn) table.sort(t,fn); return t end

-- ## Random 
rand.seed = function(n)
  Seed = (n or 1) % 2147483647; if Seed==0 then Seed = 1 end end

rand.n = function(n,    r)
  Seed = (16807 * Seed) % 2147483647; r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end

rand.shuffle = function(t,    j)
  for i=#t,2,-1 do j=l.rand(i); t[i],t[j] = t[j],t[i] end
  return t end

rand.pick = function(dct,    ks,s,r)
  ks = l.sort(l.kap(dct, function(k,_) return k end))
  s = 0; for _,k in ipairs(ks) do s = s + dct[k] end
  r = s * l.rand()
  for _,k in ipairs(ks) do
    r = r - dct[k]; if r <= 0 then return k end end end

rand.gauss = function(mu,sd)
  mu, sd = (mu or 0), (sd or 1)
  return mu + sd*2*(rand.n() + rand.n() + rand.n() - 1.5) end
