-- Tree (use). `relevant` walks one row to its leaf's rows;
-- `leafStats` folds leaves into a Num; `show` prints the
-- tree as an aligned table, best (+) and worst (-) leaves
-- marked.
local m, l, the = ...

local max = math.max

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
  ls = ls or m.Num.new()
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
    return {midOf(m.Sym.new,
                  function(r) return r[cols.klass.at] end)} end
  out = l.map(cols.y, function(c)
    return midOf(m.Num.new, function(r) return r[c.at] end) end)
  out[1+#out] = midOf(m.Num.new,
                      function(r) return m.disty(cols,r) end)
  return out end

-- mean disty of rows (0 if classify task)
function m.mu_disty(cols,rows,  p)
  if cols.klass then return 0 end
  return m.adds(rows, m.Num.new(),
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
