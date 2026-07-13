#!/usr/bin/env lua
-- mine.lua : tiny lua dialect -> lua, all regex, line counts kept.
--   fun -> function          x,y := a,b -> local x,y = a,b
--   ^x -> return x           fun((a) body) -> function(a) body end
--   in *t  -> in pairs(t)    [e for v in it]     -> list
--   in %t  -> in ipairs(t)   [k|v for k,v in it] -> dict
--   in f() -> verbatim       strings/comments untouched
local hid
local function hide(x) hid[1+#hid]=x; return "\1"..#hid.."\1" end

local lambda
function lambda(b,    args,body)
  args,body = b:sub(2,-2):match"^(%b())%s*(.*)$"
  if args then
    return "function"..args.." "..
           body:gsub("%f[%w]fun%s*(%b())",lambda).." end" end end

local comp
function comp(b,    e,vars,it,k,v)
  e,vars,it = b:sub(2,-2):match"^%s*(.-)%s+for%s+([%w_,%s]-)%s+in%s+(.-)%s*$"
  if e then
    e   = e:gsub("%b[]",comp)
    k,v = e:match"^(.-)|(.+)$"
    return ("(function(    __u) __u={} for %s in %s do __u[%s]=%s end return __u end)()")
           :format(vars, it, k or "1+#__u", k and v or e) end end

local function mine(s)
  hid = {}
  s = s:gsub("%-%-%[%[.-%]%]", hide)                            -- --[[ block comment ]]
       :gsub("%[%[.-%]%]", hide)                                -- [[long string]]
       :gsub('"[^\n"]*"', hide)                                 -- "sigils safe in here: ^ := *t [x for y]"
       :gsub("'[^\n']*'", hide)                                 -- 'same for single quotes'
       :gsub("%-%-[^\n]*", hide)                                -- -- line comment
  s = s:gsub("(%f[%w]in%f[%W]%s*)%*(%b{})", "%1pairs(%2)")      -- for k,v in *{a=1}   -> in pairs({a=1})
       :gsub("(%f[%w]in%f[%W]%s*)%%(%b{})", "%1ipairs(%2)")     -- for x in %{10,20}   -> in ipairs({10,20})
       :gsub("(%f[%w]in%f[%W]%s*)%*([%w_%.]+)", "%1pairs(%2)")  -- for k,v in *t       -> in pairs(t)
       :gsub("(%f[%w]in%f[%W]%s*)%%([%w_%.]+)", "%1ipairs(%2)") -- for x in %d.rows    -> in ipairs(d.rows)
       :gsub("(%f[%w]for%s+)([%w_]+)(%s+in%s+ipairs%()", "%1_,%2%3") -- for x in ipairs(t) -> for _,x in ipairs(t): x=value
       :gsub("%b[]", comp)                                      -- [x*x for x in %t]  [k|v*2 for k,v in *t]  (t[i] untouched)
       :gsub("%f[%w]fun%s*(%b())", lambda)                      -- fun((a,b) f(a); ^b) -> function(a,b) f(a); return b end
       :gsub("%f[%w]fun%f[%W]", "function")                     -- fun Sym.add(i,v)    -> function Sym.add(i,v) ...explicit end
       :gsub("^%^[ \t]*", "return ")                            -- ^x at very first char of file
       :gsub("([%s;])%^[ \t]*", "%1return ")                    -- ^x after space/newline/; (2^4 tight = power, untouched)
       :gsub("([%w_][%w_, ]*):=", "local %1=")                  -- x,y := 1,2          -> local x,y = 1,2
  return (s:gsub("\1(%d+)\1", function(n) return hid[tonumber(n)] end)) end -- unhide strings/comments verbatim

local loaded = {}
return function(x,    f)
  if loaded[x] == nil then
    f = assert(io.open(x..".luam"), "cannot open: "..x)
    loaded[x] = assert(load(mine(f:read"*a"), "@"..x..".luam"))()
    f:close() end
  return loaded[x] end
