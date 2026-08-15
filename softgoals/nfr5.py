# nfr5.py : world sampler for goal models; port of nfr5.pl.
# Bodies are algebra: * is and (shuffled conjunction), + is
# or (commit to one alternative). h <= body records a clause.
import random
of = isinstance

Val = str                       # 't' | 'f'
# A rule is head <= body; the head is the KEY, so the table
# stores each head's alternative bodies (a rule type
# tuple[Atom,Body] would duplicate the head in its entry).
RULES: "Rules" = {}
BAG: dict[str, str] = dict(
  makes='t', breaks='f', helps='ttf', hurts='fft')

class Term:                     # the __add__/__radd__ trick:
  def __add__(s,o):  return Or(alts(s)+alts(o))   # b+c -> Or
  def __radd__(s,o): return Or(alts(o)+alts(s))
  def __mul__(s,o):  return And(parts(s)+parts(o))# b*c -> And
  def __rmul__(s,o): return And(parts(o)+parts(s))

class Or(Term):
  def __init__(s, xs: list["Body"]): s.xs = xs
class And(Term):
  def __init__(s, xs: list["Body"]): s.xs = xs
class Link(Term):
  def __init__(s, bag: str, x: "Atom"): s.bag, s.x = bag, x
class Atom(Term):
  def __init__(s, name: str): s.name = name
  def __repr__(s) -> str:     return s.name
  def __le__(s, body: "Body") -> bool:
    RULES.setdefault(s,[]).append(body); return True

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
def makes(x: Atom)  -> Link: return Link('makes',x)
def breaks(x: Atom) -> Link: return Link('breaks',x)
def helps(x: Atom)  -> Link: return Link('helps',x)
def hurts(x: Atom)  -> Link: return Link('hurts',x)

def syms(g: Body | Demand) -> list[Atom]:
  if of(g,Atom):     return [g]
  if of(g,Link):     return [g.x]
  if of(g,(Or,And)): return [a for x in g.xs for a in syms(x)]
  if of(g,tuple):    return [g[0]]
  if of(g,list):     return [a for x in g for a in syms(x)]
  return []

def believed(w: World, g: Body) -> bool:
  return all(a in w for a in syms(g))

def label(w: World, x: Atom, v: Val) -> bool:
  "chk a believed atom, or add a fresh label."
  return w[x]==v if x in w else not w.update({x:v})

def derive(g: Atom, w: World, rp: bool) -> bool:
  "try one body under g=t; on failure deny: g=f, no death."
  w2 = dict(w); w2[g]='t'
  if isamp(random.choice(RULES[g]), w2, rp):
    w.clear(); w.update(w2); return True
  w[g]='f'; return True

def isamp(g: Body | Demand, w: World, rp: bool=False) -> bool:
  if rp and not of(g,(tuple,list)) and believed(w,g):
    return True                        # replay: settled goal
  match g:
    case list():                       # query: in order
      return all(isamp(x,w,rp) for x in g)
    case (x, v):                       # demand: chk or add
      return label(w,x,v)
    case And(xs=xs):                   # shuffled conjunction
      xs = xs[:]; random.shuffle(xs)
      return all(isamp(x,w,rp) for x in xs)
    case Or(xs=xs):                    # settled first, else dice
      if rp:
        for x in xs:
          if believed(w,x): return isamp(x,w,rp)
      return isamp(random.choice(xs), w, rp)
    case Link(bag=b, x=x):             # draw from the bag
      return label(w, x, random.choice(BAG[b]))
    case Atom() if g in w:             # memo
      return True
    case Atom() if g in RULES:         # derive or deny
      return derive(g,w,rp)
    case Atom():                       # fiat leaf
      w[g]='t'; return True
  return False

def sample(query: list, beliefs=(), rp: bool=False,
           tries: int=1000) -> World | None:
  for _ in range(tries):
    w = dict(beliefs)
    if isamp(query, w, rp): return w
  return None
