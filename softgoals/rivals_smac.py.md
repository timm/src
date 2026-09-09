# rivals_smac.py

{% raw %}
```text

```

```python
import sys, os, time, random, glob
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from ConfigSpace import ConfigurationSpace, Categorical
from smac import HyperparameterOptimizationFacade as HPO, Scenario
from run import load, Rig, musd

TRIALS, REPS = 500, 3

def one(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)
  b4 = [rig.d2h(w) for w in ws]
  leaves = sorted(rig.leaves, key=str)
  cs = ConfigurationSpace(seed=1)
  cs.add([Categorical(str(l), ['t','f']) for l in leaves])
  bystr = {str(l): l for l in leaves}
  def obj(cfg, seed=0):
    beliefs = {bystr[k]: cfg[k] for k in cfg}
    ds = [rig.d2h(w) for w in rig.gen(REPS, beliefs.items(), replay=True)]
    return sum(ds)/len(ds) if ds else 2.0   # dead worlds = terrible
  t0 = time.time()
  sc = Scenario(cs, deterministic=True, n_trials=TRIALS,
                output_directory=os.path.expanduser('~/tmp/smac_out'),
                seed=1)
  best = HPO(sc, obj, overwrite=True).optimize()
  score = obj(best)
  ms = round(1000*(time.time()-t0))
  mu0, sd0 = musd(b4)
  print(f"{name},{100*min(b4):.0f},{100*mu0:.0f} ({100*sd0:.0f}),"
        f"{100*score:.0f},{TRIALS*REPS},{len(leaves)},{ms}", flush=True)

if __name__ == '__main__':
  print("model,lo(b4),mu(b4),bestIncumbent,worlds,vars,ms")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    try: one(p)
    except Exception as e:
      print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
```

{% endraw %}