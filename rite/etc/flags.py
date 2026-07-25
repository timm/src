"""Coding vocabulary: the ONE place the per-topic flags
live. code.py (abstracts) and recode.py (full text) both
import from here. New topic: edit this file and
../README.md; touch nothing else.

Two facets. FLAGS = topic (which literature is this paper
in; drives the gap/venn argument). TECH = technology (how
the method works; characterizes the selected papers).
A paper's group is the AND of every flag that fired."""

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

LONG = dict(
  SE="software engineering task (defects, testing, "
     "requirements, code)",
  MO="multi-objective / search-based optimization",
  EX="explanation / interpretability / XAI",
  BM="benchmarking / empirical comparison")

LEGEND = "; ".join("%s %s" % (k, DESC[k]) for k in FLAGS)

TECH = dict(
  EXACT=r"integer program|linear program|constraint "
        r"program|smt|sat solv|milp",
  EVO=r"genetic algorithm|evolution(ary)?|nsga|spea|moea"
      r"|differential evolution",
  SMBO=r"bayesian optimi|gaussian process|surrogate"
       r"|acquisition function|smac|model.based optimi",
  SYM=r"decision tree|rule (list|set|induction)"
      r"|symbolic|logic program|fuzzy",
  AGG=r"scalariz|weighted sum|aggregation function"
      r"|utility function|desirability",
  NN=r"neural|deep learn|transformer|language model|llm")

TECH_LONG = dict(
  EXACT="exact solvers (integer/linear/constraint "
        "programming, SAT/SMT)",
  EVO="evolutionary / genetic / Pareto search "
      "(NSGA, SPEA, MOEA/D)",
  SMBO="sequential model-based optimization (Bayesian, "
       "surrogates, SMAC)",
  SYM="symbolic / rule-based reasoning (trees, rule "
      "lists, logic, fuzzy)",
  AGG="aggregation / scalarization (weighted sums, "
      "utility, desirability)",
  NN="neural methods (deep learning, transformers, LLMs)")
