# rivals_de.py

{% raw %}
```text

```

```python
import sys, os, time, random, glob
sys.dont_write_bytecode = True
sys.path.insert(0, '/Users/timm/gits/timm/src/softgoals')
os.chdir('/Users/timm/gits/timm/src/softgoals')
from run import load, Rig, musd

NP, GENS, F, CR, REPS = 20, 25, 0.5, 0.9, 3   # 20*25=500 evals

def one(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  random.seed(1)
  hard, soft = load(path)
  rig = Rig(hard, soft)
  ws = rig.gen(1000); rig.yardstick(ws)
  b4 = [rig.d2h(w) for w in ws]
  leaves = sorted(rig.leaves, key=str)
  n = len(leaves)

  def score(bits):
    beliefs = {l: ('t' if b else 'f')
               for l, b in zip(leaves, bits)}
    ds = [rig.d2h(w)
          for w in rig.gen(REPS, beliefs.items(), replay=True)]
    return (sum(ds)/len(ds) if ds else 2.0), bool(ds)

  t0 = time.time()
  pop = [[random.random() < .5 for _ in range(n)]
         for _ in range(NP)]
  fs, alive0 = [], 0
  for p in pop:
    f, ok = score(p); fs.append(f); alive0 += ok
  aliveN = alive0
  for g in range(1, GENS):
    aliveN = 0
    for i in range(NP):
      a, b, c = random.sample(
        [j for j in range(NP) if j != i], 3)
      j0 = random.randrange(n)
      kid = []
      for j in range(n):
        m = pop[a][j] ^ ((pop[b][j] ^ pop[c][j])
                         and random.random() < F)
        kid.append(m if (j == j0 or random.random() < CR)
                   else pop[i][j])
      f, ok = score(kid); aliveN += ok
      if f <= fs[i]: pop[i], fs[i] = kid, f
  ms = round(1000*(time.time()-t0))
  mu0, sd0 = musd(b4)
  print(f"{name},{100*min(b4):.0f},{100*mu0:.0f} ({100*sd0:.0f}),"
        f"{100*min(fs):.0f},{100*alive0/NP:.0f},"
        f"{100*aliveN/NP:.0f},{NP*GENS*REPS},{n},{ms}",
        flush=True)

if __name__ == '__main__':
  print("model,lo(b4),mu(b4),bestDE,alive%g1,alive%gN,"
        "worlds,vars,ms")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    try: one(p)
    except Exception as e:
      print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
```

{% endraw %}