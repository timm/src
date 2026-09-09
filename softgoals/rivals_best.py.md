# rivals_best.py

{% raw %}
```text

```

```python
import sys, os, time, math, random, glob, subprocess
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from run import load, Rig, norm
from rivals_asp import OUT

MODELS = sorted(glob.glob('models/*.py')) + ['small.py']
short = lambda p: p.split('/')[-1].replace('.py','').replace('CS','',1)

def dump(name, rival, beliefs, ms):
  "beliefs: [(lispname, 't'/'f')...] -> OUT/name_rival.sexp"
  open(f"{OUT}/{name}_{rival}.sexp",'w').write(
    "(" + " ".join(f"({x} . {v})" for x,v in beliefs) + ")\n")
  print(f"{name},{rival},{len(beliefs)},{ms}", flush=True)

# --- nsga2: pymoo, leaves as bits, (-benefit, footprint) -------
def nsga2(path):
  import numpy as np
  from pymoo.core.problem import ElementwiseProblem
  from pymoo.algorithms.moo.nsga2 import NSGA2
  from pymoo.operators.sampling.rnd import BinaryRandomSampling
  from pymoo.operators.crossover.pntx import TwoPointCrossover
  from pymoo.operators.mutation.bitflip import BitflipMutation
  from pymoo.optimize import minimize
  name = short(path)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)
  leaves = sorted(rig.leaves, key=str)
  class SG(ElementwiseProblem):
    def __init__(s):
      super().__init__(n_var=len(leaves), n_obj=2, xl=0, xu=1,
                       vtype=bool)
    def _evaluate(s, x, out, *a, **kw):
      beliefs = {l: ('t' if b else 'f') for l,b in zip(leaves,x)}
      bs, fs = [], []
      for _ in range(3):
        w = rig.gen(1, beliefs.items(), replay=True)
        if w: b,f = rig.bf(w[0]); bs.append(b); fs.append(f)
      out["F"] = ([-sum(bs)/len(bs), sum(fs)/len(fs)] if bs
                  else [0, len(leaves)+1])
  t0 = time.time()
  res = minimize(SG(), NSGA2(pop_size=50,
          sampling=BinaryRandomSampling(),
          crossover=TwoPointCrossover(), mutation=BitflipMutation(),
          eliminate_duplicates=True), ('n_gen', 40),
          seed=1, verbose=False)
  ms = round(1000*(time.time()-t0))
  F, X = np.atleast_2d(res.F), np.atleast_2d(res.X)
  def d2h(bf):
    nb = norm(rig.mm[0], rig.mm[1], -bf[0])
    nf = norm(rig.mm[2], rig.mm[3],  bf[1])
    return math.sqrt(((1-nb)**2 + nf**2)/2)
  x = X[min(range(len(F)), key=lambda j: d2h(F[j]))]
  dump(name, 'nsga2',
       [(l.name, 't' if b else 'f') for l,b in zip(leaves,x)], ms)

# --- smac: SMAC3 HPO facade, leaves as categoricals ------------
def smac(path):
  from ConfigSpace import ConfigurationSpace, Categorical
  from smac import HyperparameterOptimizationFacade as HPO, Scenario
  name = short(path)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)
  leaves = sorted(rig.leaves, key=str)
  bystr = {str(l): l for l in leaves}
  cs = ConfigurationSpace(seed=1)
  cs.add([Categorical(str(l), ['t','f']) for l in leaves])
  def obj(cfg, seed=0):
    beliefs = {bystr[k]: cfg[k] for k in cfg}
    ds = [rig.d2h(w) for w in rig.gen(3, beliefs.items(), replay=True)]
    return sum(ds)/len(ds) if ds else 2.0
  t0 = time.time()
  sc = Scenario(cs, deterministic=True, seed=1,
        n_trials=min(500, 2**min(len(leaves), 20)),
        output_directory=os.path.expanduser('~/tmp/smac_out'))
  opt = HPO(sc, obj, overwrite=True)
  try: best = opt.optimize()   # tiny spaces exhaust: keep incumbent
  except Exception: best = opt.intensifier.get_incumbent()
  ms = round(1000*(time.time()-t0))
  dump(name, 'smac',
       [(bystr[k].name, best[k]) for k in best], ms)

# --- de: binary differential evolution, leaves as bits ---------
def de(path):
  # DE/rand/1/bin; same budget as smac/optuna (500 evals x 3
  # worlds), scalar objective = mean replayed d2h, dead = 2.0.
  name = short(path)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)
  leaves = sorted(rig.leaves, key=str)
  n = len(leaves)
  NP, GENS, F, CR = 20, 25, 0.5, 0.9
  def score(bits):
    beliefs = {l: ('t' if b else 'f') for l,b in zip(leaves,bits)}
    ds = [rig.d2h(w)
          for w in rig.gen(3, beliefs.items(), replay=True)]
    return sum(ds)/len(ds) if ds else 2.0
  t0 = time.time()
  pop = [[random.random() < .5 for _ in range(n)]
         for _ in range(NP)]
  fs = [score(p) for p in pop]
  for g in range(1, GENS):
    for i in range(NP):
      a, b, c = random.sample(
        [j for j in range(NP) if j != i], 3)
      j0 = random.randrange(n)
      kid = [pop[a][j] ^ ((pop[b][j] ^ pop[c][j])
                          and random.random() < F)
             if (j == j0 or random.random() < CR) else pop[i][j]
             for j in range(n)]
      f = score(kid)
      if f <= fs[i]: pop[i], fs[i] = kid, f
  ms = round(1000*(time.time()-t0))
  x = pop[min(range(NP), key=lambda i: fs[i])]
  dump(name, 'de',
       [(l.name, 't' if b else 'f') for l,b in zip(leaves,x)], ms)

# --- shortr1: the SHORT paper's engine, best of 1000 runs ------
def shortr1(path):
  # their engine lives in ~/tmp/shortr1; leaves = "bases", four
  # truth values -- t,t/2 read as t; f,f/2 as f.  names matched
  # to our atoms case-insensitively on sanitized text.
  import re
  name = short(path)
  here = os.getcwd()
  os.chdir(os.path.expanduser('~/tmp/shortr1/src'))
  sys.path.insert(0, '.'); sys.path.insert(0, 'pystar')
  import warnings; warnings.filterwarnings('ignore')
  from pystar.model import Model
  from pystar.template import Graph
  J = {'Counselling':'CSCounselling',
       'CounsellingManagement':'CSCounsellingManagement',
       'FDandMarketing':'CSFDandMarketing',
       'ITDepartment':'CSITDepartment', 'SAProgram':'CSSAProgram',
       'Services':'CSServices', 'KidsandYouth':'Kids and Youth'}
  if name not in J:
    os.chdir(here); print(f"{name},shortr1,SKIP no json", flush=True)
    return
  m = Model(Graph.read(f"pystar/json/stage1/{J[name]}.json"))
  random.seed(1)
  def world():
    for n in m._tree.nodes: n.value=None; n.is_random=False; n.cost=0
    s = m.score()
    return s, {b.id: m._tree.get_node(b.id).value for b in m.bases}
  t0 = time.time()
  runs = [world() for _ in range(1000)]
  ms = round(1000*(time.time()-t0))
  _, wbest = max(runs, key=lambda r: r[0])
  named = {m._tree.get_node(k).name: v for k,v in wbest.items()}
  os.chdir(here)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  from syntax import RULES
  key = lambda s: re.sub(r'\W','',str(s)).lower()
  back = {key(a): a.name for a in rig.mention
          if a not in RULES}   # leaves AND quals: their "bases"
  bs, miss = [], 0
  for nm, v in named.items():   # their labels: 1, -1, None (unseen)
    if v is None: continue
    k = key(nm)
    if k in back: bs.append((back[k], 't' if float(v) > 0 else 'f'))
    else: miss += 1
  dump(name, 'shortr1', bs, ms)
  if miss: print(f"# {name}: {miss}/{len(named)} unmatched leaves",
                 flush=True)

if __name__ == '__main__':
  mode = sys.argv[1]
  if mode == 'replay':
    rival, seed = sys.argv[2], sys.argv[3]
    for p in MODELS:
      name = short(p)
      kf = f"{OUT}/{name}_{rival}.sexp"
      if not os.path.exists(kf): continue
      row = subprocess.run(['sbcl','--script','rig7.lisp',
        p.replace('.py','.lisp'), name, kf, seed],
        capture_output=True, text=True).stdout.strip()
      print(row.splitlines()[-1] if row else f"{name},ERR",
            flush=True)
  else:
    only = sys.argv[2] if len(sys.argv) > 2 else ''
    for p in MODELS:
      if only and only not in p: continue
      try: {'nsga2':nsga2,'smac':smac,'shortr1':shortr1,
            'de':de}[mode](p)
      except Exception as e:
        print(f"{short(p)},{mode},ERR {type(e).__name__}: {e}",
              flush=True)
```

{% endraw %}