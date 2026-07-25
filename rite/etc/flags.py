"""Coding vocabulary: the ONE place the per-topic flags
live. code.py (abstracts) and recode.py (full text) both
import from here. New topic: edit this file and
../README.md; touch nothing else."""

FLAGS = dict(
  SE=r"software|defect|code|test(ing)?|requirement|program",
  MO=r"multi.?objective|many.?objective|pareto|search.based"
     r"|optimi[sz]",
  EX=r"explain|explana|interpret|xai|black.?box|transparen",
  BM=r"benchmark|baseline|compar|empirical")

DESC = dict(
  SE="software task",
  MO="multi-objective/search",
  EX="explanation",
  BM="benchmark/compare")

LEGEND = "; ".join("%s %s" % (k, DESC[k]) for k in FLAGS)
