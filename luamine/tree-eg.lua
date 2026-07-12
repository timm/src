-- Tutorial and tests for tree.lua and show.lua.
local eg, h, a, m, l, the = ...

local Sym = m.Sym

--[[
## Trees, supervised

Recurse the cuts: a tree. Here the running example goes
real: auto93 (via $MOOT), budget-sampled, tree'd on its
last column, printed as an aligned if/else table with the
best (+) and worst (-) leaves marked. Notice the checks:
every row lands in exactly one leaf, and `relevant` routes
a row back to its leaf's rows.

| call | returns | what |
|------|---------|------|
| `d:tree(y,Sumr,leaf)` | node | greedy bi-tree on y |
| `m.show(node,cols)` | -- | print aligned table |
| `m.relevant(node,row)` | rows | that row's leaf |
| `m.leafStats(node,fn)` | num | fold over leaves |
]]

eg["--tree"] = function(    data,root,y,count,ls)
  the.budget = 32     -- label budget (lapps resets it to 512)
  data = h.egData()
  data = data:clone(l.slice(l.shuffle(l.copy(data.rows)),
                            1, the.budget))
  y = function(r) return r[#r] end
  root = data:tree(y, Sym.new, the.leaf)
  m.show(root, data.cols)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  ls = m.leafStats(root)
  return l.chk({"#rows",count(root),#data.rows},
    {"leaves>0",ls.n>0,true},
    {"relevant",#m.relevant(root,data.rows[1])>0,true}) end

--[[
## Trees, unsupervised

`ftree` grows the same shape of tree without ever reading a
y column: find two far rows (`poles`, via fastmap), project
everything onto the line between them, split on that.
Notice the promise this makes: structure gets found for
free; labels are only spent later, on the leaves we like.

| call | returns | what |
|------|---------|------|
| `m.poles(d,rows)` | a,b | two far rows |
| `d:ftree(leaf,p,cap)` | node | y never consulted |
]]

eg["--ftree"] = function(    data,p1,p2,root,count)
  data = h.egData()
  p1,p2 = m.poles(data:dxdy(), data.rows)
  root = data:ftree(the.leaf, the.p, #data.rows)
  count = function(n) if n.leaf then return #n.rows end
                      return count(n.left)+count(n.right) end
  return l.chk({"poles differ",p1 ~= p2,true},
    {"#rows",count(root),#data.rows},
    {"is tree",root.at~=nil or root.leaf,true}) end
