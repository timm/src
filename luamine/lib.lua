#!/usr/bin/env lua
-- style: https://github.com/aiez/luamine/blob/main/docs/style.md
local help = [[
# library of useful lua functions
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
  -T  --test=$MOOT/optimize/misc/auto93.csv   test CSV
      --seed=1         RNG seed
      --cliffs=0.195   Cliff's delta threshold
      --eps=0.35       Cohen's threshold (x sd)
      --ksconf=1.36    KS test threshold
## egs
  --lists     sort/list/slice/copy/shuffle/keysort/argmin
  --rand      pickDict/irwinHall
  --stats     welford/sd/mode/ent/bisect
  --sames     cliffs/ks/pooledSd/same/topTier
  --tabulate  aligned table demo
  --confuse   confusion matrix demo
  --str       thing coercion, o pretty-print
  --csv       stream csv rows
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local m,the = {},{}
m.the = the
local abs,floor,log = math.abs, math.floor, math.log

-- portable Park-Miller PRNG: seeded runs match across
-- languages (twin: lib.py). Replaces Lua's stock RNG.
local Seed = 1
-- set the random seed (any integer)
function m.srand(n)
  Seed = (n or 1) % 2147483647
  if Seed == 0 then Seed = 1 end end
-- rand() -> float in [0,1); rand(n) -> integer in 1..n
function m.rand(n,    r)
  Seed = (16807 * Seed) % 2147483647
  r = Seed / 2147483647
  return n and floor(r * n) + 1 or r end
math.random, math.randomseed = m.rand, m.srand

local max,rand,seed = math.max, math.random, math.randomseed

-- ## list
-- bind metatable mt to t (mt.__index=mt); return t
function m.new(mt,t) mt.__index=mt; return setmetatable(t,mt) end
-- sort t in place; return t
function m.sort(t,fn) table.sort(t,fn); return t end
-- append x to t; return x
function m.push(t,x) t[1+#t]=x; return x end
-- closure: nth field of a row
function m.nth(n) return function(t) return t[n] end end
-- closure: less-than on field n
function m.lt(n) return function(a,b) return a[n] < b[n] end end
-- closure: greater-than on field n
function m.gt(n) return function(a,b) return a[n] > b[n] end end
-- one random item of t
function m.any(t) return t[rand(#t)] end
-- Irwin-Hall(3): ~normal sample, mean 0, sd 1
function m.irwinHall() return 2*(rand()+rand()+rand()-1.5) end

-- apply fn to each item -> new list
function m.map(t,fn,    u)
  u={}; for _,v in ipairs(t) do u[1+#u]=fn(v) end; return u end

-- apply fn(k,v) over dict -> new list
function m.kap(t,fn,    u)
  u={}; for k,v in pairs(t) do u[1+#u]=fn(k,v) end; return u end

-- dict values -> new list
function m.list(t,    u)
  u={}; for _,v in pairs(t) do u[1+#u]=v end; return u end

-- sort by fn-derived key (decorate-sort-undecorate)
function m.keysort(t,fn,cmp,    d)
  d = function(x) return {fn(x),x} end
  return m.map(m.sort(m.map(t,d),(cmp or m.lt)(1)),m.nth(2)) end

-- n random items (with replacement)
function m.anys(t,n,    u)
  u={}; for _=1,n do u[1+#u]=m.any(t) end; return u end

-- shallow copy of list part of t
function m.copy(t,    u)
  u={}; for i,v in ipairs(t) do u[i]=v end; return u end

-- t[lo..hi] inclusive; negatives count from end
function m.slice(t,lo,hi,    u,n)
  n  = #t
  lo = lo or 1; if lo < 0 then lo = n + 1 + lo end
  hi = hi or n; if hi < 0 then hi = n + 1 + hi end
  if hi > n then hi = n end
  u={}; for i=lo,hi do u[1+#u]=t[i] end
  return u end

-- Fisher-Yates shuffle, in place; return t
function m.shuffle(t,    j)
  for i=#t,2,-1 do j=rand(i); t[i],t[j] = t[j],t[i] end
  return t end

-- weighted random key from dict; sorted keys (determinism)
function m.pickDict(dct,    ks,s,r)
  ks = m.sort(m.kap(dct, function(k,_) return k end))
  s = 0; for _,k in ipairs(ks) do s = s + dct[k] end
  r = s * rand()
  for _,k in ipairs(ks) do
    r = r - dct[k]; if r <= 0 then return k end end end

-- index of min-by-fn item (cmp=m.gt for max)
function m.argmin(t,fn,cmp,    best,bv,v)
  cmp = cmp or function(a,b) return a < b end
  best, bv = 1, fn(t[1])
  for i=2,#t do
    v = fn(t[i]); if cmp(v,bv) then best,bv = i,v end end
  return best end

-- print rows as aligned table; just[c]="<" left-pads
function m.tabulate(rows,just,gap,    w,line,s)
  gap, w = gap or " ", {}
  for _,row in ipairs(rows) do
    for c,cell in ipairs(row) do
      w[c] = max(w[c] or 0, #tostring(cell)) end end
  for _,row in ipairs(rows) do line={}
    for c,cell in ipairs(row) do s = tostring(cell)
      line[c] = just[c]=="<" and s..(" "):rep(w[c]-#s)
                              or (" "):rep(w[c]-#s)..s end
    print(table.concat(line,gap)) end end

-- ## stats
-- stdev from welford state n,m2
function m.sd(n,m2) return n<2 and 0 or (m2/(n-1))^0.5 end

-- online update of n,mu,m2 for one value v
function m.welford(v,n,mu,m2,w,    d)
  w = w or 1
  n=n+w; d=v-mu; mu=mu+w*d/n; return n,mu, m2+w*d*(v-mu) end

-- batch mu,sd of a list, via welford
function m.welfords(xs,    n,mu,m2)
  n,mu,m2=0,0,0
  for _,v in ipairs(xs) do n,mu,m2=m.welford(v,n,mu,m2) end
  return mu, m.sd(n,m2) end

-- highest-count key of dict; sorted scan (stable ties)
function m.mode(t,    ks,out,N)
  ks = m.sort(m.kap(t, function(k,_) return k end))
  N = -1
  for _,k in ipairs(ks) do
    if t[k] > N then out,N = k,t[k] end end
  return out end

-- shannon entropy (bits) of dict counts
function m.ent(t,    e,N)
  e,N=0,0
  for _,n in pairs(t) do N=N+n end
  for _,n in pairs(t) do e=e - n/N * log(n/N,2) end
  return e end

-- count of t[i]<=x (or <x if strict) in sorted t
function m.bisect(t,x,strict,    lo,hi,mid,go)
  lo,hi = 1,#t
  while lo<=hi do mid=(lo+hi)//2
    go = strict and t[mid]<x or (not strict) and t[mid]<=x
    if go then lo=mid+1 else hi=mid-1 end end
  return lo-1 end

-- pooled stdev of two raw samples
function m.pooledSd(xs,ys,    nx,sx,ny,sy)
  nx,sx = #xs, (select(2, m.welfords(xs)))
  ny,sy = #ys, (select(2, m.welfords(ys)))
  return (((nx-1)*sx*sx + (ny-1)*sy*sy)/(nx+ny-2))^0.5 end

-- Cliff's delta effect size; ys pre-sorted
function m.cliffsDelta(xs,ys,    n,p,ngt,nlt)
  n,p,ngt,nlt = #xs,#ys,0,0
  for _,v in ipairs(xs) do
    ngt = ngt + m.bisect(ys,v,true)
    nlt = nlt + (p - m.bisect(ys,v)) end
  return abs(ngt-nlt)/(n*p) end

-- Kolmogorov-Smirnov max CDF gap; both pre-sorted
function m.ks(xs,ys,    n,p,d,gap)
  n,p,d = #xs,#ys,0
  gap = function(v)
    return abs(m.bisect(xs,v)/n - m.bisect(ys,v)/p) end
  for _,v in ipairs(xs) do d=max(d,gap(v)) end
  for _,v in ipairs(ys) do d=max(d,gap(v)) end
  return d end

-- xs,ys same? all of: mid gap<=eps, cliffs, ks
function m.same(xs,ys,eps,cliffs,ksconf,    n,p,a,b)
  eps, cliffs, ksconf = eps or 0, cliffs or 0.195, ksconf or 1.36
  a,b = m.sort({table.unpack(xs)}), m.sort({table.unpack(ys)})
  n,p = #a,#b
  if abs(a[n//2+1]-b[p//2+1])<=eps then return true end
  if m.cliffsDelta(a,b)>cliffs then return false end
  return m.ks(a,b) <= ksconf*((n+p)/(n*p))^0.5 end

-- dict[k]=nums -> all keys stats-same as best mu
function m.topTier(dict,cmp,eps,cliffs,ksconf,
                   out,names,best,cand,th)
  out={}
  names = m.keysort(m.kap(dict,function(k,_) return k end),
                    function(k) return (m.welfords(dict[k])) end,
                    cmp)
  best = dict[names[1]]
  out[names[1]] = (m.welfords(best))
  for i=2,#names do
    cand = dict[names[i]]
    th = (eps or 0) * m.pooledSd(best, cand)
    if not m.same(best, cand, th, cliffs, ksconf) then break end
    out[names[i]] = (m.welfords(cand)) end
  return out end

-- ## Confuse
local Confuse = {}
-- ctor: confusion matrix counts + klass set
function Confuse.new(file)
  return m.new(Confuse, {t={}, klasses={}, file=file or ""}) end

-- bump count for (want,got) pair
function Confuse.add(i,want,got)
  i.t[want]       = i.t[want] or {}
  i.t[want][got]  = (i.t[want][got] or 0) + 1
  i.klasses[want], i.klasses[got] = true, true end

-- per-klass {tn,fn,fp,tp,acc,pred,pf,pd,...}
function Confuse.scores(i,    out,tn,fn,fp,tp,n)
  out = {}
  for _,klass in ipairs(
      m.sort(m.kap(i.klasses,
                   function(k,_) return k end))) do
    tn,fn,fp,tp = 0,0,0,0
    for want,gots in pairs(i.t) do
      for got,cnt in pairs(gots) do
        if     want==klass and got==klass then tp=tp+cnt
        elseif want==klass                then fn=fn+cnt
        elseif got==klass                 then fp=fp+cnt
        else   tn=tn+cnt end end end
    n = tn+fn+fp+tp
    out[1+#out] = {klass=klass, tn=tn, fn=fn, fp=fp, tp=tp,
      n=n, file=i.file,
      acc =100*(tp+tn)/(n+1e-32),
      pred=100*tp/(tp+fp+1e-32),
      pf  =100*fp/(fp+tn+1e-32),
      pd  =100*tp/(tp+fn+1e-32)} end
  return out end

-- print confusion stats as formatted table
function Confuse.show(i,    hdr,row)
  hdr = "%5s %5s %5s %5s %5s %5s %5s %5s %5s %-8s %s"
  row = "%5d %5d %5d %5d %5.0f %5.0f %5.0f %5.0f %5d %-8s %s"
  print(hdr:format("tn","fn","fp","tp","acc","pred","pf","pd",
                   "n","file","filename"))
  for _,r in ipairs(i:scores()) do
    print(row:format(r.tn, r.fn, r.fp, r.tp,
      r.acc, r.pred, r.pf, r.pd, r.n, r.klass, r.file)) end end

-- ## io
-- coerce str -> bool | num | str
function m.thing(s)
  return s=="true" or (s~="false" and (tonumber(s) or s)) end

-- pretty-print any value -> str (sorted dict keys)
function m.o(x,    u,kv)
  if type(x)=="number" then
    return floor(x)==x and floor(x) or ("%.2f"):format(x) end
  if type(x)~="table" then return tostring(x) end
  kv = function(k,v) return k.."="..m.o(v) end
  u = #x>0 and m.map(x,m.o) or m.sort(m.kap(x,kv))
  return "{"..table.concat(u,", ").."}" end

-- print "tag = o(x)"; return x
function m.o2(s,x) print(s.." =", m.o(x)); return x end
-- write s to stderr now; no newline
function m.say(s) io.stderr:write(s); io.stderr:flush() end
-- strip leading/trailing whitespace
function m.trim(s) return s:match"^%s*(.-)%s*$" end
-- expand leading $MOOT (env or ~/gits/moot) and ~
function m.path(s,    home)
  home = os.getenv"HOME" or "~"
  s = s:gsub("^%$MOOT",
             os.getenv"MOOT" or home.."/gits/moot")
  return (s:gsub("^~",home)) end

-- cases {tag,got,want[,tol]}; print each; ok,fail
function m.chk(...)
  for _,c in ipairs{...} do
    m.o2(c[1], c[2])
    if not (c[4] and abs(c[2]-c[3])<=c[4] or c[2]==c[3]) then
      return false, c[1] end end
  return true end

-- iter csv rows; cells coerced via thing
function m.csv(filename,    f)
  filename = m.path(filename)
  f = io.open(filename); assert(f, "cannot open: "..filename)
  return function(    s,u)
    s = f:read()
    if s then
      u={}; for x in s:gmatch"[^,]+" do
              u[1+#u] = m.thing(m.trim(x)) end
      return u
    else f:close() end end end

-- ## cli
-- body of "## name" section of text
function m.section(text,name,    pat)
  pat = "\n##%s+"..name:gsub("%W","%%%1").."%s-\n(.-)\n##%s"
  return (("\n"..text.."\n## "):match(pat)) or "" end

-- print indented flag lines of a help section
function m.flags(text,name)
  for line in (m.section(text,name).."\n"):gmatch"(.-)\n" do
    if line:match"^%s*%-" then print("  "..line) end end end

-- print title, (c), OPTIONS, ACTIONS from help text
function m.help(name,help,    title,cr)
  title = ("\n"..help):match"\n# ([^\n]+)" or ""
  cr    = ("\n"..help):match"\n(%(c%)[^\n]+)" or ""
  print(name..".lua: "..title)
  if cr~="" then print(cr) end
  print("\nOPTIONS"); m.flags(help,"options")
  print("\nACTIONS"); m.flags(help,"egs") end

-- run one eg with seed reset + pcall; err|nil
function m.run1(eg,the,    ok,flag,msg)
  seed(the.seed)
  ok, flag, msg = pcall(eg)
  if not ok      then return "ERR "..tostring(flag) end
  if flag==false then return tostring(msg) end end

-- run every eg; print failures + summary
function m.runAll(eg,the,    ks,fails,err)
  ks,fails={},{}
  m.o2("the", the); m.o2("date", os.date()); print()
  for k in pairs(eg) do ks[1+#ks]=k end
  for _,k in ipairs(m.sort(ks)) do
    print("--",k)
    err = m.run1(eg[k], the)
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
function m.main(eg,b4,name,help,    a,n,txt,key,err,tSet)
  a,n,tSet = _G.arg, 1, false
  while n <= #a do txt = a[n]
    if     txt=="-h" or txt=="--help"
    then   m.help(name,help); return
    elseif txt=="--the" then m.o2("the",the); n=n+1
    elseif txt=="--all" then m.runAll(eg,the); n=n+1
    elseif eg[txt] then
      err = m.run1(eg[txt], the)
      if err then print("FAIL "..txt..": "..err) end
      n=n+1
    elseif txt:sub(1,2)=="--" then
      key = txt:sub(3); assert(the[key]~=nil, "bad flag: "..txt)
      the[key] = m.thing(a[n+1] or "")
      tSet = syncTest(key,tSet); n=n+2
    elseif txt:sub(1,1)=="-" then
      key = SHORTS[txt:sub(2)]
      assert(key and #txt==2, "bad flag: "..txt)
      the[key] = m.thing(a[n+1] or "")
      tSet = syncTest(key,tSet); n=n+2
    else n=n+1 end end
  for k in pairs(_G) do
    if not b4[k] then print("rogue?",k) end end end

-- seed the from help options; dispatch if main
function m.boot(eg,b4,name,help)
  for k,v in m.section(help,"options"):gmatch"%-%-(%w+)=(%S+)" do
    the[k]=m.thing(v) end
  seed(the.seed)
  if (arg[0] or ""):find(name.."%.lua$") then
    m.main(eg,b4,name,help) end end

-- ## eg
local eg = {}

eg["--lists"] = function(    t,u)
  t = m.shuffle{3,1,2,5,4}
  u = m.sort(m.list{a=1,b=2,c=3})
  return m.chk({"shuffle",#t,5},
    {"sort",m.sort(m.copy(t))[1],1},
    {"list",u[1]..","..u[3],"1,3"},
    {"slice",m.slice({10,20,30,40,50},2,-2)[3],40},
    {"keysort",m.keysort({{1},{0},{2}},m.nth(1))[1][1],0},
    {"argmin",
      m.argmin({30,10,50},function(x) return x end),2}) end

eg["--rand"] = function(    d,c,k,n,mu,m2)
  d,c = {a=1,b=10,c=100}, {a=0,b=0,c=0}
  for _=1,1000 do k=m.pickDict(d); c[k]=c[k]+1 end
  n,mu,m2 = 0,0,0
  for _=1,2000 do n,mu,m2 = m.welford(m.irwinHall(),n,mu,m2) end
  return m.chk({"pickDict",c.c>c.b and c.b>c.a,true},
               {"irwin mu~0",mu,0,0.1},
               {"irwin sd~1",m.sd(n,m2),1,0.1}) end

eg["--stats"] = function(    n,mu,m2)
  n,mu,m2 = 0,0,0
  for _,v in ipairs{1,2,3,4,5} do
    n,mu,m2 = m.welford(v,n,mu,m2) end
  return m.chk({"mu",mu,3}, {"sd",m.sd(n,m2),1.5811,1E-3},
    {"mode",m.mode{a=1,b=5,c=2},"b"},
    {"ent",m.ent{a=1,b=1,c=1,d=1},2,1E-9},
    {"bisect",m.bisect({1,2,2,3,5,8},2),3}) end

eg["--sames"] = function(    mk,a,b,c,tier)
  mk = function(off,    u) u={}
    for _=1,50 do u[1+#u]=rand()+off end; return u end
  a,b,c = mk(0), mk(0), mk(5)
  tier = m.topTier({a=a,b=b,c=c}, nil,
                   the.eps, the.cliffs, the.ksconf)
  return m.chk(
    {"cliffs",m.cliffsDelta({1,2,3},{10,11,12}),1},
    {"ks",m.ks({1,2,3},{10,11,12}),1},
    {"pooledSd",m.pooledSd({1,2,3,4,5},{1,2,3,4,5}),1.5811,1E-3},
    {"same",m.same(a,b,the.eps*m.pooledSd(a,b),
                   the.cliffs,the.ksconf),true},
    {"diff",m.same(a,c,the.eps*m.pooledSd(a,c),
                   the.cliffs,the.ksconf),false},
    {"tier a+b",tier.a~=nil and tier.b~=nil,true},
    {"tier no c",tier.c,nil}) end

eg["--tabulate"] = function()
  m.tabulate({{"name","age","note"}, {"Alice","30","short"},
              {"Bob","9","longer note here"}}, {"<",">","<"})
  return true end

eg["--confuse"] = function(    cf)
  cf = Confuse.new("data.csv")
  for _=1,50 do cf:add("yes","yes") end
  for _=1, 5 do cf:add("yes","no")  end
  for _=1, 3 do cf:add("no","yes")  end
  for _=1,40 do cf:add("no","no")   end
  cf:show(); return true end

eg["--str"] = function()
  return m.chk(
    {"int",m.thing"42",42},   {"bool",m.thing"true",true},
    {"str",m.thing"hi","hi"}, {"float",m.o(1.5),"1.50"},
    {"dict",m.o{a=1,b=2},"{a=1, b=2}"},
    {"list",m.o{1,2,3},"{1, 2, 3}"}) end

eg["--csv"] = function(    tmp,f,rows)
  tmp = os.tmpname()
  f = io.open(tmp,"w"); f:write("a,b,c\n1,2,3\n"); f:close()
  rows = {}
  for r in m.csv(tmp) do rows[1+#rows]=r end
  os.remove(tmp)
  return m.chk({"#rows",#rows,2},
    {"head",rows[1][1],"a"}, {"cell",rows[2][3],3}) end

m.Confuse = Confuse
m.boot(eg,b4,"lib",help)
return m
