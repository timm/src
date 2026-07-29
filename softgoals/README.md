# re : staggered abductive reasoning over i* goal models

SHORT (Mathew, Menzies, Ernst, Klein; arXiv:1702.05568) redone in
~90 lines of Prolog (nfr2.pl). One eval//2 does both Horn abduction
(H <- Body: choice-or, commit, minimal assumptions) and softgoal
label propagation (G <~ Edges: label all, 5-valued combine), with
the belief set threaded as DCG state. Worlds are ISAMP-style: goals
walked in random order; greedy mode commits each or-choice and
restarts on contradiction instead of backtracking.

    swipl runner2.pl models/CSServices.pl # coverage, 1000 random worlds
    swipl sweep.pl   models/CSServices.pl # baseline: best-of-100, x20
    swipl rank.pl    models/CSServices.pl # key decisions + plateau k*

Models: the paper's 7 i* case studies (Horkoff), compiled from
ai-se/softgoals JSON by j2pl.py: one types(T,[Name,...]) fact per
node type (resource folded into task) plus <- rules and <~
contribution lists. expand.pl unfolds types/2 into node/2 at load
time and derives leaf/1 (no definition) and topgoal/1 (type goal).
About 10ms per random world on the largest (351 node) model.
