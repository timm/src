# rulr

## NAME

rulr - grow one greedy conjunctive rule that finds
near-best rows in multi-objective CSV data

## SYNOPSIS

    python3 rulr-eg.py [--key=val ...] [test ...]

## DESCRIPTION

rulr learns a single rule, a conjunction of column cuts,
by greedy descent with no backtracking. Each round: sort
the rows by disty (distance to the ideal goal point), tag
the top sqrt(n) rows best and the rest rest, ask every x
column for the single (col, value) cut minimizing the
size-weighted entropy of those tags, keep only the rows on
the best side of that cut, and recurse. The rule is the
cuts collected on the way down, e.g.

    Volume <= 90 AND Model > 77 AND Volume > 89

Evaluation is a 50:50 holdout: grow on one half, rank the
unseen half by how many cuts each row matches, buy the top
`check` rows, keep the best. Over 30 datasets and 20
repeats, with 400+ training rows this beats an active
learner spending 50 labels (43-57% wins, under 13%
losses); with 100 or fewer rows, the active learner wins.

Data is CSV; the header names the columns: an uppercase
first letter means numeric; a trailing `+`/`-` marks a
goal to maximize/minimize; a trailing `X` means ignore.
Cells holding `?` are missing. File paths expand a leading
`$MOOT` (env var, else `~/gits/moot`; data at
tiny.cc/moot).

## OPTIONS

    --file   data file             ($MOOT/optimize/misc/auto93.csv)
    --seed   random seed           (1)
    --leaf   min rows to keep going (3)
    --check  rows checked on test  (5)
    --round  decimals shown        (3)

## TESTS

Run any by bare name, e.g. `python3 rulr-eg.py grow`:

    tbl disty entropy cut grow holdout   one seam each
    all                                  the whole course

## FILES

    rulr.py       the library: table, disty, bins, cut, grow
    rulr-eg.py    tutorial + tests (this is the executable doc)

## SEE ALSO

`../ezr-py/` -- the active-learning cousin (trees + sway3
sampling); rulr borrows its data format, disty and its
bins/score shape.

## AUTHOR

Tim Menzies <timm@ieee.org>, MIT license.
