# infer.py : the interpreter; port of nfr5.pl. Worlds are ISAMP
# samples: goals walked in random order, one guess per choice
# point, denial not death. The same interpreter replays decision
# seeds prudently (replay=True: won goals are settled, ors prefer
# won branches). A believed-t head must re-earn its label: sample
# turns it into derive-then-insist, so its subtree gets walked
# and a failed derivation kills the world. A believed f is a
# standing denial: nothing to derive, gates against it fail.
# Undo is a trail, not a dict copy.
from typing import Iterator
from random import choice, sample as resample
from syntax import *

def shuffled(l: list) -> list:   # shuffled COPY, l untouched
  return resample(l, len(l))

def syms(g: Body, out: list|None=None) -> list[Atom]:
  out = [] if out is None else out
  if   of(g,Atom):  out.append(g)
  elif of(g,tuple):
    if   g[0]=='=':    out.append(g[1])
    elif g[0]=='link': out.append(g[2])
    else:
      for i in range(1,len(g)): syms(g[i],out)
  elif of(g,list):
    for x in g: syms(x,out)
  elif of(g,Term):  syms(compiled(g),out)
  return out

def won(w: World, g: Body) -> bool:
  return all(w.get(a)=='t' for a in syms(g))

def delivered(w: World, g: Body) -> bool:
  "no denied task inside: an or-bet paid off"
  if of(g,Atom):  return w.get(g)=='t'
  if of(g,tuple) and g[0]=='and':
    return all(delivered(w,x) for x in g[1:])
  if of(g,list):  return all(delivered(w,x) for x in g)
  return True     # '=', link, inner or: isamp already ruled

def settled(w: World, g: Body) -> bool:
  "this branch already ran, and paid off"
  return all(a in w for a in syms(g)) and delivered(w,g)

def believe(w: World, trail: list, x: Atom, v: Val) -> bool:
  "add x=v if x is fresh; else check it; refuse contradiction."
  if x in w: return w[x]==v
  w[x]=v; trail.append(x); return True

def derive(g: Atom, w: World, trail: list, replay: bool) -> bool:
  "try one body under g=t; on failure deny: g=f, no death."
  mark = len(trail)
  w[g]='t'; trail.append(g)
  if isamp(choice(RULES[g]), w, trail, replay): return True
  while len(trail) > mark: del w[trail.pop()]   # undo the attempt
  w[g]='f'; trail.append(g)
  return True

def isamp(g: Body, w: World, trail: list, replay: bool=False) -> bool:
  # dispatch by hand, not match: tuple patterns with * copy the
  # tail per visit, and this is the hot path. Order matters
  # twice: memo before derive, fiat last.
  if of(g,Atom):
    if g in w:     return True                   # memo (and replay)
    if g in RULES: return derive(g,w,trail,replay)
    w[g]='t'; trail.append(g); return True       # fiat
  if of(g,tuple):
    tag = g[0]
    if tag=='=':    return believe(w,trail,g[1],g[2])   # demand
    if tag=='link':
      if replay and g[2] in w: return True       # YIELD: label stands
      return believe(w,trail,g[2],choice(g[1]))
    if replay and won(w,g): return True          # CITE: not rederived
    if tag=='and':  return all(isamp(x,w,trail,replay)
                               for x in shuffled(list(g[1:])))
    if tag=='or':   # STEER: a paid-off branch, else a bet:
      if replay and any(settled(w,x) for x in g[1:]): return True
      x = choice(g[1:])   # the picked branch must deliver
      return isamp(x, w, trail, replay) and delivered(w,x)
  if of(g,list): return all(isamp(x,w,trail,replay) for x in g)
  if of(g,Term): return isamp(compiled(g),w,trail,replay)
  return False

def sample(query: list, beliefs=(), replay: bool=False,
           patience: int=1000) -> Iterator[World]:
  "yield worlds, skipping dead tries; stop after patience misses"
  pre, goals = {}, []
  for x,v in dict(beliefs).items():
    if v=='t' and x in RULES: goals.append([x,(x,'t')])  # RE-EARN
    else:                     pre[x] = v   # ADOPT: assumptions, denials
  q, miss = compiled(goals + list(query)), 0
  while miss < patience:
    w = dict(pre)
    if isamp(q, w, [], replay): miss = 0; yield w
    else:                       miss += 1
