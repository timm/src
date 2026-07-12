-- Cli. `section`/`flags`/`help` mine the help text; `run1`
-- runs one eg with seed reset + pcall; `runAll` sweeps the
-- lot; `main` parses argv (--flag val sets `the`; --name
-- runs an eg); `boot` seeds `the` from a help text's
-- options and dispatches only when run as main.
local l, the = ...

-- body of "## name" section of text
function l.section(text,name,    pat)
  pat = "\n##%s+"..name:gsub("%W","%%%1").."%s-\n(.-)\n##%s"
  return (("\n"..text.."\n## "):match(pat)) or "" end

-- print indented flag lines of a help section
function l.flags(text,name)
  for line in (l.section(text,name).."\n"):gmatch"(.-)\n" do
    if line:match"^%s*%-" then print("  "..line) end end end

-- print title, (c), OPTIONS, ACTIONS from help text
function l.help(name,help,    title,cr)
  title = ("\n"..help):match"\n# ([^\n]+)" or ""
  cr    = ("\n"..help):match"\n(%(c%)[^\n]+)" or ""
  print(name..".lua: "..title)
  if cr~="" then print(cr) end
  print("\nOPTIONS"); l.flags(help,"options")
  print("\nACTIONS"); l.flags(help,"egs") end

-- run one eg with seed reset + pcall; err|nil
function l.run1(eg,the,    ok,flag,msg)
  math.randomseed(the.seed)
  ok, flag, msg = pcall(eg)
  if not ok      then return "ERR "..tostring(flag) end
  if flag==false then return tostring(msg) end end

-- run every eg; print failures + summary
function l.runAll(eg,the,    ks,fails,err)
  ks,fails={},{}
  l.o2("the", the); l.o2("date", os.date()); print()
  for k in pairs(eg) do ks[1+#ks]=k end
  for _,k in ipairs(l.sort(ks)) do
    print("--",k)
    err = l.run1(eg[k], the)
    if err then fails[1+#fails] = k..": "..err end end
  for _,f in ipairs(fails) do print("FAIL", f) end
  print(#fails==0 and "all pass" or (#fails.." failed")) end

local SHORTS = {t="train", T="test"}

-- mirror train->test unless -T explicitly set
local function syncTest(key,tSet)
  if key=="test"  then return true end
  if key=="train" and not tSet then the.test = the.train end
  return tSet end

-- parse argv: --flag val sets the; --name runs eg
function l.main(eg,b4,name,help,    a,n,txt,key,err,tSet)
  a,n,tSet = _G.arg, 1, false
  while n <= #a do txt = a[n]
    if     txt=="-h" or txt=="--help"
    then   l.help(name,help); return
    elseif txt=="--the" then l.o2("the",the); n=n+1
    elseif txt=="--all" then l.runAll(eg,the); n=n+1
    elseif eg[txt] then
      err = l.run1(eg[txt], the)
      if err then print("FAIL "..txt..": "..err) end
      n=n+1
    elseif txt:sub(1,2)=="--" then
      key = txt:sub(3); assert(the[key]~=nil, "bad flag: "..txt)
      the[key] = l.thing(a[n+1] or "")
      tSet = syncTest(key,tSet); n=n+2
    elseif txt:sub(1,1)=="-" then
      key = SHORTS[txt:sub(2)]
      assert(key and #txt==2, "bad flag: "..txt)
      the[key] = l.thing(a[n+1] or "")
      tSet = syncTest(key,tSet); n=n+2
    else n=n+1 end end
  for k in pairs(_G) do
    if not b4[k] then print("rogue?",k) end end end

-- seed the from help options; dispatch if main
function l.boot(eg,b4,name,help)
  for k,v in l.section(help,"options"):gmatch"%-%-(%w+)=(%S+)" do
    the[k]=l.thing(v) end
  math.randomseed(the.seed)
  if (arg[0] or ""):find(name.."%.lua$") then
    l.main(eg,b4,name,help) end end
