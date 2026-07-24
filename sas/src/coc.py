#!/usr/bin/env python3 -B
"""
coc.py: minimal COCOMO II, post-architecture form, using
the COCOMO II.2000 calibration from the model manual.
Effort = a * kloc^e * prod(EM); e = b + 0.01*sum(SF).
The calibration constants a,b,c,d are coc2 arguments.
Ratings are ints 1..6 for vl, l, n, h, vh, xh; 3 is
nominal and the default. None marks a rating the manual
leaves undefined; asking for one is an error.
"""
from about import o

#-- scale factors: percent points on the size exponent --
SF = dict(
  prec = (6.20, 4.96, 3.72, 2.48, 1.24, 0.00),
  flex = (5.07, 4.05, 3.04, 2.03, 1.01, 0.00),
  resl = (7.07, 5.65, 4.24, 2.83, 1.41, 0.00),
  team = (5.48, 4.38, 3.29, 2.19, 1.10, 0.00),
  pmat = (7.80, 6.24, 4.68, 3.12, 1.56, 0.00))

#-- effort multipliers: linear scaling on the effort ----
_ = None
EM = dict(
  rely = (0.82, 0.92, 1.00, 1.10, 1.26,    _),
  data = (   _, 0.90, 1.00, 1.14, 1.28,    _),
  cplx = (0.73, 0.87, 1.00, 1.17, 1.34, 1.74),
  ruse = (   _, 0.95, 1.00, 1.07, 1.15, 1.24),
  docu = (0.81, 0.91, 1.00, 1.11, 1.23,    _),
  time = (   _,    _, 1.00, 1.11, 1.29, 1.63),
  stor = (   _,    _, 1.00, 1.05, 1.17, 1.46),
  pvol = (   _, 0.87, 1.00, 1.15, 1.30,    _),
  acap = (1.42, 1.19, 1.00, 0.85, 0.71,    _),
  pcap = (1.34, 1.15, 1.00, 0.88, 0.76,    _),
  pcon = (1.29, 1.12, 1.00, 0.90, 0.81,    _),
  apex = (1.22, 1.10, 1.00, 0.88, 0.81,    _),
  plex = (1.19, 1.09, 1.00, 0.91, 0.85,    _),
  ltex = (1.20, 1.09, 1.00, 0.91, 0.84,    _),
  tool = (1.17, 1.09, 1.00, 0.90, 0.78,    _),
  site = (1.22, 1.09, 1.00, 0.93, 0.86, 0.80),
  sced = (1.43, 1.14, 1.00, 1.00, 1.00,    _))

#-- risk: Madachy's risky pairs of driver settings ------
# One line per risky pair x,y. Its weight w counts how
# many of xomo's six risk groups (schedule, product,
# personnel, process, platform, reuse) cite the pair.
# The rule: risk grows as 2**(kx*x + ky*y - t), for
# exponents at or above zero. E.g. ("sced","rely",..
# -1,1,3) reads: penalty doubles as schedules tighten
# while reliability demands climb.
RISKS = (           # x, y, w, kx, ky, t
  ("sced","rely",2,-1, 1, 3), ("sced","cplx",1,-1, 1, 3),
  ("sced","time",3,-1, 1, 3), ("sced","pvol",2,-1, 1, 3),
  ("sced","tool",2,-1,-1,-3), ("sced","acap",2,-1,-1,-4),
  ("sced","apex",2,-1,-1,-4), ("sced","pcap",2,-1,-1,-4),
  ("sced","plex",2,-1,-1,-4), ("sced","ltex",2,-1,-1,-3),
  ("sced","pmat",2,-1,-1,-3), ("rely","acap",2, 1,-1, 2),
  ("rely","pcap",2, 1,-1, 2), ("rely","pmat",1, 1,-1, 2),
  ("cplx","acap",2, 1,-1, 3), ("cplx","pcap",2, 1,-1, 3),
  ("cplx","tool",2, 1,-1, 3), ("ruse","apex",3, 1,-1, 3),
  ("ruse","ltex",3, 1,-1, 3), ("pmat","acap",2,-1,-1,-3),
  ("pmat","pcap",2, 1,-1, 3), ("stor","acap",2, 1,-1, 3),
  ("stor","pcap",2, 1,-1, 3), ("time","acap",2, 1,-1, 3),
  ("time","pcap",1, 1,-1, 3), ("time","tool",2, 1,-1, 4),
  ("tool","acap",2,-1,-1,-3), ("tool","pcap",2,-1,-1,-3),
  ("tool","pmat",1,-1,-1,-3), ("ltex","pcap",1,-1,-1,-4),
  ("pvol","plex",2, 1,-1, 3), ("team","apex",2,-1,-1,-3),
  ("team","sced",1,-1,-1,-3), ("team","site",1,-1,-1,-3))

def risk(**r):
  "Madachy heuristic risk: sum of risky-pair penalties."
  n = 0
  for x, y, w, kx, ky, t in RISKS:
    e = kx * r.get(x, 3) + ky * r.get(y, 3) - t
    n += w * 2**e if e >= 0 else 0
  return n / 3.73

def coc2(kloc=10, a=2.94, b=0.91, c=3.67, d=0.28, **r):
  "Effort (person-months), schedule (months), and risk."
  bad = [k for k in r if k not in SF and k not in EM]
  assert not bad, f"unknown drivers: {bad}"
  sf = sum(SF[k][r.get(k, 3) - 1] for k in SF)
  em = 1
  for k in EM:
    m = EM[k][r.get(k, 3) - 1]
    assert m is not None, f"{k}={r[k]} is undefined"
    em *= m
  e  = b + 0.01 * sf
  pm = a * kloc**e * em
  return o(effort=pm, risk=risk(**r),
           months=c * pm**(d + 0.2*(e - b)))
