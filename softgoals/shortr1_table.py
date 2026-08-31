#!/usr/bin/env python3
# shortr1_table.py : run OUR pipeline shape (b4 / replay-all /
# replay-keys, pool/shared/keys, ddmin) on THEIR engine (shortr1,
# github dr-bigfatnoob/softgoals). Metric = % roots covered
# (their score), HIGHER is better -- printed as %cov not %d2h.
import sys, os, random, time, statistics as st
os.chdir(os.path.expanduser('~/tmp/shortr1/src'))
sys.path.insert(0, '.'); sys.path.insert(0, 'pystar')
import warnings; warnings.filterwarnings('ignore')
from pystar.model import Model
from pystar.template import Graph

N1, N2, EPS = 1000, 30, 0.05   # match run.py

def fresh(m):
  for n in m._tree.nodes: n.value=None; n.is_random=False; n.cost=0

def world(m, leaves=None):
  "one eval; leaves = preset leaf values (their decision space)"
  fresh(m)
  if leaves:
    for k,v in leaves.items(): m._tree.get_node(k).value = v
  s = m.score()
  return s, {b.id: m._tree.get_node(b.id).value for b in m.bases}

def musd(xs): return st.mean(xs), st.pstdev(xs)

def lomu(xs, roots):
  hi, (mu, sd) = max(xs), musd(xs)
  p = lambda v: round(100*v/roots)
  return f"{p(hi)},{p(mu)} ({p(sd)})"

def ddmin(test, c, n, state):
  if len(c)==1: return c
  sz = max(1,(len(c)+n-1)//n)
  chunks = [c[i:i+sz] for i in range(0,len(c),sz)]
  for ch in chunks:
    if test(ch): return ddmin(test, ch, 2, state)
  for ch in chunks:
    rest = [x for x in c if x not in ch]
    if rest and test(rest): return ddmin(test, rest, max(n-1,2), state)
  if n < len(c): return ddmin(test, c, min(len(c),2*n), state)
  return c

def rig(name, graph):
  t0 = time.time(); random.seed(1)
  m = Model(graph); roots = len(m.roots)
  runs = [world(m) for _ in range(N1)]
  scores = [s for s,_ in runs]
  sbest, wbest = max(runs, key=lambda r: r[0])
  pool   = list(wbest.items())
  shared = [(k,v) for k,v in pool
            if all(w[k]==v for _,w in runs)]
  cands  = [p for p in pool if p not in shared]
  replays = lambda seed: [world(m, dict(seed))[0] for _ in range(N2)]
  rb = replays(cands)
  target = musd(rb)[0]
  tests = [0]
  def passes(seed):
    tests[0] += 1
    return musd(replays(seed))[0] >= target - EPS*roots
  seed = ddmin(passes, cands, 2, tests) if cands else []
  ks = replays(seed)
  ms = round(1000*(time.time()-t0))
  print(f"{name},{lomu(scores,roots)},{lomu(rb,roots)},{lomu(ks,roots)},"
        f"{len(pool)},{len(shared)},{len(seed)},{tests[0]},"
        f"{round(100*len(seed)/len(m._tree.nodes))},{ms}")

J = "pystar/json/stage1/%s.json"
MODELS = [("Counselling", J % "CSCounselling"),
          ("CounsellingManagement", J % "CSCounsellingManagement"),
          ("FDandMarketing", J % "CSFDandMarketing"),
          ("ITDepartment", J % "CSITDepartment"),
          ("SAProgram", J % "CSSAProgram"),
          ("Services", J % "CSServices"),
          ("KidsandYouth", J % "Kids and Youth")]

print(" ,A,B (C),D,E (F),G,H (I),J,K,L,M,N,O")
print(" ,%cov,%cov,%cov,%cov,%cov,%cov,#,#,#,#,%,ms")
print("model,hi(b4),mu(b4),hi(all),mu(all),hi(keys),mu(keys),"
      "pool,shared,keys,tries,%keys,ms")
for name, path in MODELS:
  try: rig(name, Graph.read(path))
  except Exception as e: print(f"{name},ERR {type(e).__name__}: {e}")
