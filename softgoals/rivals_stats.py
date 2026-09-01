#!/usr/bin/env python3
# rivals_stats.py : are asp-min keys statistically different from
# the sampling pipeline's keys?  Both key sets are replayed 30x
# through the SAME engine (infer.py, leaf beliefs adopted) and the
# two d2h samples meet the same/cliffs/ks/cohen battery from
# ezr-py/xai.py -- except cohen's yardstick, per spec, is
# eps = 0.35 * sd(b4)  (the untreated worlds' spread), not the
# pooled sd of the two samples.
import sys, os, re, random, glob
from bisect import bisect_left, bisect_right
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from run import load, Rig, musd, ddmin, the
from rivals_asp import encode, nm, OUT
import subprocess

def clingo(args):
  return subprocess.run(['clingo']+args, capture_output=True,
                        text=True).stdout

def optvec(out):
  m = re.findall(r'Optimization\s*:\s*([\d ]+)', out)
  if not m: return None
  v = tuple(map(int, m[-1].split()))
  return (0,)*(3-len(v)) + v

def lbuys(out):
  for l in out.splitlines():
    if l.startswith(('hmiss','qwin','lbuy')):
      return set(re.findall(r'lbuy\((\w+)\)', l))
  return set()

def asp_keys(path, rig):
  "asp-min v2: cautious/brave hulls + ddmin, clingo as oracle"
  rules, *_ = encode(path)
  name = path.split('/')[-1].replace('.py','')
  lp = f"{OUT}/{name}_st.lp"
  open(lp,'w').write('\n'.join(rules)+'\n')
  out0 = clingo([lp,'--quiet=1','--time-limit=120'])
  target, w0 = optvec(out0), lbuys(out0)
  hull = lambda m: lbuys(clingo([lp,'--opt-mode=optN',
    f'--enum-mode={m}','0','--quiet=1','--time-limit=120']))
  caut, brave = hull('cautious'), hull('brave')
  cands = [(l, l in w0) for l in sorted(brave - caut)]
  def passes(sub):
    facts = ''.join(f"{l}.\n" if v else f":- {l}.\n" for l,v in sub)
    open(f"{OUT}/{name}_st_try.lp",'w').write(facts)
    out = clingo([lp, f"{OUT}/{name}_st_try.lp",'--quiet=1',
                  '--time-limit=60'])
    return 'OPTIMUM FOUND' in out and optvec(out) == target
  keys = ddmin(passes, cands, the.z0) if cands and passes(cands) \
         else cands
  back = {nm(l): l for l in rig.leaves}
  return [(back[l], 't' if v else 'f') for l,v in keys]

def our_keys(rig):
  "the sampling pipeline, exactly as run.py's rig()"
  ws = rig.gen(the.n1)
  rig.yardstick(ws)
  ds = [rig.d2h(w) for w in ws]
  rig.dbest, wbest = min(zip(ds,ws), key=lambda p:p[0])
  _, _, cands = rig.candidates(wbest, ws)
  rb = rig.replays(cands)
  if cands and rb: rig.dbest = musd(rb)[0]
  return (ddmin(rig.passes, cands, the.z0) if cands else []), ds

def cliffs(xs, ys):
  ys = sorted(ys); m = len(ys)
  gt = sum(bisect_left(ys, x)      for x in xs)
  lt = sum(m - bisect_right(ys, x) for x in xs)
  return abs(gt - lt) / (len(xs) * m + 1e-32)

def ks(xs, ys):
  xs, ys = sorted(xs), sorted(ys); n, m = len(xs), len(ys)
  gap = lambda v: abs(bisect_right(xs,v)/n - bisect_right(ys,v)/m)
  return max(map(gap, xs + ys))

def battery(xs, ys, sd_b4, cliff=0.195, conf=1.36):
  mux, sdx = musd(xs); muy, sdy = musd(ys)
  co = abs(mux - muy) <= 0.35 * sd_b4
  cl = cliffs(xs, ys)
  n, m = len(xs), len(ys)
  k  = ks(xs, ys)
  kok = k <= conf * ((n+m)/(n*m))**0.5
  return (co and cl <= cliff and kok,
          f"{100*mux:.0f} ({100*sdx:.0f}),{100*muy:.0f} ({100*sdy:.0f}),"
          f"{cl:.2f},{k:.2f},{'y' if co else 'n'},"
          f"{'SAME' if (co and cl<=cliff and kok) else 'DIFF'}")

if __name__ == '__main__':
  print("model,ours mu(sd),asp mu(sd),cliffs,ks,cohen,verdict")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    name = p.split('/')[-1].replace('.py','').replace('CS','',1)
    try:
      random.seed(1)
      hard, soft = load(p)
      rig = Rig(hard, soft)
      ours, ds = our_keys(rig)
      sd_b4 = musd(ds)[1]
      a = asp_keys(p, rig)
      xs = rig.replays(ours)
      ys = rig.replays(a)
      _, row = battery(xs, ys, sd_b4)
      print(f"{name},{row}", flush=True)
    except Exception as e:
      print(f"{name},ERR {type(e).__name__}: {e}", flush=True)
