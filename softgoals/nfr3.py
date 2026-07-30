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
# only mode). Loops: m.path holds the nodes now being computed;
# hitting one again means a cycle, so guess its label on the
# spot (uniform over the 5 values) and let that node's own
# combine verify guess == computed, else the world restarts.
# Guessing early kills nfr3.pl's symbolic pending terms: every
# value here is a plain number. (Divergence: nfr3.pl punts
# cyclic clusters >3 to undecided; this explores them.)
# Labels 2 1 0 -1 -2. One looseness vs the prolog:
# python cannot close the world, so a typo is a new leaf, not
# an existence error.
import random

class Fail(Exception): pass

def damp(v): return max(-1, min(1, v))

def shuffled(xs): return random.sample(list(xs), len(xs))

class Lit:                      # `&` conjoins literals into a
  def __and__(i, o): return [i, o]        # body (a list); rand
  def __rand__(i, o): return o + [i]      # extends one going

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

class Node(Lit):
  "m : pointer to model owning node; k : name"
  def __init__(i, m, k): i.m, i.k, i.bodies = m, k, []
  def __ior__(i, b):            # head |= body (an or)
    i.bodies.append(b if isinstance(b, list) else [b])
    return i
  def __call__(i, want=None):
    m, v = i.m, i.m.b.get(i.k)
    if v is not None: return demand(v, want)
    if i.k in m.path:           # loop: guess; my combine
      return maybe(m, i.k, want, (2, 1, 0, -1, -2))  # verifies
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
    m.path.add(i.k)             # else label all bodies
    es = [e for bd in i.bodies for e in bd]
    ws = [contrib(e) for e in shuffled(es)]
    m.path.discard(i.k)
    return combine(m, i.k, ws)

class Model:                    # names nodes/b/path reserved
  def __init__(i): i.nodes, i.b, i.path = {}, {}, set()
  def __getattr__(i, k): return i.nodes.setdefault(k, Node(i, k))

# ---- beliefs ----------------------------------------------
def demand(v, want):            # agree with what is known,
  if want is None or v == want: return v      # else die
  raise Fail

def maybe(m, k, want, vals=(2, -2)):   # recall, else assume:
  if k in m.b: return demand(m.b[k], want)  # leaves stagger
  m.b[k] = v = want if want is not None \
                    else random.choice(vals)   # +-2, loops
  return v                                     # guess 5-wide

# ---- soft side: contributions are plain numbers -----------
def contrib(e):
  if isinstance(e, Node): return e()        # bare = makes
  if e.op == 'no':   return maybe(e.x.m, e.x.k, -2)
  if e.op == 'amin': return min(contrib(x) for x in e.x)
  if e.op == 'amax': return max(contrib(x) for x in e.x)
  v = e.x()
  return {'makes': v,        'breaks': -v,
          'helps': damp(v),  'hurts': -damp(v)}[e.op]

def combine(m, k, ws):
  hi, lo = max([0] + ws), min([0] + ws)
  if hi == 2 and lo == -2: raise Fail  # sat meets denied
  v, w = hi + lo, m.b.get(k)  # loop closed iff any earlier
  if w is None: m.b[k] = v; return v   # guess equals the
  return demand(w, v)         # computed label

# ---- top: a world = one try, 100 restarts max -------------
def world(m, f):
  for _ in range(100):
    m.b, m.path = {}, set()
    try: return f()
    except Fail: pass

def picks(m):
  out = []
  for k, v in m.b.items():
    if not m.nodes[k].bodies:
      out.append(k if v == 2 else
                 ('no', k) if v == -2 else
                 ('lab', k, v))
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
