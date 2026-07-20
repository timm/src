#!/usr/bin/env lua
-- Library of useful lua functions: the loader. Owns the
-- shared settings table `the`, loads each topic file into
-- this one module (rand first: it replaces Lua's RNG with
-- a portable Park-Miller twin), then seeds `the` from the
-- help options. require"lib" returns the assembled module.
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
  (see luamine-eg.lua)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local l, the = {}, {}
l.the, l.helpLib = the, help


-- ## rand
-- Portable Park-Miller PRNG: seeded runs match across
-- languages (twin: rand.py in ezr2). Replaces Lua's stock
-- RNG (math.random/math.randomseed) so every later file
-- that localizes math.random gets the portable one.


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


-- ## list
-- Lists. Tiny functional helpers: sort/push/map/kap plus
-- keysort (decorate-sort-undecorate), slicing, copying and
-- an aligned-table printer.


local max = math.max

-- bind metatable mt to t (mt.__index=mt); return t
function l.new(mt,t) mt.__index=mt; return setmetatable(t,mt) end
-- sort t in place; return t
function l.sort(t,fn) table.sort(t,fn); return t end
-- append x to t; return x
function l.push(t,x) t[1+#t]=x; return x end
-- closure: nth field of a row
function l.nth(n) return function(t) return t[n] end end
-- closure: less-than on field n
function l.lt(n) return function(a,b) return a[n] < b[n] end end
-- closure: greater-than on field n
function l.gt(n) return function(a,b) return a[n] > b[n] end end

-- apply fn to each item -> new list
function l.map(t,fn,    u)
  u={}; for _,v in ipairs(t) do u[1+#u]=fn(v) end; return u end

-- apply fn(k,v) over dict -> new list
function l.kap(t,fn,    u)
  u={}; for k,v in pairs(t) do u[1+#u]=fn(k,v) end; return u end

-- dict values -> new list
function l.list(t,    u)
  u={}; for _,v in pairs(t) do u[1+#u]=v end; return u end

-- sort by fn-derived key (decorate-sort-undecorate)
function l.keysort(t,fn,cmp,    d)
  d = function(x) return {fn(x),x} end
  return l.map(l.sort(l.map(t,d),(cmp or l.lt)(1)),l.nth(2)) end

-- shallow copy of list part of t
function l.copy(t,    u)
  u={}; for i,v in ipairs(t) do u[i]=v end; return u end

-- t[lo..hi] inclusive; negatives count from end
function l.slice(t,lo,hi,    u,n)
  n  = #t
  lo = lo or 1; if lo < 0 then lo = n + 1 + lo end
  hi = hi or n; if hi < 0 then hi = n + 1 + hi end
  if hi > n then hi = n end
  u={}; for i=lo,hi do u[1+#u]=t[i] end
  return u end

-- index of min-by-fn item (cmp=l.gt for max)
function l.argmin(t,fn,cmp,    best,bv,v)
  cmp = cmp or function(a,b) return a < b end
  best, bv = 1, fn(t[1])
  for i=2,#t do
    v = fn(t[i]); if cmp(v,bv) then best,bv = i,v end end
  return best end

-- print rows as aligned table; just[c]="<" left-pads
function l.tabulate(rows,just,gap,    w,line,s)
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
-- Stats. Welford accumulation, mode/entropy for counts,
-- then the conservative equality tests: cliffsDelta + ks +
-- a median-gap check feed `same`; `topTier` keeps every
-- treatment statistically level with the best.


local abs,log,max = math.abs, math.log, math.max

-- stdev from welford state n,m2
function l.sd(n,m2) return n<2 and 0 or (m2/(n-1))^0.5 end

-- online update of n,mu,m2 for one value v
function l.welford(v,n,mu,m2,w,    d)
  w = w or 1
  n=n+w; d=v-mu; mu=mu+w*d/n; return n,mu, m2+w*d*(v-mu) end

-- batch mu,sd of a list, via welford
function l.welfords(xs,    n,mu,m2)
  n,mu,m2=0,0,0
  for _,v in ipairs(xs) do n,mu,m2=l.welford(v,n,mu,m2) end
  return mu, l.sd(n,m2) end

-- highest-count key of dict; sorted scan (stable ties)
function l.mode(t,    ks,out,N)
  ks = l.sort(l.kap(t, function(k,_) return k end))
  N = -1
  for _,k in ipairs(ks) do
    if t[k] > N then out,N = k,t[k] end end
  return out end

-- shannon entropy (bits) of dict counts
function l.ent(t,    e,N)
  e,N=0,0
  for _,n in pairs(t) do N=N+n end
  for _,n in pairs(t) do e=e - n/N * log(n/N,2) end
  return e end

-- count of t[i]<=x (or <x if strict) in sorted t
function l.bisect(t,x,strict,    lo,hi,mid,go)
  lo,hi = 1,#t
  while lo<=hi do mid=(lo+hi)//2
    go = strict and t[mid]<x or (not strict) and t[mid]<=x
    if go then lo=mid+1 else hi=mid-1 end end
  return lo-1 end

-- pooled stdev of two raw samples
function l.pooledSd(xs,ys,    nx,sx,ny,sy)
  nx,sx = #xs, (select(2, l.welfords(xs)))
  ny,sy = #ys, (select(2, l.welfords(ys)))
  return (((nx-1)*sx*sx + (ny-1)*sy*sy)/(nx+ny-2))^0.5 end

-- Cliff's delta effect size; ys pre-sorted
function l.cliffsDelta(xs,ys,    n,p,ngt,nlt)
  n,p,ngt,nlt = #xs,#ys,0,0
  for _,v in ipairs(xs) do
    ngt = ngt + l.bisect(ys,v,true)
    nlt = nlt + (p - l.bisect(ys,v)) end
  return abs(ngt-nlt)/(n*p) end

-- Kolmogorov-Smirnov max CDF gap; both pre-sorted
function l.ks(xs,ys,    n,p,d,gap)
  n,p,d = #xs,#ys,0
  gap = function(v)
    return abs(l.bisect(xs,v)/n - l.bisect(ys,v)/p) end
  for _,v in ipairs(xs) do d=max(d,gap(v)) end
  for _,v in ipairs(ys) do d=max(d,gap(v)) end
  return d end

-- xs,ys same? all of: mid gap<=eps, cliffs, ks
function l.same(xs,ys,eps,cliffs,ksconf,    n,p,a,b)
  eps, cliffs, ksconf = eps or 0, cliffs or 0.195, ksconf or 1.36
  a,b = l.sort({table.unpack(xs)}), l.sort({table.unpack(ys)})
  n,p = #a,#b
  if abs(a[n//2+1]-b[p//2+1])<=eps then return true end
  if l.cliffsDelta(a,b)>cliffs then return false end
  return l.ks(a,b) <= ksconf*((n+p)/(n*p))^0.5 end

-- dict[k]=nums -> all keys stats-same as best mu
function l.topTier(dict,cmp,eps,cliffs,ksconf,
                   out,names,best,cand,th)
  out={}
  names = l.keysort(l.kap(dict,function(k,_) return k end),
                    function(k) return (l.welfords(dict[k])) end,
                    cmp)
  best = dict[names[1]]
  out[names[1]] = (l.welfords(best))
  for i=2,#names do
    cand = dict[names[i]]
    th = (eps or 0) * l.pooledSd(best, cand)
    if not l.same(best, cand, th, cliffs, ksconf) then break end
    out[names[i]] = (l.welfords(cand)) end
  return out end


-- ## confuse
-- Confuse. A confusion matrix: count (want,got) pairs, then
-- per-klass tn/fn/fp/tp and the derived acc/pred/pf/pd.


local Confuse = {}

-- ctor: confusion matrix counts + klass set
function Confuse.new(file)
  return l.new(Confuse, {t={}, klasses={}, file=file or ""}) end

-- bump count for (want,got) pair
function Confuse.add(i,want,got)
  i.t[want]       = i.t[want] or {}
  i.t[want][got]  = (i.t[want][got] or 0) + 1
  i.klasses[want], i.klasses[got] = true, true end

-- per-klass {tn,fn,fp,tp,acc,pred,pf,pd,...}
function Confuse.scores(i,    out,tn,fn,fp,tp,n)
  out = {}
  for _,klass in ipairs(
      l.sort(l.kap(i.klasses,
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

l.Confuse = Confuse


-- ## str
-- Strings and files. `thing` coerces csv cells; `o` pretty
-- prints anything (sorted dict keys); `path` expands a
-- leading $MOOT (env, else ~/gits/moot); `csv` streams
-- typed rows; `chk` runs {tag,got,want[,tol]} test cases.


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


-- ## cli
-- Cli. `section`/`flags`/`help` mine the help text; `run1`
-- runs one eg with seed reset + pcall; `runAll` sweeps the
-- lot; `main` parses argv (--flag val sets `the`; --name
-- runs an eg); `boot` seeds `the` from a help text's
-- options and dispatches only when run as main.


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
l.boot({}, b4, "lib", help)
return l
