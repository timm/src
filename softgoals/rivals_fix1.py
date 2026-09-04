#!/usr/bin/env python3
# rivals_fix1.py : decoder encoding for DE / NSGA-II / SMAC3.
# Fix 1: the genotype is not a world but a POLICY -- one weight
# per branch of every stochastic choice point in the walk (rule
# pick, link label, or-branch).  Decoding = running isamp with
# choice() biased by those weights, so every genotype yields
# LEGAL worlds by construction: the dead-world problem cannot
# arise (a terrible policy just retries, it never contradicts).
# Objective: mean d2h of REPS sampled worlds (same 1000-world b4
# yardstick as run.py); incumbent re-scored on 30 fresh worlds.
#   python3 rivals_fix1.py de|nsga2        (brew python)
#   ~/tmp/smacenv/bin/python3 rivals_fix1.py smac
import sys, os, time, random, glob, math
sys.dont_write_bytecode = True
sys.path.insert(0, '/Users/timm/gits/timm/src/softgoals')
os.chdir('/Users/timm/gits/timm/src/softgoals')
from run import load, Rig, musd
import infer
from syntax import RULES, compiled

REPS = 3

# ---- the decoder: a policy-aware choice() --------------------
POLICY, _base = {}, random.choice

def pchoice(seq):
  w = POLICY.get(repr(seq))
  if w is None: return _base(seq)
  t = random.random()*sum(w)
  for x, wi in zip(seq, w):
    t -= wi
    if t <= 0: return x
  return seq[-1]

infer.choice = pchoice

def points(rig):
  "every stochastic choice point: (repr-key, n branches)"
  seen = {}
  def walk(g):
    if isinstance(g, tuple) and g:
      if g[0] == 'or':
        seen.setdefault(repr(g[1:]), len(g)-1)
        for x in g[1:]: walk(x)
      elif g[0] == 'link':
        seen.setdefault(repr(g[1]), len(g[1]))
        walk(g[2])
      elif g[0] == 'and':
        for x in g[1:]: walk(x)
    elif isinstance(g, list):
      for x in g: walk(x)
  for h, bs in RULES.items():
    if len(bs) > 1: seen.setdefault(repr(bs), len(bs))
    for b in bs: walk(b)
  walk(compiled(rig.q))
  return sorted(seen.items())

def set_policy(x, pts):
  POLICY.clear()
  i = 0
  for k, n in pts:
    POLICY[k] = [g + .01 for g in x[i:i+n]]; i += n

def fitness(rig, x, pts, reps=REPS):
  set_policy(x, pts)
  ws = rig.gen(reps)
  return (sum(rig.d2h(w) for w in ws)/len(ws)) if ws else 2.0

def setup(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  POLICY.clear()
  ws = rig.gen(1000); rig.yardstick(ws)
  b4 = [rig.d2h(w) for w in ws]
  pts = points(rig)
  k = sum(n for _, n in pts)
  return name, rig, b4, pts, k

def report(name, rig, b4, pts, k, best, worlds, ms):
  set_policy(best, pts)
  ds = [rig.d2h(w) for w in rig.gen(30)]
  mu0, sd0 = musd(b4)
  lo = min(ds) if ds else 2.0
  mu = (sum(ds)/len(ds)) if ds else 2.0
  print(f"{name},{100*min(b4):.0f},{100*mu0:.0f} ({100*sd0:.0f}),"
        f"{100*lo:.0f},{100*mu:.0f},{worlds},{k},{ms}",
        flush=True)

# ---- arms ----------------------------------------------------
def de_search(rig, pts, k, NP=20, GENS=25, F=0.5, CR=0.9):
  pop = [[random.random() for _ in range(k)] for _ in range(NP)]
  fs = [fitness(rig, p, pts) for p in pop]
  for g in range(1, GENS):
    for i in range(NP):
      a, b, c = random.sample(
        [j for j in range(NP) if j != i], 3)
      j0 = random.randrange(k)
      kid = [min(1, max(0, pop[a][j] + F*(pop[b][j]-pop[c][j])))
             if (j == j0 or random.random() < CR) else pop[i][j]
             for j in range(k)]
      f = fitness(rig, kid, pts)
      if f <= fs[i]: pop[i], fs[i] = kid, f
  return pop[min(range(NP), key=lambda i: fs[i])]

def de(path):
  name, rig, b4, pts, k = setup(path)
  t0 = time.time()
  best = de_search(rig, pts, k)
  ms = round(1000*(time.time()-t0))
  report(name, rig, b4, pts, k, best, 20*25*REPS, ms)

def keys(path):
  # the bridge: policy -> best world -> ddmin -> minimal keys,
  # judged like every other rival (rig7 20-seed replay).  The
  # policy only STEERS sampling; ddmin and all replays run with
  # the policy OFF, so the keys stand alone in the plain walk.
  from run import ddmin, the, musd
  name, rig, b4, pts, k = setup(path)
  t0 = time.time()
  best = de_search(rig, pts, k)
  set_policy(best, pts)
  ws = rig.gen(1000)
  ds = [rig.d2h(w) for w in ws]
  rig.dbest, wbest = min(zip(ds, ws), key=lambda p: p[0])
  pool, shared, cands = rig.candidates(wbest, ws)
  POLICY.clear()
  rb = rig.replays(cands)
  if cands and rb: rig.dbest = musd(rb)[0]
  seed = ddmin(rig.passes, cands, the.z0) if cands else []
  ms = round(1000*(time.time()-t0))
  out = os.path.join(os.environ.get('TMPDIR', '/tmp'),
                     'softgoals_asp')
  os.makedirs(out, exist_ok=True)
  open(f"{out}/{name}_depol.sexp", 'w').write(
    "(" + " ".join(f"({x.name} . {v})" for x, v in seed) + ")\n")
  print(f"{name},depol,{len(seed)},{ms}", flush=True)

def nsga2(path):
  import numpy as np
  from pymoo.core.problem import ElementwiseProblem
  from pymoo.algorithms.moo.nsga2 import NSGA2
  from pymoo.optimize import minimize
  name, rig, b4, pts, k = setup(path)
  class SG(ElementwiseProblem):
    def __init__(s):
      super().__init__(n_var=k, n_obj=2, xl=0.0, xu=1.0)
    def _evaluate(s, x, out, *a, **kw):
      set_policy(list(x), pts)
      ws = rig.gen(REPS)
      if ws:
        bs, fs2 = zip(*[rig.bf(w) for w in ws])
        out["F"] = [-sum(bs)/len(bs), sum(fs2)/len(fs2)]
      else:
        out["F"] = [0, len(rig.leaves)+1]
  t0 = time.time()
  res = minimize(SG(), NSGA2(pop_size=50), ('n_gen', 40),
                 seed=1, verbose=False)
  ms = round(1000*(time.time()-t0))
  F, X = np.atleast_2d(res.F), np.atleast_2d(res.X)
  from run import norm
  def d2h(bf):
    nb = norm(rig.mm[0], rig.mm[1], -bf[0])
    nf = norm(rig.mm[2], rig.mm[3],  bf[1])
    return math.sqrt(((1-nb)**2 + nf**2)/2)
  best = list(X[min(range(len(F)), key=lambda j: d2h(F[j]))])
  report(name, rig, b4, pts, k, best, 50*40*REPS, ms)

def smac(path, TRIALS=500):
  from ConfigSpace import ConfigurationSpace, Float
  from smac import HyperparameterOptimizationFacade as HPO, \
       Scenario
  name, rig, b4, pts, k = setup(path)
  cs = ConfigurationSpace(seed=1)
  cs.add([Float(f"w{i}", (0.0, 1.0)) for i in range(k)])
  def obj(cfg, seed=0):
    return fitness(rig, [cfg[f"w{i}"] for i in range(k)], pts)
  t0 = time.time()
  sc = Scenario(cs, deterministic=True, seed=1, n_trials=TRIALS,
        output_directory=os.path.expanduser('~/tmp/smac_out'))
  opt = HPO(sc, obj, overwrite=True)
  try: inc = opt.optimize()
  except Exception: inc = opt.intensifier.get_incumbent()
  ms = round(1000*(time.time()-t0))
  best = [inc[f"w{i}"] for i in range(k)]
  report(name, rig, b4, pts, k, best, TRIALS*REPS, ms)

if __name__ == '__main__':
  arm = {'de': de, 'nsga2': nsga2, 'smac': smac,
         'keys': keys}[sys.argv[1]]
  print("model,lo(b4),mu(b4),loPol,muPol,worlds,vars,ms")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    try: arm(p)
    except Exception as e:
      print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
