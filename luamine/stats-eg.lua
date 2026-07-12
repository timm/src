-- Tutorial and tests for stats.lua.
local eg, h, a, m, l, the = ...

local rand = math.random

--[[
## Stats, and when do two results differ?

Welford folds values one at a time (no list kept); mode and
entropy summarize counts. Then the conservative equality:
`same` needs median-gap AND cliffs AND ks to agree, and
`topTier` keeps every treatment statistically level with
the best. Notice the demo: two same-distribution samples
tier together; the shifted one drops out.

| call | returns | what |
|------|---------|------|
| `l.welford(v,n,mu,m2)` | n,mu,m2 | online update |
| `l.same(xs,ys,...)` | bool | all three tests agree |
| `l.topTier(dict)` | dict | keys level with the best |
]]

eg["--stats"] = function(    n,mu,m2)
  n,mu,m2 = 0,0,0
  for _,v in ipairs{1,2,3,4,5} do
    n,mu,m2 = l.welford(v,n,mu,m2) end
  return l.chk({"mu",mu,3}, {"sd",l.sd(n,m2),1.5811,1E-3},
    {"mode",l.mode{a=1,b=5,c=2},"b"},
    {"ent",l.ent{a=1,b=1,c=1,d=1},2,1E-9},
    {"bisect",l.bisect({1,2,2,3,5,8},2),3}) end

eg["--sames"] = function(    mk,x,y,z,tier)
  mk = function(off,    u) u={}
    for _=1,50 do u[1+#u]=rand()+off end; return u end
  x,y,z = mk(0), mk(0), mk(5)
  tier = l.topTier({a=x,b=y,c=z}, nil,
                   the.eps, the.cliffs, the.ksconf)
  return l.chk(
    {"cliffs",l.cliffsDelta({1,2,3},{10,11,12}),1},
    {"ks",l.ks({1,2,3},{10,11,12}),1},
    {"pooledSd",l.pooledSd({1,2,3,4,5},{1,2,3,4,5}),1.5811,1E-3},
    {"same",l.same(x,y,the.eps*l.pooledSd(x,y),
                   the.cliffs,the.ksconf),true},
    {"diff",l.same(x,z,the.eps*l.pooledSd(x,z),
                   the.cliffs,the.ksconf),false},
    {"tier a+b",tier.a~=nil and tier.b~=nil,true},
    {"tier no c",tier.c,nil}) end
