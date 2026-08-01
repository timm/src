#!/usr/bin/env python3 -B
# nfr3.py : nfr3.pl said in python. The model is data and the
# DSL is operator abuse: nodes spring into existence when
# mentioned (__getattr__), bodies conjoin with `&`, or-clauses
# accumulate with `|=` (each clause IS a disjunct, so the
# operators mean what logic says). As in nfr3.pl, hard vs soft
# is read off body shapes: any all-hard body makes a rule
# node (choice-or, commit), else an edge node (label all
# bodies, combine). ISAMP replaces backtracking: a
# contradiction raises, the world restarts fresh (nfr3's greedy
# mode is the only mode).
# A Node is a logic Var with bodies attached (head |= body
# asserts one clause; the head is the Node itself). A Var
# with no bodies is an abducible: assumable, never proved
# (ALP framing: theory + abducibles -> explanations).
# Var.binding is None (unbound) or a number. Head-first, like
# the prolog: a rule binds 2 then walks its body; an edge binds
# a coinductive guess (uniform over the 5 labels) then walks;
# either way a loop-back just reads a bound var -- a consistent
# subset -- and the edge's own combine verifies guess ==
# computed, else the world restarts. unify is prolog unify
# grown one abductive habit: asked to bind with no demand it
# guesses (labeling): abducibles stagger +-2.
# Labels 2 1 0 -1 -2. One looseness vs the prolog: python
# cannot close the world, so a typo is a new leaf, not an
# existence error.
import random

class Fail(Exception): pass

def damp(v): return max(-1, min(1, v))

def shuffled(xs): return random.sample(list(xs), len(xs))

class Lit:                      # `&` conjoins literals into a
  def __and__(i, o): return [i, o]        # clause (a list);
  def __rand__(i, o): return o + [i]      # rand extends one

class Term(Lit):                # no/makes/.../And/Or wrapper
  def __init__(i, op, x): i.op, i.x = op, x

def no(x):     return Term('no', x)
def makes(x):  return Term('makes', x)
def breaks(x): return Term('breaks', x)
def helps(x):  return Term('helps', x)
def hurts(x):  return Term('hurts', x)
def And(*xs):  return Term('amin', xs)
def Or(*xs):   return Term('amax', xs)

def hardlit(l): return isinstance(l, Node) or l.op == 'no'

class Var(Lit):
  "k : name; binding : None | label"
  def __init__(i, k): i.k, i.binding = k, None
  def unify(i, want=None, vals=(2, -2)):
    v = i.binding
    if v is None:                     # unbound: bind the
      i.binding = v = want if want is not None \
                           else random.choice(vals)  # demand,
      return v                        # else guess (labeling)
    if want is None or v == want: return v  # bound: agree
    raise Fail                              # or die

class Node(Var):
  "a Var plus its bodies, split hard/soft as they arrive"
  def __init__(i, k): Var.__init__(i, k); i.hards, i.softs=[],[]

  def abducible(i): return not (i.hards or i.softs)

  def __ior__(i, b):            # head |= body (an or); any
    b = b if isinstance(b, list) else [b]   # all-hard body
    (i.hards if all(hardlit(l) for l in b)  # makes a rule
             else i.softs).append(b)        # node, else edge
    return i

  def combine(i, ws):
    hi, lo = max([0] + ws), min([0] + ws)
    if hi == 2 and lo == -2: raise Fail  # sat meets denied
    return i.unify(hi + lo)     # computed must match my guess

  def __call__(i, want=None):
    if i.binding is not None: return i.unify(want)  # memo
    if i.abducible(): return i.unify(want)    # stagger +-2
    if i.hards:                 # rule: pick one body, walk
      if want == -2: raise Fail # it; falsity is assumed,
      i.binding = 2             # never derived (soft bodies
      for l in shuffled(random.choice(i.hards)):  # dead)
        l(2) if isinstance(l, Node) else l.x.unify(-2)
      return 2
    if want is not None:        # edge: a demand is assumed,
      i.binding = want          # not derived (nfr2 guess
      return want               # parity)
    i.binding = random.choice((2, 1, 0, -1, -2))  # guess,
    es = [e for c in i.softs for e in c]            # head-first
    return i.combine([contrib(e) for e in shuffled(es)])

class Theory:                   # name nodes reserved. `m.x |= b`
  def __init__(i): i.__dict__['nodes'] = {}   # reads m.x (making
  def __getattr__(i, k): return i.nodes.setdefault(k, Node(k))
  def __setattr__(i, k, v): i.nodes[k] = v    # it) then writes
                                              # it back: same Node

# ---- soft side: contributions are plain numbers -----------
def contrib(e):
  if isinstance(e, Node): return e()        # bare = makes
  if e.op == 'no':   return e.x.unify(-2)
  if e.op == 'amin': return min(contrib(x) for x in e.x)
  if e.op == 'amax': return max(contrib(x) for x in e.x)
  v = e.x()
  return {'makes': v,        'breaks': -v,
          'helps': damp(v),  'hurts': -damp(v)}[e.op]

# ---- top: a world = one try, 100 restarts max -------------
def world(m, f):
  for _ in range(100):
    for n in m.nodes.values(): n.binding = None
    try: return f()
    except Fail: pass

def picks(m):
  out = []
  for n in m.nodes.values():
    if n.binding is not None and n.abducible():
      out.append(n.k if n.binding == 2 else
                 ('no', n.k) if n.binding == -2 else
                 ('lab', n.k, n.binding))
  return tuple(sorted(out, key=str))

def abduce(m, g):               # one world proving g, shown
  def run(): g(2); return picks(m)         # as its leaf picks
  return world(m, run)

def soften(m, g):               # one world labelling g
  def run(): return g(), picks(m)
  return world(m, run)

def worlds(n, f):               # sample n, keep distinct
  ws = {w for w in (f() for _ in range(n)) if w}
  return sorted(ws, key=str)

# ---- keys: score worlds, credit settings, find plateau ----
def settle(m, hs, ss, priors=()):  # one world under priors:
  vs = list(m.nodes.values())      # score, and its +-2
  xs = [n for n in vs if n not in ss]        # settings
  for _ in range(100):
    for n in vs: n.binding = None
    for n, v in priors: n.binding = v
    try:
      for h in shuffled(hs): h(2)
    except Fail: continue
    good = 0
    for s in shuffled(ss):
      snap = [(n, n.binding) for n in vs]
      try:
        if s() >= 2: good += 1
      except Fail:
        for n, b in snap: n.binding = b
    used = sum(n.binding is not None for n in xs)
    return (good/len(ss) - used/len(xs),   # max soft, min use
            [(n, n.binding) for n in vs
             if n.abducible() and n.binding in (2, -2)])

def keys(m, hs, ss, runs=100, reps=20, same=None):
  credit = {}                # setting -> scores of its worlds
  for _ in range(runs):
    if r := settle(m, hs, ss):
      for kv in r[1]: credit.setdefault(kv, []).append(r[0])
  mid = lambda a: sorted(a)[len(a)//2]
  rank = sorted(credit, key=lambda kv: -mid(credit[kv]))
  score = lambda pr: sorted(r[0] for _ in range(reps)
                            if (r := settle(m, hs, ss, pr)))
  prev, k = score(()), 0     # assert top-k until no gain
  while k < len(rank):
    cur = score(rank[:k+1])
    if mid(cur) <= mid(prev) or same and same(prev, cur): break
    prev, k = cur, k + 1
  return rank[:k], prev

# ---- eg: the nfr3-eg.pl graphs ----------------------------
m = Theory()
m.happy |= m.rich
m.happy |= m.loved & no(m.lonely)
m.rich  |= m.works & m.lucky
m.loved |= m.friends
m.friends |= m.happy            # loop
m.g |= m.p & m.q
m.p |= m.x
m.q |= no(m.x)                  # x and no(x): no worlds
m.performance |= helps(m.indexing) & hurts(m.logging)
m.security    |= makes(m.encryption) & hurts(m.indexing)
m.usability   |= breaks(m.encryption) & helps(m.gui)
m.good  |= And(m.performance, m.security, m.usability)
m.trust |= helps(m.good) & makes(m.trust)  # self loop
m.hard_goals |= m.happy
m.soft_goals |= Or(m.performance, m.security, m.usability)

if __name__ == '__main__':
  w = lambda n, g: worlds(n, lambda: abduce(m, g))
  print("happy", w(300, m.happy))
  print("g    ", w(100, m.g))
  print("hard ", w(300, m.hard_goals))
  ws = worlds(600, lambda: soften(m, m.good))
  print("good ", len(ws), "worlds, best",
        max(ws, key=lambda x: x[0]))
  print("trust", sorted({s[0] for s in
        (soften(m, m.trust) for _ in range(300)) if s}))
