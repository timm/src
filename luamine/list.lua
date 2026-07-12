-- Lists. Tiny functional helpers: sort/push/map/kap plus
-- keysort (decorate-sort-undecorate), slicing, copying and
-- an aligned-table printer.
local l, the = ...

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
