-- Strings and files. `thing` coerces csv cells; `o` pretty
-- prints anything (sorted dict keys); `path` expands a
-- leading $MOOT (env, else ~/gits/moot); `csv` streams
-- typed rows; `chk` runs {tag,got,want[,tol]} test cases.
local l, the = ...

local abs,floor = math.abs, math.floor

-- coerce str -> bool | num | str
function l.thing(s)
  return s=="true" or (s~="false" and (tonumber(s) or s)) end

-- pretty-print any value -> str (sorted dict keys)
function l.o(x,    u,kv)
  if type(x)=="number" then
    return floor(x)==x and floor(x) or ("%.2f"):format(x) end
  if type(x)~="table" then return tostring(x) end
  kv = function(k,v) return k.."="..l.o(v) end
  u = #x>0 and l.map(x,l.o) or l.sort(l.kap(x,kv))
  return "{"..table.concat(u,", ").."}" end

-- print "tag = o(x)"; return x
function l.o2(s,x) print(s.." =", l.o(x)); return x end
-- write s to stderr now; no newline
function l.say(s) io.stderr:write(s); io.stderr:flush() end
-- strip leading/trailing whitespace
function l.trim(s) return s:match"^%s*(.-)%s*$" end

-- expand leading $MOOT (env or ~/gits/moot) and ~
function l.path(s,    home)
  home = os.getenv"HOME" or "~"
  s = s:gsub("^%$MOOT",
             os.getenv"MOOT" or home.."/gits/moot")
  return (s:gsub("^~",home)) end

-- cases {tag,got,want[,tol]}; print each; ok,fail
function l.chk(...)
  for _,c in ipairs{...} do
    l.o2(c[1], c[2])
    if not (c[4] and abs(c[2]-c[3])<=c[4] or c[2]==c[3]) then
      return false, c[1] end end
  return true end

-- iter csv rows; cells coerced via thing
function l.csv(filename,    f)
  filename = l.path(filename)
  f = io.open(filename); assert(f, "cannot open: "..filename)
  return function(    s,u)
    s = f:read()
    if s then
      u={}; for x in s:gmatch"[^,]+" do
              u[1+#u] = l.thing(l.trim(x)) end
      return u
    else f:close() end end end
