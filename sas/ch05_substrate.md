# The Substrate

This chapter assembles the pieces: a settings file, two column types, a table, and
two distances. Everything in Parts II to IV is a short function over what this
chapter builds. Total cost so far, including the test rig: under 250 lines.

## about.py, in full

%%file src/about.py

That is the entire configuration system. To say that another way: every experiment in
this book is fully described by (a) this file, (b) any --key=val overrides, and (c)
one seed. When Chapter 16 hands this repository to an AI colleague, that property
will matter a great deal.

## Columns know their jobs

The first csv row names the columns, and the names carry the schema. An uppercase
first letter means numeric. A trailing "+" or "-" marks a goal to maximize or
minimize. A trailing "X" means ignore. Everything else is an observable x column.
This is **CoC** (convention over configuration): the data describes itself, and no
schema file exists to drift out of date. It is also schema *on read*: types come from
data, not declarations.

%%code src/lib.py Tbl

Two details deserve a look. Firstly, `Num` and `Sym` are plain functions returning
`o` structs tagged with an `it` slot, and one `add` serves both. That is duck typing
doing the work inheritance is usually hired for: two types, one protocol (add, mid,
var), no class hierarchy. Secondly, `addRow` folds a row into every column summary
incrementally. The table never recomputes. It only ever updates.

%%run python3 src/lib_eg.py tbl

Read that transcript against the axiom of Chapter 1. The table has 398 rows, and 4 of
its 8 columns are cheap x values while 3 are dear y goals. Everything downstream
respects that boundary: x is free to read, y is metered.

`clone` deserves its one line of fame. Given any table and any subset of rows, it
re-learns a fresh summary over just those rows, using the same header. Clusters, tree
leaves, and sliding windows are all, underneath, clones.

%%code src/lib.py clone

## Distance to heaven

Now the two workhorses. `distx` measures how *different* two rows are, reading only x
columns, normalizing each gap to 0..1 and handling "?" by assuming the worst case (an
unknown value is scored as far away as it could be, which keeps missingness from
faking similarity). `disty` measures how *good* one row is: the distance from its
goal values to heaven, where heaven is 0 for a minimize column and 1 for a maximize
column. Zero is best.

%%code src/lib.py disty

This paragraph is the definition of **distance to heaven**: collapse many objectives
to one scalar by measuring each goal's normalized gap to its ideal, then aggregating
with Minkowski. No weights to tune. All later chapters cite this paragraph rather
than redefine it. Note also what `disty` reads: y columns only. Hence counting calls
to `disty` counts the labels we bought, and every budget claim in this book is
auditable from that one chokepoint.

Sort all 398 cars by `disty` and print the five best, then the five worst:

%%run python3 src/lib_eg.py dist

Notice the shape. Light, late, high-mpg cars float to the top. Big old guzzlers sink.
No learner has run yet. This is just geometry over one table, and already it ranks a
car lot. The whole of Part III is a set of strategies for reaching those top rows
while paying for as few `disty` calls as possible.

## What the substrate buys

Here ends Part I. We close with the claim the next eleven chapters must now earn.
Clustering will be grouping by distx. Nearest-neighbor prediction will be distx with
no fit step. Bayes will be grouping with labels. Trees will be grouping, recursively.
Anomalies will be rows far from their group. Each arrives in roughly twenty lines,
because the hard parts (summaries, normalization, missing values, distance,
statistics) already live here, written once. The good news is that you have now read
the hard parts. The bad news is two-fold: the substrate is dull, and we made you read
it anyway. It was that or repeat it eleven times.

## Lessons sighted

**SSOT** again (about.py, in full, as the experiment
record); **CoC** and schema-on-read via header suffixes;
duck typing, now defined; incremental summaries and
clone; worst-case handling of missing values; **distance
to heaven**, defined above; labels metered at one
chokepoint. Onward to Part II, where the Fortune Teller
takes the first appointment.
