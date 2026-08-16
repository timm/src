# nfr5.py : world sampler for goal models; port of nfr5.pl.
# Bodies are algebra: * is and (shuffled conjunction), + is
# or (commit to one alternative). h <= body records a clause.
from typing import Iterator
from random import choice, sample as resample
of = isinstance

def shuffled(l: list) -> list:   # shuffled COPY, l untouched
  return resample(l, len(l))

Val = str                       # 't' | 'f'
# A rule is head <= body; the head is the KEY, so the table
# stores each head's alternative bodies (a rule type
# tuple[Atom,Body] would duplicate the head in its entry).
RULES: "Rules" = {}

class Term:                     # the __add__/__radd__ trick:
  def __add__(i,o):  return Or(alts(i)+alts(o))   # b+c -> Or
  def __radd__(i,o): return Or(alts(o)+alts(i))
  def __mul__(i,o):  return And(parts(i)+parts(o))# b*c -> And
  def __rmul__(i,o): return And(parts(o)+parts(i))

class Or(Term):
  def __init__(i, xs: list["Body"]): i.xs = xs
class And(Term):
  def __init__(i, xs: list["Body"]): i.xs = xs
class Link(Term):
  def __init__(i, bag: str, x: "Atom"): i.bag, i.x = bag, x
class Atom(Term):
  def __init__(i, name: str): i.name = name
  def __repr__(i) -> str:     return i.name
  def __le__(i, body: "Body") -> bool:
    RULES.setdefault(i,[]).append(body); return True

Body   = Term | list            # a goal, or a query list
Rules  = dict[Atom, list[Body]] # head -> alternative bodies
World  = dict[Atom, Val]        # beliefs in, labels out
Demand = tuple[Atom, Val]       # (x,'t'): chk or add

def alts(x: Body) -> list[Body]:
  return x.xs if of(x,Or) else [x]
def parts(x: Body) -> list[Body]:
  return x.xs if of(x,And) else [x]
def atoms(names: str) -> list[Atom]:
  return [Atom(n) for n in names.split()]

def makes(x: Atom)    -> Link: return Link('t',  x)
def breaks(x: Atom)   -> Link: return Link('f',  x)
def helps(x: Atom)    -> Link: return Link('ttf',x)
def hurts(x: Atom)    -> Link: return Link('fft',x)

def syms(g: Body | Demand) -> list[Atom]:
  if of(g,Atom):     return [g]
  if of(g,Link):     return [g.x]
  if of(g,(Or,And)): return [a for x in g.xs for a in syms(x)]
  if of(g,tuple):    return [g[0]]
  if of(g,list):     return [a for x in g for a in syms(x)]
  return []

def believed(w: World, g: Body) -> bool:
  return all(a in w for a in syms(g))

def believe(w: World, x: Atom, v: Val) -> bool:
  "add x=v if x is fresh; else check it; refuse contradiction."
  return w[x]==v if x in w else not w.update({x:v})

def derive(g: Atom, w: World, replay: bool) -> bool:
  "try one body under g=t; on failure deny: g=f, no death."
  w2 = dict(w); w[g]='t'          # snapshot, attempt in place
  if isamp(choice(RULES[g]), w, replay): return True
  w.clear(); w.update(w2)         # undo the failed attempt
  w[g]='f'
  return True

def isamp(g: Body | Demand, w: World,
          replay: bool=False) -> bool:
  if replay and not of(g,(tuple,list)) and believed(w,g):
    return True                # replay: settled goal
  match g: # order matters twice: list before (x,v), memo before derive, fiat last
    case list():               return all(isamp(x,w,replay) for x in g)
    case (x, v):               return believe(w,x,v)  # demand
    case Atom() if g in w:     return True            # memo
    case Atom() if g in RULES: return derive(g,w,replay)
    case Atom():               w[g]='t'; return True  # fiat
    case Link(bag=b, x=x):     return believe(w,x,choice(b))
    case And(xs=xs):           return all(isamp(x,w,replay) for x in shuffled(xs))
    case Or(xs=xs):            # settled branch = done, else dice
      if replay and any(believed(w,x) for x in xs): return True
      return isamp(choice(xs), w, replay)
  return False

def sample(query: list, beliefs=(), replay: bool=False,
           patience: int=1000) -> Iterator[World]:
  "yield worlds, skipping dead tries; stop after patience misses"
  miss = 0
  while miss < patience:
    w = dict(beliefs)
    if isamp(query, w, replay): miss = 0; yield w
    else:                       miss += 1
