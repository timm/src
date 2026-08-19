# fft.lua

{% raw %}
```text
fft.lua -- fast frugal trees. Lua port of fft.lisp,
line-faithful: same algorithm, same seed, same output.
Runs on Lua 5.1..5.5 and LuaJIT.
(c) 2026 Tim Menzies timm@ieee.org, MIT license.
Usage: lua fft.lua [--trees] [--grows [reps [k]]]
```

```lua
local SETTINGS = {seed=1234567891, p=2, bins=7, depth=4,
                  file="$MOOT/optimize/misc/auto93.csv"}
local BIG  = 1e32
local SEED = SETTINGS.seed
local floor, exp, sqrt = math.floor, math.exp, math.sqrt
local max, min, abs    = math.max, math.min, math.abs

-- ---- 1. columns ---------------------------------------------
local function Num(n, mu, m2)
  return {nump=true, n=n or 0, mu=mu or 0.0, m2=m2 or 0.0} end

local function Sym() return {} end

local function sd(i)
  if i.n < 2 then return 0 end
  return sqrt(max(0, i.m2) / (i.n - 1)) end

local function welford(i, v, w)
  w = w or 1
  i.n = i.n + w
  if i.n < 1 then return Num() end
  local d = v - i.mu
  i.mu = i.mu + w * d / i.n
  i.m2 = i.m2 + w * d * (v - i.mu)
  return i end

local function norm(i, v)
  local z = (v - i.mu) / (sd(i) + 1e-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z)))) end

local function mix(i, j, w)
  w = w or 1
  if i.nump then
    local m = i.n + w * j.n
    local d = j.mu - i.mu
    if m < 1 then return Num() end
    return Num(m, (i.n * i.mu + w * j.n * j.mu) / m,
               i.m2 + w * j.m2 + w * d * d * i.n * j.n / m) end
  local out = {}
  for k, v in pairs(i) do out[k] = (out[k] or 0) + v end
  for k, v in pairs(j) do out[k] = (out[k] or 0) + w * v end
  return out end

-- ---- 2. data -------------------------------------------------
local function add(i, v, w)
  w = w or 1
  if v == "?" then return i end
  if i.nump then return welford(i, v, w) end
  i[v] = (i[v] or 0) + w
  return i end

local function adds(lst, it)
  it = it or Num()
  for _, v in ipairs(lst) do it = add(it, v) end
  return it end

local function role(i, s, at)
  local z = s:sub(-1)
  i.cols[at] = s:sub(1, 1):match("%l") and Sym() or Num()
  i.all[#i.all + 1] = i.cols[at]
  if z == "-" or z == "+" or z == "!" then
    i.goal[at] = z == "+" and 1 or 0
    i.y[#i.y + 1] = at
  elseif z ~= "X" then
    i.x[#i.x + 1] = at end end

local function data(names, rows)
  local i = {names=names, rows=rows,
             x={}, y={}, goal={}, cols={}, all={}}
  for at, s in ipairs(names) do role(i, s, at) end
  for _, row in ipairs(rows) do
    for at, c in ipairs(i.all) do add(c, row[at]) end end
  return i end

-- ---- 3. discretization --------------------------------------
local function bin(c, v)
  if c.nump then return floor(SETTINGS.bins * norm(c, v)) end
  return v end

local function top(c, v, old)
  if c.nump then return max(old or -BIG, v) end
  return v end

local function cutsOf(c, bins, hi, at)
  local out = {}
  if c.nump then
    local ks = {}
    for k in pairs(bins) do ks[#ks + 1] = k end
    table.sort(ks)
    local l = Num()
    for idx = 1, #ks - 1 do
      local k = ks[idx]
      l = mix(l, bins[k])
      out[#out + 1] = {at=at, lo=-BIG, hi=hi[k], ys=l} end
  else
    for k, ys in pairs(bins) do
      out[#out + 1] = {at=at, lo=hi[k], hi=hi[k], ys=ys} end end
  return out end

local function cutsAt(c, lst, ys, at)
  local bins, hi = {}, {}
  for j, r in ipairs(lst) do
    local v = r[at]
    if v ~= "?" then
      local k = bin(c, v)
      bins[k] = add(bins[k] or Num(), ys[j])
      hi[k] = top(c, v, hi[k]) end end
  return cutsOf(c, bins, hi, at) end

local function cuts(i, lst, y)
  local ys, out = {}, {}
  for j, r in ipairs(lst) do ys[j] = y(r) end
  for _, at in ipairs(i.x) do
    for _, cut in ipairs(cutsAt(i.cols[at], lst, ys, at)) do
      out[#out + 1] = cut end end
  return out end

-- ---- 4. grow trees ------------------------------------------
local function mink(lst, p)
  p = p or SETTINGS.p
  local s = 0
  for _, x in ipairs(lst) do s = s + abs(x) ^ p end
  return (s / #lst) ^ (1.0 / p) end

local function disty(i, row)
  local out = {}
  for j, at in ipairs(i.y) do
    out[j] = norm(i.cols[at], row[at]) - i.goal[at] end
  return mink(out) end

local function has(v, lo, hi)
  if v == "?" then return true end
  if type(v) == "string" then return v == lo end
  return lo <= v and v <= hi end

local function branch(nd, right)
  return {at=nd.at, lo=nd.lo, hi=nd.hi,
          left=nd.left, right=right} end

local function least(lst, f)
  local out = lst[1]
  for j = 2, #lst do
    if f(lst[j]) < f(out) then out = lst[j] end end
  return out end

local function most(lst, f)
  local out = lst[1]
  for j = 2, #lst do
    if f(lst[j]) > f(out) then out = lst[j] end end
  return out end

local function splits(i, y, root)
  local enough = (#root.rows) ^ 0.33
  local cs = {}
  for _, c in ipairs(cuts(i, i.rows, y)) do
    if c.ys.n > enough then cs[#cs + 1] = c end end
  if #cs == 0 then return {} end
  local out = {}
  for _, bp in ipairs({{"0", least}, {"1", most}}) do
    local bit, pick = bp[1], bp[2]
    local best = pick(cs, function(c) return c.ys.mu end)
    local no = {}
    for _, r in ipairs(i.rows) do
      if not has(r[best.at], best.lo, best.hi) then
        no[#no + 1] = r end end
    if #no > 0 then
      out[#out + 1] = {bit,
        {at=best.at, lo=best.lo, hi=best.hi, left=best.ys},
        no} end end
  return out end

local function grows(i, y, root, d)
  d = d or 0
  local out = {}
  if d < SETTINGS.depth then
    for _, s in ipairs(splits(i, y, root)) do
      local bit, nd, no = s[1], s[2], s[3]
      local kid = data(i.names, no)
      for _, br in ipairs(grows(kid, y, root, d + 1)) do
        out[#out + 1] = {bit .. br[1], branch(nd, br[2])} end
    end end
  if #out == 0 then
    local ys = {}
    for j, r in ipairs(i.rows) do ys[j] = y(r) end
    out[1] = {"", adds(ys)} end
  return out end

-- ---- 5. use trees -------------------------------------------
local function predict(tr, row)
  if tr.nump then return tr.mu end
  if has(row[tr.at], tr.lo, tr.hi) then
    return predict(tr.left, row) end
  return predict(tr.right, row) end

local function err(tr, lst, y)
  local s = 0
  for _, r in ipairs(lst) do
    s = s + abs(y(r) - predict(tr, r)) end
  return s / #lst end

local function tune(cands, lst, y)
  return least(cands, function(t) return err(t, lst, y) end) end

local function fmtnum(v)
  if type(v) == "number" and v == floor(v) then
    return string.format("%d", v) end
  return tostring(v) end

local function rule(i, tr)
  local s, lo, hi = i.names[tr.at], tr.lo, tr.hi
  if lo == hi   then return s .. " == " .. fmtnum(lo) end
  if lo == -BIG then return s .. " <= " .. fmtnum(hi) end
  return s .. " >= " .. fmtnum(lo) end

local function show(i, tr)
  if tr.nump then
    print(string.format("%-33s leaf  d2h %.2f n=%d",
                        "", tr.mu, tr.n))
  else
    local l = tr.left
    print(string.format("if %-30s then d2h %.2f n=%d",
                        rule(i, tr), l.mu, l.n))
    show(i, tr.right) end end

-- ---- utils (lithp.lisp equivalents) -------------------------
local function thing(s)
  s = s:match("^%s*(.-)%s*$")
  if s == "True" then return true end
  if s == "False" then return false end
  return tonumber(s) or s end

local function path(s)
  if s:sub(1, 5) == "$MOOT" then
    return (os.getenv("MOOT") or
            (os.getenv("HOME") .. "/gits/moot")) .. s:sub(6) end
  return s end

local function csv(file)
  local out = {}
  for line in io.lines(path(file)) do
    local l = line:match("^%s*(.-)%s*$")
    if l ~= "" and l:sub(1, 1) ~= "#" then
      local row = {}
      for cell in (l .. ","):gmatch("([^,]*),") do
        row[#row + 1] = thing(cell) end
      out[#out + 1] = row end end
  return out end

local function rand(n)
  n = n or 1
  SEED = (16807 * SEED) % 2147483647
  return n * SEED / 2147483647 end

local function rint(n) return floor(rand(n or 2)) end

local function shuffle(l)
  local v = {}
  for j, x in ipairs(l) do v[j] = x end
  for j = #v, 2, -1 do
    local k = rint(j) + 1
    v[j], v[k] = v[k], v[j] end
  return v end

local function few(l, n)
  local v, out = shuffle(l), {}
  for j = 1, n do out[j] = v[j] end
  return out end

-- ---- 6. demos -----------------------------------------------
local function egMain()
  local t = csv(SETTINGS.file)
  local names = table.remove(t, 1)
  local i = data(names, t)
  local y = function(r) return disty(i, r) end
  local ts = {}
  for j, br in ipairs(grows(i, y, i)) do ts[j] = br[2] end
  show(i, tune(ts, i.rows, y)) end

local function egTrees()
  local t = csv(SETTINGS.file)
  local names = table.remove(t, 1)
  local i = data(names, t)
  local y = function(r) return disty(i, r) end
  for k, br in ipairs(grows(i, y, i)) do
    print(string.format(
      "===== tree %2d   bias %-5s   err %.3f =====",
      k, br[1], err(br[2], i.rows, y)))
    show(i, br[2])
    print("") end end

local function egGrows(reps, k)
  reps, k = reps or 10, k or 100
  local t = csv(SETTINGS.file)
  local names = table.remove(t, 1)
  local m, t0 = 0, os.clock()
  for _ = 1, reps do
    local i = data(names, few(t, k))
    m = #grows(i, function(r) return disty(i, r) end, i) end
  local s = os.clock() - t0
  print(string.format("%dx (sample %d, %d trees): %.3f s"
                      .. " -> %.1f ms", reps, k, m, s,
                      1000 * s / reps)) end

-- ---- 7. start -----------------------------------------------
local a = arg or {}
for j, f in ipairs(a) do
  for key in pairs(SETTINGS) do
    if f == "-" .. key:sub(1, 1) and a[j + 1] then
      local v = thing(a[j + 1])
      SETTINGS[key] = v end end end
SEED = SETTINGS.seed
local function argfind(s)
  for j, f in ipairs(a) do
    if f == s then return j end end
  return nil end
local g = argfind("--grows")
if g then
  egGrows(tonumber(a[g + 1]), tonumber(a[g + 2]))
elseif argfind("--trees") then
  egTrees()
else
  egMain() end
```

{% endraw %}