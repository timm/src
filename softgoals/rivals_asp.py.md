# rivals_asp.py

{% raw %}
```text

```

```python
import sys, os, re, subprocess, time, glob
sys.dont_write_bytecode = True
sys.path.insert(0, '/Users/timm/gits/timm/src/softgoals')
os.chdir('/Users/timm/gits/timm/src/softgoals')
from run import load, Rig
from syntax import Atom

OUT = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'softgoals_asp')
os.makedirs(OUT, exist_ok=True)   # generated .lp live outside the repo

def nm(a): return 'a_' + re.sub(r'\W', '_', str(a)).lower()

KIND = {('t',):'sup', ('t','t','f'):'sup',
        ('f',):'att', ('f','f','t'):'att'}

class T:
  def __init__(s):
    s.rules, s.n = [], 0
  def aux(s):
    s.n += 1; return f"b{s.n}"
  def walk(s, g, ctx):
    "return list of body literals for g, under context atom ctx"
    if isinstance(g, Atom): return [nm(g)]
    if isinstance(g, list):
      return [l for x in g for l in s.walk(x, ctx)]
    if isinstance(g, tuple):
      tag = g[0]
      if tag == '=':
        return [nm(g[1])] if g[2]=='t' else [f"not {nm(g[1])}"]
      if tag == 'link':
        s.rules.append(f"{KIND[tuple(g[1])]}_{nm(g[2])} :- {ctx}.")
        return []
      if tag == 'and':
        return [l for x in g[1:] for l in s.walk(x, ctx)]
      if tag == 'or':
        o = s.aux()
        for x in g[1:]:
          b = s.aux()
          lits = s.walk(x, b)
          s.rules.append(f"{b} :- {', '.join(lits) or '#true'}.")
          s.rules.append(f"{o} :- {b}.")
        return [o]
    raise ValueError(g)

def encode(path):
  hard, soft = load(path)
  rig = Rig(hard, soft)
  from infer import RULES
  t = T()
  for h, bodies in RULES.items():
    for b in bodies:
      c = t.aux()
      lits = t.walk(b, c)
      t.rules.append(f"{c} :- {', '.join(lits) or '#true'}.")
      t.rules.append(f"{nm(h)} :- {c}.")
  for l in rig.leaves:  t.rules.append(f"{{{nm(l)}}}.")
  for q in rig.quals:
    t.rules.append(f"{nm(q)} :- sup_{nm(q)}, not att_{nm(q)}.")
    t.rules.append(f"sup_{nm(q)} :- #false.")
    t.rules.append(f"att_{nm(q)} :- #false.")
  for h in hard:
    t.rules.append(f"hmiss({nm(h)}) :- not {nm(h)}.")
    t.rules.append(f":~ hmiss({nm(h)}). [1@3,{nm(h)}]")
  for q in rig.quals:
    t.rules.append(f"qwin({nm(q)}) :- {nm(q)}.")
    t.rules.append(f":~ not {nm(q)}. [1@2,{nm(q)}]")
  for l in rig.leaves:
    t.rules.append(f"lbuy({nm(l)}) :- {nm(l)}.")
    t.rules.append(f":~ {nm(l)}. [1@1,{nm(l)}]")
  t.rules += ["#show hmiss/1.", "#show qwin/1.", "#show lbuy/1."]
  return t.rules, len(rig.quals), len(rig.leaves), len(hard)

def solve(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  rules, nq, nl, nh = encode(path)
  lp = f"{OUT}/{name}.lp"
  open(lp, 'w').write('\n'.join(rules) + '\n')
  t0 = time.time()
  r = subprocess.run(['clingo', lp, '--quiet=1', '--time-limit=120'],
                     capture_output=True, text=True)
  ms = round(1000*(time.time()-t0))
  out = r.stdout
  status = ('OPTIMUM' if 'OPTIMUM FOUND' in out else
            'UNSAT' if 'UNSATISFIABLE' in out else 'TIMEOUT/UNK')
  ans = [l for l in out.splitlines() if l.startswith(('hmiss','qwin','lbuy'))]
  last = ans[-1] if ans else ''
  hm, qw, lb = (last.count('hmiss('), last.count('qwin('),
                last.count('lbuy('))
  print(f"{name},{status},hard {nh-hm}/{nh},benefit {qw}/{nq},"
        f"cost {lb}/{nl},{ms}", flush=True)

if __name__ == '__main__':
  print("model,status,benefit,cost,ms")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    try: solve(p)
    except Exception as e:
      print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
```

{% endraw %}