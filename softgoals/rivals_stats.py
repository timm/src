#!/usr/bin/env python3
# rivals_stats.py : are asp-min keys statistically different from
# the sampling pipeline's keys?  Python finds the asp keys (clingo
# cautious/brave hulls + ddmin, clingo as oracle) and writes them
# as an alist; rig7.lisp (the truth walk, nfr7.lisp) finds our
# keys, replays BOTH sets 30x through the same engine, and judges
# with cliffs/ks/cohen -- except cohen's yardstick, per spec, is
# eps = 0.35 * sd(b4) (the untreated worlds' spread), not the
# pooled sd of the two samples.  Win by lo (keys chase the best
# world); mu (sd) printed beside it so disagreement is visible.
# Usage: python3 rivals_stats.py [SEED]
import sys, os, re, glob, subprocess, time
sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from run import load, Rig, ddmin, the
from rivals_asp import encode, nm, OUT

def clingo(args):
  return subprocess.run([sys.executable,'-m','clingo']+args,
                        capture_output=True, text=True).stdout

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
  # sorted: encode() order varies with PYTHONHASHSEED; rule order
  # is ASP-irrelevant but steers clingo's tie-break among optima
  open(lp,'w').write('\n'.join(sorted(rules))+'\n')
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
  back = {nm(l): l.name for l in rig.leaves}
  return [(back[l], 't' if v else 'f') for l,v in keys]

if __name__ == '__main__':
  seed = sys.argv[1] if len(sys.argv) > 1 else '1'
  subprocess.run([sys.executable,'to-lisp.py'],
                 capture_output=True)   # regen models/*.lisp
  print("model,ours lo,ours mu(sd),asp lo,asp mu(sd),"
        "ourkeys,aspkeys,cliffs,ks,cohen,verdict,win,ms")
  for p in sorted(glob.glob('models/*.py')) + ['small.py']:
    name = p.split('/')[-1].replace('.py','').replace('CS','',1)
    try:
      t0 = time.perf_counter()
      hard, soft = load(p)
      a = asp_keys(p, Rig(hard, soft))
      kf = f"{OUT}/{name}_keys.sexp"
      open(kf,'w').write(
        "(" + " ".join(f"({x} . {v})" for x,v in a) + ")\n")
      row = subprocess.run(
        ['sbcl','--script','rig7.lisp',
         p.replace('.py','.lisp'), name, kf, seed],
        capture_output=True, text=True).stdout.strip()
      ms = round(1000*(time.perf_counter()-t0))
      print(f"{row.splitlines()[-1]},{ms}" if row
            else f"{name},ERR no output", flush=True)
    except Exception as e:
      print(f"{name},ERR {type(e).__name__}: {e}", flush=True)
