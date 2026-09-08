#!/usr/bin/env python3 -B
"""
y3.py: y2 with fewer parts (ydist trees, bayes, derived sd)
(c) 2026 Tim Menzies <timm@ieee.org> MIT license

Options:

  -P=2       minkowski coefficient
  -Start=4   acquire: initial random labels
  -Stop=50   acquire: total labelling budget
  -Few=128   max train rows
  -Leaf=4    tree: min rows in any leaf
  -Check=5   holdout: top picks to label
  -k=1       bayes: rare klass hack
  -m=2       bayes: rare evidence hack
  -Seed=1234567891  random number seed
  -File=$MOOT/optimize/misc/auto93.csv"""
# pylint: disable=bad-indentation,invalid-name
# pylint: disable=missing-function-docstring
# pylint: disable=multiple-statements,multiple-imports
# pylint: disable=unnecessary-lambda-assignment
# pylint: disable=inconsistent-return-statements
# pylint: disable=dangerous-default-value
# pylint: disable=broad-exception-caught

import os, random, re, sys, traceback
from math import exp, log, log2, pi, sqrt
from types import SimpleNamespace as o

def atom(s, bools={"True": True, "False": False}):
    try:
        return int(s)
    except ValueError:
        try:
            return float(s)
        except ValueError:
            s = s.strip()
            return bools.get(s, s)

pat = r"(\w+)=(\S+)"
the = o(**{k: atom(v) for k, v in re.findall(pat, __doc__ or "")})

def csv(file):
    file = file.replace(
        "$MOOT", os.environ.get("MOOT") or os.path.expanduser("~/gits/moot"), 1
    )
    with open(file, encoding="utf-8") as f:
        return [
            tuple(atom(x) for x in line.split(","))
            for line in f
            if line.strip()
        ]

# -- structs -----------------------------------------------
Num = lambda: (0, 0, 0)  # n, mu, m2: all Welford keeps
Sym = dict

def is_num(col):
    return isinstance(col, tuple)

def sd(col):
    return 0 if col[0] < 2 else sqrt(col[2] / (col[0] - 1))

def add(col, v, inc=1):  # new Num, or updated Sym; inc=-1 undoes
    if v == "?":
        return col
    if not is_num(col):
        col[v] = col.get(v, 0) + inc
        return col
    n, mu, m2 = col
    n += inc
    d = v - mu
    mu += inc * d / max(1, n)
    return (n, mu, max(0, m2 + inc * d * (v - mu)))

def adds(lst, it=None):  # accumulate a list into it
    if it is None:
        it = Num()  # NB: "it or Num()" would
    for y in lst:
        it = add(it, y)  # clobber an empty Sym()
    return it

def size(col):
    return col[0] if is_num(col) else sum(col.values())

def div(col):  # Num: sd. Sym: entropy
    if is_num(col):
        return sd(col)
    n = sum(col.values())
    return -sum(v / n * log2(v / n) for v in col.values() if v > 0)

def Tbl(src):
    tbl = o(rows=[], cols={}, x=[], y={}, names=src[0], klass=None)
    for at, s in enumerate(tbl.names):
        if not s.endswith("X"):
            tbl.cols[at] = Num() if s[0].isupper() else Sym()
            if s[-1] == "!":
                tbl.klass = at
            elif s[-1] in "+-":
                tbl.y[at] = s[-1] == "+"
            else:
                tbl.x.append(at)
    for row in src[1:]:
        addRow(tbl, row)
    return tbl

def clone(tbl, rows=[]):
    return Tbl([tbl.names] + rows)

def addRow(tbl, row=None, inc=1):  # inc=-1 pops the last row
    if inc > 0:
        tbl.rows.append(row)
    else:
        row = tbl.rows.pop()
    for at in tbl.cols:
        tbl.cols[at] = add(tbl.cols[at], row[at], inc)
    return row

# -- distance ----------------------------------------------
def norm(col, v):
    z = max(-3, min(3, (v - col[1]) / (1e-32 + sd(col))))
    return 1 / (1 + exp(-1.7 * z))

def mid(col):
    return col[1] if is_num(col) else max(col, key=col.get)

def mids(tbl):  # centroid; only ever read over x columns
    return {at: mid(tbl.cols[at]) for at in tbl.x}

def ydist(tbl, row):
    return (
        sum(
            abs(norm(tbl.cols[at], row[at]) - w) ** the.P
            for at, w in tbl.y.items()
        )
        / len(tbl.y)
    ) ** (1 / the.P)

def _dist(col, a, b):
    if a == "?" or b == "?":
        return 1
    return abs(norm(col, a) - norm(col, b)) if is_num(col) else a != b

def xdist(tbl, row, m):
    return (
        sum(_dist(tbl.cols[at], row[at], m[at]) ** the.P for at in tbl.x)
        / len(tbl.x)
    ) ** (1 / the.P)

def ymu(tbl, rows):
    return sum(ydist(tbl, r) for r in rows) / len(rows)

def ymids(tbl, rows):
    return [sum(r[at] for r in rows) / len(rows) for at in tbl.y]

# -- acquire -----------------------------------------------
def pop(tbl, best, rest, todo):
    b, r = mids(best), mids(rest)
    todo.sort(key=lambda z: xdist(tbl, z, r) - xdist(tbl, z, b))
    return todo.pop()

def label(tbl, best, rest, row):  # keep best pool near sqrt
    addRow(best, row)
    best.rows.sort(key=lambda r: ydist(tbl, r))
    b, r = len(best.rows), len(rest.rows)
    if b > sqrt(1 + b + r):
        addRow(rest, addRow(best, inc=-1))

def acquire(tbl, cap=None):
    best, rest = clone(tbl), clone(tbl)
    todo = random.sample(tbl.rows, len(tbl.rows))[: the.Few]
    for _ in range(the.Start):
        label(tbl, best, rest, todo.pop())
    cap = cap or the.Stop
    while todo and len(best.rows) + len(rest.rows) < cap:
        label(tbl, best, rest, pop(tbl, best, rest, todo))
    return best.rows + rest.rows

# -- bayes -------------------------------------------------
def like(col, v, prior=0):  # P(v | col)
    if not is_num(col):
        return (col.get(v, 0) + the.m * prior) / (size(col) + the.m + 1e-32)
    s = sd(col) + 1e-32
    return exp(-((v - col[1]) ** 2) / (2 * s * s)) / sqrt(2 * pi * s * s)

def likes(tbl, row, nall, nh):  # log P(tbl | row), unscaled
    prior = (len(tbl.rows) + the.k) / (nall + the.k * nh)
    return log(prior) + sum(
        log(1e-32 + like(tbl.cols[at], v, prior))
        for at in tbl.x
        if (v := row[at]) != "?"
    )

def liked(tbls, row):  # most likely of several tables
    n = sum(len(t.rows) for t in tbls.values())
    return max(tbls, key=lambda k: likes(tbls[k], row, n, len(tbls)))

def confuse(pairs):  # (got, want)s --> per-klass scores
    out = {
        x: o(l=x, tp=0, fp=0, fn=0, tn=0)
        for x in {x for p in pairs for x in p}
    }
    for got, want in pairs:
        if got == want:
            out[want].tp += 1
        else:
            out[want].fn += 1
            out[got].fp += 1
    for c in out.values():
        c.tn = len(pairs) - c.tp - c.fn - c.fp
        c.acc = (c.tp + c.tn) / len(pairs)
        c.pd = c.tp / (c.tp + c.fn + 1e-32)
        c.pf = c.fp / (c.fp + c.tn + 1e-32)
        c.prec = c.tp / (c.tp + c.fp + 1e-32)
    return out

# -- tree --------------------------------------------------
# Node = [edge, n, ymu, ymids, go, kid, kid]
def xpect(a, b):  # sizes are >= the.Leaf, so no zero guard
    return (div(a) * size(a) + div(b) * size(b)) / (size(a) + size(b))

def cutNum(xy, acc):  # (left, right, x) per value boundary
    xy.sort()
    here, there = acc(), adds((y for _, y in xy), acc())
    for i, (x, y) in enumerate(xy[:-1]):
        here, there = add(here, y), add(there, y, -1)
        if x != xy[i + 1][0]:
            yield here, there, x

def cutSym(xy, acc):  # (in, out, sym), one per symbol
    for v in sorted({x for x, _ in xy}):
        yield (
            adds((y for x, y in xy if x == v), acc()),
            adds((y for x, y in xy if x != v), acc()),
            v,
        )

def cut(tbl, rows, ys, acc):  # best (col, val) split
    best = (1e30, None, None)
    for at in tbl.x:
        xy = [(x, y) for r, y in zip(rows, ys) if (x := r[at]) != "?"]
        what = cutNum if is_num(tbl.cols[at]) else cutSym
        for here, there, v in what(xy, acc):
            if the.Leaf <= size(here) <= len(xy) - the.Leaf:
                if (s := xpect(here, there)) < best[0]:
                    best = (s, at, v)
    if best[1] is not None:
        return best[1:]

def routing(tbl, at, v):
    s, c = tbl.names[at], tbl.cols[at]
    if is_num(c):
        return (
            f"{s} <= {round(v, 2)}",
            f"{s} > {round(v, 2)}",
            lambda r: (c[1] if r[at] == "?" else r[at]) <= v,
        )
    return (f"{s} = {v}", f"{s} != {v}", lambda r: r[at] == v)

def tree(tbl, rows, edge="", y=None):
    y = y or (lambda r: ydist(tbl, r))
    ys = [y(r) for r in rows]
    acc = Sym if isinstance(ys[0], str) else Num
    node = [edge, len(rows), mid(adds(ys, acc())), ymids(tbl, rows)]
    if len(rows) > the.Leaf and (best := cut(tbl, rows, ys, acc)):
        e1, e2, go = routing(tbl, *best)
        yes, no = [], []
        for r in rows:
            (yes if go(r) else no).append(r)
        if yes and no:
            node += [go, tree(tbl, yes, e1, y), tree(tbl, no, e2, y)]
    return node

def kids(n):
    return n[5:]

def leaf(tr, row):
    while kids(tr):
        tr = tr[5] if tr[4](row) else tr[6]
    return tr

# -- report ------------------------------------------------
def leafs(tr):
    return [x for k in kids(tr) for x in leafs(k)] or [tr]

def show(tbl, tr):
    ls = sorted(leafs(tr), key=lambda z: z[2])
    print("  d2h   n" + "".join(f"{tbl.names[at]:>7}" for at in tbl.y))

    def walk(z, pre=None):
        m = "+" if z is ls[0] else "-" if z is ls[-1] else " "
        print(
            (
                f"{m} {round(100 * z[2]):>3} {z[1]:>3}"
                + "".join(f"{round(v):>7}" for v in z[3])
                + "   "
                + (pre or "")
                + z[0]
            ).rstrip()
        )
        for k in kids(z):
            walk(k, "" if pre is None else pre + "|  ")

    walk(tr)

# -- tests -------------------------------------------------
def wins(tbl):
    ys = sorted(ydist(tbl, r) for r in tbl.rows)
    lo, b4 = ys[0], sum(ys) / len(ys)
    return lambda r: max(
        -100, min(100, 100 * (1 - (ydist(tbl, r) - lo) / (b4 - lo + 1e-32)))
    )

def holdout(tbl):
    rows = random.sample(tbl.rows, len(tbl.rows))
    n = len(rows) // 2
    train, test = rows[:n][: the.Few], rows[n:]
    tr = clone(tbl, train)
    tt = tree(tr, acquire(tr, the.Stop - the.Check))
    top = sorted(test, key=lambda r: leaf(tt, r)[2])[: the.Check]
    return min(top, key=lambda r: ydist(tr, r))

# -- start-up ----------------------------------------------
def test_help():
    "Show usage, settings, demos"
    print(
        "usage: python3 y3.py [-Key val ..] [--demo ..]",
        "\nsettings:",
        *[f"  -{k:<6} {v}" for k, v in sorted(vars(the).items())],
        "\ndemos:",
        *[
            f"  --{k[5:]:<10} {f.__doc__}"
            for k, f in globals().items()
            if k[:5] == "test_"
        ],
        sep="\n",
    )

def test_num():
    "Welford add matches textbook mean and sd"
    c = adds([2, 4, 4, 4, 5, 5, 7, 9])
    assert c[0] == 8 and c[1] == 5 and abs(sd(c) - 2.138) < 0.01
    print(f"mu {c[1]} sd {round(sd(c), 3)}")

def test_sym():
    "Syms count; mid is mode; div is entropy"
    c = adds("aabbbc", Sym())
    assert c["b"] == 3 and mid(c) == "b" and abs(div(c) - 1.459) < 0.01
    print(f"mode {mid(c)} ent {round(div(c), 3)}")

def test_tbl():
    "Headers route columns to x, y, klass, or nowhere"
    t = Tbl([("Age", "job!", "SkipX", "Weight-"), (2, "a", 3, 80)])
    assert t.x == [0] and t.y == {3: False} and t.klass == 1
    assert 2 not in t.cols
    print(f"x {t.x} y {t.y} klass {t.klass}")

def test_cuts():
    "cut returns a legal, routable split"
    t = Tbl(csv(the.File))
    rows = t.rows[:64]
    ys = [ydist(t, r) for r in rows]
    at, v = cut(t, rows, ys, Num)
    e1, e2, go = routing(t, at, v)
    yes = sum(go(r) for r in rows)
    assert 0 < yes < len(rows)
    print(f"cut: {e1} yes={yes}; {e2} no={len(rows) - yes}")

def test_wins():
    "wins grades the best row 100"
    t = Tbl(csv(the.File))
    w = wins(t)(min(t.rows, key=lambda r: ydist(t, r)))
    assert w == 100
    print(f"best row wins {w}")

def test_tree():
    "Acquire, grow and show the.File's tree"
    tbl = Tbl(csv(the.File))
    lab = acquire(tbl)
    print(
        f"{the.File} n={len(tbl.rows)}"
        f" mid={round(ymu(tbl, tbl.rows), 3)}"
        f" ezr={round(ydist(tbl, lab[0]), 3)}"
    )
    show(tbl, tree(tbl, lab))

def test_holdout():
    "Mean win over 20 train/test holdouts"
    tbl = Tbl(csv(the.File))
    win = wins(tbl)
    mu = sum(win(holdout(tbl)) for _ in range(20)) / 20
    print(f"win {round(mu)}")

def _klass(fit, file="$MOOT/classify/diabetes.csv"):
    tbl = Tbl(csv(file))  # fit(tbl, rows, y) --> predictor(row)
    y = lambda r: r[tbl.klass]
    pairs = []
    for _ in range(20):  # 50:50 train:test, pool all pairs
        rows = random.sample(tbl.rows, len(tbl.rows))
        n = len(rows) // 2
        got = fit(tbl, rows[:n], y)
        pairs += [(got(r), y(r)) for r in rows[n:]]
    for c in confuse(pairs).values():
        print(
            f"{c.l:>15} acc {c.acc:.2f} pd {c.pd:.2f}"
            f" pf {c.pf:.2f} prec {c.prec:.2f}"
        )

def test_klassTree():
    "Tree classify diabetes: pd, pf, prec per class"

    def fit(tbl, rows, y):
        b4, the.Leaf = the.Leaf, int(sqrt(len(rows)))
        tt = tree(clone(tbl, rows), rows, y=y)
        the.Leaf = b4
        return lambda r: leaf(tt, r)[2]

    _klass(fit)

def test_klassBayes():
    "Bayes classify diabetes: pd, pf, prec per class"

    def fit(tbl, rows, y):
        tbls = {}
        for r in rows:
            if y(r) not in tbls:
                tbls[y(r)] = clone(tbl)
            addRow(tbls[y(r)], r)
        return lambda r: liked(tbls, r)

    _klass(fit)

def run(f=None):
    try:
        random.seed(the.Seed)
        (f or test_help)()
    except Exception:
        traceback.print_exc()
        return 1
    return 0

def cli(d, funs, args, n=0):
    while args:
        s = args.pop(0)
        if s[:2] == "--":
            n += run(funs.get("test_" + s[2:]))
        elif s[1:] in d:
            d[s[1:]] = atom(args.pop(0))
        else:
            print(f"unknown arg: {s}")
    sys.exit(n)

if __name__ == "__main__":
    cli(vars(the), globals(), sys.argv[1:] or ["--help"])
