-- Portable Park-Miller PRNG: seeded runs match across
-- languages (twin: rand.py in ezr2). Replaces Lua's stock
-- RNG (math.random/math.randomseed) so every later file
-- that localizes math.random gets the portable one.
local l, the = ...

local floor = math.floor
local Seed = 1

-- set the random seed (any integer)
function l.srand(n)
  Seed = (n or 1) % 2147483647
  if Seed == 0 then Seed = 1 end end

-- rand() -> float in [0,1); rand(n) -> integer in 1..n
function l.rand(n,    r)
  Seed = (16807 * Seed) % 2147483647
  r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end

math.random, math.randomseed = l.rand, l.srand

-- one random item of t
function l.any(t) return t[l.rand(#t)] end

-- n random items (with replacement)
function l.anys(t,n,    u)
  u={}; for _=1,n do u[1+#u]=l.any(t) end; return u end

-- Fisher-Yates shuffle, in place; return t
function l.shuffle(t,    j)
  for i=#t,2,-1 do j=l.rand(i); t[i],t[j] = t[j],t[i] end
  return t end

-- weighted random key from dict; sorted keys (determinism)
function l.pickDict(dct,    ks,s,r)
  ks = l.sort(l.kap(dct, function(k,_) return k end))
  s = 0; for _,k in ipairs(ks) do s = s + dct[k] end
  r = s * l.rand()
  for _,k in ipairs(ks) do
    r = r - dct[k]; if r <= 0 then return k end end end

-- Irwin-Hall(3): ~normal sample, mean 0, sd 1
function l.irwinHall()
  return 2*(l.rand()+l.rand()+l.rand()-1.5) end
