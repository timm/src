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
| [2](#l2)  | Tables, roles, forgetting  | 17–…    | ROLE, STREAM |
| [3](#l3)  | Distance & gap-to-heaven   | …       | MINK, D2H, PARETO |
| [4](#l4)  | Clustering by poles        | …       | POLE, FASTMAP |
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

*(Lectures 2–10, glossary, appendix, and exam bank follow as the
build continues.)*
