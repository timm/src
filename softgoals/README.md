# re : staggered abductive reasoning over i* goal models

SHORT (Mathew, Menzies, Ernst, Klein; arXiv:1702.05568) redone as ~60
lines of Prolog. A meta-interpreter tries clauses in random order
(setof + random + clause/2), so SLD resolution itself does ISAMP-style
random worlds generation. Keys found via best/rest ranking (Fig 8) and
KEYS2-style doubling eras with early stop (Fig 9).

    swipl -g gay2   models/KidsandYouth.pl short.pl   # find the keys
    swipl -g report models/CSServices.pl   short.pl   # f1/f2 + keys%

Models: the paper's 7 i* case studies (Horkoff), compiled from
ai-se/softgoals JSON to facts by j2pl.py. edge(Src,Dst,W) with
W in {1, 0.5, -0.5, -1} = make/help/hurt/break (Fig 3).
Runs in ~1 sec/model on one 2.8GHz core. Caveat: and-decompositions
treated as weight-1 edges; see chat notes.
