# re : staggered abductive reasoning over i* goal models

SHORT (Mathew, Menzies, Ernst, Klein; arXiv:1702.05568) redone in
a few pages of Prolog. nfr3.pl is the reference engine: `<--`
clauses stay in the database as data, preprocess/0 compiles each
head, and one belief list threads DCG-style through hard abduction
(choice-or, commit, minimal assumptions) and soft label propagation
(label all, 5-valued combine). Worlds are ISAMP-style: goals walked
in random order; greedy mode commits each or-choice and restarts on
contradiction instead of backtracking. nfr2.pl (+ nfr2-eg.pl) is the
older meta-interpreter, kept as a read-only reference; parity quirks
are documented in nfr3.pl's header.

    swipl runner3.pl models/CSServices.pl # coverage, 1000 random worlds
    swipl sweep.pl   models/CSServices.pl # baseline: best-of-100, x20
    swipl rank.pl    models/CSServices.pl # key decisions + plateau k*

Models: the paper's 7 i* case studies (Horkoff), compiled from
ai-se/softgoals JSON by j2pl.py into the nfr3 dialect: one `<--`
arrow for rules and contribution edges alike (hard vs soft read off
the body shapes), no type declarations. What is not derivable from
structure ships as two goal clauses per model: goals(hard) lists
the type-goal nodes, goals(soft) wraps the type-softgoal nodes in
or([...]). Leaves are derived (referenced, no clauses). About 10ms
per random world on the largest (351 node) model.
