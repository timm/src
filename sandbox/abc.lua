local the,help={},[[
abc

## options
  --seed=1  RNG seed ]]

local function what(s)
  return s=="true" or (s~="false" and (tonumber(s) or s)) end

for k,v in help:gmatch"%-%-(%w+)=(%S+)" do the[k]=what(v) end

-- ## Strings
local str={what=what}

function str.csv(filename,    f,trim)
  function trim(s) return s:match"^%s*(.-)%s*$" end
  filename = filename:sub("~",os.getenv"HOME")
  f = io.open(filename)
  return function(    s,u)
    s = f:read()
    if s then
      u={}; for x in s:gmatch"[^,]+" do 
        u[1+#u] = str.what(trim(x)) end
      return u
    else f:close() end end end

-- ## Maths
local min,max,floor = math.min, math.max, math.floor

local function new(mt,t) 
  mt.__index=mt; return setmetatable(t,mt) end

-- ## Lists 
local list={}
function list.sort(t,fn) table.sort(t,fn); return t end

-- ## Random
local Seed = 1
function rand.seed(n)
  Seed = (n or 1) % 2147483647; if Seed==0 then Seed = 1 end end

function rand.n(n,    r)
  Seed = (16807 * Seed) % 2147483647; r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end

function rand.shuffle(t,    j)
  for i=#t,2,-1 do j=rand.n(i); t[i],t[j] = t[j],t[i] end
  return t end

function rand.pick(dct,    ks,s)
  ks, s = {}, 0
  for k,w in pairs(dct) do ks[1+#ks] = k; s = s + w end
  return function(    r)
    r = s * rand.n()
    for _,k in ipairs(ks) do
      r = r - dct[k]; if r <= 0 then return k end end
    return ks[#ks] end end

function rand.gauss(mu,sd)
  mu, sd = (mu or 0), (sd or 1)
  return mu + sd*2*(rand.n() + rand.n() + rand.n() - 1.5) end
