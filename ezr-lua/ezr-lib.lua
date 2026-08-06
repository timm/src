#!/usr/bin/env lua
local help = [[
ezr-lib.lua: the batteries under ezr.lua. No learners here,
just the little functions that make the learners short.
Settings live in `the`, built by The() from this help;
other files extend it with the:also"help". For LuaJIT,
or any Lua from 5.1 up.

core options:
  round=2          decimals printed by show
  seed=1234567891  every random stream starts here
  DATA=data/       bare table names live here (relative
                   DATA hangs off this script's own dir,
                   then ../ up: rock bins sit one level
                   under their rock's data)
  file=auto93.csv  default table]]

local max,min,floor = math.max, math.min, math.floor

-- All defs below land in this fresh table (which _G backs for
-- reads), so `function name` both defines and exports: the
-- last line returns _ENV as the module. The local works on
-- Lua 5.2+; the setfenv line is the same trick for 5.1 and
-- LuaJIT (where it is a plain local and setfenv is nil).
local _ENV = setmetatable({}, {__index = _G})
if setfenv then setfenv(1, _ENV) end

--## make and feed ---------------------------------------------
function new(kl,t) -- class table is also its metatable
  kl.__index=kl;kl.__tostring=show; return setmetatable(t,kl) end

function iter(src,    at) -- iterate a list or a function
  if type(src) == "function" then return src end
  at = 0; return function() at = at + 1; return src[at] end end

function thing(s) -- string to number, bool, or string
  s = s:match"^%s*(.-)%s*$"
  return tonumber(s) or s=="True" or (s~="False" and s) end

function pathname(s,    d,t,f) -- bare names live in
  s = s or the.file   -- the.DATA; relative DATA hangs off
  if not s:find"/" then -- this script's dir, then ../ up;
    d = the.DATA        -- $VARS expand
    if d:find"^[/$]" then s = d .. s else
      t = (arg and arg[0] or ""):gsub("[^/]*$","")
      f = io.open(t .. d .. s)
      if f then f:close() end
      s = (f and t or t .. "../") .. d .. s end end
  return (s:gsub("%$(%w+)", function(k)
    return os.getenv(k) or k == "MOOT" and
           os.getenv"HOME" .. "/gits/moot" end)) end

function csv(file,    f) -- stream rows of coerced cells
  f = io.lines(pathname(file))
  return function(    t,l)
    for line in f do
      l = line:gsub("\239\187\191","")   -- strip any BOM
              :gsub("%%.*",""):match"^%s*(.-)%s*$"
      if l ~= "" then
        t={}                        -- (.-), keeps empty cells
        for s in (l..","):gmatch"(.-)," do t[#t+1]=thing(s) end
        return t end end end end

--## settings --------------------------------------------------
THE = {}

function The(s,    i) -- settings from "k=v" words in a string
  i = new(THE, {_help=s}) -- only after whitespace: "--k=v"
  for k,v in (" "..s):gmatch"%s(%a%w*)=(%S+)" do -- in usage
    i[k] = thing(v) end                 -- examples is prose
  return i end

function THE.also(i,t) -- merge new settings; string or table.
  if type(t) == "string" then     -- same-name fields crash.
    -- newest file's full text leads; older helps keep only
    -- their options paragraphs
    i._help = t.."\n"..(i._help:match"[^\n]*[Oo]ptions:.*" or "")
    t = The(t) end
  for k,v in pairs(t) do
    if k ~= "_help" then
      assert(i[k] == nil, "duplicate setting: "..k)
      i[k] = v end end
  return i end

--## list making -----------------------------------------------
function push(t,v) t[1+#t] = v; return v end

function fun(f) -- a callable: f itself; or method name
  if type(f)=="string" then
    return function(v,...) return v[f](v,...) end end
  if type(f)=="number" then return function(v) return v[f]end end
  return f end

function map(t,f,    u) -- f (fn or method name) over list
  f = fun(f)
  u = {}; for _,v in ipairs(t) do u[1+#u]=f(v) end; return u end

function kap(t,f,    u) -- f(k,v) over all pairs, any order.
  u = {}                -- nil results vanish: kap also filters
  for k,v in pairs(t) do u[1+#u] = f(k,v) end; return u end

function sub(t,lo,hi,    u) -- copy t[lo..hi]; any size
  u, hi = {}, min(hi or #t, #t)
  for j = max(lo or 1, 1), hi do u[1+#u] = t[j] end
  return u end

function copy(t) -- shallow copy of the list part
  return map(t, function(v) return v end) end

function sum(t,f,    n) -- add f(v) over values
  n = 0; for _, v in pairs(t) do n = n + f(v) end; return n end

--## ordering --------------------------------------------------
function sorted(t,f,    s) -- sorted copy; f optional
  s = copy(t); table.sort(s, f); return s end

function keysort(t,f,    px,ix) -- sort by f(v); stable,
  px, ix = {}, {}               -- so ties keep input order
  for at, v in ipairs(t) do px[v], ix[v] = f(v), at end
  return sorted(t, function(u,v)
           if px[u] == px[v] then return ix[u] < ix[v] end
           return px[u] < px[v] end) end

function keys(t,skip,    u) -- sorted keys; skip prefix?
  u = kap(t, function(k)
        if not (skip and tostring(k):sub(1,1) == skip) then
          return k end end)
  return keysort(u, tostring) end

function least(    lo) -- min-so-far reducer: call f{val,..}
  return function(x)   -- to offer, f() to read; the champion
    if x and (lo == nil or x[1] < lo[1]) then lo = x end
    return lo end end  -- rides in the closure

--## randomness ------------------------------------------------
-- Own Park-Miller PRNG: exact doubles, so the same seed
-- yields the same stream on any Lua, any machine.
Seed = 1234567891

function srand(n) -- any integer; lands in 1..2^31-2
  Seed = floor(n or 1234567891) % 2147483647
  if Seed <= 0 then Seed = Seed + 2147483646 end end

function rand(lo,hi,    x) -- () -> [0,1); (n) -> 1..n;
  Seed = (16807 * Seed) % 2147483647  -- (lo,hi) -> lo..hi
  x = Seed / 2147483647
  if not lo then return x end
  if not hi then lo, hi = 1, lo end
  return lo + floor(x * (hi - lo + 1)) end

function shuffle(lst,    t,j) -- Fisher-Yates; copies first
  t = copy(lst)
  for at = #t, 2, -1 do
    j = rand(at); t[at],t[j] = t[j],t[at] end
  return t end

function some(lst,k,    t) -- k items at random (all, if k big)
  t = shuffle(lst)
  for at = #t, min(k, #t) + 1, -1 do t[at] = nil end
  return t end

--## rendering -------------------------------------------------
function round(v,n) -- round to n (default the.round) places
  if v % 1 == 0 then return floor(v) end -- re-floor whole
  n = 10 ^ (n or the.round)     -- results: 5.3+ would print
  v = floor(v * n + 0.5) / n    -- the float 15.0 as "15.0",
  return v % 1 == 0 and floor(v) or v end -- 5.1/JIT as "15"

function show(t,    u) -- render anything. tables recurse:
  if type(t) ~= "table" then  -- lists keyless, dicts ":k v"
    return tostring(type(t) == "number" and round(t) or t) end
  u = #t > 0 and map(t, show) or
      sorted(kap(t, function(k,v)
        if tostring(k):sub(1,1) ~= "_" then
          return ":"..k.." "..show(v) end end))
  return "{"..table.concat(u, " ").."}" end

--## start-up --------------------------------------------------
function cli(d,    v) -- --key=val flags update settings;
  for _, s in ipairs(arg) do            -- -h prints help
    if s == "-h" then print(d._help) end
    for k in pairs(d) do
      v = s:match("^%-%-" .. k .. "=(.*)")
      if v then
        v = thing(v)   -- new value must keep the old type
        assert(type(v) == type(d[k]),
               "bad "..s.." : want "..type(d[k]))
        d[k] = v end end end
  return d end

function run(funs,w,    ok,msg) -- one seeded example
  srand(the.seed)
  if funs[w] then
    ok, msg = xpcall(funs[w], debug.traceback)
    if not ok then print(msg) end
    return ok end end

function go(eg,    n) -- parse flags, run the demos named on
  if arg and arg[0] and     -- the command line, exiting with
     debug.getinfo(2,"S").source == "@"..arg[0] then -- the
    cli(the)                -- failure count. A no-op unless
    n = 0                   -- the caller is the main script.
    for _,w in ipairs(arg) do
      if run(eg, w) == false then n = n + 1 end end
    os.exit(n) end end

the = The(help)

srand(the.seed) -- default stream; runners may reseed later

return _ENV
