#!/usr/bin/env python3
# rivals_aspmin.py : ASP inside the SAME minimization loop as the
# nfr6 pipeline. Per model:
#   1. sample N optimal worlds via clingo randomized sign draws
#      (--sign-def=rnd --seed=K --rand-freq=1), 10-way parallel
#   2. pool   = every leaf with its label in world #1
#      shared = leaves unanimous across all N draws (forced)
#      cands  = pool - shared
#   3. ddmin cands; the pass/fail oracle is clingo itself: assert
#      the candidate labels as facts (t -> fact, f -> :- l.) and
#      pass iff the certified optimum vector is unchanged.
# N=1000 by default (rand-freq is slow on FDandMarketing; the
# parallel pool keeps it ~4min there, ms reported per phase).
import sys, os, re, time, glob, subprocess
from concurrent.futures import ThreadPoolExecutor
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from rivals_asp import encode, nm, OUT
from run import load, Rig

N, JOBS = 1000, 10

def clingo(args):
  return subprocess.run(['clingo'] + args, capture_output=True,
                        text=True).stdout

def optvec(out):
  # a priority level with no ground weak constraints is OMITTED
  # from clingo's cost vector (e.g. facts make every hard goal
  # true at grounding, so the hmiss level vanishes): left-pad.
  m = re.findall(r'Optimization\s*:\s*([\d ]+)', out)
  if not m: return None
  v = tuple(map(int, m[-1].split()))
  return (0,)*(3-len(v)) + v

def shown(out):
  for l in out.splitlines():
    if l.startswith(('hmiss','qwin','lbuy')): return l
  return ''

def draw(lp, k):
  out = clingo([lp, '--quiet=1', '--time-limit=60',
                '--sign-def=rnd', f'--seed={k}', '--rand-freq=1'])
  if 'OPTIMUM FOUND' not in out: return None   # unproven: discard
  return frozenset(re.findall(r'lbuy\((\w+)\)', shown(out)))

def one(path):
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  rules, nq, nl, nh = encode(path)
  hard, soft = load(path); rig = Rig(hard, soft)
  leaves = sorted(nm(l) for l in rig.leaves)
  lp = f"{OUT}/{name}.lp"
  open(lp, 'w').write('\n'.join(rules) + '\n')
  target = optvec(clingo([lp, '--quiet=1', '--time-limit=120']))
  t0 = time.time()
  with ThreadPoolExecutor(JOBS) as ex:
    worlds = [w for w in ex.map(lambda k: draw(lp, k), range(1, N+1))
              if w is not None]
  ms_sample = round(1000*(time.time()-t0))
  distinct = len(set(worlds))
  w0 = worlds[0]
  pool   = [(l, l in w0) for l in leaves]
  shared = [(l,v) for l,v in pool
            if all((l in w)==v for w in worlds)]
  cands  = [p for p in pool if p not in shared]
  tests  = [0]
  def passes(sub):
    tests[0] += 1
    facts = ''.join(f"{l}.\n" if v else f":- {l}.\n" for l,v in sub)
    open(f"{OUT}/{name}_try.lp",'w').write(facts)
    out = clingo([lp, f"{OUT}/{name}_try.lp", '--quiet=1',
                  '--time-limit=60'])
    return 'OPTIMUM FOUND' in out and optvec(out) == target
  def ddmin(c, n):
    if len(c) <= 1: return c
    sz = max(1,(len(c)+n-1)//n)
    chunks = [c[i:i+sz] for i in range(0,len(c),sz)]
    for ch in chunks:
      if passes(ch): return ddmin(ch, 2)
    for ch in chunks:
      rest = [x for x in c if x not in ch]
      if rest and passes(rest): return ddmin(rest, max(n-1,2))
    if n < len(c): return ddmin(c, min(len(c),2*n))
    return c
  t1 = time.time()
  keys = ddmin(cands, 2) if cands and passes(cands) else \
         (cands if cands else [])
  ms_dd = round(1000*(time.time()-t1))
  note = '' if not cands or passes(keys) else ' FULLSET-FAILS'
  print(f"{name},{distinct},{len(pool)},{len(shared)},"
        f"{len(cands)},{len(keys)},{tests[0]},"
        f"{ms_sample},{ms_dd}{note}", flush=True)

def one_exact(path):
  # v2: no sampling. cautious enumeration = exact unanimity: a leaf
  # in EVERY optimum is forced-t, in NO optimum (outside brave) is
  # forced-f; only the brave-minus-cautious gap goes to ddmin.
  name = path.split('/')[-1].replace('.py','').replace('CS','',1)
  rules, nq, nl, nh = encode(path)
  hard, soft = load(path); rig = Rig(hard, soft)
  leaves = set(nm(l) for l in rig.leaves)
  lp = f"{OUT}/{name}.lp"
  open(lp, 'w').write('\n'.join(rules) + '\n')
  t0 = time.time()
  out0 = clingo([lp, '--quiet=1', '--time-limit=120'])
  target = optvec(out0)
  w0 = set(re.findall(r'lbuy\((\w+)\)', shown(out0)))
  def hull(mode):
    out = clingo([lp, '--opt-mode=optN', f'--enum-mode={mode}',
                  '0', '--quiet=1', '--time-limit=120'])
    return set(re.findall(r'lbuy\((\w+)\)', shown(out)))
  caut, brave = hull('cautious'), hull('brave')
  shared = [(l, True) for l in sorted(caut)] + \
           [(l, False) for l in sorted(leaves - brave)]
  cands  = [(l, l in w0) for l in sorted(brave - caut)]
  tests  = [0]
  def passes(sub):
    tests[0] += 1
    facts = ''.join(f"{l}.\n" if v else f":- {l}.\n" for l,v in sub)
    open(f"{OUT}/{name}_try.lp",'w').write(facts)
    out = clingo([lp, f"{OUT}/{name}_try.lp", '--quiet=1',
                  '--time-limit=60'])
    return 'OPTIMUM FOUND' in out and optvec(out) == target
  def ddmin(c, n):
    if len(c) <= 1: return c
    sz = max(1,(len(c)+n-1)//n)
    chunks = [c[i:i+sz] for i in range(0,len(c),sz)]
    for ch in chunks:
      if passes(ch): return ddmin(ch, 2)
    for ch in chunks:
      rest = [x for x in c if x not in ch]
      if rest and passes(rest): return ddmin(rest, max(n-1,2))
    if n < len(c): return ddmin(c, min(len(c),2*n))
    return c
  keys = ddmin(cands, 2) if cands and passes(cands) else \
         (cands if cands else [])
  ms = round(1000*(time.time()-t0))
  note = '' if not cands or passes(keys) else ' FULLSET-FAILS'
  print(f"{name},{len(leaves)},{len(shared)},{len(cands)},"
        f"{len(keys)},{tests[0]},{ms}{note}", flush=True)

if __name__ == '__main__':
  if '--exact' in sys.argv:
    print("model,pool,shared,cands,keys,tries,ms")
    for p in sorted(glob.glob('models/*.py')) + ['small.py']:
      try: one_exact(p)
      except Exception as e:
        print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
  else:
    print("model,distinct/1000,pool,shared,cands,keys,tries,"
          "msSample,msDdmin")
    for p in sorted(glob.glob('models/*.py')) + ['small.py']:
      try: one(p)
      except Exception as e:
        print(f"{p},ERR {type(e).__name__}: {e}", flush=True)
