# fft.py

{% raw %}
```text

```

```python
import math, os, sys

SETTINGS = dict(seed=1234567891, p=2, bins=7, depth=4,
                file="$MOOT/optimize/misc/auto93.csv")
BIG = 1e32
SEED = SETTINGS["seed"]

# ---- 1. columns ---------------------------------------------
class Num:
    __slots__ = ("n", "mu", "m2")
    def __init__(i, n=0, mu=0.0, m2=0.0):
        i.n, i.mu, i.m2 = n, mu, m2

def sym(): return {}

def sd(i):
    return 0 if i.n < 2 else math.sqrt(max(0, i.m2) / (i.n - 1))

def welford(i, v, w=1):
    i.n += w
    if i.n < 1: return Num()
    d = v - i.mu
    i.mu += w * d / i.n
    i.m2 += w * d * (v - i.mu)
    return i

def norm(i, v):
    z = (v - i.mu) / (sd(i) + 1e-32)
    return 1 / (1 + math.exp(-1.7 * max(-3, min(3, z))))

def mix(i, j, w=1):
    if isinstance(i, Num):
        m = i.n + w * j.n
        d = j.mu - i.mu
        if m < 1: return Num()
        return Num(m, (i.n * i.mu + w * j.n * j.mu) / m,
                   i.m2 + w * j.m2 + w * d * d * i.n * j.n / m)
    out = {}
    for k, v in i.items(): out[k] = out.get(k, 0) + v
    for k, v in j.items(): out[k] = out.get(k, 0) + w * v
    return out

# ---- 2. data -------------------------------------------------
class Data:
    __slots__ = ("names", "x", "y", "goal", "cols", "all", "rows")
    def __init__(i):
        i.x, i.y, i.goal, i.cols, i.all = [], [], {}, {}, []

def add(i, v, w=1):
    if v is None: return i
    if isinstance(i, Num): return welford(i, v, w)
    i[v] = i.get(v, 0) + w
    return i

def adds(lst, it=None):
    it = it if it is not None else Num()
    for v in lst: it = add(it, v)
    return it

def role(i, s, at):
    z = s[-1]
    i.cols[at] = sym() if s[0].islower() else Num()
    i.all.append(i.cols[at])
    if z in "-+!":
        i.goal[at] = 1 if z == "+" else 0
        i.y.append(at)
    elif z != "X":
        i.x.append(at)

def data(src):
    i = Data()
    i.names, i.rows = src[0], src[1:]
    for at, s in enumerate(i.names): role(i, s, at)
    for row in i.rows:
        for c, v in zip(i.all, row): add(c, v)
    return i

# ---- 3. discretization --------------------------------------
def bin_(c, v):
    return math.floor(SETTINGS["bins"] * norm(c, v)) \
        if isinstance(c, Num) else v

def top(c, v, old):
    return max(old if old is not None else -BIG, v) \
        if isinstance(c, Num) else v

def cuts_of(c, bins, hi, at):
    if isinstance(c, Num):
        out, l = [], Num()
        for k in sorted(bins)[:-1]:
            l = mix(l, bins[k])
            out.append((at, -BIG, hi[k], l))
        return out
    return [(at, hi[k], hi[k], bins[k]) for k in bins]

def cuts_at(c, lst, ys, at):
    bins, hi = {}, {}
    for r, y1 in zip(lst, ys):
        v = r[at]
        if v is not None:
            k = bin_(c, v)
            bins[k] = add(bins.get(k) or Num(), y1)
            hi[k] = top(c, v, hi.get(k))
    return cuts_of(c, bins, hi, at)

def cuts(i, lst, y):
    ys = [y(r) for r in lst]
    out = []
    for at in i.x:
        out += cuts_at(i.cols[at], lst, ys, at)
    return out

# ---- 4. grow trees ------------------------------------------
def mink(lst, p=None):
    p = p if p is not None else SETTINGS["p"]
    return (sum(abs(x) ** p for x in lst) / len(lst)) ** (1.0 / p)

def disty(i, row):
    return mink([norm(i.cols[at], row[at]) - i.goal[at]
                 for at in i.y])

def has(v, lo, hi):
    if v is None: return True
    if isinstance(v, str): return v == lo
    return lo <= v <= hi

def branch(nd, right):
    return dict(at=nd["at"], lo=nd["lo"], hi=nd["hi"],
                left=nd["left"], right=right)

def splits(i, y, root):
    enough = len(root.rows) ** 0.33
    cs = [c for c in cuts(i, i.rows, y) if c[3].n > enough]
    if not cs: return []
    out = []
    for bit, pick in (("0", min), ("1", max)):
        at, lo, hi, leaf = pick(cs, key=lambda c: c[3].mu)
        no = [r for r in i.rows if not has(r[at], lo, hi)]
        if no:
            out.append((bit, dict(at=at, lo=lo, hi=hi,
                                  left=leaf), no))
    return out

def grows(i, y, root, d=0):
    out = []
    if d < SETTINGS["depth"]:
        for bit, nd, no in splits(i, y, root):
            kid = data([i.names] + no)
            for bias, r in grows(kid, y, root, d + 1):
                out.append((bit + bias, branch(nd, r)))
    return out or [("", adds([y(r) for r in i.rows]))]

# ---- 5. use trees -------------------------------------------
def predict(tr, row):
    if isinstance(tr, Num): return tr.mu
    return predict(tr["left"] if has(row[tr["at"]], tr["lo"],
                                     tr["hi"])
                   else tr["right"], row)

def err(tr, lst, y):
    return sum(abs(y(r) - predict(tr, r)) for r in lst) / len(lst)

def tune(cands, lst, y):
    return min(cands, key=lambda t: err(t, lst, y))

def rule(i, tr):
    s, lo, hi = i.names[tr["at"]], tr["lo"], tr["hi"]
    if lo == hi:   return f"{s} == {lo}"
    if lo == -BIG: return f"{s} <= {hi}"
    return f"{s} >= {lo}"

def show(i, tr):
    if isinstance(tr, Num):
        print(f"{'':<33} leaf  d2h {tr.mu:.2f} n={tr.n}")
    else:
        l = tr["left"]
        print(f"if {rule(i, tr):<30} then d2h {l.mu:.2f} "
              f"n={l.n}")
        show(i, tr["right"])

# ---- utils (lithp.lisp equivalents) -------------------------
def thing(s):
    s = s.strip()
    if s == "?": return None
    if s == "True": return True
    if s == "False": return False
    try: return int(s)
    except ValueError:
        try: return float(s)
        except ValueError: return s

def path(s):
    if s.startswith("$MOOT"):
        return (os.environ.get("MOOT") or
                os.path.expanduser("~/gits/moot")) + s[5:]
    return s

def csv(file):
    out = []
    with open(path(file)) as f:
        for line in f:
            l = line.strip()
            if l and l[0] != "#":
                out.append([thing(x) for x in l.split(",")])
    return out

def rand(n=1):
    global SEED
    SEED = (16807 * SEED) % 2147483647
    return n * SEED / 2147483647

def rint(n=2): return math.floor(rand(n))

def shuffle(l):
    v = list(l)
    for i in range(len(v) - 1, 0, -1):
        j = rint(i + 1)
        v[i], v[j] = v[j], v[i]
    return v

def few(l, n): return shuffle(l)[:n]

# ---- 6. demos -----------------------------------------------
def eg_main():
    i = data(csv(SETTINGS["file"]))
    y = lambda r: disty(i, r)
    ts = [t for _, t in grows(i, y, i)]
    show(i, tune(ts, i.rows, y))

def eg_trees():
    i = data(csv(SETTINGS["file"]))
    y = lambda r: disty(i, r)
    for k, (bias, tr) in enumerate(grows(i, y, i), 1):
        print(f"===== tree {k:2d}   bias {bias:<5} "
              f"  err {err(tr, i.rows, y):.3f} =====")
        show(i, tr)
        print()

def eg_grows(reps=10, k=100):
    import time
    all_ = csv(SETTINGS["file"])
    m, t0 = 0, time.perf_counter()
    for _ in range(reps):
        i = data([all_[0]] + few(all_[1:], k))
        m = len(grows(i, lambda r: disty(i, r), i))
    s = time.perf_counter() - t0
    print(f"{reps}x (sample {k}, {m} trees): {s:.3f} s "
          f"-> {1000 * s / reps:.1f} ms")

# ---- 7. start -----------------------------------------------
def cli(args):
    it = iter(args)
    for f in it:
        for key in SETTINGS:
            if f == "-" + key[0]:
                SETTINGS[key] = thing(next(it))

if __name__ == "__main__":
    a = sys.argv[1:]
    cli(a)
    SEED = SETTINGS["seed"]
    if "--grows" in a:
        j = a.index("--grows")
        extra = [int(x) for x in a[j + 1:j + 3] if
                 x.lstrip("-").isdigit()]
        eg_grows(*extra)
    elif "--trees" in a:
        eg_trees()
    else:
        eg_main()
```

{% endraw %}