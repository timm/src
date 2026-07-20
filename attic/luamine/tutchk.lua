#!/usr/bin/env lua
-- Replay every [n]> REPL event in tut.md inside one Lua
-- state, emulating the REPL's expression echo, and diff
-- each output against the transcript. Run from this dir:
--   lua tutchk.lua           # all events
--   lua tutchk.lua -v        # also list passing events
local file, verbose = "tut.md", false
for _,x in ipairs(arg) do
  if x=="-v" then verbose=true else file=x end end

-- events whose OUTPUT is environment-specific (lua version,
-- absolute paths): still executed (must not error), but the
-- transcript diff is skipped
local SKIP = { "_VERSION", "l%.path" }

local events = {}          -- {n=, code=, want={}, line=}
do
  local fence, cur = false, nil
  local ln = 0
  for line in io.lines(file) do
    ln = ln + 1
    if line:match"^```" then fence = not fence; cur = nil
    elseif fence then
      local n, code = line:match"^%[(%d+)%]>%s?(.*)"
      if n then
        cur = {n=tonumber(n), code=code, want={}, line=ln}
        events[1+#events] = cur
      elseif cur then
        cur.want[1+#cur.want] = line end end end
end

-- capture print/io.write into a buffer, REPL-style
local buf = {}
local realPrint, realWrite = print, io.write
local function grab(...)
  local parts = {}
  for i=1,select("#",...) do
    parts[i] = tostring((select(i,...))) end
  buf[1+#buf] = table.concat(parts,"\t") end
local function grabWrite(...)
  -- io.write appends to the current (last) buffered line
  local s = table.concat({...})
  for piece, nl in s:gmatch"([^\n]*)(\n?)" do
    if #buf==0 then buf[1]="" end
    buf[#buf] = buf[#buf]..piece
    if nl=="\n" then buf[1+#buf] = "" end
    if piece=="" and nl=="" then break end end end

local fails, total = 0, 0
for _,e in ipairs(events) do
  total = total + 1
  buf = {}
  _G.print, io.write = grab, grabWrite
  local f = load("return "..e.code, e.code)
  local res = {}
  if f then res = {pcall(f)}
  else
    f = load(e.code, e.code)
    if f then res = {pcall(f)}
    else res = {false, "does not compile"} end end
  if res[1] and f and #res > 1 then
    grab(table.unpack(res, 2, #res)) end  -- REPL echo
  _G.print, io.write = realPrint, realWrite
  if #buf > 0 and buf[#buf]=="" then buf[#buf]=nil end
  local want = {}
  for _,w in ipairs(e.want) do
    if w:match"%S" or #want>0 then want[1+#want]=w end end
  while #want>0 and not want[#want]:match"%S" do
    want[#want]=nil end
  -- two lines match if equal token-by-token, numbers
  -- compared at 10 significant digits (the course's rule)
  local function sameLine(g,w,    gt,wt)
    g, w = g:gsub("%s+$",""), w:gsub("%s+$","")
    if g == w then return true end
    gt, wt = {}, {}
    for t in g:gmatch"%S+" do gt[1+#gt]=t end
    for t in w:gmatch"%S+" do wt[1+#wt]=t end
    if #gt ~= #wt then return false end
    for i=1,#gt do
      local gn, wn = tonumber(gt[i]), tonumber(wt[i])
      if gn and wn then
        if ("%.10g"):format(gn) ~= ("%.10g"):format(wn)
        then return false end
      elseif gt[i] ~= wt[i] then return false end end
    return true end
  local skip = false
  for _,pat in ipairs(SKIP) do
    if e.code:find(pat) then skip = true end end
  local ok = res[1] and (skip or #buf == #want)
  if ok and not skip then
    for i=1,#want do
      if not sameLine(buf[i] or "", want[i]) then
        ok=false end end end
  if not ok then
    fails = fails + 1
    print(("FAIL [%d] line %d: %s"):format(e.n,e.line,e.code))
    if not res[1] then print("  ERR "..tostring(res[2])) end
    for i=1,math.max(#buf,#want) do
      local g,w = buf[i] or "<none>", want[i] or "<none>"
      if g:gsub("%s+$","") ~= w:gsub("%s+$","") then
        print("  want: "..w); print("  got:  "..g) end end
  elseif verbose then
    print(("pass [%d] %s"):format(e.n, e.code)) end end
print(("%d events, %d failed"):format(total, fails))
os.exit(fails==0 and 0 or 1)
