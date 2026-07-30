#!/usr/bin/env python3 -B
# nfr3.py : nfr3.pl said in python. The model is data and the
# DSL is operator abuse: nodes spring into existence when
# mentioned (__getattr__), bodies conjoin with `&`, or-clauses
# accumulate with `|=` (each clause IS a disjunct, so the
# operators mean what logic says). As in nfr3.pl, hard vs soft
# is read off body shapes: any all-hard body makes a rule node
# (choice-or, commit), else an edge node (label all bodies,
# combine). ISAMP replaces backtracking: a contradiction
# raises, the world restarts fresh (nfr3's greedy mode is the
# only mode). Pending loop values are Boxes guessed at combine
# time; a self-loop closes iff the guess equals the computed
# label. Labels 2 1 0 -1 -2. One looseness vs the prolog:
# python cannot close the world, so a typo is a new leaf, not
# an existence error.
import random

class Fail(Exception): pass
class Box: val = None

def shuffled(xs): return random.sample(list(xs), len(xs))

class Term:                     # no/makes/.../And/Or wrapper
  def __init__(i, op, x): i.op, i.x = op, x
  def __and__(i, o): return [i, o]
  def __rand__(i, o): return o + [i]

def no(x):     return Term('no', x)
def makes(x):  return Term('makes', x)
def breaks(x): return Term('breaks', x)
def helps(x):  return Term('helps', x)
def hurts(x):  return Term('hurts', x)
def And(*xs):  return Term('amin', xs)
def Or(*xs):   return Term('amax', xs)

def hardlit(l): return isinstance(l, Node) or l.op == 'no'

class Node:
  def __init__(i, m, k): i.m, i.k, i.bodies = m, k, []
  def __and__(i, o): return [i, o]
  def __rand__(i, o): return o + [i]
  def __ior__(i, b):            # head |= body (an or)
    i.bodies.append(b if isinstance(b, list) else [b])
    return i
  def __call__(i, want=None):
    m, v = i.m, i.m.b.get(i.k)
    if v is not None: return demand(v, want)
    if not i.bodies: return maybe(m, i.k, want)
    hards = [b for b in i.bodies if all(hardlit(l) for l in b)]
    if hards:                   # rule: pick one body, walk
      if want == -2: raise Fail # it; falsity is assumed,
      m.b[i.k] = 2              # never derived
      for l in shuffled(random.choice(hards)):
        l(2) if isinstance(l, Node) else maybe(m, l.x.k, -2)
      return 2
    if want is not None:        # edge: a demand is assumed,
      m.b[i.k] = want           # not derived (nfr2 guess
      return want               # parity)
    b = Box(); m.b[i.k] = b     # else label all bodies
    es = [e for bd in i.bodies for e in bd]
    return combine(b, [contrib(e) for e in shuffled(es)])

class Model:
  def __init__(i):
    object.__setattr__(i, 'nodes', {})
    object.__setattr__(i, 'b', {})
  def __getattr__(i, k): return i.nodes.setdefault(k, Node(i, k))
  def __setattr__(i, k, v):
    if isinstance(v, Node): i.nodes[k] = v
    else: object.__setattr__(i, k, v)

# ---- beliefs ----------------------------------------------
def demand(v, want):            # agree with what is known,
  if want is None: return v     # else fill it, else die
  if isinstance(v, Box):
    if v.val is None: v.val = want; return want
    if v.val == want: return want
    raise Fail
  if v == want: return v
  raise Fail

def maybe(m, k, want):          # recall, else assume: leaves
  if k in m.b: return demand(m.b[k], want)  # get the random
  v = want if want is not None \
           else random.choice((2, -2))      # +-2 stagger
  m.b[k] = v
  return v

# ---- soft side: contributions as symbolic value trees -----
def contrib(e):
  if isinstance(e, Node): return e()        # bare = makes
  if e.op == 'no': return maybe(e.x.m, e.x.k, -2)
  if e.op in ('amin', 'amax'):
    return (e.op, tuple(contrib(x) for x in e.x))
  v = e.x()
  return {'makes':  v,
          'breaks': ('neg', v),
          'helps':  ('damp', v),
          'hurts':  ('neg', ('damp', v))}[e.op]

def pends(e, out):
  if isinstance(e, Box) and e.val is None: out[id(e)] = e
  elif isinstance(e, tuple):
    for x in e:
      if not isinstance(x, str): pends(x, out)

def evalx(e):
  if isinstance(e, Box): return e.val
  if not isinstance(e, tuple): return e
  op, a = e
  if op == 'neg':  return -evalx(a)
  if op == 'damp': return max(-1, min(1, evalx(a)))
  ws = [evalx(x) for x in a]
  return min(ws) if op == 'amin' else max(ws)

def combine(b, vs):
  ps = {}
  for v in vs: pends(v, ps)
  for p in ps.values():         # big cyclic cluster: punt
    p.val = 0 if len(ps) > 3 \
              else random.choice((2, 1, 0, -1, -2))
  ws = [evalx(v) for v in vs]
  hi, lo = max([0] + ws), min([0] + ws)
  if hi == 2 and lo == -2: raise Fail  # sat meets denied
  return demand(b, hi + lo)     # closes self-loops: the
                                # guess must equal it
# ---- top: a world = one try, 100 restarts max -------------
def world(m, f):
  for _ in range(100):
    m.b = {}
    try: return f()
    except Fail: pass

def picks(m):
  out = []
  for k, v in m.b.items():
    if not m.nodes[k].bodies:
      v = v.val if isinstance(v, Box) else v
      out.append(k if v == 2 else
                 ('no', k) if v == -2 else
                 ('lab', k, v))
  return tuple(sorted(out, key=str))

def abduce(m, g): return world(m, lambda: (g(2), picks(m))[1])
def soften(m, g): return world(m, lambda: (unbox(g()), picks(m)))
def unbox(v):     return v.val if isinstance(v, Box) else v

def worlds(n, f):               # sample n, keep distinct
  ws = {w for w in (f() for _ in range(n)) if w}
  return sorted(ws, key=str)

# ---- eg: the nfr3-eg.pl graphs ----------------------------
m = Model()
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
