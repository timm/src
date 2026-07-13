local the,help={},[[
abc

## options
  --seed=1  RNG seed ]]

local min,max,floor = math.min, math.max, math.floor

local function new(mt,t) 
  mt.__index=mt; return setmetatable(t,mt) end

-- ## Strings
local str={}

function str.settings(s)
  for k,v in s:gmatch"%-%-(%w+)=(%S+)" do 
    the[k] = str.what(v) end end

function str.what(s)
  s = str.trim(s)
  return s=="true" or (s~="false" and (tonumber(s) or s)) end

function str.trim(s) return s:match"^%s*(.-)%s*$" end

function str.filename(s) 
  return filename:sub("~",os.getenv"HOME") end

function str.csv(s,    f)
  f = io.open(str.filename(s))
  return function(    s,u)
    s = f:read()
    if s then
      u={}; for x in s:gmatch"[^,]+" do u[1+#u] = str.what(x) end
      return u
    else f:close() end end end

-- ## lists 
local lst={}
function lst.sort(t,fn) table.sort(t,fn); return t end

-- ## rndom
local Seed = 1
function rnd.seed(n)
  Seed = (n or 1) % 2147483647; if Seed==0 then Seed = 1 end end

function rnd.n(n,    r)
  Seed = (16807 * Seed) % 2147483647; r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end

function rnd.shuffle(t,    j)
  for i=#t,2,-1 do j=rnd.n(i); t[i],t[j] = t[j],t[i] end
  return t end

function rnd.pick(dct,    ks,s)
  ks, s = {}, 0
  for k,w in pairs(dct) do ks[1+#ks] = k; s = s + w end
  return function(    r)
    r = s * rnd.n()
    for _,k in ipairs(ks) do
      r = r - dct[k]; if r <= 0 then return k end end
    return ks[#ks] end end

function rnd.gauss(mu,sd)
  mu, sd = (mu or 0), (sd or 1)
  return mu + sd*2*(rnd.n() + rnd.n() + rnd.n() - 1.5) end
