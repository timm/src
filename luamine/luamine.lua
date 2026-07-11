#!/usr/bin/env lua
-- style: https://github.com/aiez/luamine/blob/main/docs/style.md
local help = [[
# AI primitives: Num, Sym, Cols, dist, tree
(c) 2026 Tim Menzies <timm@ieee.org> MIT license
## options
  -t  --train=$MOOT/optimize/misc/auto93.csv  train CSV
  -T  --test=$MOOT/optimize/misc/auto93.csv   test CSV
      --seed=1     RNG seed
  --bins=2     Num cut count (percentile-spaced)
  --leaf=3     stop recursion when #rows < leaf
  --p=2        default Minkowski exponent for dist
  --cap=2048   ftree row-sample size before build
  --budget=32  label budget for active acquire loop
  --k=1        Bayes Laplace/Lidstone smoothing
  --m=2        Bayes m-estimate prior weight
  --F=0.5      DE extrapolate scale
  --cr=0.9     DE crossover rate (per dim)
## egs
  --cols    Sym/Num/adds + header parse
  --data    Data ctor, clone, centroid, dxdy
  --dist    distx/disty/near
  --cuts    cut emit/apply + bestCut
  --tree    bi-tree build/show/relevant/leafStats
  --ftree   fastmap bi-tree + poles
  --bayes   like/likes
  --mutate  pick/picks/extrapolate
  --body    iter csv rows (skip header)
]]
local b4={}; for k,_ in pairs(_G) do b4[k]=k end
local m = {}
local l = require"lib"
local the = l.the
local floor,exp,abs,log = math.floor,math.exp,math.abs,math.log
local sqrt,pi,huge = math.sqrt, math.pi, math.huge
local min,max,rand = math.min, math.max, math.random


-- ## Cut ops
-- A `cut` is one test: op(row[at], val). `eq` and `le` are
-- the two ops; `cut` packs one with its yes/no print names
-- and an imputation `mid`. Column types emit cuts below.
local Cut = {}
-- cut op: equality
local function eq(a,b) return a==b end
-- cut op: less-or-equal
local function le(a,b) return a<=b end
-- build one Cut on col c: op(row[c.at], val)
local function cut(c,op,val,yes,no)
  return l.new(Cut, {at=c.at, op=op, val=val, yes=yes, no=no,
                     mid=c:mid(), txt=c.txt}) end


-- ## Sym
-- `Sym` summarizes one symbolic column: counts in has{}.
-- `mid` = mode, `spread` = entropy; `cuts` emits one ==cut
-- per value seen (one-vs-rest).
local Sym = {}
-- ctor: symbol counts in has{}
function Sym.new(s,at)
  return l.new(Sym, {at=at or 0, txt=s or "", n=0, has={}}) end

-- bump count for v, weight w; skip "?" and nil
function Sym.add(i,v,    w)
  if v=="?" or v==nil then return end
  w = w or 1
  i.n, i.has[v] = i.n + w, w + (i.has[v] or 0) end

-- mid of Sym = mode
function Sym.mid(i) return l.mode(i.has) end
-- spread of Sym = entropy
function Sym.spread(i) return l.ent(i.has) end

-- one ==cut per value seen in rows (one-vs-rest)
function Sym.cuts(i,rows,    seen,cuts,x)
  seen,cuts = {},{}
  for _,r in ipairs(rows) do
    x = r[i.at]; if x~="?" then seen[x]=true end end
  seen = l.sort(l.kap(seen, function(k,_) return k end))
  for _,v in ipairs(seen) do
    l.push(cuts, cut(i,eq,v,"==","~=")) end
  return cuts end


-- ## Num
-- `Num` summarizes one numeric column by Welford (n,mu,m2):
-- `mid`/`spread` = mean/sd; `norm` squashes to 0..1 via a
-- logistic z-score; `cuts` emits bins-1 percentile <=cuts.
-- A name ending "-" sets goal 0 (minimize).
local Num = {}
-- ctor: welford state; goal 0 if name ends "-"
function Num.new(s,at)
  return l.new(Num, {at=at or 0, txt=s or "", n=0, mu=0, m2=0,
                     goal=(s or ""):find"-$" and 0 or 1}) end

-- welford update; skip "?" and nil
function Num.add(i,v,w)
  if v=="?" or v==nil then return v end
  i.n,i.mu,i.m2 = l.welford(v, i.n, i.mu, i.m2, w)
  return v end

-- mid of Num = mean
function Num.mid(i) return i.mu end
-- spread of Num = stdev
function Num.spread(i) return l.sd(i.n, i.m2) end
-- mu +- k spreads (legal range for mutants)
function Num.lohi(i,k)
  return i.mu - k*i:spread(), i.mu + k*i:spread() end

-- sigmoid-normalize v to 0..1; "?" passes through
function Num.norm(i,v)
  if v=="?" then return v end
  v = (v - i.mu) / (i:spread() + 1E-32)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, v)))) end

-- bins-1 percentile-spaced <=cuts, deduped
function Num.cuts(i,rows,    vs,n,cuts,v,prev)
  vs = {}
  for _,r in ipairs(rows) do
    if r[i.at]~="?" then l.push(vs, r[i.at]) end end
  if #vs < 2 then return {} end
  l.sort(vs); n,cuts = #vs, {}
  for j = 1, the.bins-1 do
    v = vs[max(1, floor(j * n / the.bins + 0.5))]
    if v ~= prev then
      l.push(cuts, cut(i,le,v,"<=",">")); prev = v end end
  return cuts end


-- ## adds
-- `adds` folds a list or iterator into any summary
-- (default: a fresh `Num`).
-- fold list or iterator into summary it (or Num)
function m.adds(src,it,fn)
  it = it or Num.new()
  if   type(src)=="function"
  then for x in src do it:add(fn and fn(x) or x) end
  else for _,x in ipairs(src or {}) do
         it:add(fn and fn(x) or x) end end
  return it end


-- ## Cols
-- `Cols` types header names into columns: leading uppercase
-- = `Num`; trailing -,+,! = y goals (! = klass); X = skip.
-- `add` routes one row's cells; `mid` = cached centroid.
local Cols = {}
-- header names -> {all,x,y,klass} typed columns
function Cols.new(names,    i,col)
  i = l.new(Cols, {names=names, all={}, x={}, y={},
                   klass=nil, mids=nil})
  for at,s in ipairs(names) do
    col = (s:match"^[A-Z]" and Num or Sym).new(s,at)
    l.push(i.all, col)
    if not s:find"X$" then
      l.push(s:find"[-+!]$" and i.y or i.x, col)
      if s:find"!$" then i.klass = col end end end
  return i end

-- update every column with row; wipe mid cache
function Cols.add(i,row)
  i.mids = nil
  for _,c in ipairs(i.all) do c:add(row[c.at]) end
  return row end

-- centroid = mid of each column (cached)
function Cols.mid(i)
  i.mids = i.mids or l.map(i.all,function(c) return c:mid() end)
  return i.mids end


-- ## Data
-- `Data` = rows + `Cols`; the first row is the header.
-- `clone` reuses a header over new rows. `dxdy` bakes p
-- into x,y,win distance views (win: 100=best, 0=median).
-- `body` iterates a csv's rows, skipping the header.
local Data = {}
-- rows + cols from iterator or list-of-lists
function Data.new(src)
  return m.adds(src, l.new(Data, {cols=nil, rows={}})) end

-- first row builds cols; later rows stored+added
function Data.add(i,row)
  if not i.cols then i.cols = Cols.new(row)
  else i.cols:add(row); l.push(i.rows, row) end
  return row end

-- empty Data, same header; rows optional seed
function Data.clone(i,rows)
  return m.adds(rows or {}, Data.new{i.cols.names}) end

-- dist views x,y,win with p baked in; win 0..100
function Data.dxdy(i,p,    y,lo,mid,sd,prep)
  p = p or the.p
  y = function(r) return m.disty(i.cols,r,p) end
  prep = function(    t,n,ten)
    if lo then return end
    t   = l.sort(l.map(i.rows, y))
    n   = #t; ten = floor(n/10)
    lo, mid = t[1], t[max(1, floor(n/2))]
    sd  = ten>0
          and (t[max(1,9*ten)] - t[max(1,ten)])/2.56 or 0 end
  return {
    x   = function(r1,r2) return m.distx(i.cols,r1,r2,p) end,
    y   = y,
    win = function(r,    x,rng)
      prep()
      x = y(r)
      if x < lo + 0.35*sd then x = lo end
      rng = mid - lo
      if rng == 0 then return 100 end
      return max(-100, floor(100*(1-(x-lo)/rng))) end } end

-- iter csv rows after header
function m.body(file,    iter)
  iter = l.csv(file); iter()
  return iter end


-- ## dist
-- `distx` = Minkowski over x cols (pessimistic on "?");
-- `disty` = distance to ideal y goals (0 = best); `better`
-- = Zitzler domination; `near` sorts rows by distx from a
-- query row.
-- Minkowski dist over x cols; pessimistic "?"
function m.distx(cols,r1,r2,  p,    d,n,v1,v2)
  d,n,p = 0,0,p or the.p
  for _,c in ipairs(cols.x) do
    n = n+1
    v1, v2 = r1[c.at], r2[c.at]
    if v1=="?" and v2=="?" then d=d+1
    elseif c.mu then
      v1, v2 = c:norm(v1), c:norm(v2)
      if v1=="?" then v1 = v2 > 0.5 and 0 or 1 end
      if v2=="?" then v2 = v1 > 0.5 and 0 or 1 end
      d = d + abs(v1-v2)^p
    else
      d = d + (v1==v2 and 0 or 1)^p end end
  return (d/n)^(1/p) end

-- distance to ideal over y goals (0=best)
function m.disty(cols,row,  p,    d,n)
  d,n,p = 0,0,p or the.p
  for _,c in ipairs(cols.y) do
    n,d = n+1, d + abs(c:norm(row[c.at]) - c.goal)^p end
  return (d/n)^(1/p) end

-- Zitzler continuous domination: a betters b?
function m.better(data,row1,row2,    s1,s2,n,w,a,b)
  s1, s2, n = 0, 0, #data.cols.y
  for _,col in ipairs(data.cols.y) do
    a, b = col:norm(row1[col.at]), col:norm(row2[col.at])
    w    = col.goal==1 and 1 or -1
    s1   = s1 - exp(w * (a - b) / n)
    s2   = s2 - exp(w * (b - a) / n) end
  return s1/n < s2/n end

-- rows sorted by distx to query; self parked last
function m.near(cols,query,rows,  p)
  return l.keysort(rows, function(r)
    return r==query and 2 or m.distx(cols,query,r,p) end) end


-- ## bayes
-- `like` = P(v|col): m-estimate for Syms, gaussian pdf for
-- Nums. `likes` = log-sum likelihood of one row given one
-- class's data. Enough for naive bayes (see lapps.lua).
-- P(v|col): Sym m-estimate, Num gaussian pdf
function m.like(col,v,prior,    sd,z)
  if not col.mu then
    return ((col.has[v] or 0) + the.k*prior)
           / (col.n + the.k) end
  sd = col:spread() + 1E-32; z = 2 * sd * sd
  return exp(-(v-col.mu)^2 / z) / sqrt(pi * z) end

-- log-sum likelihood of row given class data
function m.likes(data,row,nRows,nKlasses,  prior,out,v)
  prior = (#data.rows + the.m) / (nRows + the.m * nKlasses)
  out = log(prior)
  for _,c in ipairs(data.cols.x) do
    v = row[c.at]
    if v ~= "?" and v ~= nil then
      v = m.like(c,v,prior)
      if v > 0 then out = out + log(v) end end end
  return out end


-- ## pick / mutate
-- Mutators for the optimizers in lapps.lua: `pick` samples
-- one column (Sym by frequency, Num by gauss +-3sd);
-- `picks` mutates n random x cells; `extrapolate` is DE's
-- a + F*(b - c), wrapped to mu +- 4sd.
-- sample new value: Sym by freq, Num gauss+-3sd
function m.pick(col,v,    tmp,lo,hi,new)
  if not col.mu then return l.pickDict(col.has) end
  tmp = (v and v ~= "?") and v or col.mu
  lo, hi = col:lohi(3)
  new = tmp + col:spread() * l.irwinHall()
  return max(lo, min(hi, new)) end

-- copy row; mutate n random x cols via pick
function m.picks(data,row,n,    out,xs,col)
  out, xs = l.copy(row), {}
  for _,col in ipairs(data.cols.x) do xs[1+#xs] = col end
  l.shuffle(xs)
  for j = 1, min(n, #xs) do
    col = xs[j]; out[col.at] = m.pick(col, out[col.at]) end
  return out end

-- DE blend a+F*(b-c) per dim, prob CR; wraps
-- to mu+-4sd; Syms flip to b with prob F; "?" keeps a
function m.extrapolate(cols,a,b,c,F,CR,
                       out,va,vb,vc,v,lo,hi,span,keep)
  F, CR = F or the.F, CR or the.cr
  out  = l.copy(a)
  keep = cols[rand(#cols)]
  for _,col in ipairs(cols) do
    if col ~= keep and rand() < CR then
      va,vb,vc = a[col.at], b[col.at], c[col.at]
      if va == "?" then out[col.at] = "?"
      elseif not col.mu then
        out[col.at] = (rand() < F) and vb or va
      elseif vb=="?" or vc=="?" then out[col.at] = va
      else
        v = va + F*(vb-vc)
        lo, hi = col:lohi(4)
        span = hi - lo + 1E-32
        out[col.at] = lo + (v - lo) % span end end end
  return out end


-- ## Cut
-- Using cuts: `apply` splits rows ("?" imputed via mid),
-- returning both sides plus their y summaries; `score` =
-- size-weighted y-spread; `bestCut` = min score over every
-- cut of every x column.
-- split rows on cut; "?" imputed via cut.mid;
-- also returns y-summaries of both sides
function Cut.apply(i,rows,y,Sumr,    ls,rs,lsum,rsum,x)
  Sumr = Sumr or Sym.new
  ls,rs,lsum,rsum = {},{},Sumr(),Sumr()
  for _,r in ipairs(rows) do x = r[i.at]
    if x=="?" then x = i.mid end
    if i.op(x, i.val)
    then ls[1+#ls]=r; lsum:add(y(r))
    else rs[1+#rs]=r; rsum:add(y(r)) end end
  return ls,rs,lsum,rsum end

-- size-weighted y-spread after applying cut
function Cut.score(i,rows,y,Sumr,    ls,rs,lsum,rsum)
  ls,rs,lsum,rsum = i:apply(rows,y,Sumr)
  if #ls==0 or #rs==0 then return huge end
  return (lsum.n*lsum:spread() + rsum.n*rsum:spread())
       / (lsum.n + rsum.n) end

-- min-score cut across all x cols, all cuts
function m.bestCut(cols,rows,y,Sumr,    best,score,s)
  best,score = nil, huge
  for _,c in ipairs(cols.x) do
    for _,cut in ipairs(c:cuts(rows)) do
      s = cut:score(rows,y,Sumr)
      if s<score then best,score = cut,s end end end
  return best end


-- ## Tree (build)
-- `bitree` grows a greedy binary tree; its pick(rows)
-- callback returns y,Sumr to keep splitting, or nil to
-- leaf. `Data.tree` supervises on y (default: disty).
-- `Data.ftree` is unsupervised fastmap over pole
-- projections: y columns never consulted.
-- generic greedy bi-tree; pick(rows)->y,Sumr|nil
function m.bitree(cols,rows,leaf,pick,    y,Sumr,cut,ls,rs)
  y,Sumr = pick(rows)
  if y then
    cut = m.bestCut(cols,rows,y,Sumr)
    if cut then
      ls,rs = cut:apply(rows,y,Sumr)
      if #ls>=leaf and #rs>=leaf then
        cut.rows  = rows
        cut.left  = m.bitree(cols,ls,leaf,pick)
        cut.right = m.bitree(cols,rs,leaf,pick)
        return cut end end end
  return {rows=rows, leaf=true} end

-- supervised bi-tree on y (default disty)
function Data.tree(i,y,Sumr,leaf,  p)
  leaf, Sumr = leaf or the.leaf, Sumr or Num.new
  y = y or i:dxdy(p).y
  return m.bitree(i.cols, i.rows, leaf, function(rs)
    if #rs>=leaf then return y,Sumr end end) end

-- 2 far rows via fastmap: rand->far->far(far)
function m.poles(d,rows,    far,a,b)
  far = function(piv) return l.keysort(rows, function(r)
          return d.x(piv,r) end)[1 + floor(0.9 * #rows)] end
  a = far(rows[rand(#rows)])
  b = far(a)
  return a, b end

-- fastmap bi-tree: split on pole projection;
-- y cols never consulted; rows cap-sampled first
function Data.ftree(i,leaf,p,cap,    d)
  cap, leaf, p = cap or the.cap, leaf or the.leaf, p or the.p
  d = i:dxdy(p)
  return m.bitree(i.cols, l.anys(i.rows,cap), leaf,
    function(rs,    a,b,y)
      if #rs < 2*leaf then return end
      a,b = m.poles(d,rs)
      y = function(r) return d.x(r,a) - d.x(r,b) end
      return y, Num.new end) end


-- ## Tree (use)
-- `relevant` walks one row to its leaf's rows; `leafStats`
-- folds leaves into a Num; `show` prints the tree as an
-- aligned table, best (+) and worst (-) leaves marked.
-- walk tree to leaf for row; "?" imputed
function m.relevant(node,row,    x)
  while not node.leaf do
    x = row[node.at]
    if x=="?" then x = node.mid end
    node = node.op(x, node.val)
           and node.left or node.right end
  return node.rows end

-- fold fn over leaves into a Num (default: size)
function m.leafStats(node,fn,ls)
  fn = fn or function(n) return #n.rows end
  ls = ls or Num.new()
  if node.leaf then ls:add(fn(node))
  else m.leafStats(node.left,fn,ls)
       m.leafStats(node.right,fn,ls) end
  return ls end

-- y header list: klass txt | y txts + "disty"
function m.ylabel(cols,    out)
  if cols.klass then return {cols.klass.txt} end
  out = l.map(cols.y, function(c) return c.txt end)
  out[1+#out] = "disty"
  return out end

-- y stats list: klass mode | y means + disty mu
function m.ystats(cols,rows,    midOf,out)
  midOf = function(K,get)
    return l.o(m.adds(rows, K(), get):mid()) end
  if cols.klass then
    return {midOf(Sym.new,
                  function(r) return r[cols.klass.at] end)} end
  out = l.map(cols.y, function(c)
    return midOf(Num.new, function(r) return r[c.at] end) end)
  out[1+#out] = midOf(Num.new,
                      function(r) return m.disty(cols,r) end)
  return out end

-- mean disty of rows (0 if classify task)
function m.mu_disty(cols,rows,  p)
  if cols.klass then return 0 end
  return m.adds(rows, Num.new(),
    function(r) return m.disty(cols,r,p) end):mid() end

-- recurse tree into out.rows; best/worst marked
local function showRows(node,cols,depth,op,out,
                        row,a,b,kids,mark)
  mark = (node==out.best and "+")
      or (node==out.worst and "-") or ""
  row = {mark, tostring(#node.rows)}
  for _,v in ipairs(m.ystats(cols, node.rows)) do
    l.push(row, v) end
  l.push(row, ("|  "):rep(max(0,depth-1))..(op or "."))
  l.push(out.rows, row)
  if not node.leaf then
    a = {node.left,  node.yes, m.mu_disty(cols,node.left.rows)}
    b = {node.right, node.no,  m.mu_disty(cols,node.right.rows)}
    kids = a[3] <= b[3] and {a,b} or {b,a}
    for _,k in ipairs(kids) do
      showRows(k[1], cols, depth+1,
        node.txt.." "..k[2].." "..l.o(node.val), out) end end end

-- print tree as aligned if/else table
function m.show(node,cols,    out,hdr,scan)
  out  = {rows={}, just={"<",">"}}
  scan = function(n,    d)
    if n.leaf then d = m.mu_disty(cols, n.rows)
      if not out.best or d < out.bd then
        out.best, out.bd = n, d end
      if not out.worst or d > out.wd then
        out.worst, out.wd = n, d end
    else scan(n.left); scan(n.right) end end
  scan(node)
  hdr = {"", "n"}
  for _,v in ipairs(m.ylabel(cols)) do
    l.push(hdr, v); l.push(out.just, ">") end
  l.push(hdr, "tree"); l.push(out.just, "<")
  l.push(out.rows, hdr)
  showRows(node, cols, 0, nil, out)
  l.tabulate(out.rows, out.just, "  ") end


-- ## start
-- Export the classes; `boot` seeds `the` from the help
-- options, then dispatches egs only when run as main
-- (a require never triggers the CLI).
m.Sym, m.Num, m.Data, m.Cols = Sym,Num,Data,Cols
m.help = help
l.boot({},b4,"luamine",help)
return m
