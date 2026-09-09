# rp3.py

{% raw %}
```text
rp3.py: batch rows -> clusters -> prune rows and cols. No bins:
raw-value distx (Gower) drives poles, projections, buckets;
KS (rank-based, needs no discretization) prunes cols.
Demos: python3 rp3.py [--k v ...]
```

---

[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)

## ---------------------------------------------------------- stats {#b1}

<small>**---------------------------------------------------------- stats** · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)</small>



```python
Sym = dict
Num = lambda: (0,0,0) # (n, mu, m2)

def makeCols(names):
  return o(names=names,
    all={at: (Num() if s[0].isupper() else Sym())
             for at, s in enumerate(names)},
    ws={at: (s[-1]=="+") for at,s in enumerate(names)},
    xs={at for at, s in enumerate(names) if s[-1] not in "X+-!"},
    ys={at for at, s in enumerate(names) if s[-1] in "+-!"})

def Tbl(src, n=1e32):
  src = iter(src)
  return adds(src, o(rows=[], cols=makeCols(next(src))), n)

def adds(src, it=None, n=1e32):
  it = Num() if it is None else it
  for i, v in enumerate(src):
    it = add(it, v)
    if i + 1 >= n: break
  return it

def add(it, v):
  if v == "?": return it
  if type(it) is tuple: return welford(it, v)
  if type(it) is dict: it[v] = it.get(v, 0) + 1; return it
  it.rows += [v]
  it.cols.all = {at: add(c, v[at]) for at, c in it.cols.all.items()}
  return it

def welford(num, v):
  n, mu, m2 = num
  n += 1; d = v - mu; mu += d / n
  return (n, mu, m2 + d * (v - mu))

def mid(it): 
  if type(it) is dict: return max(it, key=it.get)
  if type(it) is tuple: return  it[1]
  return [mid(col) for col in it.cols.all]

def var(it):
  if type(it) is dict:
    N = sum(it.values())
    return -sum(n/N * log(n/N, 2) for n in it.values() if n)
  n, mu, m2 = it
  return 0 if n < 2 else (max(0, m2) / (n - 1)) ** .5

def norm(num, v):
  if v=="?": return v
  z = (v - num[1]) / (var(num) + TINY)
  return 1 / (1 + exp(-1.702 * max(-3, min(3, z))))

def distx(it, a, b):
  if a == b == "?": return 1
  if type(it) is dict: return a != b
  if type(it) is tuple: return aha(norm(it, a),norm(it, b))
  d = n = 0
  for x in it.cols.xs:
    n += 1; d += distx(it.cols.all[x], a[x], b[x]) ** the.p
  return (d / n) ** (1 / the.p)

def aha(a,b):
  if a == "?": a = 0 if b > .5 else 1
  if b == "?": b = 0 if a > .5 else 1
  return abs(a - b)
```

## ---------------------------------------------------------- table {#b2}

<small>[---------------------------------------------------------- stats](#b1) · **---------------------------------------------------------- table** · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)</small>



```python
def Cols(names):
  return o(names=names,
           all={at: (Num() if s[0].isupper() else Sym())
                for at, s in enumerate(names)},
           xs={at for at, s in enumerate(names) if s[-1] not in "X+-!"},
           ys={at for at, s in enumerate(names) if s[-1] in "+-!"})

def Tbl(src, n=1e32):
  "first row is names; then read rows (all, or just the first n)"
  src = iter(src)
  return adds(src, o(rows=[], cols=Cols(next(src))), n)

def degenerate(tbl, at):
  "bob's rules: cull the syntactically dead. cheap, marginal."
  col, n = tbl.cols.all[at], len(tbl.rows)
  q = sum(1 for r in tbl.rows if r[at] == "?")
  if q > .5 * n: return "missing"
  if type(col) is dict:
    if len(col) > .9 * (n - q): return "id"
    if max(col.values()) > the.most * (n - q): return "const"
  elif var(col) == 0: return "const"

def deads(tbl):
  return {at: why for at in sorted(tbl.cols.xs)
          if (why := degenerate(tbl, at))}
```

## ------------------------------------------------------- geometry {#b3}

<small>[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · **------------------------------------------------------- geometry** · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)</small>



```python
def poles(rows, x):
  "each new pole far (percentile, not max) from those before"
  out = [any1(rows)]
  while len(out) < the.poles:
    tmp = sorted(rows, key=lambda r: min(x(r, p) for p in out))
    out += [tmp[int(the.far * (len(tmp) - 1))]]
  return out

def project(a, b, x):
  c = x(a, b) + TINY
  return lambda r: (x(a, r)**2 + c*c - x(b, r)**2) / (2*c)

def cuts(vals):
  vals = sorted(vals); n = len(vals)
  return [vals[i * n // the.pbins] for i in range(1, the.pbins)]

def digit(v, cut): return sum(v >= c for c in cut)

def grid(rows, x):
  "poles -> consecutive-pair projections -> equal-freq cuts -> int key"
  ps    = poles(rows, x)
  projs = [project(a, b, x) for a, b in zip(ps, ps[1:])]
  cutss = [cuts([p(r) for r in rows]) for p in projs]
  def key(r):
    k = 0
    for p, cut in zip(projs, cutss): k = k * the.pbins + digit(p(r), cut)
    return k
  return key

def push(buckets, k, x):
  "reservoir: bucket sees all, keeps the.cap, unbiased"
  b = buckets.setdefault(k, o(n=0, kept=[]))
  b.n += 1
  if len(b.kept) < the.cap: b.kept += [x]
  elif random.random() < the.cap / b.n:
    b.kept[random.randrange(the.cap)] = x
  return b
```

## ---------------------------------------------------------- prune {#b4}

<small>[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · **---------------------------------------------------------- prune** · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)</small>



```python
def ks(a, b):
  "max gap between two sample cdfs"
  a, b = sorted(a), sorted(b)
  d = i = j = 0
  while i < len(a) and j < len(b):
    x = a[i] if a[i] <= b[j] else b[j]
    while i < len(a) and a[i] <= x: i += 1
    while j < len(b) and b[j] <= x: j += 1
    d = max(d, abs(i / len(a) - j / len(b)))
  return d

def kolmogorov(tbl, buckets):
  "timm's rule: a col lives iff some bucket differs from the crowd"
  live = set()
  bs = [b for b in buckets.values() if len(b.kept) >= 4]
  for c in sorted(tbl.cols.xs):
    glob = [r[c] for b in bs for r in b.kept if r[c] != "?"]
    for b in bs:
      vals = [r[c] for r in b.kept if r[c] != "?"]
      if len(vals) >= 4 and ks(vals, glob) >= the.ks:
        live.add(c); break
  return live
```

## ------------------------------------------------------- pipeline {#b5}

<small>[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · **------------------------------------------------------- pipeline** · [---------------------------------------------------------- demos](#b6) · [----------------------------------------------------------- lib](#b7)</small>



```python
def pipeline(src):
  tbl  = Tbl(src)                                  # 1. read all
  dead = deads(tbl)                                # 2. bob's rules
  tbl.cols.xs -= set(dead)
  x    = lambda r1, r2: distx(tbl, r1, r2)         # 3. geometry
  key  = grid(tbl.rows, x)
  buckets = {}
  for r in tbl.rows: push(buckets, key(r), r)      # 4. cluster
  live = kolmogorov(tbl, buckets)                  # 5. timm's rule
  return o(tbl=tbl, buckets=buckets, n=len(tbl.rows),
           dead=dead, live=live)
```

## ---------------------------------------------------------- demos {#b6}

<small>[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · **---------------------------------------------------------- demos** · [----------------------------------------------------------- lib](#b7)</small>



```python
def test_pipe():
  z    = pipeline(csv(the.file))
  kept = sum(len(b.kept) for b in z.buckets.values())
  print(f"  rows {z.n} -> {kept} kept in {len(z.buckets)} buckets"
        f" (of {the.pbins ** (the.poles - 1)} possible)")
  print(f"  cols: dead {z.dead or 'none'};"
        f" live {[z.tbl.cols.names[c] for c in sorted(z.live)]}"
        f" of {[z.tbl.cols.names[c] for c in sorted(z.tbl.cols.xs)]}")
  assert kept <= len(z.buckets) * the.cap
  assert z.live <= z.tbl.cols.xs

def test_hist():
  z = pipeline(csv(the.file))
  for k, b in sorted(z.buckets.items(), key=lambda kb: -kb[1].n):
    pct = 100 * b.n / z.n
    print(f"  {k:6} {b.n:4} {pct:5.1f}% {'*' * round(pct)}")

def test_speed():
  t0 = time.perf_counter()
  z  = pipeline(csv(the.file))
  ms = 1000 * (time.perf_counter() - t0)
  print(f"  {z.n} rows in {ms:.1f} ms ({z.n / ms:.1f} rows/ms)")
  assert ms < 5000
```

## ----------------------------------------------------------- lib {#b7}

<small>[---------------------------------------------------------- stats](#b1) · [---------------------------------------------------------- table](#b2) · [------------------------------------------------------- geometry](#b3) · [---------------------------------------------------------- prune](#b4) · [------------------------------------------------------- pipeline](#b5) · [---------------------------------------------------------- demos](#b6) · **----------------------------------------------------------- lib**</small>



```python
def thing(s):
  try: return float(s)
  except ValueError: return s

def csv(f):
  for l in open(f, encoding="utf-8-sig"):
    if l := l.strip():
      yield [thing(s.strip()) for s in l.split(",")]

def cli(d, s):
  "--k v or --k=v, any key of d; coerce to the old value's type"
  for k, old in vars(d).items():
    if m := re.search(f"--{k}[= ]+(\\S+)", s):
      vars(d)[k] = type(old)(m.group(1))

def tests(funs):
  for k, f in sorted(funs.items()):
    if k[:5] == "test_":
      print("#", k); srand(the.seed); f()
  print("all passed")

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(dict(globals()))
```

{% endraw %}