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
| [5](#l5)  | Discretization & cuts      | 70–84   | CUT, IG, VAL |
| [6](#l6)  | Trees & XAI                | 85–94   | CART, XAI, PRUNE |
| [7](#l7)  | Active learning / acquire  | 95–108  | ACQ, AL, BO, TS |
| [8](#l8)  | The holdout rig            | 109–124 | HOLD, WIN, BASELINE |
| [9](#l9)  | Statistics                 | 125–142 | COHEN, KS, CLIFF, SAME, POWER, SK |
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

<a name="l5"></a>
# Lecture 5: Discretization & cuts

Lecture 4 split rows by geometry. Now we split by *purpose*: find the
one place, in one input column, where cutting the data most separates
good rows from bad. This is the atom of a decision tree — and, run
once, already a useful thing: it names the single most informative
threshold in your data.

**Where this bites.** "At what mileage does a used car's value fall
off a cliff?" "Above what request rate does p99 latency break?" Every
such question asks for a *cut* — a threshold that carves one variable
so the outcome on each side is as pure as possible. Get the cut
right and you have an explanation a manager can act on; get it from
eyeballing a scatter plot and you have folklore.

## 5.1 The champion cut

`bestcut` scans every input column, asks each for its purest split
(numbers try thresholds between sorted values; symbols try each key),
and feeds all candidates to one `least` reducer that keeps the single
best. It returns `{score, column-index, cut-value}`.

    function TBL.bestcut(i,rows,Y,acc,best)
      for _,c in ipairs(i.cols.x) do i:cuts(rows,c,Y,acc,best) end
      return best() end

```
[72]> b = t:bestcut(t.rows, t:Y(), Num, least())
[73]> c = t.cols.all[b[2]]
[74]> c.name
Volume
[75]> round(b[3])
262
[76]> round(b[1])
0.14
```

The most informative split in 398 cars: engine `Volume ≤ 262`. One
line named the variable and the threshold that best sorts good cars
from bad.

> **CUT — supervised discretization.** Turning a continuous column
> into "≤ v vs > v" by the split that most purifies an outcome is
> supervised discretization (Fayyad & Irani, 1993, used entropy for
> exactly this). It is the recursive step of CART trees and the
> feature-engineering move behind rule learners. Today's bet: *one
> axis-aligned threshold carries real signal* — falsified when the
> boundary is diagonal (two features only matter together).

**Check.** `bestcut` never builds a list of candidate cuts — it
streams them into `least`. Why does that matter for a column with
10,000 distinct values, and what would the naive "collect then sort"
version cost?

## 5.2 Apply the cut

`divide` sends each row left or right by `c:holds` (`≤ v` for
numbers). Rows are conserved.

```
[77]> yes, no = t:divide(t.rows, c, b[3])
[78]> show{yes=#yes, no=#no, total=#yes + #no}
{:no 99 :total 398 :yes 299}
```

299 smaller-engined cars on one side, 99 big blocks on the other.

**Check.** The cut `Volume ≤ 262` put 299 rows in `yes`. From the
centroid in `[20]` (mean Volume 193), why is the majority on the `≤`
side unsurprising?

## 5.3 The sides differ in goodness

The split earns its keep: the small-engine side averages far nearer
heaven than the big-engine side.

```
[79]> round(adds(map(yes, t:Y())).mu)
0.42
[80]> round(adds(map(no, t:Y())).mu)
0.84
```

Smaller engines, better cars (lighter, thriftier) — 0.42 vs 0.84. The
threshold discovered a real regularity in the fleet.

**Check.** Both sides were scored by `disty` (goals), but the cut was
chosen on an *input* column. How is that different from
"test-on-train" leakage, which Lecture 8 warns against?

## 5.4 val: why 262 wins

`val` scores a split by the size-weighted average diversity of its
two sides — spread for numbers, entropy for symbols. Lower is purer.
The winning split's `val` (0.14) sits well below the undivided
table's diversity (0.23): the cut removed real disorder.

    function val(a,b)
      return (a:div()*a.n + b:div()*b.n) / (a.n + b.n + TINY) end

```
[81]> lo = adds(map(yes, t:Y()))
[82]> hi = adds(map(no, t:Y()))
[83]> round(val(lo, hi))
0.14
[84]> round(adds(map(t.rows, t:Y())):div())
0.23
```

> **IG / VAL — impurity reduction.** Information gain is
> (parent impurity − weighted child impurity); a cut is worth making
> when that gap is positive. `val` is the child term; comparing it to
> the parent's 0.23 is the gain (here ≈ 0.09). Quinlan's ID3/C4.5
> built entire trees by greedily maximizing this. Lecture 6 does the
> same, recursively.

**Check.** The gain here is 0.23 − 0.14 ≈ 0.09. A second cut deeper
in the tree shows gain 0.01. Why might you still make the 0.01 cut —
and what course principle (Lecture 6) tells you when to *stop*?

## Recap

REPL events covered: 70–84. `bestcut` streams every candidate
threshold through one reducer to name the single most purifying split
([CUT](#glossary)); `divide` applies it; `val` scores a split's
purity, and its gap to the parent's diversity is the information gain
([IG](#glossary)/[VAL](#glossary)). Recurse this and you have a tree —
Lecture 6.

**Coming attraction.** Stack these cuts and print the result:

    lua ezr-eg.lua --cuts

**Exercises.**
1. Rerun `[72]` with `the.leaf = 40`. Does the champion cut move off
   `Volume`? Explain via `big` (both sides must hold ≥ `the.leaf`).
2. Compute the information gain (parent 0.23 − `val`) for a cut you
   force on `Clndrs` instead. Is it above or below `Volume`'s 0.09?
3. Feed `bestcut` only `sub(t.rows, 1, 50)`. Does the winning column
   change? What does that say about cuts from small samples
   (Lecture 9's theme)?
4. **Field trip.** Print the yes/no mean `Mpg+` (not `disty`) for the
   `Volume ≤ 262` split. By how many miles per gallon do small
   engines lead?

[contents](#contents)

---

<a name="l6"></a>
# Lecture 6: Trees & XAI

Stack Lecture 5's cut, recursively, and you get a decision tree: a
model you can *read*. This lecture grows one over the gap-to-heaven
score, prints it, uses it to predict an unseen row's goodness, and
then does the thing most tutorials skip — enumerates every pruning to
find the smallest tree that still explains the data.

**Where this bites.** A bank must tell a customer *why* the loan was
denied; a clinician must defend *why* the model flagged a scan. "The
neural net said so" is not an answer regulators (or juries) accept.
A tree whose every branch is a threshold on a named feature is an
explanation by construction — the whole field of XAI trying to buy
back, expensively, what a small tree gives for free.

## 6.1 Grow the tree

`Tree` recurses `bestcut`/`divide`, stopping at `the.maxd` depth or
`the.leaf` rows. Each node summarizes its rows' `disty`.

```
[87]> tr = Tree(t, t.rows)
[88]> tr.leafs
14
```

Fourteen leaves — fourteen distinct "kinds of car," each a rule path.

**Check.** `Tree` stops at `the.maxd` or when a side would fall below
`the.leaf`. Which limit is protecting *interpretability*, and which
is protecting against *overfitting* (Lecture 8)?

## 6.2 Read the tree

`show` prints one row per node: count, `d2h` (mean gap to heaven),
each goal's mean in its own column, then the branch condition trailing
right. `*` marks the best leaf, `!` the worst.

```
[89]> tr:show(t)
    n   d2h     Lbs-     Acc+     Mpg+
  398  0.53  2970.42    15.57    23.84
  299  0.42  2583.54    16.49    26.86  Volume <= 262
  123  0.29  2099.59    16.85    31.71  |  Volume <= 112
    4  0.63   2398.5    13.25       20  |  |  Clndrs <= 3
  119  0.28  2089.54    16.97     32.1  |  |  Clndrs >  3
*  22  0.17  1910.59    18.35    33.64  |  |  |  Volume <= 85
   97  0.30  2130.12    16.66    31.75  |  |  |  Volume >  85
  176  0.52  2921.76    16.25    23.47  |  Volume >  112
   ...
   99  0.84  4138.89    12.77    14.75  Volume >  262
   84  0.87  4200.01    12.49    13.69  |  Model <= 77
!  39  0.91  4321.33    11.54    11.79  |  |  |  Model <= 73
   ...
```

Read the best leaf (`*`): 22 cars with `Volume ≤ 112`, `Clndrs > 3`,
`Volume ≤ 85` — averaging 1911 lbs and 33.6 mpg, `d2h` 0.17. The
worst (`!`): 39 heavy cars, 11.8 mpg, `d2h` 0.91. The path IS the
explanation: small four-cylinder engines make the best all-round
cars in this fleet.

> **CART / XAI — trees you can read.** Breiman's CART (1984) grows a
> recursive-partition model whose every decision is a named
> threshold. "Explainable AI" is the modern name for wanting exactly
> that: a model whose reasoning a human can audit. The trade — trees
> lose a little accuracy to fully-connected models — is the price of
> a defense you can say out loud.

**Check.** Every internal row's `n` equals the sum of its two
children's `n` (299 = 123 + 176). Why is that a useful *audit* that
the tree partitioned rather than duplicated rows?

## 6.3 Predict by walking to a leaf

`TREE.leaf` sends a row down the branches and returns its leaf's mean
`disty` — a prediction. For row 1, the tree guesses 0.81; the true
`disty` is 0.79.

```
[90]> round(tr:leaf(t, t.rows[1]))
0.81
[91]> round(t:disty(t.rows[1]))
0.79
```

A two-hundredths miss, from a model you can print on one screen.

**Check.** The tree predicted 0.81 for a row whose true score is
0.79 — but it was trained *on* row 1. Why is this NOT yet evidence
the tree generalizes, and what would Lecture 8 do differently to find
out?

## 6.4 Prune: the smallest tree that still works

`walk` visits every pruning of the grown tree (each subtree collapsed
or kept). Scoring all 256 of them, the best keeps only 5 leaves at
`val` 0.17 — nearly a third the size of the full 14-leaf tree, no
worse on the score.

```
[92]> n = 0; best = nil
[93]> tr:walk(function(w) n = n + 1; if not best or w.val < best.val or (w.val == best.val and w.leafs < best.leafs) then best = w end end);
[94]> show{prunings=n, full_leafs=tr.leafs, best_leafs=best.leafs, best_val=round(best.val)}
{:best_leafs 5 :best_val 0.17 :full_leafs 14 :prunings 256}
```

> **PRUNE — Occam's razor, enumerated.** Post-pruning removes
> branches that do not earn their complexity, trading fit for
> simplicity (CART's cost-complexity pruning does this with a
> penalty term). Here it is brute force: enumerate every pruning,
> keep the smallest that ties the best score. Today's bet: *the
> simplest model that fits will generalize best* — falsified when the
> signal genuinely needs all 14 leaves, and pruning to 5 drops
> accuracy on unseen rows.

**Check.** The best pruning has 5 leaves and the same `val` as trees
with more. Given two prunings with equal `val`, `[93]` prefers fewer
leaves. State the course principle that tie-break encodes, in one
sentence.

## Recap

REPL events covered: 85–94. Recursive cuts grow a readable tree
([CART](#glossary)/[XAI](#glossary)); `show` prints the rules and
flags best/worst leaves; `leaf` predicts by walking a row down; and
enumerating prunings ([PRUNE](#glossary)) finds the smallest tree
that still explains the data. Next: stop grading rows we can see, and
start *choosing which rows to label* — active learning.

**Coming attraction.** Spend a tiny label budget to rank unseen data:

    lua ezr-eg.lua --acquire

**Exercises.**
1. Regrow with `the.maxd = 2` and re-print `[89]`. Which
   best-leaf rule survives the shallower tree, and what detail is
   lost?
2. Predict `[90]` for `rows[398]` (worst car). Does the tree's guess
   land near its true 0.96? Which leaf catches it?
3. Raise `the.leaf` to 20 and recount prunings `[94]`. Does the best
   pruning shrink below 5 leaves? Interpret via Occam.
4. **Field trip.** Read the `*` leaf's rule path off `[89]` and find
   a real car in `auto93.csv` that satisfies it. Does its mpg beat
   the fleet mean (23.8) from `[20]`?

[contents](#contents)

---

<a name="l7"></a>
# Lecture 7: Active learning — spend labels wisely

Until now every row arrived pre-scored. Reality is stingier: scoring
a row can mean a wet-lab assay, a week-long benchmark, a human
grader. So the question flips from "what does the data say?" to
"which few rows should I pay to label?" This lecture's `acquire` labels
a handful, culls the pool toward the promising pole, and repeats —
finding a near-best row after touching a small fraction of the data.

**Where this bites.** Tuning a compiler, a chemical process, or a
deep net's hyperparameters, each trial costs hours of compute. A
2017 config-tuning study (Nair et al.) found that ranking software
configurations well needed only *dozens* of measured samples, not the
thousands a full grid demands. Active learning is how you buy a good
answer when every answer has a price tag.

## 7.1 The label budget

`the.budget` caps how many rows may be scored. `acquirer` returns the
labelled set, best-first.

```
[97]> #t.rows
398
[98]> the.budget
50
```

**Check.** The budget is 50 against 398 rows. Why is "labels spent,"
not "rows in the file," the cost that matters in the scenarios above?

## 7.2 Acquire: label, cull, loop

`acquirer` shuffles the rows, labels a few, sorts the pool toward the
best pole found so far, keeps the promising `keepf` fraction, and
loops until the budget is spent — reshuffling and re-anchoring on the
best/worst seen if a pool dries early.

    while #rows >= 2*the.leaf do
      more, new = min(the.more, cap - #lab), {}
      ...
      rows = sub(keysort(rows, (i:poles(new, lo, hi))),
                 1, max(1, floor(the.keepf * #rows))) end

```
[99]> y = t:Y()
[100]> lab = t:acquirer(the.budget)
[101]> #lab
50
```

> **ACQ / AL / BO — buy the label that teaches most.** Active
> learning (Settles, 2009) lets the model choose its next query
> instead of taking labels in file order. Bayesian optimization is
> the continuous cousin: fit a cheap surrogate, then sample where it
> promises the most gain. Both rest on an *acquisition function* — a
> rule for "where next." Here the rule is geometric: cull toward the
> pole nearest heaven.

**Check.** `acquire` never scores a row twice (a `seen` set guards
it). Why is that guard essential to *counting* the budget honestly —
and what would double-scoring do to the "labels spent" claim?

## 7.3 Fifty labels find a near-best car

The best of the 50 labelled rows scores 0.09 — against the true best
of all 398, which is 0.07. Thirteen percent of the labels, essentially
the right answer.

```
[102]> round(y(lab[1]))
0.09
[103]> round(y(keysort(t.rows, y)[1]))
0.07
```

> **TS — Thompson's old idea.** Thompson (1933) proposed choosing an
> action in proportion to the probability it is best — balancing
> *exploiting* the current best guess against *exploring* uncertain
> options. Every acquisition rule since is a variation on that
> balance. `acquire`'s reshuffle-and-re-anchor when a pool dries is
> its exploration valve.

**Check.** `acquire` labelled 50 rows and returned them sorted; the
best is 0.09, not the true 0.07. Name one row the method could only
have found by *luck*, and explain why 0.09-not-0.07 is a feature, not
a bug, of a budget-bounded search.

## 7.4 The labelled set spans good to bad

`acquirer` returns labels sorted best-first, so the pool it explored
runs from near-heaven to mediocre — it did not only sample winners.

```
[104]> round(y(lab[1]))
0.09
[105]> round(y(lab[#lab]))
0.68
```

Seeing bad rows matters: the poles need a far anchor to project
against.

**Check.** Why would an acquirer that labelled ONLY good-looking rows
(no 0.68 tail) actually find *worse* answers? Tie your reason to the
poles of Lecture 4.

## 7.5 More budget, smaller gap

Double the budget to 100 and the best labelled row matches the true
best exactly (0.07). Diminishing returns, honestly shown.

```
[106]> the.budget = 100
[107]> lab2 = t:acquirer(the.budget)
[108]> show{labels=#lab2, best=round(y(lab2[1]))}
{:best 0.07 :labels 100}
```

Is active selection actually *better* than spending those 100 labels
at random? A single run cannot say — the honest, repeated comparison
is Lecture 8's job.

**Check.** Going 50 → 100 labels moved the best from 0.09 to 0.07.
Extrapolate: would 200 labels help much? What does that curve's shape
tell you about when to STOP buying labels?

## Recap

REPL events covered: 95–108. `acquire` spends a label budget by
labelling a few rows, culling the pool toward the good pole
([ACQ](#glossary)/[AL](#glossary)/[BO](#glossary)), and looping with
an explore/exploit valve ([TS](#glossary)). Fifty labels found a
near-best car; a hundred nailed it. Whether that beats random needs a
rig — Lecture 8.

**Coming attraction.** The honest active-vs-random showdown, repeated
20 times:

    lua ezr-eg.lua --holdouts

**Exercises.**
1. Rerun `[100]`/`[102]` at `the.budget = 30` and `= 200`. Plot best
   vs budget; where does the curve flatten?
2. Halve `the.keepf` (cull harder) and re-check `[102]`. Faster or
   worse? Explain the explore/exploit cost of aggressive culling.
3. Set `the.more = 1` (one label per round). Does the best improve or
   degrade at fixed budget? Why might labelling in bigger batches
   waste budget?
4. **Field trip.** Print `lab[1]`'s full row and compare it to the
   tree's `*` leaf rule from `[89]`. Did active learning rediscover
   the small-four-cylinder winner?

[contents](#contents)

---

<a name="l8"></a>
# Lecture 8: The holdout rig

A model that scores well on the data it trained on has proven
nothing. This lecture builds the rig that keeps everyone honest: train
on one half, rank the *unseen* half, spend a few labels to check the
top of that ranking, and score the result on a 0–100 scale. Then the
lecture does what most tool demos refuse to — runs the whole thing 20
times against a random baseline and lets a statistics test say
whether the winner really won.

**Where this bites.** The 2023 reproducibility reckoning in ML (and
the older one in psychology) traces to two habits: reporting the run
that looked best, and skipping the baseline. A holdout split answers
"does it generalize?"; a repeated baseline answers "is it better than
doing nothing clever?" Skip either and you ship folklore with a
confidence interval.

## 8.1 The win score

`wins` converts `disty` into a 0–100 grade: 100 is the best row seen,
0 is the median, negatives are worse-than-median. It makes runs
comparable across datasets with different `disty` ranges.

```
[111]> t.rows = some(t.rows, the.cap)
[112]> #t.rows
398
[113]> W = t:wins()
[114]> best = keysort(t.rows, t:Y())[1]
[115]> round(W(best))
100
```

> **WIN — a normalized, capped score.** Reporting raw error hides
> whether "0.14" is good. Rescaling to "% of the way from median to
> best" makes results legible and cross-dataset comparable — the same
> reason optimization papers report normalized regret, not raw
> objective values.

**Check.** `W(best)` is exactly 100 and the median maps to 0. Why
does anchoring the scale to *this dataset's* best-and-median make two
different datasets' win scores comparable, where raw `disty` would
not?

## 8.2 One holdout

`holdout` shuffles, trains on half via a labelling strategy `how`
(default: active `acquirer`), grows a tree, ranks the unseen test
half, and returns the best of the top `the.check`. It asserts it never
overspends the budget.

    train = sub(rows,1,n); test = sub(rows,n+1)
    lab   = how(i:clone(train), the.budget - the.check)
    assert(#lab + the.check <= the.budget)
    t     = Tree(i, lab)
    top   = sub(keysort(test, function(r) return t:leaf(i,r) end),
              1, the.check)

```
[116]> b = t:holdout()
[117]> show{disty=round(t:disty(b)), win=round(W(b))}
{:disty 0.14 :win 85.68}
```

One honest pass: the row it picked from data it had never scored lands
at win 86 — most of the way to best.

> **HOLD — train/test separation.** The holdout (Stone, 1974,
> formalized cross-validation) is the oldest defense against fooling
> yourself: never grade a model on rows it learned from. Every
> `assert` in this function is a tripwire against the subtle leak of
> spending more budget than declared.

**Check.** `holdout` ranks the test half with a tree grown ONLY on
the train half. Name the exact line that would introduce
test-on-train leakage if you deleted it, and what the win score would
do (up or down) as a result.

## 8.3 The honest comparison: 20 runs

A single run is an anecdote. `go` runs 20 seeded holdouts and sorts
the wins; `L` uses active `acquire`, `R` uses the first `cap` rows
(random order = a random baseline).

```
[118]> go = function(how, u) u = {}; for j=1,20 do srand(the.seed+j); u[1+#u]=W(t:holdout(how)) end; return sorted(u) end
[119]> L = go()
[120]> R = go(function(t2,cap) return sub(t2.rows, 1, cap) end)
[121]> ml = round(sum(L, function(x) return x end)/20)
[122]> mr = round(sum(R, function(x) return x end)/20)
[123]> show{active=ml, random=mr}
{:active 84.68 :random 86.93}
```

> **BASELINE — beat random, or admit you didn't.** The most
> informative line in any results table is the dumb baseline. A 2019
> reproducibility study of recommender-system papers (Dacrema et al.)
> found most "state of the art" methods lost to well-tuned trivial
> baselines. If your clever method cannot beat random selection, the
> cleverness is decoration.

**Check.** Active scored 84.68, random 86.93 — random is *higher*.
Before Lecture 9, would you report "random beats active" from these
two numbers? What single question must you answer first?

## 8.4 Is the gap real?

Two means differ — but 84.68 vs 86.93, over 20 noisy runs, might be
nothing. `same` (Lecture 9) runs three effect-size tests and reports
whether the two samples are statistically indistinguishable.

```
[124]> same(L, R) and "tie" or (ml > mr and "active wins" or "random wins")
tie
```

**A tie.** On this easy, fully-labelled dataset, active learning does
not beat random selection — and, crucially, does not *lose* to it
either: the gap is noise. This is the honest result, and it is the
whole point of the rig. Active learning earns its keep where labels
are genuinely expensive and the data is hard — the external-model
world of Lecture 10 — not on 398 pre-scored cars where random already
does fine. A rig that only ever confirmed the clever method would be
worthless; this one is willing to say "no difference."

**Check.** The verdict is "tie," yet the means differ by ~2 points.
Explain how `same` can call a 2-point gap a tie, and why reporting
the raw means WITHOUT this test would have been a (small) research
crime.

## Recap

REPL events covered: 109–124. `wins` grades on a legible 0–100 scale
([WIN](#glossary)); `holdout` trains and tests on separate halves
([HOLD](#glossary)); and 20 repeated runs against a random
[BASELINE](#glossary), judged by `same`, delivered an honest tie —
the rig's willingness to say "no difference" is what makes its
occasional "yes" trustworthy. Lecture 9 opens the statistics that
made the call.

**Coming attraction.** The effect-size tests behind that "tie":

    lua ezr-eg.lua --same

**Exercises.**
1. Rerun `[119]`–`[123]` at `the.budget = 20`. Does the tie hold when
   both methods get fewer labels? Which degrades faster?
2. Replace the random baseline in `[120]` with "worst-first"
   (`keysort` by `disty` descending, take `cap`). Predict the win
   before running; explain.
3. Delete the `assert` in `holdout` and set `the.check = the.budget`.
   What leaks, and how would the win score lie?
4. **Field trip.** Run the 20-run comparison on a harder MOOT table
   (e.g. `csv"$MOOT/optimize/misc/auto93.csv"` vs a config dataset).
   Does active ever break the tie? Note which datasets it wins on.

[contents](#contents)

---

<a name="l9"></a>
# Lecture 9: Statistics — the noise floor and the eps gate

This is the deepest lab, because it is where most published results
go wrong. Lecture 8 asked "is 84.68 different from 86.93?" and a
function answered "no." Now we open that function. Three ideas do the
work: two samples from the *same* source still score a nonzero
difference (the noise floor); the *same* real difference is invisible
at n=10 and glaring at n=2000 (statistical power); and a difference
smaller than your measurement noise is not a difference at all (the
eps gate).

**Where this bites.** The replication crisis — psychology's, then
medicine's, then ML's — is mostly two mistakes this lecture inoculates
against: calling noise a discovery, and calling an undetectable-but-
real effect "no effect." The A/B test that "won" on 200 users and
vanished on 2 million; the drug whose effect was real but too small to
matter — both are failures to distinguish a difference that is *real*
from one that is *large enough to act on*.

## 9.1 Effect size: identical is zero, shifted is large

`cohen` reports the gap between two means in pooled-standard-deviation
units — a scale-free "how many sigmas apart." Identical lists: 0. A
+3 shift on unit-spread data: 1.9 (a large effect).

    function cohen(xs,ys,   x,y,n,m,sd)
      x,y = adds(xs), adds(ys); n,m = x.n, y.n
      sd = sqrt(((n-1)*x:div()^2 + (m-1)*y:div()^2)/(n+m-2))
      return abs(x.mu - y.mu) / (sd + TINY) end

```
[126]> round(cohen({1,2,3,4,5}, {1,2,3,4,5}))
0
[127]> round(cohen({1,2,3,4,5}, {4,5,6,7,8}))
1.9
```

> **COHEN — effect size, not p-value.** Cohen's d (1969) measures
> *how big* a difference is, in standard-deviation units, independent
> of sample size. This is the number that matters for decisions: a
> p-value shrinks to "significant" with enough data even for a
> trivial effect, but d does not move. Report d, act on d.

**Check.** `cohen` is scale-free: multiply both lists by 1000 and it
is unchanged. Why does that property make it safer than reporting the
raw mean difference (which *would* change)?

## 9.2 The noise floor

Draw two samples from the *same* Gaussian. They are not identical —
sampling jitter gives them a small but nonzero effect size (0.11 here)
— yet `same` correctly calls them indistinguishable.

```
[128]> g = function(n, mu, u) u={}; for j=1,n do u[j]=(mu or 0)+math.sqrt(-2*math.log(1-rand()))*math.cos(2*math.pi*rand()) end; return sorted(u) end
[129]> x = g(500, 0)
[130]> y = g(500, 0)
[131]> round(cohen(x, y))
0.11
[132]> same(x, y)
true
```

> **CLT — why the floor exists.** The central limit theorem says a
> sample mean scatters around the true mean with spread σ/√n. So two
> honest samples of the same thing *always* differ by a little; the
> noise floor is that scatter. Any threshold for "different" must sit
> above it, or you will discover differences in coin flips.

**Check.** `[131]` is 0.11, not 0, for two samples of the *same*
distribution. If a paper reported cohen = 0.11 as evidence its method
differs from a baseline, what would you ask to see before believing
it?

## 9.3 The eps gate: `same` ANDs three tests

`same` calls two samples the same only if all three agree they are
close: Cohen's d (means), Cliff's delta (rank imbalance), and a
normalized KS (max CDF gap). Sweep a growing shift and watch which
test trips first — KS breaks at 0.30 while Cohen still says "close"
to 0.50; `same`, being an AND, follows the strictest.

```
[135]> for _,mu in ipairs{0, .1, .2, .3, .35, .5, 1} do ... end
 0.00   true  true   true |  true
 0.10   true  true   true |  true
 0.20   true  true   true |  true
 0.30   true false   true | false
 0.35   true false   true | false
 0.50  false false  false | false
 1.00  false false  false | false
```

> **KS / CLIFF / SAME — agree, or it isn't real.** The
> Kolmogorov–Smirnov statistic is the largest gap between two
> cumulative distributions; Cliff's delta counts how often one
> sample outranks the other. Combining three tests with AND
> (Cohen + Cliff + KS) is deliberately conservative — it declares a
> difference only when means, ranks, AND shapes all agree, so a
> single over-eager test cannot manufacture a finding.

**Check.** At shift 0.30, KS says "different" but Cohen says "close,"
and `same` returns false. Rewrite `same` to use OR instead of AND —
at which shift would it now first cry "different," and why is that
the more dangerous rule for a researcher?

## 9.4 Statistical power: the same effect, two sample sizes

A fixed 0.2 shift is a *real* difference. At n=10 the test detects it
in only 15 of 30 trials — half the time it hides under the noise
floor. At n=2000 it is caught every time. The difference did not
change; the power to see it did.

```
[136]> rate = function(n, u) u=0; for j=1,30 do srand(the.seed+j); local x=g(n,0); local y=map(x,function(v) return v+0.2 end); if not same(sorted(x),sorted(y)) then u=u+1 end end; return u end
[137]> show{n=10, detected=rate(10), of=30}
{:detected 15 :n 10 :of 30}
[138]> show{n=2000, detected=rate(2000), of=30}
{:detected 30 :n 2000 :of 30}
```

> **POWER — absence of evidence isn't evidence of absence. A
> statistical test's power is its chance of catching a real effect;
> it climbs with sample size. An underpowered "no difference" (n=10
> here) means "we couldn't see it," not "it isn't there." Half of
> the n=10 runs missed a difference that is unmistakable at n=2000.

**Check.** At n=10 the 0.2 shift was "detected" 15/30 times. A team
runs it ONCE at n=10, gets "same," and concludes their change is
harmless. State their error using the word *power*, and the one-line
fix.

## 9.5 Ranking many treatments

`ranks` sorts groups by their median and walks up, giving the next
group a new rank only when `same` says it truly differs from the
current best — so statistical ties share a rank. Here `a` and `b`
(shifts 0 and 0.05) tie at rank 0 and are both winners; `c` (shift 2)
and `e` (shift 4) separate into ranks 1 and 2.

```
[139]> d = {a=g(20,0), b=g(20,0.05), c=g(20,2), e=g(20,4)}
[140]> r = ranks(d)
[141]> show(r.ranks)
{:a 0 :b 0 :c 1 :e 2}
[142]> show(r.winners)
{a b}
```

> **SK — Scott-Knott ranking.** Scott & Knott (1974) rank many
> treatments into statistically distinct groups, so a results table
> shows "these three tie for first, then a gap, then the rest" —
> never a spurious strict ordering of indistinguishable methods.
> This is the right way to report a 21-optimizer bake-off: ranks,
> not a leaderboard of noise.

**Check.** `a` (shift 0) and `b` (shift 0.05) share rank 0. Given
Lecture 9's other lessons, at what sample size might `b` break away
from `a` into its own rank — and would that make `b` *better*, or
just *distinguishable*?

## Recap

REPL events covered: 125–142. Effect size ([COHEN](#glossary))
measures how big, not just whether; the noise floor ([CLT](#glossary))
means same-source samples always differ a little; `same`
([KS](#glossary)/[CLIFF](#glossary)/[SAME](#glossary)) ANDs three
tests to stay conservative; power ([POWER](#glossary)) means small
samples miss real effects; and [SK](#glossary) ranking groups
statistical ties. This is the machinery that kept Lecture 8 honest.
Lecture 10 spends it on the real payoff: apps, then an external-model
optimizer where labels genuinely cost.

**Coming attraction.** The full apps suite, one call each:

    lua ezr-apps.lua --all

**Exercises.**
1. Rerun the sweep `[135]` with 1000-sample `x`. Does KS trip at a
   *smaller* shift than at n=256? Connect to power `[137]`.
2. Change `same` to require only 2 of 3 tests to agree. Re-run `[135]`
   and report the new first-different shift. Safer or riskier?
3. Add a group `f=g(20,0.1)` to `[139]`. Does it join `a`/`b`'s
   winning rank or break away? Predict from `[135]`'s 0.10 row.
4. **Field trip.** Take the `L` and `R` win-lists from Lecture 8
   (`[119]`/`[120]`) and run `cohen`, `ks`, `cliffs` on them
   separately. Which of the three came closest to calling active vs
   random "different"?

[contents](#contents)

---

*(Lecture 10, glossary, appendix, and exam bank follow as the build
continues.)*
