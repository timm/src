# rpl0.py

{% raw %}
```text
rpl1.py: repgrids, two passes, on a budget. Part 1: the substrate.
Tbl/Num/Sym, distance, ball trees. Demos: python3 rpl1.py [X.csv]
(or pytest rpl1.py, if you have it; same test_* functions).
```

```python
"""rpl1.py: repgrids, two passes, on a budget. Part 1: the substrate.
Tbl/Num/Sym, distance, ball trees. Demos: python3 rpl1.py [X.csv]
(or pytest rpl1.py, if you have it; same test_* functions)."""
from types import SimpleNamespace as o
from math import log, exp, floor
from random import choice as any1, sample as anys, seed as srand
import re, os, sys

the  = o(bins=7, far=.85, p=2, seed=1234567891,
         close=.3, warm=30, dry=2,
         reach=2, dull=.6, cull=.5, budget=50, wait=10,
         file=os.environ["HOME"] + "/gits/moot/optimize/misc/auto93.csv")
TINY = 1e-32

Sym = dict
Num = lambda n=0, mu=0, m2=0: (n, mu, m2)

def thing(s):
  try: return float(s)
  except: return s

def csv(f):
  for l in open(f, encoding="utf-8-sig"):
    if l := l.strip():
      yield [thing(s.strip()) for s in l.split(",")]

def worker(rows):
  def norm(lo,hi):
    return lambda v: max(0,min(1,(v-lo) / (hi-lo+TINY)))
  bin = {}
  for x in xs:
    a  = [row[x] for row in rows if row[x] != "?"]
    if (nump := all(not isinstance(v, str) for v in a)):
      a = sorted(a)
      bin[x] = norm(a[(.1*len(a))//1], a[(.9*len(a))//1])
    else:
      bin[x] = lambda v:v

      
def test_row():
  print([row for row in csv(the.file)])

def cli(d, s):
  "--k v or --k=v, any key of d; coerce to the old value's type"
  for k, old in vars(d).items():
    if m := re.search(f"--{k}[= ]+(\\S+)", s):
      vars(d)[k] = type(old)(m.group(1))

def tests(funs):
  for k, f in sorted(funs.items()):
    if k[:5] == "test_": print("#", k); srand(the.seed); f()
  print("all passed")

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
```

{% endraw %}