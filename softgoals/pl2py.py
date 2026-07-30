#!/usr/bin/env python3 -B
# pl2py.py : read goal models written in the nfr3.pl dialect
# (Head <-- [Lit,...]. clauses; no X negation; makes/breaks/
# helps/hurts contributions; and([..]) or([..]); compound
# heads like goals(hard) become node names verbatim) into an
# nfr3.py Model, so the moot/re corpus runs on the python
# engine unchanged.
#   python3 pl2py.py model.pl   run one model's goals
#   python3 pl2py.py dir        smoke-load every *.pl below
import re, sys, glob, os
from nfr3 import (Model, Node, no, makes, breaks, helps,
                  hurts, And, Or, abduce, soften, worlds)

SOFT = dict(makes=makes, breaks=breaks, helps=helps,
            hurts=hurts)
TOK = re.compile(r"[a-zA-Z_][A-Za-z0-9_]*|<--|[\[\](),]")

def clauses(text):              # comment-free token lists,
  text = re.sub(r"%[^\n]*", "", text)      # one per clause
  for c in re.split(r"\.(?:\s|$)", text):
    c = c.strip()
    if c and not c.startswith(":-"): yield TOK.findall(c)

def node(m, k): return m.nodes.setdefault(k, Node(m, k))

def pterm(m, ts, i):            # one literal, recursively
  t, i = ts[i], i + 1
  if t == 'no':
    x, i = pterm(m, ts, i)
    return no(x), i
  if i < len(ts) and ts[i] == '(':
    if t in SOFT:               # makes(x) etc
      x, i = pterm(m, ts, i + 1)
      return SOFT[t](x), i + 1  # skip ')'
    if t in ('and', 'or'):      # and([..]) or([..])
      xs, i = plist(m, ts, i + 1)
      return (And if t == 'and' else Or)(*xs), i + 1
    d, j = 1, i + 1             # compound atom: rebuild the
    while d:                    # source text as the name
      d, j = d + (ts[j] == '(') - (ts[j] == ')'), j + 1
    return node(m, ''.join(ts[i-1:j])), j
  return node(m, t), i

def plist(m, ts, i):            # ts[i] == '[' ... ']'
  xs, i = [], i + 1
  while ts[i] != ']':
    x, i = pterm(m, ts, i)
    xs.append(x)
    if ts[i] == ',': i += 1
  return xs, i + 1

def load(path):
  m = Model()
  for ts in clauses(open(path).read()):
    head, i = pterm(m, ts, 0)
    assert ts[i] == '<--', (path, ts[:i+1])
    body, i = plist(m, ts, i + 1)
    head.bodies.append(body)
  return m

def run(path):                  # one model: its goals nodes
  m = load(path)
  for k in ('goals(hard)', 'goals(soft)'):
    if k in m.nodes and m.nodes[k].bodies:
      g = m.nodes[k]
      if k == 'goals(hard)':
        ws = worlds(100, lambda: abduce(m, g))
        print(k, len(ws), "worlds sampled,",
              "first" if ws else "none", ws[:1])
      else:
        ws = worlds(100, lambda: soften(m, g))
        print(k, len(ws), "worlds sampled, best",
              max((w[0] for w in ws), default=None))

def smoke(top):                 # whole corpus: load + one
  ok = bad = 0                  # world each
  for f in sorted(glob.glob(top + "/**/*.pl",
                            recursive=True)):
    try:
      m = load(f)
      for n in m.nodes.values():
        if n.bodies: soften(m, n); break
      ok += 1
    except Exception as e:
      bad += 1
      print("FAIL", f, type(e).__name__, e)
  print(f"{ok} ok, {bad} fail")

if __name__ == '__main__':
  p = sys.argv[1]
  smoke(p) if os.path.isdir(p) else run(p)
