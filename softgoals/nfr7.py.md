# nfr7.py

{% raw %}
```text
nfr7.py : the truth walk; python twin of nfr7.lisp.
isamp(g,w) = "is g achieved in this world?" -- a denied child
fails its parent. One walk, play == replay; replay is play with
labels preloaded. No gates, no sugar: a hard goal or a believed
claim is just a goal that must come out t; softs are walked,
never judged. Same models, flags and report as run.py:
Usage: python3 nfr7.py [OPTIONS] models/small.py
```

```python
"""nfr7.py : the truth walk; python twin of nfr7.lisp.
isamp(g,w) = "is g achieved in this world?" -- a denied child
fails its parent. One walk, play == replay; replay is play with
labels preloaded. No gates, no sugar: a hard goal or a believed
claim is just a goal that must come out t; softs are walked,
never judged. Same models, flags and report as run.py:
Usage: python3 nfr7.py [OPTIONS] models/small.py
"""
import sys; sys.dont_write_bytecode = True
import math, random, time
from itertools import islice
from run import (load, statics, norm, musd, lomu, ddmin, the, cli,
                 shortname)
from syntax import RULES, Atom, alts, of
from infer import syms, shuffled

def add(x, v, w, trail):
  w[x] = v; trail.append(x); return True

def undo(mark, w, trail):
  "roll back to mark; reports False: undoing is never success"
  while len(trail) > mark: del w[trail.pop()]
  return False

def believe(x, v, w, trail):
  return w[x] == v if x in w else add(x, v, w, trail)

def eager(gs, w):
  "knowns to the front (free checks); dice only for the rest"
  yes, no = [], []
  for g in gs:
    (yes if all(a in w for a in syms(g)) else no).append(g)
  return yes + shuffled(no)

def many(gs, patience, w, trail):
  # PATIENCE failures tolerated (each rolled back alone), one more
  # undoes the lot; win early once no losing streak can sink us
  mark = len(trail)
  for i, g in enumerate(gs):
    if len(gs) - i <= patience: return True
    t = len(trail)
    if not isamp(g, w, trail):
      undo(t, w, trail)
      patience -= 1
      if patience < 0: return undo(mark, w, trail)
  return patience >= 0

def derive(g, w, trail):
  "argue one body under g=t; win keeps g=t, loss denies: g=f"
  mark = len(trail)
  add(g, 't', w, trail)
  if isamp(random.choice(RULES[g]), w, trail): return True
  undo(mark, w, trail); add(g, 'f', w, trail); return False

def isamp(g, w, trail):
  "t = g achieved; denial is a label read right here, not later"
  if of(g, Atom):
    if g in w:     return w[g] == 't'          # memo: report the label
    if g in RULES: return derive(g, w, trail)
    return add(g, 't', w, trail)               # fiat: abduce to t
  if of(g, tuple):
    tag = g[0]
    if tag == '=':    return believe(g[1], g[2], w, trail)
    if tag == 'link':                          # evidence stands
      return True if g[2] in w else \
             add(g[2], random.choice(g[1]), w, trail)
    gs = list(g[1:])
    if tag == 'and': return many(eager(gs, w), 0, w, trail)
    if tag == 'or':  return many(eager(gs, w), len(gs)-1, w, trail)
  if of(g, list): return all(isamp(x, w, trail) for x in g)  # seq
  return False

def sample(query, beliefs=(), softs=(), patience=1000):
  "worlds where QUERY holds; SOFTS are walked, never judged"
  pre, claims = {}, []
  for x, v in dict(beliefs).items():
    if v == 't' and x in RULES: claims.append(x)  # RE-EARN: a claim
    else:                       pre[x] = v        # is a goal; ADOPT
  claims.reverse()       # children re-earn before parents: their
  goals = claims + list(query)   # labels steer the parents' ors
  miss = 0
  while miss < patience:
    w, trail = dict(pre), []
    if all(isamp(g, w, trail) for g in goals):
      for s in softs: isamp(s, w, trail)
      miss = 0; yield w
    else: miss += 1

class Rig7:
  "one model's pipeline: generate, reduce, assess."
  def __init__(s, hard, soft):
    s.hard, s.soft = hard, soft
    s.mention, s.quals, s.leaves, s.settable = statics(hard, soft)
    s.q     = list(hard)
    s.tests = 0
    s.mm    = (0, 0, 0, 0)
    s.dbest = 0.0

  def gen(s, n, seed=()):
    return list(islice(sample(s.q, dict(seed), softs=alts(s.soft)), n))

  def bf(s, w):
    return (sum(1 for q in s.quals  if w.get(q) == 't'),
            sum(1 for l in s.leaves if w.get(l) == 't'))

  def d2h(s, w):
    b, f = s.bf(w)
    nb, nf = norm(s.mm[0], s.mm[1], b), norm(s.mm[2], s.mm[3], f)
    return math.sqrt(((1-nb)**2 + nf**2)/2)

  def yardstick(s, ws):
    Bs, Fs = zip(*[s.bf(w) for w in ws])
    s.mm = (min(Bs), max(Bs), min(Fs), max(Fs))

  def candidates(s, wbest, ws):
    # pool = settable labels of the best world -- but a denial of
    # a defined atom is a conclusion, not a choice: skip it
    pool   = [(x, v) for x, v in wbest.items() if x in s.settable
              and not (v == 'f' and x in RULES)]
    shared = [(x, v) for x, v in pool
              if all(w.get(x) == v for w in ws)]
    return pool, shared, [p for p in pool if p not in shared]

  def replays(s, seed):
    return [s.d2h(w) for w in s.gen(the.n2, seed)]

  def passes(s, seed):
    s.tests += 1; ds = s.replays(seed)
    return bool(ds) and musd(ds)[0] <= s.dbest + the.eps

def rig(name, hard, soft):
  t0 = time.time()
  random.seed(the.seed)
  r  = Rig7(hard, soft)
  ws = r.gen(the.n1)
  r.yardstick(ws)
  ds = [r.d2h(w) for w in ws]
  r.dbest, wbest = min(zip(ds, ws), key=lambda p: p[0])
  pool, shared, cands = r.candidates(wbest, ws)
  rb = r.replays(cands)   # rebaseline: ddmin's target is what the
  if cands and rb:        # FULL candidate set scores under replay
    r.dbest = musd(rb)[0]
  seed = ddmin(r.passes, cands, the.z0) if cands else []
  print(f"{name},{lomu(ds)},{lomu(rb)},{lomu(r.replays(seed))},"
        f"{len(pool)},{len(shared)},{len(seed)},"
        f"{r.tests},{100*len(seed)/len(r.mention):.0f},"
        f"{1000*(time.time()-t0):.0f}")

if __name__ == '__main__':
  cli(the.__dict__)
  if len(sys.argv) < 2 or not sys.argv[-1].endswith('.py') \
     or sys.argv[-1].endswith('nfr7.py'):
    sys.exit(__doc__)
  hard, soft = load(sys.argv[-1])
  rig(shortname(sys.argv[-1]), hard, soft)
```

{% endraw %}