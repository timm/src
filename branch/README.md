# branch

## NAME

branch - actively label a few rows, grow one regression
tree, then prune it every possible way and keep the best
small tree

## SYNOPSIS

    python3 branch-eg.py [--key=val ...] [test ...]

## DESCRIPTION

Labels are dear; trees are cheap. branch spends a small
label budget with an active learner (`acquire`: label
`more` rows per round, project the pool onto the line
joining the best and worst labels, keep the `best`
fraction nearest the good pole), fits a binary regression
tree to the labels' d2h (distance to the ideal goal
point), then walks every pruning of that tree: below each
cut, each side either stays or collapses to a leaf -- four
shapes per cut, up to 4^maxd trees, generated lazily with
shared structure.

Every yielded tree carries at its root the min mean-d2h of
its leaves, so choosing the best pruning is a single min()
over a generator. That winner then sorts the unseen half
of the data; the top `check` rows are bought and the best
kept.

Data is CSV; the header names the columns: an uppercase
first letter means numeric; a trailing `+`/`-` marks a
goal to maximize/minimize; a trailing `X` means ignore.
Cells holding `?` are missing. File paths expand a leading
`$MOOT` (env var, else `~/gits/moot`; data at
tiny.cc/moot).

## OPTIONS

    --file   data file             ($MOOT/optimize/misc/auto93.csv)
    --seed   random seed           (1)
    --budget labeling cap          (50)
    --more   labels per round      (4)
    --best   pool keep fraction    (0.66)
    --cap    acquire pool cap      (1024)
    --leaf   tree min leaf rows    (3)
    --maxd   tree max depth        (4)
    --check  rows checked on test  (5)
    --round  decimals shown        (3)

## TESTS

Run any by bare name, e.g. `python3 branch-eg.py walk`:

    tbl disty acquire tree walk holdout tied compare
    all      the whole course

The stats for comparisons (Cliff's delta, KS, Cohen,
`differ`/`tied`) live in branch-eg.py, not the library.

## FILES

    branch.py     the library: table, disty, acquire,
                  Tree, walk, holdout
    branch-eg.py  tutorial + tests + comparison stats
    REPORT.md     study: prunings as a free model zoo;
                  ROC coverage, fairness for free (RQ1-7)
    fair4.png     the study's one figure (see REPORT.md)

## SEE ALSO

`../ezr-py/` -- the full active-learning system this
distills; `../tiny/` -- the study that showed pruned
spines tie full trees (see tiny/WHY_NO_3.md).

## AUTHOR

Tim Menzies <timm@ieee.org>, MIT license.
