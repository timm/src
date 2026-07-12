#!/usr/bin/env python3 -B
"""
ezr2-eg.py: tutorial and tests for ezr2 (library in ezr2.py).

Run any test by its bare name; pass --key=val to override a knob:
  python3 ezr2-eg.py tree
  python3 ezr2-eg.py all

One -eg file per engine file, loaded below in tutorial order;
prose lives in string blocks; every sample is pasted from a
real run, never hand-typed.
"""
from ezr2 import *

"""
# ezr2: from zero to someplace cool

Tables of data are cheap; *labels* are dear. So: how few
labels buy a good row, plus an explanation of why it is
good? One table runs through this tutorial: auto93 (via
$MOOT), 398 cars, goals minimize Lbs-, maximize Acc+ and
Mpg+.
"""

# The tutorial, one -eg file per engine file, reading order
load("lib-eg", "rand-eg", "cols-eg", "data-eg", "dist-eg",
     "stats-eg", "acquire-eg", "cuts-eg", "tree-eg",
     "show-eg", "main-eg", into=globals())

"""
## Runner

`test_all` walks this file's globals in definition order,
reseeding before each, so the tutorial runs top to bottom.
"""

def test_all():
  "Run every other test_*, reseting the seed before each."
  for n,f in list(globals().items()):
    if n.startswith("test_") and n != "test_all":
      print("\n#", n, "-"*40)
      try: random.seed(the.seed); f()
      except Exception as e:
        print("FAIL:", n, type(e).__name__, e)

if __name__ == "__main__": main(globals())
