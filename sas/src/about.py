#!/usr/bin/env python3 -B
"""
about.py: every knob, one place. Change a value here, or
override it on the command line (e.g. --p 1), and all
downstream code obeys. No other file defines a setting.
"""

class o:
  "Dot-access struct. Its repr prints the public slots."
  def __init__(i, **d): i.__dict__.update(**d)
  def __repr__(i):
    return "{" + " ".join(":%s %s" % (k, v)
      for k, v in sorted(i.__dict__.items())
      if k[0] != "_") + "}"

the = o(
  seed = 1234567891,        # every random stream starts here
  p    = 2,                 # minkowski coefficient
  few  = 128,               # sample size for cheap guesses
  file = "data/auto93.csv") # default table (via MOOT)
