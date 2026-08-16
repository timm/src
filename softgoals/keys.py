# keys.py : keys-from-sampling pipeline; port of gen18.pl.
# Usage: python3 keys.py models/small.py
import sys, math, random
from itertools import islice
import nfr5
from nfr5 import RULES, Or, Link, sample, syms

N1, N2, EPS, SEED = 1000, 30, 0.05, 1
Z0, ZUP, ZDN      = 2, 2, 1

def load(path):
  ns = {}
  exec(open(path).read(), ns)
  return ns['HARD'], ns['SOFT']

def walk(g):
  yield g
  if isinstance(g,(Or,nfr5.And)):
    for x in g.xs: yield from walk(x)

# the candidate pool: what a stakeholder can SET -- leaves
# (nothing derives them) and or-alternatives (branch picks).
# HARD/SOFT never enter RULES, so the Prolog goals(_) guard
# is structural here, not legislated.
def statics(hard, soft):
  heads   = set(RULES)
  targets = {g.x for bs in RULES.values() for b in bs
                 for g in walk(b) if isinstance(g,Link)}
  mention = ({a for bs in RULES.values() for b in bs
                for a in syms(b)}
             | heads | set(hard) | set(syms(soft)))
  quals   = targets - heads
  leaves  = mention - heads - quals
  choicy  = {a for bs in RULES.values() for b in bs
               for g in walk(b) if isinstance(g,Or)
               for a in g.xs if isinstance(a,nfr5.Atom)}
  return mention, quals, leaves, (mention-heads)|choicy

def norm(lo,hi,x):
  return 0.5 if hi<=lo else (x-lo)/(hi-lo)

def musd(ds):
  mu = sum(ds)/len(ds)
  return mu, math.sqrt(sum((d-mu)**2 for d in ds)/len(ds))

def ddmin(test, c, n):
  if len(c)==1: return c
  sz = max(1,(len(c)+n-1)//n)
  chunks = [c[i:i+sz] for i in range(0,len(c),sz)]
  for ch in chunks:               # a chunk passes alone?
    if test(ch): return ddmin(test, ch, Z0)
  for ch in chunks:               # dropping a chunk passes?
    rest = [x for x in c if x not in ch]
    if rest and test(rest):
      return ddmin(test, rest, max(n-ZDN,Z0))
  if n < len(c):                  # split finer
    return ddmin(test, c, min(len(c),ZUP*n))
  return c                        # 1-minimal

class Rig:
  "one model's pipeline: generate, reduce, assess."
  def __init__(s, path):
    s.hard, s.soft = load(path)
    _, s.quals, s.leaves, s.settable = statics(s.hard, s.soft)
    s.mention = _
    s.q = ([g for h in s.hard for g in (h,(h,'t'))]
           + [s.soft])
    s.tests = 0
    s.mm    = (0,0,0,0)   # set by yardstick
    s.dbest = 0.0         # set by run

  def gen(s, n, seed=(), replay=False):
    return list(islice(sample(s.q, dict(seed), replay), n))

  def d2h(s, w):
    nb = norm(s.mm[0], s.mm[1],
              sum(1 for q in s.quals  if w.get(q)=='t'))
    nf = norm(s.mm[2], s.mm[3],
              sum(1 for l in s.leaves if w.get(l)=='t'))
    return math.sqrt(((1-nb)**2 + nf**2)/2)

  def yardstick(s, ws):
    Bs = [sum(1 for q in s.quals  if w.get(q)=='t')
          for w in ws]
    Fs = [sum(1 for l in s.leaves if w.get(l)=='t')
          for w in ws]
    s.mm = (min(Bs),max(Bs),min(Fs),max(Fs))

  def candidates(s, wbest, ws):
    return [(x,v) for x,v in wbest.items()
            if x in s.settable
            and not all(w.get(x)==v for w in ws)]

  def passes(s, seed):
    s.tests += 1
    ds = [s.d2h(w) for w in s.gen(N2, seed, replay=True)]
    return bool(ds) and musd(ds)[0] <= s.dbest+EPS

  def assess(s, seed):
    return musd([s.d2h(w)
                 for w in s.gen(N2, seed, replay=True)])

def run(path):
  random.seed(SEED)
  r  = Rig(path)
  ws = r.gen(N1)
  r.yardstick(ws)
  ds = [r.d2h(w) for w in ws]
  mu0, sd0 = musd(ds)
  r.dbest, wbest = min(zip(ds,ws), key=lambda p:p[0])
  cands = r.candidates(wbest, ws)
  seed  = ddmin(r.passes, cands, Z0) if cands else []
  mus, sds = r.assess(seed)
  name = (path.split('/')[-1].replace('.py','')
          .replace('CS','',1))
  print(f"{name},{mu0:.4f},{sd0:.4f},{r.dbest:.4f},"
        f"{mus:.4f},{sds:.4f},{len(cands)},{len(seed)},"
        f"{r.tests},{100*len(seed)/len(r.mention):.1f}")

if __name__ == '__main__': run(sys.argv[1])
