<a name="contents"></a>
# tut.md — Ten Lectures on Data-Lite AI, at the REPL

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license.

*Build: 2026-08-07 — trace numbers below come from this build.*

Ryan Dahl says the era of human-written code is ending. Jensen
Huang advises the young against learning to code. The new orthodoxy:
nobody reads programs anymore — fly over the details, let the machine
drive. This course disagrees by demonstration. We read five short Lua
files, a few hundred lines each, carefully, at the REPL — and out
falls a toolkit that summarizes data, draws explainable trees, spots
anomalies, sorts options by many goals at once, and optimizes under
label budgets that would bankrupt fancier methods.

Some numbers, to set the stakes. The sample table here holds 398 cars
scored on three competing goals (lighter, quicker, thirstier-or-not).
The active learner in Lecture 8 ranks an unseen half of the data
after buying only ~50 labels — and beats random selection. In
Lecture 10 the optimizer drives an external model whose rows are born
unlabelled (`"?"`): a label is computed only when a row is actually
examined, because in the real world one label can cost a lab run.
Moral, and course thesis: every learner is a falsifiable bet about
the shape of your problem, and a few hundred readable lines are
enough to run the experiment yourself.

The mechanics: numbered REPL events (`[1]>` onward), every one
executed against the real code by a replay harness — outputs shown
are real, never retyped. A language appendix (numbered from `[1000]>`)
teaches the Lua the sources use. Each lecture mixes lab blocks
(prompts + a check question) with woven theory, and ends with
exercises that reuse its prompts by number. One thread runs through
all ten: reasoning from small samples — what they show, what they
hide, how far to trust them.

**Homework, standing assignment.** Reimplement this system in a
language of your choice (Python recommended), paced by the lectures:
by the end of week *k*, your program reproduces every REPL event
through that lecture's range. The RNG is a portable 10-line
Park-Miller generator (`rand` in `ezr-lib.lua`), so a correct port
prints the SAME numbers shown here — grading is diff. Match table
contents exactly; match floats to the printed precision.

**Setup** (Lecture 1 walks through this):

    git clone http://github.com/timm/src
    cd src/ezr-lua
    lua -i ezr-eg.lua        # an interactive REPL, code preloaded

To replay a lecture's inputs and regenerate its trace:

    EZR=$(pwd) lua etc/tut/repl.lua etc/tut/l1.in 1

| # | Lecture | REPL | Ideas |
|---|---------|------|-------|
| [1](#l1)  | Orientation & columns      | 1–16    | NOIR, WEL, CDF, LOG |
| [2](#l2)  | Tables, roles, forgetting  | 17–36   | ROLE, STREAM |
| [3](#l3)  | Distance & gap-to-heaven   | 37–53   | MINK, D2H, PARETO |
| [4](#l4)  | Clustering by poles        | 54–69   | POLE, FASTMAP, HALVE |
| [5](#l5)  | Discretization & cuts      | …       | ENT, CUT, IG |
| [6](#l6)  | Trees & XAI                | …       | CART, XAI |
| [7](#l7)  | Active learning / acquire  | …       | ACQ, AL, BO |
| [8](#l8)  | The holdout rig            | …       | HOLD, WIN |
| [9](#l9)  | Statistics                 | …       | COHEN, KS, CLIFF, SAME, SK |
| [10](#l10)| Apps, then DTLZ (advanced) | …       | KNN, ANOM, NB, KM, DTLZ |
| [quiz](#quiz)     | Revision guide (gated questions) | | |
| [answers](#answers) | Worked answers               | | |
| [glossary](#glossary) | Acronyms & terms           | | |
| [appendix](#appendix) | Lua-101                    | 1000–  | |
| [refs](#refs)     | References                       | | |

*(REPL ranges fill in as lectures land; this is an in-progress build.)*

---

<a name="l1"></a>
# Lecture 1: Orientation & columns

You cannot reason about data you have not summarized. This lecture
opens the toolkit's front door: read a CSV into a table, let each
column decide whether it is a number or a symbol from its own name,
and watch four one-line summaries — center, spread, and a
cumulative-position score — fall out of a handful of lines. Nothing
here is deep. Everything here is load-bearing: every later lecture
stands on these columns.

**Where this bites.** A 2020 survey of data scientists (Anaconda,
*State of Data Science*) put ~45% of working time on data
loading and cleaning, before any modeling. The cheapest bug in the
building is a column read as the wrong type — a ZIP code averaged, a
label summed. So the first design decision in this code is: a column
knows its own kind, from its name, before it sees a single value.

## 1.1 Settings live in one table

Every knob lives in `the`, parsed once from the help string. Reading
`the.seed` before any random call, and reseeding from it, is how a
run becomes reproducible — the whole point of the homework diff.

    the = The(help)      -- in ezr-lib.lua
    function srand(n) Seed = floor(n or 1234567891) % 2147483647 ...

```
[1]> srand(the.seed);
[2]> the.seed
1234567891
[3]> the.file
auto93.csv
```

> **NOIR — the scales of measurement.** Stevens (1946) split data
> into Nominal, Ordinal, Interval, Ratio. This code keeps the
> cut that matters for arithmetic: symbols (Nominal — a mode, a
> count) versus numbers (Ratio — a mean, a spread). A column's role
> is fixed before data arrives, so no symbol is ever averaged.

**Check.** After `[1]`, why does `the.seed` still print the same
number on your machine as on mine? (What did `[1]` guarantee?)

## 1.2 Read a table; row 1 is the header

`Tbl` folds a CSV stream into fresh columns. The first row names the
columns; every later row is coerced cell-by-cell and summarized.

    function Tbl(src)
      src = iter(src)
      return adds(src, new(TBL, {rows={}, mid=nil,
                                 cols=Cols(src())})) end

```
[4]> t = Tbl(csv())
[5]> #t.rows
398
[6]> show(t.cols.names)
{Clndrs Volume HpX Model origin Lbs- Acc+ Mpg+}
```

Read the header: 398 cars, eight columns. The names carry meaning we
decode next.

**Check.** `[5]` counts rows *after* the header. If the file has 399
lines, why does `#t.rows` print 398?

## 1.3 Roles are read from the names

A trailing `+` or `-` marks a goal (maximize / minimize); `!` marks a
class; an `X` suffix means "ignore"; anything else is an ordinary
input feature. `Cols` sorts the header into `x` (inputs) and `y`
(goals) once, so no later code re-parses names.

    if s:find"!$" then klass = all[at]
    elseif s:find"[+-]$" then y[#y+1] = all[at]
    elseif s:sub(-1) ~= "X" then x[#x+1] = all[at] end

```
[7]> show(map(t.cols.y, function(c) return c.name end))
{Lbs- Acc+ Mpg+}
[8]> show(map(t.cols.x, function(c) return c.name end))
{Clndrs Volume Model origin}
```

Three goals, and they conflict: a car cannot always be light, quick,
AND economical. Holding several goals at once is the whole problem of
Lectures 3 and 10. Note `HpX` is absent from both lists — its `X`
suffix says "ignore me."

**Check.** From `[7]`/`[8]`, which columns would a change to `Mpg+`'s
name (say, to `MpgX`) move, and into which list?

## 1.4 A Num summarises a numeric column, in one pass

`NUM.add` keeps a running mean and a running sum-of-squared-deviations
with no stored list — Welford's method. `mid` returns the mean; `div`
the standard deviation.

    function NUM.add(i,v,inc,   d)
      i.n = i.n + inc; d = v - i.mu
      i.mu = i.mu + inc * d / i.n
      i.m2 = i.m2 + inc * d * (v - i.mu); return v end

```
[9]> n = adds{2,4,4,4,5,5,7,9}
[10]> show{mu=n:mid(), sd=round(n:div())}
{:mu 5 :sd 2.14}
```

> **WEL — Welford's online variance.** Welford (1962) computes
> variance in one pass, updating mean and `m2` per value, never
> storing the data. It matters here twice: streaming tables that
> never hold history, and the forgetting trick of Lecture 2, where
> the same recurrence run backwards *removes* a row.

**Check.** `[10]` shows sd ≈ 2.14 for those eight numbers without a
second pass over them. Which field carries the information a second
pass would need, and what does `add` do to it each call?

## 1.5 A Sym summarises a symbolic column

Symbols cannot be averaged. `SYM.mid` returns the mode (commonest
value); `SYM.div` returns entropy — the spread of a distribution with
no arithmetic mean.

```
[11]> s = adds({"a","a","a","b","b","c"}, Sym())
[12]> s:mid()
a
[13]> round(s:div())
1.46
```

> **ENT — Shannon entropy.** Shannon (1948) measures a symbol
> distribution's disorder as −Σ p·log₂p, in bits. Here it is a
> symbol column's "spread," standing in for the standard deviation a
> mode cannot supply. A pure column scores 0; a uniform one scores
> log₂(k). Lecture 5 minimizes it to find good splits.

**Check.** Three `a`, two `b`, one `c` gives entropy ≈ 1.46 bits.
Without recomputing, will adding a fourth `a` raise or lower it, and
why?

## 1.6 norm maps a value to its position, 0..1

To compare a weight against an acceleration you first put both on a
common 0..1 scale. `NUM.norm` pushes a value through a logistic
squashing of its z-score — a smooth cumulative-position score that
never quite hits 0 or 1 and shrugs off outliers (the z is clamped to
±3).

    function NUM.norm(i,v,   z)
      z = (v - i.mu) / (i:div() + TINY)
      return 1 / (1 + exp(-1.702 * max(-3, min(3, z)))) end

```
[14]> round(n:norm(2))
0.08
[15]> round(n:norm(5))
0.5
[16]> round(n:norm(9))
0.96
```

The mean (5) lands at 0.5, low values near 0, high near 1.

> **CDF / LOG — cumulative position via a logistic.** A cumulative
> distribution function reports the fraction of a population at or
> below a value. This code approximates the normal CDF with a
> logistic curve (the 1.702 constant matches the two within ~1%),
> giving every column a shared 0..1 ruler for the distances of
> Lecture 3.

**Check.** `[15]` puts the mean at exactly 0.5. Why must ANY
cumulative-position score send the mean of a symmetric column there?

## Recap

REPL events covered: 1–16. A column knows its kind from its name
([NOIR](#glossary)); numbers summarize in one streaming pass
([WEL](#glossary)) as mean and sd; symbols summarize as mode and
entropy ([ENT](#glossary)); `norm` puts any value on a shared 0..1
ruler ([CDF](#glossary)/[LOG](#glossary)). Next lecture folds these
columns into whole tables that can also *forget*.

**Coming attraction.** By Lecture 6 these summaries grow an
explainable tree you can print at the shell:

    lua ezr-eg.lua --show

**Exercises.**
1. Rerun `[9]`–`[10]` with `adds{2,4,4,4,5,5,7,90}` (a 9 to a 90).
   Which moves more, `mid` or `div`, and why does WEL make that
   cheap?
2. Predict `n:norm(5)` before running `[15]` for the list in
   exercise 1 — is it still 0.5? Explain from the definition of the
   mean.
3. Build a `Sym` of ten values that scores entropy 0, and one that
   scores the maximum for its number of distinct keys. State both
   before checking with `[13]`-style calls.
4. **Field trip.** Load `auto93.csv` yourself (`[4]`) and print
   `t.cols.x[1]` — read its `mu` and `n`. How many cylinders does the
   average car in this file have?

[contents](#contents)

---

<a name="l2"></a>
# Lecture 2: Tables, roles, forgetting

Lecture 1 summarized single columns. Now we fold columns into a whole
table that keeps its rows, reports a centroid, and — the surprising
part — can *forget* a row as cheaply as it learned it. Forgetting is
not a party trick: it is what lets a model slide a window over a
stream, or undo a trial move during search, without ever rebuilding
from scratch.

**Where this bites.** Fraud and click-stream models age fast: last
month's normal is this month's anomaly. Teams that retrain nightly on
the full history pay for data they mean to expire. A summary that
subtracts as easily as it adds turns "retrain" into "forget the old
tail" — O(1) per row, not O(n).

## 2.1 A table is columns plus rows

Rebuilding in a fresh process (every lecture starts clean — so must
your port). `TBL.add` files each row and updates every column
summary; `#t.rows` counts the data past the header.

```
[17]> srand(the.seed);
[18]> t = Tbl(csv())
[19]> #t.rows
398
```

**Check.** Why does re-issuing `srand(the.seed)` at the top of every
lecture matter for the homework diff, even in a lecture with no
visible random call yet?

## 2.2 The centroid: every middle at once

`mids` maps `mid` over all columns — the mean of each number, the
mode of each symbol — giving the table's center in one row.

    function TBL.mids(i)
      i.mid = i.mid or map(i.cols.all, "mid"); return i.mid end

```
[20]> show(t:mids())
{5.46 193.43 104.47 76.01 1 2970.42 15.57 23.84}
```

The average car: 5.46 cylinders, 2970 lbs, 23.8 mpg. Column 5
(`origin`) is symbolic, so its "middle" is the mode, 1.

> **ROLE — features versus goals.** A supervised table splits
> columns into inputs (x) and outputs/goals (y). Keeping the split in
> the header — not in separate files — means every row carries its
> own labels-in-waiting, and any column can be read as either without
> a schema change. Lecture 3 scores rows by their y-columns alone.

**Check.** In `[20]`, which of the eight numbers is a mode rather
than a mean, and how could you tell from Lecture 1's `[8]` alone?

## 2.3 clone: same header, empty summaries

`clone` makes a new table with identical column roles but no rows —
the workhorse for splitting data (trees, holdouts, clusters) without
re-reading names or re-deciding types.

```
[21]> u = t:clone()
[22]> #u.rows
0
[23]> show(u.cols.names)
{Clndrs Volume HpX Model origin Lbs- Acc+ Mpg+}
```

**Check.** A clone starts with zero rows but full column structure.
Why is that exactly what a tree node needs when it splits its rows in
two (Lecture 6)?

## 2.4 Forgetting a Num, with Welford run backwards

The same recurrence that added a value ([WEL](#glossary), Lecture 1)
runs in reverse to remove one. `NUM.__sub` subtracts a whole
sub-summary: build A+B, subtract B, recover A.

    function NUM.__sub(i,j,   n,d)  -- tot - part -> new NUM
      n = i.n - j.n; d = j.mu - i.mu
      return new(NUM, {n=n, mu=(i.n*i.mu - j.n*j.mu)/n, ...})

```
[24]> a = adds{1,2,3,4,5}
[25]> b = adds{10,20,30}
[26]> ab = adds({10,20,30}, adds{1,2,3,4,5})
[27]> show{mu=ab.mu, n=ab.n}
{:mu 9.38 :n 8}
[28]> back = ab - b
[29]> show{mu=back.mu, sd=round(back:div())}
{:mu 3 :sd 1.58}
```

`back` recovers A's mean (3) and spread (1.58) exactly, having never
stored A's five numbers — only the combined summary and B's.

> **STREAM — subtractable summaries.** A summary is *invertible* when
> removing a datum costs the same as adding it. Welford's mean/m2
> pair qualifies; a stored median does not. Invertibility is what
> makes the tree of Lecture 6 cheap: moving a row across a split
> updates two summaries by ±1, never a rescan.

**Check.** `[29]` recovers A without A's data. What two summaries did
it subtract, and why could you NOT do this if `div` had stored the
raw list instead of `m2`?

## 2.5 Add fifty rows, then forget them

The whole-table version: `TBL.sub` folds a row out of every column
(and drops it from `rows`). Add 50 sampled rows to column 1, then
subtract them — the count and mean return to exactly where they
began.

```
[30]> c = t.cols.all[1]
[31]> show{n=c.n, mu=round(c.mu)}
{:mu 5.46 :n 398}
[32]> xtra = some(t.rows, 50)
[33]> for _,r in ipairs(xtra) do t:add(r) end
[34]> show{n=c.n, mu=round(c.mu)}
{:mu 5.46 :n 448}
[35]> for _,r in ipairs(xtra) do t:sub(r) end
[36]> show{n=c.n, mu=round(c.mu)}
{:mu 5.46 :n 398}
```

Watch `n`: 398 → 448 → 398. The mean is stable because we re-added
rows already like the population; the *count* is the honest witness
that add and subtract are true inverses.

**Check.** The mean printed 5.46 at all three steps. Why is `n` (not
`mu`) the trustworthy evidence that `sub` truly undid `add` here?
Design a two-line change to `[32]` that would make `mu` move visibly.

## Recap

REPL events covered: 17–36. Tables fold Lecture 1's columns
([ROLE](#glossary)) and report a centroid; `clone` copies structure
without data; and invertible summaries ([STREAM](#glossary), built on
[WEL](#glossary)) let a table forget a row as cheaply as it learned
it. Next: distance — turning these columns into a ruler between any
two rows, and a single "how good" score across all the goals at once.

**Coming attraction.** Forgetting is the engine under the anomaly
detector of Lecture 10:

    lua ezr-apps.lua --detect

**Exercises.**
1. Rerun `[24]`–`[29]` with `b = adds{10,20,30,40}`. Does `back`
   still recover A exactly? Why is the answer independent of B's
   contents?
2. After `[33]`, print `#t.rows` as well as `c.n`. Confirm both grew
   by 50; then predict both after `[35]`.
3. Modify `[32]` to `xtra = some(t.rows, 50)` from only the heaviest
   cars (hint: `keysort` by `Lbs-`), re-run add/sub, and explain why
   `mu` now dips then returns.
4. **Field trip.** Compute the centroid `[20]` of just the first 100
   rows (`t:clone(sub(t.rows,1,100))`) and compare Mpg+ to the full
   table. Are early rows thirstier or leaner?

[contents](#contents)

---

<a name="l3"></a>
# Lecture 3: Distance & gap-to-heaven

Two rows, eight columns of mixed types — how far apart are they? And
the harder question this whole course turns on: given three goals
that fight each other, how *good* is a single row? This lecture builds
one ruler for inputs (`distx`) and one for goals (`disty`), and the
second is the quiet star: a single 0..1 number that says how close a
row sits to the unreachable best on every goal at once.

**Where this bites.** Buying a car, you juggle price, mileage, and
reliability; no listing wins them all. Ranking by any single column
lies. The multi-goal score here is the same tool a cloud team uses to
pick an instance type (cost vs latency vs memory) — it collapses a
Pareto trade-off into one sortable key, without pretending the
trade-off is gone.

## 3.1 A gap between two values, 0..1

Each column type defines its own `dist`. Symbols: 0 if equal, 1 if
not. Numbers: the absolute gap between the two values' normalized
positions ([CDF](#glossary), Lecture 1), so a spread-aware distance
falls in 0..1.

    function NUM.dist(i,a,b)
      a, b = i:norm(a), i:norm(b); return abs(a - b) end

```
[39]> c = t.cols.all[1]
[40]> c:dist(4, 4)
0.0
[41]> round(c:dist(4, 8))
0.74
```

Four cylinders to eight is most of the way across this column's
range.

**Check.** `[40]` is 0 and `[41]` is 0.74. Why can a numeric `dist`
never exceed 1, given how `norm` bounds each value?

## 3.2 Minkowski folds column gaps into one

`minkowski` is the p-norm mean of the per-column gaps; `distx` applies
it over the input columns only. With `the.p = 2` it is ordinary
Euclidean distance, averaged so the result stays in 0..1 whatever the
column count.

    function minkowski(cols,f,   d,n)
      d,n = 0,TINY
      for _,c in ipairs(cols) do n,d = n+1, d + f(c)^the.p end
      return (d/n)^(1/the.p) end

```
[42]> the.p
2
[43]> round(t:distx(t.rows[1], t.rows[1]))
0
[44]> round(t:distx(t.rows[1], t.rows[2]))
0.04
[45]> round(t:distx(t.rows[1], t.rows[398]))
0.82
```

Row 1 to itself is 0; to its neighbor, 0.04; to the last row, 0.82.
The ruler behaves.

> **MINK — the Minkowski distance.** Minkowski's p-norm unifies a
> family: p=1 is Manhattan (city blocks), p=2 is Euclidean (straight
> line), p→∞ is Chebyshev (the single worst gap). `the.p` is one
> knob that reshapes every distance, cluster, and tree downstream —
> the first falsifiable bet: *Euclidean geometry fits this data*,
> falsified when a p-sweep changes who is nearest whom.

**Check.** Set `the.p = 1` and predict whether `[45]` rises or falls
before running it. (Hint: how does averaging `f(c)^p` then taking the
p-th root treat one large gap as p grows?)

## 3.3 disty: the distance to heaven

Every goal column knows its `heaven` — 1 for a `+` goal (maximize),
0 for a `-` goal (minimize). `disty` normalizes each goal, measures
its gap to that column's heaven, and Minkowski-folds those gaps. Zero
means "best possible on every goal at once."

    function TBL.disty(i,row)
      return minkowski(i.cols.y, function(y)
               return abs(y:norm(row[y.at]) - y.heaven) end) end

```
[46]> round(t:disty(t.rows[1]))
0.79
```

Row 1 sits 0.79 from heaven — a poor all-rounder.

> **D2H / PARETO — one score for many goals.** A solution is
> Pareto-optimal when no other beats it on every goal at once; the
> Pareto front is the set of such solutions, and reading it is the
> whole task of multi-objective work. "Distance to heaven" projects
> that front onto a single axis: the gap to an ideal corner that no
> real row reaches. It cannot show every trade-off a full front does
> — but it makes rows *sortable*, which is what Lectures 7–10 need.

**Check.** `disty` uses only the y-columns. Two cars with identical
weight, acceleration, and mpg but different engines get the same
`disty`. Why is that correct for ranking, and when might it hide
something you care about?

## 3.4 Sort the whole table by goodness

`Y` hands `disty` back as a plain key function, so `keysort` lines
every row up best-first. The extremes tell the story.

```
[47]> d = t:Y()
[48]> rows = keysort(t.rows, d)
[49]> round(d(rows[1]))
0.07
[50]> show(map(t.cols.y, function(c) return c.name end))
{Lbs- Acc+ Mpg+}
[51]> show(sub(rows[1], 6, 8))
{1985 21.5 40}
[52]> round(d(rows[#rows]))
0.96
[53]> show(sub(rows[#rows], 6, 8))
{4951 11 10}
```

The best car (`disty` 0.07): 1985 lbs, 21.5 s to speed, 40 mpg —
light, quick, economical. The worst (0.96): 4951 lbs, 11, 10 mpg —
heavy, sluggish, thirsty. One number sorted 398 cars across three
fighting goals, and the ends are exactly who you would pick and
reject by hand.

**Check.** `rows[1]` scores 0.07, not 0. What would a `disty` of
exactly 0 require of a row, and why does no real car in this file
reach it?

## Recap

REPL events covered: 37–53. Per-column `dist` becomes a whole-row
ruler through [MINK](#glossary); goal columns fold into a single
gap-to-heaven score ([D2H](#glossary)/[PARETO](#glossary)) that sorts
every row best-first. This one sortable key is the foundation for
clustering (Lecture 4), active learning (Lecture 7), and the whole
optimization story.

**Coming attraction.** `disty` is the compass the optimizer follows:

    lua ezr-eg.lua --disty

**Exercises.**
1. Rerun `[44]`/`[45]` with `the.p = 1`, then `the.p = 4`. Tabulate
   how the near and far distances shift, and say which p most
   separates near from far here.
2. Print `disty` for `rows[199]` (a median car). Is it near 0.5?
   Explain why the median of a `disty` sort need not score 0.5.
3. Flip `Acc+` to `Acc-` in a copy of the header names and rebuild.
   Which car now leads the `[48]` sort, and why did heaven move?
4. **Field trip.** `keysort` all 398 cars by `disty` and print the
   top 5's `Mpg+`. Do the best-overall cars also top mpg alone, or
   does the multi-goal score reward a compromise?

[contents](#contents)

---

<a name="l4"></a>
# Lecture 4: Clustering by poles

Distance (Lecture 3) lets us group rows that resemble each other —
without labels, without a grid search. The trick here is cheap: don't
compare every row to every other (that is O(n²)); find two far-apart
rows (poles) and project everyone onto the line between them. Recurse,
and a whole clustering tree falls out of nothing but `distx`.

**Where this bites.** Customer segmentation, image-patch grouping,
log triage — all start by carving a big undifferentiated pile into a
few coherent groups. Classic k-means demands you name k and pay for
many full passes. Pole-based halving names nothing and touches only a
sample per split, which is why it scales to tables k-means chokes on.

## 4.1 Halve on two far poles, best pole first

`halve` samples the rows, finds a far pair with `poles` (a
FastMap-style projection), orders everyone by their projection, and
cuts at the median. It returns the two poles `a`,`b` and the two
halves — and it puts the pole nearer heaven first.

    function TBL.halve(i,rows,   fun,a,b,n)
      fun,a,b = i:poles(some(rows, the.few))
      rows = keysort(rows, fun); n = floor(#rows/2)
      return a, b, sub(rows,1,n), sub(rows,n+1) end

```
[56]> a, b, lo, hi = t:halve(t.rows)
[57]> show{lo=#lo, hi=#hi, total=#lo + #hi}
{:hi 199 :lo 199 :total 398}
[58]> round(t:disty(a))
0.12
[59]> round(t:disty(b))
0.87
```

A clean split (199/199), and the two poles sit at opposite ends of
goodness: `a` at 0.12 (near heaven), `b` at 0.87 (far). We found a
good car and a bad car with no labels beyond these two.

> **POLE / FASTMAP — projection onto a far pair.** Faloutsos &
> Lin's FastMap (1995) places points on a line by their distance to
> two "pivot" objects, approximating an expensive embedding with O(n)
> distance calls. Here the pivots are the far pair, and the
> projection orders rows for a median cut. Today's bet: *the axis
> between two extremes captures the main variation* — falsified when
> the data's real structure is a ring or a spiral, where no single
> line separates it.

**Check.** `halve` calls `poles` on `some(rows, the.few)`, a sample,
not all rows. What does that trade away, and why is it usually a good
trade for finding *far* poles specifically?

## 4.2 The good half really is better

The split is not cosmetic. Average `disty` over each half: the `lo`
half beats the `hi` half on the goals, even though `halve` only ever
looked at input columns to make the cut.

```
[60]> round(adds(map(lo, t:Y())).mu)
0.36
[61]> round(adds(map(hi, t:Y())).mu)
0.69
```

Splitting purely on *inputs* sorted the rows on their *goals*. That
is the free lunch clustering sometimes buys: structure in x that
tracks quality in y.

**Check.** `halve` used only `distx` (inputs), yet the halves differ
in mean `disty` (goals). What assumption about the data makes that
possible, and how would you detect a dataset where it fails (the
halves come out 0.5 vs 0.5)?

## 4.3 Node: recurse the halving into a tree

`Node` applies `halve` again to each half until groups get small
(`the.stop`), building a binary tree of clusters. Rows are conserved:
every original row lands in exactly one leaf.

```
[62]> nd = Node(t)
[63]> leaves = 0; rows = 0
[64]> walk = function(x) if x.lo then walk(x.lo); walk(x.hi) else leaves = leaves + 1; rows = rows + #x.here.rows end end;
[65]> walk(nd)
[66]> show{leaves=leaves, rows=rows}
{:leaves 8 :rows 398}
```

Eight leaves, 398 rows accounted for — no row lost, none double
counted.

> **HALVE — recursive bisection.** Repeatedly splitting a set on its
> principal axis is the shared skeleton of k-d trees, hierarchical
> clustering, and the decision trees of Lecture 6. The difference is
> only the split rule: geometry here, goal-purity there. Same
> recursion; the homework is porting it once and reusing it.

**Check.** `[66]` shows leaves × (rows per leaf) summing to 398. Why
does `walk` counting `#x.here.rows` only at leaves (not internal
nodes) avoid double-counting?

## 4.4 leaf: drop a row to its cluster

`NODE.leaf` walks a row down the tree, at each node going to whichever
pole it is nearer. The landing leaf is that row's neighborhood.

```
[67]> leaf1 = nd:leaf(t.rows[1])
[68]> #leaf1.here.rows
50
[69]> round(t:disty(leaf1.here.rows[1]))
0.5
```

Row 1 lands in a 50-row cluster of cars like it.

**Check.** `leaf` chooses `lo` or `hi` at each node by comparing
`distx(row, a)` to `distx(row, b)`. Why must it use the SAME two
poles the tree was *built* with, and where are those stored?

## Recap

REPL events covered: 54–69. Two far poles ([POLE](#glossary)/
[FASTMAP](#glossary)) project rows onto a line for a median cut; the
good half is genuinely better on the goals; recursion
([HALVE](#glossary)) grows a cluster tree that conserves every row;
and `leaf` drops any row into its neighborhood. Lecture 5 swaps the
geometric split for a goal-purity split — the seed of decision trees.

**Coming attraction.** The same recursion, split on goal purity
instead of geometry, prints as an explainable tree:

    lua ezr-eg.lua --tree

**Exercises.**
1. Rerun `[56]`–`[59]` after `the.few = 32`, then `the.few = 256`.
   Do the pole distances stabilize? What does that say about how many
   samples "find a far pole" needs?
2. Raise `the.stop` and re-count leaves `[66]`. Sketch the relation
   between `the.stop` and leaf count; predict the leaves at
   `the.stop = 64`.
3. Drop `rows[398]` (the worst car) through `[67]`. Is its leaf
   `disty` near 0.5 like row 1's, or worse? Interpret.
4. **Field trip.** Grow the `Node` tree and print each leaf's mean
   `disty`. Is there a single "best cluster," and how big is it
   relative to the 50-row leaf in `[68]`?

[contents](#contents)

---

*(Lectures 5–10, glossary, appendix, and exam bank follow as the
build continues.)*
