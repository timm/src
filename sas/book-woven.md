# Preface {.unnumbered}

This book makes a wager. We bet that most of what matters
in software engineering, in classic AI, and in day-to-day
Python can be shown, not just told, from one small code
base. The code base is EZR (an incremental active learner
whose conclusions are small decision trees), about 400
lines of Python with no dependencies beyond the standard
library [@menzies26ezr]. Around it we hang 123 lessons.
Many lessons appear more than once, seen from different
heights, so the count of sightings runs past 200.

Every chapter follows the same ritual: (a) set a seed;
(b) run a small program; (c) paste its output, untouched;
(d) end in an assert. Nothing you read here was typed from
memory. The build tool re-runs every example and fails if
the output drifts.^[If you find a transcript in this book
that does not reproduce, that is a bug. Please report it.]

## How to read this book {.unnumbered}

Read Chapter 1, then skip Chapter 2. That chapter places
this book against fifty years of prior work and it will
mean more after you have met the code. Come back to it
late, or never.

Chapters 3 to 5 build the substrate: a little Python, a
little maths, then columns, tables, and distance. All
later chapters stand on these three. After that, each
chapter is one application with a fun name and a serious
bracket (e.g. "The Bouncer (anomaly detection)"). The
bracketed term is the index entry that joins that chapter
to the standard literature. Read the applications in any
order.

You need Python 3.12 or later, curl, and make. You do not
need pip. The number of packages this book installs is
0 + 0 = 0. Example data comes from MOOT (a public
collection of 120+ multi-objective SE optimization
tasks)^[`github.com/timm/moot`; fetched by `make data`.]
and one table runs through most demos: auto93, 398 cars,
where we want to minimize weight while maximizing
acceleration and miles per gallon.

A note on style. We avoid diagrams. Prose, code, and
transcripts carry the whole argument, in the manner of
Seibel's *Practical Common Lisp* [@seibel05]. Also, core
terms are defined exactly once, in one flagged place, and
everywhere else points there.

\part{The Substrate}

# Simple Ain't Stupid

Much recent press says that developers no longer need to
read code. The creator of Node.js suggests the era of
human-written code is ending. Nvidia's CEO advises against
learning to code at all [@menzies26ezr]. The claim behind
the phrasing is always the same: AI is the new compiler,
and nobody reads what a compiler emits.

We disagree. This book is our evidence.

The evidence is 400 lines of Python that implement Naive
Bayes, k-means clustering, decision trees, anomaly
detection, active learning, and multi-objective
optimization on one shared substrate. Tested on 120+
tasks from the MOOT repository, these tiny tools perform
as well as or better than SHAP, LIME, and the SMAC3
optimizer, while running 500 times faster than SMAC3 and
using orders of magnitude fewer labels [@menzies26ezr].
That result was found by reading: years of taking learners
apart, noticing that distant parts of different algorithms
were the same part, and deleting the copies. Reading code
is not nostalgia. It is a research method, and it works.

## The axiom

One economic fact organizes everything that follows.
Tables of data are cheap; *labels* are dear. Anyone can
list 10,000 configuration options. Knowing which one
compiles fastest costs a compile per option. Hence the
question this book asks, over and over: how few labels buy
a good row, plus an explanation of why it is good?

Our running example is auto93: 398 cars, 8 columns. Four
columns are cheap to observe (cylinders, engine volume,
model year, origin). Three are goals we must pay to know:
minimize Lbs-, maximize Acc+ and Mpg+. One (HpX) we
ignore. That is 4 + 3 + 1 = 8. When we say a method is
good, we mean it finds near-best cars after paying for
few labels.

## The ritual

**Every claim in this book can be re-run from a seed, and
any claim that cannot is not in this book.** Each demo (a)
resets the random stream; (b) runs; (c) prints; (d)
asserts. The printed output is captured by the build tool
at build time, so what you read is what the code did, on
the day this book was compiled. Chapter 15 shows the
statistics that police the stronger claims: no "X beats Y"
without effect size and significance agreeing.

We should state failure criteria too, since we demand them
of others. If, on your machine, with our seed, any
transcript in this book fails to reproduce, then our
central claim fails and you should say so, loudly, in
public.

## The map

Part I (Chapters 3 to 5) builds the substrate: cells,
columns, tables, distance. Part II reads the world: six
applications that predict, detect, monitor, diagnose,
triage, and explain. Part III changes the world: eight
applications that optimize, plan, repair, generate,
compress, negotiate, and learn on streams. Part IV earns
trust: certification by statistics, and the onboarding of
an AI colleague. Chapter 2 relates all this to prior work.
Skip it for now.

One convention, used throughout. Where a lesson has a
canonical name, that name appears in bold at first use
(e.g. **SSOT**, single source of truth). Where a lesson
has no canonical name, none is invented. The unnamed ones
are the new ones.

# Before Us (Skip This on First Read)

This chapter has one job: to say what is old here, so that
what is new stands out honestly. It cites much and proves
nothing. Come back after Part II.

## Four crowded neighborhoods

Code with commentary, on one system, has a patron saint:
Lions' commentary on UNIX, the complete Edition 6 source
plus a reading of it, bootlegged for decades and still
used in teaching [@lions77]. Spinellis later made code
reading a discipline of its own [@spinellis03]. We take
from Lions the core structural move: print the system
once, then tour it repeatedly at different altitudes.

Language books with practicals form the second
neighborhood. Norvig's *PAIP* taught classic AI through
small idiomatic Common Lisp programs [@norvig92]. Seibel's
*Practical Common Lisp* taught a language by building a
spam filter, an MP3 database, and other things a reader
might actually want [@seibel05]. Our Part II and Part III
copy Seibel's test directly: every chapter is named for a
want, and the machinery hides behind it.

Small-programs anthologies are the third. *500 Lines or
Less* walks 26 programs by 26 authors, each solving a
canonical problem in under 500 lines [@brown16]. Wilson's
*Software Design by Example* does the same solo
[@wilson22]. These books share our size discipline. They
do not share our substrate: their programs have nothing in
common, so their lessons cannot compose. Ours do, since
every application here reuses the same 400 lines.

Heuristics catalogs are the fourth: Hunt and Thomas
[@hunt99], Glass's facts and fallacies [@glass02],
Ousterhout [@ousterhout18]. These argue by anecdote and
citation. We argue by flag: when this book says "always
keep a baseline", that baseline is one command-line
option away, and you can run the ablation yourself.

Each neighborhood is crowded. Their intersection, as far
as we can tell, is empty. That intersection is this book.

## The grid and the ladder

Buse and Zimmermann once organized software analytics as
a 3-by-3 grid: exploration, analysis, and experimentation
crossed with past, present, and future [@buse12]. It was,
and is, a useful catalog of what managers ask for. Yet we
read the grid differently. Its three rows are the three
rungs of Pearl's ladder of causation: seeing, explaining,
and imagining alternatives [@pearl18]. Its three columns
are a clock. And a clock is a presentation dimension, not
a reasoning one. Chapters 8, 9, and 10 of this book make
that point in code: planning, diagnosis, and repair turn
out to be one tree-difference mechanism pointed at the
future, the past, and the imperative. Time multiplies
interfaces. It does not multiply mechanisms. Hence, in
this book, streaming is a crosscutting section in many
chapters rather than a wing of the taxonomy.

## Tasks, not tenses

For the taxonomy of tasks we reach further back, to
knowledge engineering. Clancey observed that expert
systems mostly perform *heuristic classification*
[@clancey85], and the CommonKADS school cataloged the
task types [@schreiber00]: analysis tasks (predict,
monitor, diagnose, classify, explain) and synthesis tasks
(plan, design, configure, repair). That catalog is
finite. Part II covers the analysis tasks. Part III
covers the synthesis tasks, plus the modern additions
(compress, negotiate, stream). We know of no other short
book that runs the whole KADS catalog on one substrate.

There is one rung the old catalogs lack. Neither the grid
nor the ladder nor KADS has a place for *certification*:
establishing that the seeing and the doing can be trusted
by another person, another runtime, or another kind of
colleague. Buse and Zimmermann tuck significance testing
into a corner cell as a bullet point. We give it Part IV.
The 2026 problem, we will argue, lives on that rung, and
it costs about sixty lines.

## What is actually new

Firstly, the substrate: many seemingly different learners
shown as one grouping idea at different granularities, in
runnable form. Secondly, the receipts: heuristics with
flags and seeds, not heuristics with anecdotes. Thirdly,
the last two chapters: a statistics gate and an
agent-onboarding process, both demonstrated from one
repository's own history. To our knowledge the third item
exists in no prior book at all. That said, it may date
the fastest. We accept the trade.

# A Little Python

This chapter shows the Python that the rest of the book
assumes. Not all of Python. Just the dozen moves that let
400 lines carry twenty algorithms. Readers fluent in the
language should skim the transcripts and move on.

## Cells, and asking forgiveness

Csv cells arrive as strings. One function coerces each
cell: "23" becomes an int, "-1e2" a float (csv cells can
hide exponents), "True" and "False" become bools, "?"
stays as our mark for missing, and anything else stays
text.

```python
def thing(s):
  "Coerce one csv cell: int, float, bool, else string."
  for fn in (int, float):
    try: return fn(s)
    except ValueError: pass
  s = s.strip()
  return {"True": True, "False": False}.get(s, s)
```

Note the shape of the type test. We do not inspect the
string to decide if it is a number. We try the conversion
and catch the failure. Python calls this **EAFP** (easier
to ask forgiveness than permission), as opposed to
**LBYL** (look before you leap). EAFP is shorter here and,
more importantly, it delegates the definition of "looks
like an int" to the one authority that matters, which is
`int` itself.

```
$ python3 src/lib_eg.py thing
[23, 3.14, -100.0, True, False, '?', 'ab']
```

## One struct, one settings object

The whole book uses one generic record type: a class `o`
whose instances are dot-accessible bags of slots, and
whose repr prints those slots sorted.

```python
class o:
  "Dot-access struct. Its repr prints the public slots."
  def __init__(i, **d): i.__dict__.update(**d)
  def __repr__(i):
    return "{" + " ".join(":%s %s" % (k, v)
      for k, v in sorted(i.__dict__.items())
      if k[0] != "_") + "}"
```

Two Python facts do the work: (a) every object carries a
`__dict__` of its slots, so one line of reflection prints
anything; (b) `__repr__` is a protocol, so every object in
this book can appear in a transcript. Also, all settings
live in a single instance called `the`, defined in
about.py and nowhere else. That file is this book's first
sighting of **SSOT** (single source of truth): one place
to look, one place to change.

```
$ python3 src/lib_eg.py the
{:few 128 :file data/auto93.csv :p 2 :seed 1234567891}
```

The command line can override any knob, because the flag
parser walks `vars(the)` and matches names. Watch the same
test, run with `--p=1`:

```
$ python3 src/lib_eg.py the --p=1
{:few 128 :file data/auto93.csv :p 1 :seed 1234567891}
```

No parser was written for that flag. The settings object
is the parser's schema, by reflection. Hence a new knob
costs one line, in one file.

## Streams, sorts, and transposes

Files are read by a generator, so no table is ever loaded
twice or held whole when a stream will do:

```python
def csv(file):
  "Stream a csv file, one row of coerced cells at a time."
  with open(file) as f:
    for line in f:
      line = line.split("%")[0].strip()
      if line:
        yield [thing(s) for s in line.split(",")]
```

The `yield` makes `csv` lazy: callers pull one row at a
time. Later chapters lean hard on this laziness (e.g. the
streaming chapter treats an unbounded source exactly like
a file). Three more idioms appear on nearly every page of
this book, so we test them once here: sorting by a
computed key, never in place; transposing a table with
`zip(*rows)`; and list comprehensions as the default loop.

```
$ python3 src/lib_eg.py idioms
[[3, 30], [2, 20], [1, 10]]
[(1, 3, 2), (10, 30, 20)]
```

## Dispatch by name

Every code file in this book ships with a matching `_eg`
file of demos. Each demo runs by its bare name from the
command line. The trick is four lines of reflection: look
up `"test_" + word` in the module's globals.

```python
def main(g):
  "For each bare command-line word w, run test_w, seeded."
  cli(the.__dict__)
  todo = [s for s in sys.argv[1:]
          if not s.startswith("-")] or ["all"]
  for word in todo:
    random.seed(the.seed)
    g.get("test_" + word,
          lambda: print("?", word, "(no such test)"))()
```

Note that the seed is reset before every test. Hence any
demo reproduces in isolation, in any order, on any
machine. This one habit does more for reproducibility
than any tool we know, and it costs one line.

## Lessons sighted

**EAFP** and **LBYL**; **SSOT**; duck typing (previewed;
defined properly in Chapter 5); generators and laziness;
reflection via `vars` and `globals`; sort-by-key;
`zip(*rows)`; the seeded-demo ritual. Just to repeat a
point made above: none of this is advanced Python. That
is the point. Relentless basics, then one or two sharp
tricks.

# A Little Maths

Six pieces of maths run the whole book: two summaries, a
rescaling, a distance, a random stream, and a trust test.
None needs more than high-school algebra. Each gets a
demo here and a citation for readers who want the long
form.

## Center and spread, one value at a time

For numbers we track the mean and the standard deviation.
For symbols we track counts, then report the mode and the
entropy. The interesting part is *how* the numeric case
updates. The textbook formula for variance wants two
passes and a stored list. Welford's update [@welford62]
wants neither. Keep three slots (n, mu, m2). On each new
value v, let d = v - mu. Then mu moves by d/n, and m2
grows by d times the *new* gap (v - mu). The standard
deviation is (m2 / (n - 1)) raised to 0.5, on demand.

```python
def add(col, v, inc=1):
  "Fold v into col; inc=-1 unfolds it. Returns v."
  if v != "?":
    col.n += inc
    if col.it is Sym:
      col.has[v] = inc + col.has.get(v, 0)
    else:
      col.lo, col.hi = min(v, col.lo), max(v, col.hi)
      if inc < 0 and col.n < 2:
        col.mu = col.m2 = col.n = 0
      else:
        d       = v - col.mu
        col.mu += inc * d / col.n
        col.m2 += inc * d * (v - col.mu)
  return v
```

One pass. No stored raws. Constant memory. Also, look at
the `inc` argument: the same code run with inc = -1 makes
the summary *forget* a value. Chapter 13 builds sliding
windows from nothing but that minus sign. Here is add and
its inverse, round-tripping to nine decimals:

```
$ python3 src/lib_eg.py unadd
mu 9.948 sd 2.215 (before: 9.948 2.215)
```

## Entropy is just counting

For a bag of symbols with counts k out of n, the entropy
is the sum over symbols of -(k/n) log2 (k/n). It measures
surprise: how many yes-or-no questions, on average, to
name the next symbol. Take the bag "aaaabbc", so n = 7
and the counts are 4, 2, 1. The three terms are
-(4/7) log2 (4/7) = 0.461, -(2/7) log2 (2/7) = 0.516, and
-(1/7) log2 (1/7) = 0.401. Their sum is 0.461 + 0.516 +
0.401 = 1.379 bits.^[Purists will note we never round
away the working. House rule.] The demo checks that
arithmetic, then checks Welford against 10,000 samples
from a unit gaussian:

```
$ python3 src/lib_eg.py cols
sym mid a ent 1.379
num mu 0.007 sd 1.002
```

## Nothing is comparable until it is 0..1

In auto93, weight runs in the thousands of pounds while
acceleration runs in the tens of seconds. Any distance
computed on raw values would be a weight measure wearing
a distance costume. Hence, before comparing, every number
is mapped to 0..1 by its column's seen range: (v - lo) /
(hi - lo). A tiny epsilon in the denominator guards the
degenerate column whose lo equals its hi. Numerical
hygiene of that kind (a TINY here, a max(m2, 0) there) is
not fussiness. It is where AI code goes to die, quietly.

## One distance, three classics

With every gap scaled to 0..1, we aggregate gaps by the
Minkowski formula: the p-th root of the mean of the p-th
powers [@menzies26ezr]. One knob, three famous distances:
p = 1 is city-block, p = 2 is Euclidean, and large p
approaches Chebyshev (the max gap wins). For two gaps of
0.3 and 0.4 at p = 2, that is ((0.09 + 0.16) / 2) ^ 0.5 =
(0.125) ^ 0.5 = 0.354.

```python
def minkowski(ds):
  "Aggregate several 0..1 gaps into one (see the.p)."
  ds = list(ds)
  return (sum(d ** the.p for d in ds)
          / (len(ds) + TINY)) ** (1 / the.p)
```

## Random streams are lab equipment

Every stochastic demo in this book starts by seeding the
random stream, so every transcript reproduces. Treat the
generator as lab equipment: calibrated, logged, reset
between experiments. When we later port code across
languages, we will go further and use Lehmer's portable
generator with multiplier 16807, which is 7 * 7 * 7 * 7 *
7 = 16807, i.e. 7^5 [@park88]. Same seed, same stream, in
every language. Five printed draws then certify a port
before any learner runs.

## The trust test

Later chapters keep saying "X beats Y". Such talk is
cheap, so we tax it. Two lists of results are called the
same unless three tests all agree they differ: Cohen's
rule (means closer than 0.35 pooled standard deviations
are the same) [@cohen88], Cliff's delta (rank overlap
above the 0.197 threshold is the same) [@cliff93;
@hess04], and Kolmogorov-Smirnov (cdf gap under the 5%
critical value 1.36 sqrt((n + m) / nm) is the same)
[@massey51]. Watch the conjunction work on a gaussian
nudged by ever-larger shifts. A shift of 0.1 standard
deviations passes as same. From 0.3 on, the tests call
it different:

```
$ python3 src/lib_eg.py stats
shift  same   cliffs cohen
 +0.0  True   0.00   True
 +0.1  True   0.11   True
 +0.3  False  0.21   True
 +0.5  False  0.34   False
 +1.0  False  0.56   False
 +2.0  False  0.82   False
```

Note the humility this buys. Any single test can be
gamed, and p-values alone say nothing about effect size.
Demanding agreement from an effect-size test and a
distribution test before crying "difference" makes our
later victory claims conservative. When this book says
"beats", it has cleared all three bars.

## Lessons sighted

Welford's one-pass update; reversible summaries; entropy
as counted surprise; min-max normalization and epsilon
hygiene; the Minkowski family; seeds as lab equipment
(with **PRNG** portability via 7^5); and the conjunctive
trust test. That last one is this book's referee. It sits
in the substrate, before any learner, on purpose.

# The Substrate

This chapter assembles the pieces: a settings file, two
column types, a table, and two distances. Everything in
Parts II to IV is a short function over what this chapter
builds. Total cost so far, including the test rig: under
250 lines.

## about.py, in full

```python
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
```

That is the entire configuration system. To say that
another way: every experiment in this book is fully
described by (a) this file, (b) any --key=val overrides,
and (c) one seed. When Chapter 16 hands this repository
to an AI colleague, that property will matter a great
deal.

## Columns know their jobs

The first csv row names the columns, and the names carry
the schema. An uppercase first letter means numeric.
A trailing "+" or "-" marks a goal to maximize or
minimize. A trailing "X" means ignore. Everything else is
an observable x column. This is **CoC** (convention over
configuration): the data describes itself, and no schema
file exists to drift out of date. It is also schema *on
read*: types come from data, not declarations.

```python
def Tbl(src):
  "First row names the columns; the rest are data."
  src   = iter(src)
  names = next(src)
  cols  = [(Num if s[0].isupper() else Sym)(at, s)
           for at, s in enumerate(names)]
  tbl   = o(it=Tbl, names=names, cols=cols, rows=[],
            x=[c.at for c in cols
               if c.name[-1] not in "X+-"],
            y=[c.at for c in cols if c.name[-1] in "+-"])
  for row in src: addRow(tbl, row)
  return tbl
```

Two details deserve a look. Firstly, `Num` and `Sym` are
plain functions returning `o` structs tagged with an `it`
slot, and one `add` serves both. That is duck typing
doing the work inheritance is usually hired for: two
types, one protocol (add, mid, var), no class hierarchy.
Secondly, `addRow` folds a row into every column summary
incrementally. The table never recomputes. It only ever
updates.

```
$ python3 src/lib_eg.py tbl
rows 398 |x| 4 |y| 3
Mpg+ mu 23.84 sd 8.34
```

Read that transcript against the axiom of Chapter 1. The
table has 398 rows, and 4 of its 8 columns are cheap x
values while 3 are dear y goals. Everything downstream
respects that boundary: x is free to read, y is metered.

`clone` deserves its one line of fame. Given any table
and any subset of rows, it re-learns a fresh summary over
just those rows, using the same header. Clusters, tree
leaves, and sliding windows are all, underneath, clones.

```python
def clone(tbl, rows=[]):
  "A fresh table with the same header; optionally refill."
  return Tbl([tbl.names] + rows)
```

## Distance to heaven

Now the two workhorses. `distx` measures how *different*
two rows are, reading only x columns, normalizing each
gap to 0..1 and handling "?" by assuming the worst case
(an unknown value is scored as far away as it could be,
which keeps missingness from faking similarity). `disty`
measures how *good* one row is: the distance from its
goal values to heaven, where heaven is 0 for a minimize
column and 1 for a maximize column. Zero is best.

```python
def disty(tbl, row):
  "Distance from a row's goals to heaven; 0=best, 1=worst."
  return minkowski(abs(norm(c, row[c.at]) - c.heaven)
                   for c in (tbl.cols[a] for a in tbl.y)
                   if row[c.at] != "?")
```

This paragraph is the definition of **distance to
heaven**: collapse many objectives to one scalar by
measuring each goal's normalized gap to its ideal, then
aggregating with Minkowski. No weights to tune. All
later chapters cite this paragraph rather than redefine
it. Note also what `disty` reads: y columns only. Hence
counting calls to `disty` counts the labels we bought,
and every budget claim in this book is auditable from
that one chokepoint.

Sort all 398 cars by `disty` and print the five best,
then the five worst:

```
$ python3 src/lib_eg.py dist
Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
     4      97   52     82       2  2130  24.6    40  0.167
     4      90   48     80       2  2335  23.7    40  0.190
     4      90   48     78       2  1985  21.5    40  0.193
     4      90   48     80       2  2085  21.7    40  0.195
     4      85   65     81       3  1975  19.4    40  0.242

     8     429  198     73       1  4952  11.5    10  0.917
     8     383  180     71       1  4955  11.5    10  0.917
     8     440  215     70       1  4312   8.5    10  0.918
     8     455  225     73       1  4951    11    10  0.926
     8     400  175     71       1  5140    12    10  0.927
```

Notice the shape. Light, late, high-mpg cars float to the
top. Big old guzzlers sink. No learner has run yet. This
is just geometry over one table, and already it ranks a
car lot. The whole of Part III is a set of strategies for
reaching those top rows while paying for as few `disty`
calls as possible.

## What the substrate buys

Here ends Part I. We close with the claim the next eleven
chapters must now earn. Clustering will be grouping by
distx. Nearest-neighbor prediction will be distx with no
fit step. Bayes will be grouping with labels. Trees will
be grouping, recursively. Anomalies will be rows far from
their group. Each arrives in roughly twenty lines,
because the hard parts (summaries, normalization,
missing values, distance, statistics) already live here,
written once. The good news is that you have now read the
hard parts. The bad news is two-fold: the substrate is
dull, and we made you read it anyway. It was that or
repeat it eleven times.

## Lessons sighted

**SSOT** again (about.py, in full, as the experiment
record); **CoC** and schema-on-read via header suffixes;
duck typing, now defined; incremental summaries and
clone; worst-case handling of missing values; **distance
to heaven**, defined above; labels metered at one
chokepoint. Onward to Part II, where the Fortune Teller
takes the first appointment.
