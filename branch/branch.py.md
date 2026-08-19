# branch.py

{% raw %}
```text
branch: prune one regression tree into many small trees.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 branch-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --budget labeling cap          = 50
  --more   labels per round      = 4
  --best   pool keep fraction    = 0.66
  --cap    acquire pool cap      = 1024
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 4
  --check  rows checked on test  = 5
  --round  decimals shown        = 3
  -h       print this help

TESTS: (in branch-eg.py; run with their bare name):
  tbl disty acquire tree klass walk holdout
  tied confuse compare
  all      run every test above, reseting seed each

IDEA: an active learner labels a few rows per round and
culls the pool toward the good pole; a binary regression
tree fits the labels' d2h; a walk then yields every pruned
version of that tree (at each cut, each side stays or
collapses to a leaf: 4 shapes per cut). Every yielded tree
carries at its root the min mean-d2h of its leaves, so the
best pruning is one min() over a generator, and that tree
sorts the holdout.
```

---

[](#b1) · [](#b2) · [](#b3) · [](#b4) · [](#b5) · [](#b6) · [](#b7) · [](#b8) · [](#b9)

##  {#b1}

<small>**** · [](#b2) · [](#b3) · [](#b4) · [](#b5) · [](#b6) · [](#b7) · [](#b8) · [](#b9)</small>



```python
Sym = dict
Num = lambda n=0, mu=0, m2=0: (n, mu, m2)

def is_sym(i): return type(i) is dict

def Tbl(src):
  src = iter(src)
  tbl = o(names=next(src), cols={},x=[],y={},rows=[],klass=None)
  return adds(src, Cols(tbl))

def Cols(tbl):
  for at, s in enumerate(tbl.names):
    tbl.cols[at] = Num() if s[0].isupper() else Sym()
    if s[-1] == "X": continue
    if   s[-1] == "!"  : tbl.klass = at
    elif s[-1] in "+-" : tbl.y[at] = s[-1] == "+"
    else: tbl.x += [at]
  return tbl
```

##  {#b2}

<small>[](#b1) · **** · [](#b3) · [](#b4) · [](#b5) · [](#b6) · [](#b7) · [](#b8) · [](#b9)</small>



```python
def size(i): return sum(i.values()) if is_sym(i) else i[0]

def mid(i): return max(i, key=i.get) if is_sym(i) else i[1]

def var(i): return ent(i) if is_sym(i) else sd(i)

def ent(d):
  N = size(d)
  return -sum(v/N*log2(v/N) for v in d.values() if v)

def sd(i):
  n,_,m2 = i
  return 0 if n < 2 else (max(0,m2)/(n-1))**.5

def count(sym, v):
  sym[v] = sym.get(v, 0) + 1
  return sym

def add(i, v):
  if isinstance(i, o):
    i.rows += [v]
    for at, c in i.cols.items(): i.cols[at] = add(c, v[at])
    return i
  if v == "?": return i
  if is_sym(i): return count(i, v)
  n, mu, m2 = i
  n += 1; d = v - mu; mu += d/n
  return (n, mu, m2 + d*(v - mu))

def adds(src, i=None):
  i = Num() if i is None else i
  for v in src: i = add(i, v)
  return i

def sub(i, j):
  if is_sym(i):
    return {k: n for k in i
            if (n := i[k] - j.get(k, 0)) > 0}
  (ni,mui,m2i), (nj,muj,m2j) = i, j
  if (n := ni - nj) <= 0: return Num()
  d = muj - mui
  return (n, (ni*mui - nj*muj)/n,
          max(0, m2i - m2j - d*d*ni*nj/n))
```

##  {#b3}

<small>[](#b1) · [](#b2) · **** · [](#b4) · [](#b5) · [](#b6) · [](#b7) · [](#b8) · [](#b9)</small>



```python
def norm(tbl, at, v):
  if v == "?": return v
  z = (v - tbl.cols[at][1]) / (sd(tbl.cols[at]) + TINY)
  return 1 / (1 + exp(-1.7 * max(-3, min(3, z))))

def disty(tbl, row):
  d = n = 0
  for at, g in tbl.y.items():
    if (v := row[at]) != "?":
      n += 1; d += (norm(tbl, at, v) - g)**2
  return (d / n) ** .5

def distx(tbl, r1, r2):
  d = n = 0
  for at in tbl.x:
    u, v = r1[at], r2[at]
    if u == v == "?": g = 1
    elif is_sym(tbl.cols[at]): g = u != v
    else:
      u, v = norm(tbl, at, u), norm(tbl, at, v)
      if u == "?": u = 1 if v < .5 else 0
      if v == "?": v = 1 if u < .5 else 0
      g = abs(u - v)
    n += 1; d += g*g
  return (d/n) ** .5
```

##  {#b4}

<small>[](#b1) · [](#b2) · [](#b3) · **** · [](#b5) · [](#b6) · [](#b7) · [](#b8) · [](#b9)</small>



```python
def project(rows, x, y, east=None, west=None):
  far  = lambda r: max(rows, key=lambda z: x(z, r))
  east = east or far(rows[0])
  west = west or far(east)
  if y(east) > y(west): east, west = west, east
  c = x(east, west) + TINY
  return lambda r: (x(east,r)**2 + c*c - x(west,r)**2)/(2*c)

def acquire(tbl, rows):
  y = lambda r: disty(tbl, r)
  x = lambda a, b: distx(tbl, a, b)
  return sorted(sway3(some(rows, the.cap), y, x,
                      the.budget - the.check), key=y)

def sway3(rows, y, x, cap, lab=None, east=None, west=None):
  b4  = rows[:]
  lab = lab or {}
  while len(rows) >= 2*the.leaf:
    more = min(the.more, cap - len(lab))
    less = int(max(1, the.best * len(rows)))
    new  = []
    for r in rows:
      if   id(r) in lab         : new += [r]
      elif (more := more-1) >= 0: new += [r]; lab[id(r)]=r
    if len(lab) >= cap: return lab.values()
    rows = sorted(rows,
                  key=project(new, x, y, east, west))[:less]
  if len(lab) < len(b4):
    seen = sorted(lab.values(), key=y)
    return sway3(shuffle(b4), y, x, cap,
                 lab, seen[0], seen[-1])
  return lab.values()
```

##  {#b5}

<small>[](#b1) · [](#b2) · [](#b3) · [](#b4) · **** · [](#b6) · [](#b7) · [](#b8) · [](#b9)</small>



```python
def score(a, b):
  return ((var(a)*size(a) + var(b)*size(b))
          / (size(a) + size(b) + TINY))

def has(tbl, row, at, v):
  x = row[at]
  return x == "?" or (x == v if is_sym(tbl.cols[at])
                      else x <= v)

def bins(tbl, rows, at, Y, accum=Num):
  xy  = [(r[at], Y(r)) for r in rows if r[at] != "?"]
  n   = len(xy)
  tot = adds((y for _,y in xy), accum())
  bin = lambda here,k: (score(here, sub(tot,here)), at, k)
  if is_sym(tbl.cols[at]):
    d = {}
    for x, y in xy: d[x] = add(d.get(x) or accum(), y)
    if len(d) > 1:
      for k, here in d.items(): yield bin(here, k)
  else:
    xy.sort(key=lambda z: z[0]); here = accum()
    for j,(x,y) in enumerate(xy):
      here = add(here, y)
      if j+1 < n and x != xy[j+1][0]: yield bin(here, x)

def Tree(tbl, rows, Y=None, accum=Num, lvl=0):
  Y  = Y or (lambda r: disty(tbl, r))
  ys = adds(map(Y, rows), accum())
  tree = o(at=None, n=len(rows), mu=mid(ys), leafs=1,
           ys=ys, here=var(ys) if is_sym(ys) else mid(ys))
  tree.score = tree.here
  if len(rows) >= 2*the.leaf and lvl < the.maxd:
    if b := min((c for at in tbl.x
                 for c in bins(tbl,rows,at,Y,accum)),
                default=None, key=lambda c: c[0]):
      _, at, v = b
      yes, no = [], []
      for r in rows:
        (yes if has(tbl, r, at, v) else no).append(r)
      if yes and no:
        tree.at, tree.v = at, v
        tree.yes   = Tree(tbl, yes, Y, accum, lvl+1)
        tree.no    = Tree(tbl, no,  Y, accum, lvl+1)
        tree.score = min(tree.yes.score, tree.no.score)
        tree.leafs = tree.yes.leafs + tree.no.leafs
  return tree

def leafed(x):
  return o(at=None, n=x.n, mu=x.mu, here=x.here,
           score=x.here, leafs=1, ys=x.ys)
```

##  {#b6}

<small>[](#b1) · [](#b2) · [](#b3) · [](#b4) · [](#b5) · **** · [](#b7) · [](#b8) · [](#b9)</small>



```python
def walk(tree):
  if tree.at is None: yield tree; return
  for yes in sides(tree.yes):
    for no in sides(tree.no):
      yield o(at=tree.at, v=tree.v, n=tree.n,
              yes=yes, no=no,
              score=min(yes.score, no.score),
              leafs=yes.leafs + no.leafs)

def sides(tree):
  yield leafed(tree)
  if tree.at is not None: yield from walk(tree)

def leaf(tbl, tree, row):
  while tree.at is not None:
    tree = (tree.yes if has(tbl, row, tree.at, tree.v)
            else tree.no)
  return tree.mu
```

##  {#b7}

<small>[](#b1) · [](#b2) · [](#b3) · [](#b4) · [](#b5) · [](#b6) · **** · [](#b8) · [](#b9)</small>



```python
def holdout(tbl, get=None):
  rows = shuffle(tbl.rows)
  half = len(rows)//2
  train, test = rows[:half], rows[half:]
  lab  = (get or acquire)(tbl, train)
  best = min(walk(Tree(tbl, lab)),
             key=lambda x: (x.score, x.leafs))
  top  = sorted(test, key=lambda r: leaf(tbl, best, r))
  return best, min(top[:the.check],
                   key=lambda r: disty(tbl, r)), test
```

##  {#b8}

<small>[](#b1) · [](#b2) · [](#b3) · [](#b4) · [](#b5) · [](#b6) · [](#b7) · **** · [](#b9)</small>



```python
def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

def settings(doc):
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

def path(s):
  return os.path.expanduser(s.replace("$MOOT", MOOT, 1))

def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]

def shuffle(lst): return random.sample(lst, len(lst))

def some(lst, k): return random.sample(lst, min(k, len(lst)))
```

##  {#b9}

<small>[](#b1) · [](#b2) · [](#b3) · [](#b4) · [](#b5) · [](#b6) · [](#b7) · [](#b8) · ****</small>



```python
def main(funs):
  if "-h" in sys.argv: return print(__doc__)
  for a in sys.argv[1:]:
    if a[:2]=="--" and "=" in a:
      k,v = a[2:].split("=",1)
      if k in vars(the): setattr(the, k, thing(v))
  for a in sys.argv[1:]:
    if (n := "test_"+a) in funs:
      random.seed(the.seed); funs[n]()

the = settings(__doc__)
```

{% endraw %}