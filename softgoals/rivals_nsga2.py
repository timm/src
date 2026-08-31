#!/usr/bin/env python3
# rivals_nsga2.py : NSGA-II (pymoo) over the softgoals corpus.
# Decision vector = the model's LEAVES (t/f bits), same space as
# shortr1's DE. Evaluator = our python engine (infer.sample with
# leaf beliefs adopted). Objectives = (-benefit, footprint).
# Reports: runtime, evals, front size, best d2h on the front
# (d2h normalized by the same 1000-world b4 yardstick as run.py).
import sys, os, time, math, random
sys.dont_write_bytecode = True
sys.path.insert(0, '/Users/timm/gits/timm/src/softgoals')
os.chdir('/Users/timm/gits/timm/src/softgoals')
import numpy as np
from pymoo.core.problem import ElementwiseProblem
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.operators.sampling.rnd import BinaryRandomSampling
from pymoo.operators.crossover.pntx import TwoPointCrossover
from pymoo.operators.mutation.bitflip import BitflipMutation
from pymoo.optimize import minimize
from run import load, Rig, musd, norm, the

REPS = 3   # worlds averaged per evaluation

class SG(ElementwiseProblem):
  def __init__(s, rig, leaves):
    s.rig, s.leaves = rig, leaves
    s.evals = 0
    super().__init__(n_var=len(leaves), n_obj=2, xl=0, xu=1, vtype=bool)

  def _evaluate(s, x, out, *a, **kw):
    s.evals += 1
    beliefs = {l: ('t' if b else 'f') for l, b in zip(s.leaves, x)}
    bs, fs = [], []
    for _ in range(REPS):
      ws = s.rig.gen(1, beliefs.items(), replay=True)
      if ws:
        b, f = s.rig.bf(ws[0]); bs.append(b); fs.append(f)
    if bs: out["F"] = [-sum(bs)/len(bs), sum(fs)/len(fs)]
    else:  out["F"] = [0, len(s.leaves)+1]   # every world died

def one(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)           # same ruler as run.py
  b4 = [rig.d2h(w) for w in ws]
  leaves = sorted(rig.leaves, key=str)
  t0 = time.time()
  prob = SG(rig, leaves)
  alg  = NSGA2(pop_size=50, sampling=BinaryRandomSampling(),
               crossover=TwoPointCrossover(), mutation=BitflipMutation(),
               eliminate_duplicates=True)
  res  = minimize(prob, alg, ('n_gen', 40), seed=1, verbose=False)
  ms   = round(1000*(time.time()-t0))
  F    = np.atleast_2d(res.F)
  def d2h(bf):
    nb = norm(rig.mm[0], rig.mm[1], -bf[0])
    nf = norm(rig.mm[2], rig.mm[3],  bf[1])
    return math.sqrt(((1-nb)**2 + nf**2)/2)
  ds = sorted(d2h(f) for f in F)
  mu0, sd0 = musd(b4)
  print(f"{name},{100*min(b4):.0f},{100*mu0:.0f} ({100*sd0:.0f}),"
        f"{100*ds[0]:.0f},{100*ds[len(ds)//2]:.0f},{len(F)},"
        f"{prob.evals*REPS},{len(leaves)},{ms}", flush=True)

if __name__ == '__main__':
  print("model,lo(b4),mu(b4),bestFront,medFront,front,worlds,vars,ms")
  import glob
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    try: one(p)
    except Exception as e:
      print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
