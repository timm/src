-- Stats. Welford accumulation, mode/entropy for counts,
-- then the conservative equality tests: cliffsDelta + ks +
-- a median-gap check feed `same`; `topTier` keeps every
-- treatment statistically level with the best.
local l, the = ...

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
