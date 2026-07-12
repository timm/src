#!/usr/bin/env python3 -B
"""
ezr2: landscape analysis for xai and optimization CSV data.
(c) 2026, Tim Menzies <timm@ieee.org>, MIT license

USAGE: python3 ezr2-eg.py [--key=val ...] [test ...]

OPTIONS: (defaults below are parsed into `the`):
  --file   data file  = $MOOT/optimize/misc/auto93.csv
  --seed   random seed           = 1
  --leaf   tree min leaf rows    = 3
  --maxd   tree max depth        = 8
  --more   add labels/round      = 4
  --budget labeling cap          = 50
  --cap    max rows kept         = 1024
  --check  rows labelled by tree = 5
  --keepf  keep frac             = 0.66
  --round  decimals shown        = 3
  --acquire  active | random   = active
  -h       print this help

TESTS: (run with their bare name):
  disty       rows by disty: top 5 / bottom 5
  acquire   20 shuffles; best disty per run
  acquires  one mean-win line (the sweep)
  tree      build+show a tree on acquired rows
  holdout  50:50 split; tree picks best test row
  holdouts holdout x20; land vs random verdict
  pure     no tree: best labelled, land vs random
  same     demo+validate the same() stat test
  all      run every test above, reseting seed each
"""
"""
INSTALL: one curl fetches every file; data lives in the moot
repo (tiny.cc/moot), cloned to ~/gits/moot (or set $MOOT):
  REPO=https://raw.githubusercontent.com/timm/src/main/ezr2
  curl -fL $REPO/INSTALL.md | sh
  git clone https://github.com/timm/moot ~/gits/moot
  python3 ezr2-eg.py disty

MODES: optimize a static CSV (format below), or a live model by
  overriding labelled() to compute goals live -- worked example
  in dtlz.py ($REPO/dtlz.py).

DATA: comma-separated, first row names the columns. A name's last
character sets that column's role; its first sets its type:
  Upper case first letter  -> numeric  (else: symbolic)
  +  /  -   suffix         -> goal: maximize / minimize  (y-col)
  !         suffix         -> klass   (a y-column)
  X         suffix         -> ignore this column
  ~         suffix         -> protected x-column
  (no suffix)              -> ordinary x-column (input)
E.g. auto93 header Clndrs,Volume,HpX,Model,origin,Lbs-,Acc+,Mpg+
has numeric inputs (Clndrs/Volume/Model), symbolic input origin,
an ignored column (HpX); goals minimize Lbs, maximize Acc/Mpg.

DISTY: each row's "distance to heaven" -- its distance to ideal
point where goals are best (0 = ideal, 1 = worst). `disty` reads
only the y-columns, so optimization scores a row without seeing
how it was made. `python3 ezr2-eg.py disty` sorts by disty and
prints the best 5, a blank line, then the worst 5:

  Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
       4      90   48     78       2  1985  21.5    40  0.075
       ...                                              ...
       8     455  225     70       1  4425    10    10  0.954

Best rows (disty~0) are light, high-Mpg cars; worst (disty~1) are
heavy guzzlers. Optimizers seek low-disty rows while labelling
(inspecting the y of) as few rows as possible.
"""
import os, re, sys, random
from math import log2, exp
from bisect import bisect_left, bisect_right
from types import SimpleNamespace as o
BIG  = 1e32
TINY = 1e-32
MOOT = (os.environ.get("MOOT")
        or os.path.expanduser("~/gits/moot"))

# One load point for the whole engine: exec each sibling file
# into one namespace (default: this one), in dependency
# order, exactly once. The eg loader passes its own globals.
def load(*files, into=None):
  here = os.path.dirname(os.path.abspath(__file__))
  for f in files:
    p = os.path.join(here, f + ".py")
    with open(p, encoding="utf-8") as fp:
      exec(compile(fp.read(), p, "exec"),
           globals() if into is None else into)

load("lib", "rand", "cols", "tbl", "dist", "acquire",
     "bins", "tree", "stats", "show", "main")

the = settings(__doc__)
