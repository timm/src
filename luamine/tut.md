<a name="contents"></a>
# tut.md — Ten Lectures on Data-Lite AI, at the REPL

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

*Version: 2026-06-11*

 
<img align=right width="346" height="135" alt="image" src="https://gist.github.com/user-attachments/assets/0d143e63-fef9-40a6-a406-88f3b44d0d3c" />

Ryan Dahl says the era of human-written code is ending.
Jensen Huang advises against learning to code. The new
orthodoxy is that nobody needs to read programs anymore —
just fly over the details and let the machine drive. This
course disagrees, by demonstration: we read a few hundred
lines of Lua, carefully, at the REPL — and out falls a
toolkit that explains data, tunes systems, catches
anomalies, and optimizes under budgets that would bankrupt
fancier methods.

Some numbers to set the stakes. A real product-line config
table studied here has 86,000 rows over 88 options; one
label in such tables can cost a recompile and an hour-long
benchmark. Lecture 10's tool, spending ~34 labels per
split, averages a win score of 87/100 across twenty trials
— seven-eighths of the way to what labeling everything
achieves. And in
a recent 21-optimizer tournament across 90+ SE tasks, the
winner changed with the evaluation budget — while random
search beat two fashionable methods. Moral, and course
thesis: every optimizer is a falsifiable bet about the
shape of your problem, and a few hundred readable lines are
enough to run the experiment yourself.

The mechanics: 261 numbered REPL prompts (`[1]>` onward)
plus a 46-prompt Lua appendix (numbered from `[1000]>`).
Everything was executed against the real code; outputs
shown are real. Lectures mix lab blocks (prompts + check
questions) with theory and real-world sections; each ends
with exercises that reuse its prompts. One thread runs
through everything: reasoning from small samples — what
they show, what they hide, how much to trust them.

**Homework, standing assignment.** Reimplement this system
in a language of your choice (Python recommended), paced by
the lectures: by the end of week k, your program must
reproduce every REPL prompt through that lecture's last
event (the ranges in the table below — roughly 20-25 events
a week). The course RNG is a portable 10-line generator
(see `l.rand` in rand.lua), so a correct port produces the
SAME numbers shown here: grading is diff. Where outputs are
tables, match the content; where they are floats, match to
ten significant digits.

**Setup** (lecture 1 walks through this):

    git clone https://github.com/timm/src
    git clone http://github.com/timm/moot ~/gits/moot
    cd src/luamine && lua -i

Source files: three modules, each a thin loader assembling
page-sized topic files:
[lib.lua](https://github.com/timm/src/blob/main/luamine/lib.lua)
(helpers: rand, list, stats, confuse, str, cli),
[luamine.lua](https://github.com/timm/src/blob/main/luamine/luamine.lua)
(AI primitives: cut, sym, num, cols, data, dist, bayes,
mutate, tree, show), and
[lapps.lua](https://github.com/timm/src/blob/main/luamine/lapps.lua)
(applications: cluster, classify, acquire, sample, bob,
race, ga, de, search). Annotated pages:
[timm.github.io/src/luamine](https://timm.github.io/src/luamine/). Words in SMALL CAPS like
[ACQ](#glossary) are defined in the [glossary](#glossary),
cited in full in the [references](#refs); new to Lua? start
with the [Lua 101 appendix](#appendix); test yourself
against the [revision guide](#quiz) — each question unlocks
at a numbered prompt.

## Contents

| # | lecture | REPL | ideas |
|---|---------|------|-------|
| 1 | [Getting started](#l1) | 1-22 | BETS, SIMP, CONF, SSOT, CSV, LIL, FAIL, SEED, ROGUE |
| 2 | [Lists + incremental stats](#l2) | 23-45 | WEL, ENT, CLT, PDF/CDF |
| 3 | [Summaries: Num, Sym, Data](#l3) | 46-70 | NUM/SYM, POLY, NOIR, COC |
| 4 | [Distance is all you need](#l4) | 71-95 | DIST, D2H, KNN, ZIT |
| 5 | [Naive Bayes + k-means](#l5) | 96-123 | NB, MEST, ACC, KM, XVAL |
| 6 | [Cuts, trees, interpretability, causality](#l6) | 124-146 | CUT, TREE, XPLN, INTERP, LADDER |
| 7 | [Projections, synthesis, anomalies](#l7) | 147-171 | FMAP, SYNTH, ANOM, MFID |
| 8 | [Mutation + (1+1) search](#l8) | 172-197 | MUT, SURR, SA, LS, MH |
| 9 | [Populations, racing, SBSE](#l9) | 198-220 | GA, DE, RACE, GP, PARETO, SBSE, APR |
| 10 | [Active learning + honest stats](#l10) | 221-261 | ACQ, BOB, EFF, KS, SAMP, TIER, BO, THOM |
|   | [Revision guide](#quiz) | gates 4-233 | 104 exam questions: recall + bug-hunt |
|   | [Answers](#answers) | | worked answers to all 104 |
|   | [Glossary](#glossary) | | all 55 acronyms |
|   | [Lua 101](#appendix) | 1000-1045 | just enough Lua, hands on |
|   | [References](#refs) | | every citation, with links |

---
<a name="l1"></a>
# Lecture 1: Getting Started

The only way to learn a new code base is to run it. This
lecture gets you to a working REPL with the luamine code loaded,
shows you where all the configuration lives, and reads your
first data file. Everything else in this course builds on
these mechanics, so do not skip them. We are not trying to be
complete here; we want you running real code in the first ten
minutes.

You need three things: Lua 5.x, this repo, and the data repo.

    git clone https://github.com/timm/src
    git clone http://github.com/timm/moot ~/gits/moot
    cd src/luamine

**Where this bites.** A real product-line table in tonight's
data repo (SS-X) has 86,000 rows of configurations over 88
options. One open-source database exposes more option
combinations than there are stars in the observable
universe. Nobody reasons about such spaces unaided;
"configurability is a liability without tool support". The
tools start here.

## 1.0 The claim

Before any code, the bet this course makes. Software
engineering is mostly choice under competing goals: pick the
test order, the config, the release plan, the cloud layout —
maximizing some things (speed, coverage, mpg) while
minimizing others (cost, weight, risk). Three obstacles make
this hard: the spaces are huge (a 20-option config file has
more combinations than you will ever test); honest
evaluations are expensive (a build, a benchmark, an
engineer's afternoon); and humans systematically overlook
simple solutions while reaching for complex ones.

The hypothesis, tested all semester on real data: a few
dozen well-chosen evaluations, summarized by a few dozen
lines of code, get most of what exhaustive search would get.
You will see the thesis stated numerically in lecture 10
(`[233]`: mean win 87/100 over twenty splits, ~34 labels
each). If that
claim offends you — good. Every lecture hands you tools to
attack it.

Why these datasets? The MOOT collection (cloned below) holds
over a hundred multi-objective SE tables — config tuning,
effort estimation, process models — all in the same CSV
dialect you will meet at `[15]`. One format, one toolkit,
a hundred chances to falsify the hypothesis.

One more framing tool, used all course. Every algorithm you
will meet is a BET about the shape of the search space.
Hill climbing (walk greedily uphill) bets that small steps
give small changes in solution quality; crossover (splice
two good candidates) bets that good solutions are built
from separable good parts; surrogate methods bet that a
cheap stand-in model can replace a dear evaluation. Bets can be wrong, per task — and that makes
optimizer choice an EXPERIMENT, not a brand preference.
Watch for "today's bet" notes at each algorithm.

> **BETS — optimizers are falsifiable bets.** The choice of
> optimizer is not a choice between names; it is a choice
> between beliefs about the landscape, and each belief can
> be tested. When a method loses, you learned a property of
> your task. Menzies 2026 (egs.pdf).

> **SIMP — simplicity first.** Benchmark the dumbest thing
> that could possibly work before believing anything fancier.
> Decades of SE model-building keep finding tiny models that
> match big ones; humans keep not noticing. Holte 1993 (1R);
> Fu & Menzies 2017; Rudin 2019.

**Check:** name one decision in your current project that is
secretly multi-objective search. What are its x columns and
its y columns?

## 1.1 Hello, REPL

Start Lua interactively from the luamine directory and load the
three source files. By convention we bind them to one-letter
names: `l` for the generic library, `m` for the AI primitives,
`a` for the applications.

    lua -i

```
[1]> l = require"lib"
[2]> m = require"luamine"
[3]> a = require"lapps"
[4]> print(_VERSION)
Lua 5.5
```

If `require"lib"` fails, you are not in the luamine directory.
Fix that before reading on. (Each of those three files is a
thin loader: it assembles its module from the page-sized
topic files sitting beside it -- rand.lua, list.lua, sym.lua
and friends -- so requiring needs the whole directory, not
one downloaded file; `sh INSTALL.md` fetches the lot.)

**Check:** what does `require` return? (Hint: each loader ends
by returning its module table.)

## 1.2 One table of settings

Every option in the system lives in one table, `l.the`. It is
built automatically by parsing each file's help text: any line
like `--seed=1` in the help string becomes a key in `the`.
Docs and defaults cannot drift apart, because the docs ARE the
defaults.

```
[5]> l.o(l.the)
{F=0.50, bins=2, budget1=1000, budget=512, cap=2048, check=4, cliffs=0.20, cr=0.90, dot=25, eps=0.35, few=128, gens=100, iter=10, k=1, ksconf=1.36, leaf=3, m=2, mut=0.80, np=20, p=2, pool=512, repeats=20, seed=1, start=10, test=$MOOT/optimize/misc/auto93.csv, tour=5, train=$MOOT/optimize/misc/auto93.csv, wait=10}
[6]> l.the.train
$MOOT/optimize/misc/auto93.csv
[7]> l.the.seed
1
```

`l.o` is the pretty-printer; we will use it constantly. Note
that loading luamine and lapps added their options (`bins`, `np`,
...) to the same table: one config, shared everywhere.

> **CONF — one config struct.** All knobs in one table, parsed
> from the help text, overridable from the command line
> (`lua luamine-eg.lua --seed 42 ...`). No scattered constants, no
> separate config file to rot. See `l.boot` in cli.lua.
> The help text is the single source of truth (SSOT);
> everything else derives from it.

The same trick generalizes. The column-name protocol coming
at `[15]` is another little language: one header line is a
complete problem definition. So is pulling defaults from
help text. The SE pattern names for what you are looking
at: DRY ("don't repeat yourself" — one parsed source of
truth) versus WET ("write everything twice"); and the
refactoring rule of thumb — once is fine, twice can chill,
three times means extract.

> **LIL — little languages.** Encode policy in tiny
> declarative notations (a header row, a help string, a
> regex, a Makefile rule) parsed by small mechanisms. The
> spec separates from the machinery; behavior changes by
> editing a string. Bentley 1986.

Both patterns serve one architecture rule, worth its own
name:

> **SSOT — single source of truth.** Each fact lives in
> exactly one authoritative artifact; everything else
> derives mechanically. Here: defaults derive from help
> text ([CONF](#glossary)); next block, schema derives from
> the header. Two sources WILL drift; one cannot.
> Hunt & Thomas 1999.

**Check:** from the shell, what does
`lua lib.lua --the` print, and why?

## 1.3 Strings to things

CSV files give us strings. `l.thing` coerces a string to a
boolean, a number, or (failing those) leaves it as a string.
`l.o` renders any value compactly: lists in order, dictionary
keys sorted.

```
[8]> l.thing"42"
42
[9]> l.thing"true"
true
[10]> l.thing"hi"
hi
[11]> l.o{1,2,3}
{1, 2, 3}
[12]> l.o{name="v", age=10}
{age=10, name=v}
```

Two tiny functions, but they carry the whole I/O story: thing
on the way in, o on the way out.

**Check:** what is `l.thing"1.5"`? `l.thing""`?

## 1.4 Streaming a CSV

`l.csv(file)` returns an iterator: each call yields one row as
a list of coerced cells. `l.path` expands `~` and `$MOOT` (the
data repo root; set the `MOOT` env var to move it).

```
[13]> l.path"$MOOT/optimize/misc/auto93.csv"
/Users/timm/gits/moot/optimize/misc/auto93.csv
[14]> csv = l.csv(l.the.train)
[15]> l.o(csv())
{Clndrs, Volume, HpX, Model, origin, Lbs-, Acc+, Mpg+}
[16]> l.o(csv())
{8, 304, 193, 70, 1, 4732, 18.50, 10}
[17]> n = 0; for _ in l.csv(l.the.train) do n = n + 1 end
[18]> n
399
```

399 = one header plus 398 data rows. Note the iterator
streams: rows are processed one at a time, never all in
memory. That choice matters when, later, we insist all our
learners work incrementally.

> **CSV — self-describing header.** Column names carry the
> schema. First char upper-case = numeric, else symbolic.
> Suffix `+`/`-` = goal to maximize/minimize; `!` = class;
> `X` = ignore; cells with `?` are missing. `Lbs-` means
> "numeric, minimize". No separate schema file, ever.
> Another little language ([LIL](#glossary)), and another
> [SSOT](#glossary): the header alone decides roles.

One more habit hides in `[14]`: `l.csv` ASSERTS on a bad
path, crashing immediately with the filename in the error.
The alternative — return nil, let the crash happen later,
far away — is how "0 anomalies found" gets reported on data
that never loaded.

> **FAIL — fail fast, loudly.** Detect broken assumptions
> at the boundary and stop with a named cause (bad path,
> unknown flag). Errors caught late are errors diagnosed
> expensively; silence is worst of all. Shore 2004.

**Check:** in the header at `[15]`, which columns are goals?
Which are ignored?

## 1.5 Seeds, or: science requires reproducibility

Much of this course uses random numbers (sampling, shuffling,
mutation). Runs are only debuggable and gradeable if they are
reproducible, so every script seeds its random number
generator from `the.seed`.

```
[19]> math.randomseed(l.the.seed);
[20]> math.random()
7.826369259e-06
[21]> math.randomseed(l.the.seed);
[22]> math.random()
7.826369259e-06
```

Same seed, same number. When an experiment "sometimes fails",
your first question is now: what was the seed?

> **SEED — seeded randomness.** Stochastic algorithms must be
> rerunnable: seed the generator, record the seed, vary it
> deliberately (and only deliberately). luamine reseeds before
> every test action so each runs independent of the others.

**Check:** why does `lua luamine-eg.lua --all` reseed before every
test, rather than once at startup?

One final discipline runs at every exit. In Lua, any
variable not declared `local` silently becomes global —
shared state leaking across files. So luamine snapshots the
globals at startup (`b4`) and, after main, prints `rogue?`
for anything new. Hygiene, enforced by the runtime, every
run.

> **ROGUE — enforced hygiene.** Don't just adopt a
> cleanliness rule (no global leaks); make the program
> AUDIT the rule on every run and name violators. A
> convention checked by machinery survives; one checked by
> code review decays. See `b4` (top of each loader) and `l.main` in cli.lua.

## 1.6 Preview: the whole movie

Fair warning: the next three lectures are groundwork —
lists, statistics, tables, distance. Worth doing properly,
but you signed up for AI. So here is where this road goes,
run from your shell right now, zero understanding required:

    $ lua luamine-eg.lua --tree
        n     Lbs-   Acc+   Mpg+  disty  tree                
       32  2906.16  15.83  26.25   0.53  .                   
       16  2233.31  17.34  33.75   0.34  Volume <= 120       
       12  2282.42  18.10  33.33   0.32  |  origin ~= 3      
        8  2086.88  18.18  36.25   0.27  |  |  Volume <= 98  
    +   4     2095     20     40   0.17  |  |  |  Model > 78 
        4  2078.75  16.35  32.50   0.37  |  |  |  Model <= 78
        4  2673.50  17.95  27.50   0.42  |  |  Volume > 98   
        4     2086  15.08     35   0.40  |  origin == 3      
       16     3579  14.33  18.75   0.73  Volume > 120        
        8  2926.38  15.72  21.25   0.61  |  Clndrs <= 6      
        8  4231.62  12.93  16.25   0.85  |  Clndrs > 6       
        5  4040.20  13.38     18   0.82  |  |  Volume <= 350 

A decision tree that found the good cars (`+`) and the bad
ones (`-`) from 32 labels — built by lecture 6's code. And:

    $ lua luamine-eg.lua --race
    who      eval  gen  disty     Lbs-   Acc+   Mpg+
    average     -    -   0.50  2970.42  15.57  23.84
    ga          1    1   0.15     2035  22.20     30
    ga          4    1   0.14     1835  20.50     30
    de         20    1   0.09     2130  24.60     40
    de        152    4   0.07     1985  21.50     40

Four optimizers racing; the best car in the whole table
found by evaluation 152 of 2000+ — lecture 9's code. Every line of both programs
will be yours: the tree costs ~40 lines, the race ~80, and
they stand on the ~150 lines of "groundwork" we start now.
That ratio is the course: the boring parts ARE the AI.

**Check:** both commands run before you understand them.
What, in lecture 1 terms, made that possible? (Hint: `[5]`,
`[15]`.)

## Recap

REPL prompts covered: 1-22. You can now: load the system,
read and override its one config table ([CONF](#glossary)),
coerce and pretty-print values, stream a self-describing CSV
([CSV](#glossary)), and rerun any stochastic result exactly
([SEED](#glossary)).

**Exercises.**

1. Rerun `[15]`-`[16]` on a different file from
   `$MOOT/optimize/`. Which columns are goals?
2. From the shell: `lua luamine-eg.lua --seed 7 --kpp`. Run it
   twice. Same output? Now drop the `--seed 7`. Explain.
3. Write a five-line REPL loop that counts the `?` cells in
   auto93.csv. (Hint: `[17]` plus an inner loop.)
4. Field trip: `lua lib.lua -t $MOOT/optimize/config/SS-X.csv --the`
   then count its rows with the `[17]` loop. (86,058 — and your
   laptop shrugged.)

[contents](#contents)

---

<a name="l2"></a>
# Lecture 2: Lists and Incremental Statistics

AI codes are mostly list-wrangling plus a little statistics.
This lecture covers both, in about thirty lines of library
code. The statistics half introduces the single most reused
function in the whole system: Welford's incremental update.
Master `[34]`-`[38]` and lectures 3 through 10 will feel easy.

Start your REPL as in `[1]`-`[3]`.

**Where this bites.** Project-health dashboards watch
streams of repository metrics — commits, churn, issue
close-times — and must summarize them as they fly past,
in constant memory. Today's thirty lines of list and stats
helpers are that machinery.

## 2.1 sort, map, copy

The list helpers are one-liners but they fix Lua's sharp
edges: `table.sort` returns nothing, so `l.sort` returns the
table; `l.copy` lets us sort without destroying the original.

    function m.sort(t,fn) table.sort(t,fn); return t end
    function m.map(t,fn,    u)
      u={}; for _,v in ipairs(t) do u[1+#u]=fn(v) end; return u end

```
[23]> t = {3,1,4,1,5}
[24]> l.o(l.sort(l.copy(t)))
{1, 1, 3, 4, 5}
[25]> l.o(t)
{3, 1, 4, 1, 5}
[26]> l.o(l.sort(l.copy(t), function(x,y) return x > y end))
{5, 4, 3, 1, 1}
[27]> l.o(l.map(t, function(x) return x * 10 end))
{30, 10, 40, 10, 50}
```

`[25]` shows `t` survived: copy first, then mutate. Functions
are values in Lua, so `[26]` passes the comparator inline.

**Check:** what breaks if you call `l.sort(t)` twice with two
different comparators, without copies?

## 2.2 keysort, slice, shuffle

`l.keysort(t, fn)` sorts by a derived key (decorate, sort,
undecorate). `l.slice` is Python's `t[lo:hi]` with negative
indexing. `l.shuffle` is the Fisher-Yates shuffle, in place.

```
[28]> rows = {{"bob",30}, {"alice",25}, {"carol",35}}
[29]> l.o(l.keysort(rows, l.nth(2))[1])
{alice, 25}
[30]> l.o(l.slice({10,20,30,40,50}, 2, 4))
{20, 30, 40}
[31]> l.o(l.slice({10,20,30,40,50}, -2))
{40, 50}
[32]> math.randomseed(l.the.seed);
[33]> l.o(l.shuffle{1,2,3,4,5,6})
{5, 3, 2, 4, 6, 1}
```

keysort is how this system does nearly everything: "rows
sorted by distance", "candidates sorted by score" are both
one keysort call. Note `[32]`: we reseed before the shuffle
so `[33]` is reproducible ([SEED](#glossary)).

**Check:** `keysort` calls `fn` once per item; naive
`sort(t, function(a,b) return fn(a)<fn(b) end)` calls it
O(n log n) times. When does that difference matter?

## 2.3 Running mean and sd: Welford

Here is the workhorse. Given a new value `v` and the state
`(n, mu, m2)`, Welford's rule updates the count, mean, and sum
of squared deviation in O(1), no stored list:

    function m.welford(v,n,mu,m2,w,    d)
      w = w or 1
      n=n+w; d=v-mu; mu=mu+w*d/n; return n,mu, m2+w*d*(v-mu) end

```
[34]> n, mu, m2 = 0, 0, 0
[35]> for _,x in ipairs{1,2,3,4,5} do n,mu,m2 = l.welford(x,n,mu,m2) end
[36]> mu
3.0
[37]> l.sd(n, m2)
1.58113883
[38]> l.welfords{1,2,3,4,5}
3.0	1.58113883
```

Standard deviation falls out as `(m2/(n-1))^0.5`. `welfords`
is the batch convenience wrapper; the incremental form is the
one the learners use.

> **WEL — Welford incremental moments.** Mean and sd updated
> per-arriving-value, constant space, no second pass, better
> numerical stability than the sum-of-squares shortcut. This
> is why every learner in this course can run on streams.
> Ref: Welford 1962; Knuth TAOCP v2.

**Check:** the textbook `sd = sqrt(E[x^2] - E[x]^2)` formula
can return negative numbers under floating point. Why can't
Welford's `m2`?

## 2.4 mode, entropy, rank

Symbols get counted in a dictionary `{key=count}`. Their
central tendency is the mode; their spread is entropy: the
number of bits needed to transmit the distribution.

```
[39]> l.mode{a=3, b=5, c=1}
b
[40]> l.ent{a=1, b=1, c=1, d=1}
2.0
[41]> l.ent{a=4}
0.0
[42]> sorted = {10,20,20,30,50}
[43]> l.bisect(sorted, 20)
3
[44]> l.bisect(sorted, 25)
3
[45]> l.bisect(sorted, 5)
0
```

`[40]`: four equally likely symbols need two bits. `[41]`: a
sure thing needs zero. `l.bisect` binary-searches a sorted
list, returning how many items are <= x — the building block
for the rank statistics in lecture 10.

> **ENT — entropy as spread.** For symbols, "variance" makes
> no sense; entropy `-sum(p log2 p)` plays the same role:
> zero when pure, maximal when uniform. Lecture 6 grows trees
> by cutting data to minimize it. Ref: Shannon 1948.

**Check:** which is "more spread": `{a=50,b=50}` or
`{a=98,b=1,c=1}`? Guess, then compute with `l.ent`.

## 2.5 Theory: why these statistics

Why do mean and sd summarize a Num? Because of the central
limit theorem: sums of many small independent effects drift
toward the normal (gaussian) distribution, the bell curve
fully described by exactly two numbers, mu and sd. That is
also why `l.irwinHall` works (`[35]`-ish, lecture 1 seeds):
the sum of three uniform randoms is already so close to
gaussian that we use it as a cheap normal generator — no
Box-Muller trigonometry required.

And why entropy, ranks, and (later, lecture 10) CDF gaps
instead of more gaussians? Because real SE data is routinely
skewed, multi-modal, and contaminated: effort datasets have
million-hour outliers; config landscapes have cliffs. The
gaussian summaries are cheap first sketches; whenever a
decision matters, this codebase switches to rank-based,
distribution-free machinery (bisect here; cliffs+ks in
lecture 10) that makes no shape assumptions at all.

Two pictures of any distribution recur all course, so fix
them now. The PDF (probability density) is the histogram's
smooth limit: its height at x says how COMMON values near x
are; the gaussian's bell is a pdf. The CDF (cumulative
distribution) at x answers a different question: what
FRACTION of values fall at or below x? It runs 0 to 1,
always rising; medians and percentiles are just the CDF
read sideways. Watch for both: lecture 4's norm squashes
values through a gaussian-shaped CDF; lecture 5's `like`
reads heights off a gaussian PDF; lecture 7's anomaly
detector reports positions on an empirical CDF; lecture
10's KS test measures the gap between two CDFs.

> **PDF/CDF — density vs cumulation.** pdf(x) = how common
> is x; cdf(x) = what fraction sits at or below x. Same
> distribution, two views: heights answer likelihood
> questions, cumulations answer rank and percentile
> questions. en.wikipedia.org/wiki/Cumulative_distribution_function

> **CLT — central limit theorem.** Sums of independent
> effects tend gaussian, which is why (mu, sd) is a fair
> two-number sketch of well-behaved columns — and why
> Irwin-Hall(3) fakes a normal from three uniforms. When
> data stops being well-behaved, switch to ranks.

**Check:** `l.ent` and `l.sd` both measure "spread". Give
one concrete column where sd is the wrong choice and
entropy is the only option.

## Recap

REPL prompts covered: 23-45. Lists: sort/map/copy/keysort/
slice/shuffle. Numbers get mean and sd incrementally
([WEL](#glossary)); symbols get mode and entropy
([ENT](#glossary)); bisect ranks values in sorted lists.

**Coming attraction:** `lua luamine-eg.lua --kmeans` — lecture 5
clusters cars using nothing but this lecture's sort, shuffle,
and Welford.

**Exercises.**

1. Redo `[34]`-`[37]` over the `Lbs-` column of auto93.csv
   (column 6; reuse the csv loop from `[17]`).
2. Time `l.keysort` vs naive comparator-sort on 10,000 random
   rows where the key calls `math.exp` twice. (os.clock.)
3. Plot (by hand) `l.ent{a=k, b=100-k}` for k = 0,10,...,100.
   Where is the peak, and why?
5. Field trip: welford the first numeric column of
   $MOOT/optimize/process/pom3a.csv (20,000 software-process
   simulations). mu, sd?

[contents](#contents)

---

<a name="l3"></a>
# Lecture 3: Summaries — Num, Sym, Data

A learner does not need your data; it needs a summary of your
data. luamine has exactly two summary types: `Num` for numbers,
`Sym` for symbols. Everything bigger — columns, tables, whole
models — is built by composing them. By the end of this
lecture, one line of code loads a 398-row CSV into a fully
summarized table.

**Where this bites.** The MOOT repo holds 124 optimization
tasks from recent SE papers — config tuning, process
models, effort estimation — from 197 to 86,000 rows, 3 to
88 options. All share one shape: a CSV whose header names
inputs and goals. Today you build the type that eats all
124: summaries in O(columns), however many the rows.

## 3.1 Num

A `Num` watches a stream of numbers and maintains count `n`,
mean `mu`, and `m2` (for sd) via Welford ([WEL](#glossary)):

    function Num.add(i,v,w)
      if v=="?" or v==nil then return v end
      i.n,i.mu,i.m2 = l.welford(v, i.n, i.mu, i.m2, w)
      return v end

```
[46]> num = m.Num.new("Age")
[47]> for _,x in ipairs{20,30,40,50,60} do num:add(x) end
[48]> num:mid()
40.0
[49]> num:spread()
15.8113883
[50]> num:add("?")
?
```

`[50]`: missing values (`?`) pass straight through, ignored.
Every learner in this course inherits "don't know" handling
from this one line.

**Check:** after `[50]`, what is `num.n` — 5 or 6? Why does
that matter for the mean?

## 3.2 Sym

A `Sym` counts symbol frequencies in a hash. Its `mid` is the
mode; its `spread` is entropy ([ENT](#glossary)).

```
[51]> sym = m.Sym.new("color")
[52]> for _,x in ipairs{"red","red","blue","red"} do sym:add(x) end
[53]> l.o(sym.has)
{blue=1, red=3}
[54]> sym:mid()
red
```

Num and Sym answer the same three questions — `add(v)`,
`mid()`, `spread()` — with type-appropriate math. Same verbs,
different nouns.

**Check:** what is `sym:spread()` here? Compute by hand from
`{blue=1, red=3}`, then check in the REPL.

## 3.3 adds: one verb, any summary

`m.adds(src, it, fn)` folds anything — a list, or an iterator
like `l.csv` — into any summary. Default summary is a fresh
Num; `fn` extracts the value from each item.

```
[55]> m.adds({1,2,3,4,5}):mid()
3.0
[56]> m.adds({"a","a","b"}, m.Sym.new()):mid()
a
[57]> num2 = m.adds({{1,"a"},{2,"b"},{3,"c"}}, m.Num.new(), function(r) return r[1] end)
[58]> num2.mu
2.0
```

> **POLY — polymorphic add.** One `adds` loop serves Num, Sym,
> and (next block) whole Data tables, because they share the
> `add` protocol. New summary type? Write `new/add/mid/spread`
> and every existing pipeline accepts it. Liskov for poor
> people, in 7 lines.

**Check:** `m.adds(l.csv(file))` crashes. Why? (What does the
first csv row contain?)

## 3.4 Cols: the header is the schema

`Cols.new(names)` reads a header row and builds the right
summary per column, using the [CSV](#glossary) protocol from
lecture 1: leading capital = Num; `+`/`-`/`!` marks goals;
trailing `X` = ignore. Columns land in `all`, with the active
ones split into `x` (inputs) and `y` (goals).

```
[59]> cols = m.Cols.new{"Age","name","Mpg+","Lbs-","statusX"}
[60]> #cols.x
2
[61]> #cols.y
2
[62]> l.o(l.map(cols.y, function(c) return c.txt end))
{Mpg+, Lbs-}
[63]> cols.all[3].goal
1
[64]> cols.all[4].goal
0
```

`goal` records direction: 1 = maximize (`Mpg+`), 0 = minimize
(`Lbs-`). `statusX` was built but joined neither x nor y.
Notice what is ABSENT: no registration calls, no mapping
file, no per-column setup. Naming did everything.

> **COC — convention over configuration.** Encode the
> common decisions in naming conventions and defaults;
> demand explicit configuration only for the unusual.
> luamine needs zero schema declarations for any of MOOT's
> 124 tables. The cost — conventions must be learned — is
> paid once; configuration is paid per table. Rails
> doctrine (Hansson).

**Check:** which summary type did column `name` get, and from
which character in the protocol?

## 3.5 Data and clone

`Data` is rows plus their column summaries. Feed it the csv
iterator: first row builds Cols, every later row is stored and
summarized, one pass, constant extra memory.

    function Data.add(i,row)
      if not i.cols then i.cols = Cols.new(row)
      else i.cols:add(row); l.push(i.rows, row) end
      return row end

```
[65]> d = m.Data.new(l.csv(l.the.train))
[66]> #d.rows
398
[67]> l.o(d.cols:mid())
{5.46, 193.43, 104.47, 76.01, 1, 2970.42, 15.57, 23.84}
[68]> d2 = d:clone()
[69]> #d2.rows
0
[70]> l.o(d2.cols.names)
{Clndrs, Volume, HpX, Model, origin, Lbs-, Acc+, Mpg+}
```

`[67]` is the centroid: the mid of every column. `clone` gives
an empty table with the same schema — the trick that lets
lecture 5 build one sub-table per class, and lecture 7 build
one per cluster, all summarizing themselves as rows arrive.

> **NUM/SYM — incremental summaries everywhere.** The whole
> architecture is: streams update Nums and Syms; tables are
> just organized collections of them. Model update cost is
> O(columns) per row, so "relearn" is never a batch job.

**Check:** `d2 = d:clone(d.rows)` — predict `#d2.rows` and
`d2.cols:mid()`. Verify.

## 3.6 Theory: NOIR, and why two summaries suffice

Measurement theory (Stevens 1946) sorts every column you
will ever meet into four scales: Nominal (names; only == is
meaningful), Ordinal (ranks; < is meaningful, gaps are not),
Interval (gaps meaningful, no true zero: temperature in C),
Ratio (true zero: weight, time). The NOIR hierarchy decides
which math is legal: modes and entropy for nominal; medians
and ranks for ordinal; means and sds only from interval up.

luamine's deliberate simplification: everything collapses to
Sym (nominal) or Num (interval/ratio), with ordinal data
treated as numeric when it is digits and nominal otherwise.
That is a modeling choice, not a law — and it is exactly the
kind of choice the [CSV](#glossary) header protocol makes
visible instead of burying in code.

One more design note. `Sym.add` and `Num.add` here only ever
ADD. A `sub` (forget one row) is a 6-line extension —
Welford runs backwards — and it buys incremental
cross-validation and sliding-window learning over streams.
The Python sibling of this codebase (ezr) has it; porting
`sub` is this lecture's hard exercise.

> **NOIR — know your scale.** Nominal, Ordinal, Interval,
> Ratio: each scale licenses some statistics and forbids
> others. Taking the mean of zip codes is not analysis.
> Stevens 1946.

**Check:** model-year (`Model`) in auto93 — which NOIR scale
is it really, and what does luamine treat it as? What
information does that lose?

## Recap

REPL prompts covered: 46-70. Num and Sym summarize streams
([WEL](#glossary), [ENT](#glossary)); `adds` folds anything
into any summary ([POLY](#glossary)); Cols turns a header into
schema ([CSV](#glossary)); Data is rows + Cols, built in one
pass; clone copies structure without data.

**Coming attraction:** the Num and Sym you just built are the
entire data layer: `lua luamine-eg.lua --bayes` (lecture 5) and
`lua luamine-eg.lua --tree` (lecture 6) run on nothing else.

**Exercises.**

1. Build a Num over `Acc+` (column 7) of auto93 two ways:
   with `m.adds` + csv, and with `m.Data.new` + reading
   `d.cols.all[7]`. Same mu?
2. Make `weird.csv` with header `{"Up+","downX","size"}`.
   Check which columns land in x and y.
3. `d:clone(l.slice(d.rows,1,50))` — how do the centroids
   `[67]` shift? Why?
4. Field trip: `m.Data.new` on
   $MOOT/optimize/config/SQL_AllMeasurements.csv. How many x
   columns, y columns, rows? What did the header tell you for
   free?

[contents](#contents)

---

<a name="l4"></a>
# Lecture 4: Distance Is All You Need

An astonishing amount of AI is just "how far apart are these
two things?". This lecture builds distance for mixed numeric/
symbolic rows with missing values, then aims it in two
directions: row-to-row (clustering, nearest neighbor) and
row-to-heaven (multi-objective optimization). Lectures 5-10
are applications of these ~30 lines.

**Where this bites.** Apache's server config table in MOOT:
192 configurations, each labeled with response time versus
CPU load. "Which config is best?" needs one number per row
that respects BOTH goals — and "which configs are similar?"
needs a distance that mixes numbers and symbols. Both ship
today.

## 4.1 norm: putting columns on one scale

Raw columns have wild ranges (weight in thousands, mpg in
tens). Before mixing them in one distance, `Num.norm` squashes
a value to 0..1 with a sigmoid centered on the column's mean:

    function Num.norm(i,v)
      if v=="?" then return v end
      v = (v - i.mu) / (i:spread() + 1E-32)
      return 1 / (1 + exp(-1.7 * max(-3, min(3, v)))) end

```
[71]> d = m.Data.new(l.csv(l.the.train))
[72]> mpg = d.cols.all[8]
[73]> mpg:norm(10)
0.05616169583
[74]> mpg:norm(24)
0.5079370208
[75]> mpg:norm(40)
0.9641830554
```

Mean mpg is ~23.8 (`[67]`), so 24 lands near 0.5; 10 and 40
push to the tails. The 1.7 makes the sigmoid approximate a
gaussian CDF; the clamp at +-3 sd tames outliers. In
[PDF/CDF](#glossary) terms, norm(v) answers: what fraction
of this column sits below v?

**Check:** why normalize by mean and sd rather than min and
max? (What does one outlier do to each scheme?)

## 4.2 distx: distance between rows

`m.distx` is Minkowski distance (`the.p` = 2: Euclidean) over
the x columns only. Numbers are normed then differenced;
symbols differ 0-or-1; if both values are missing, assume the
worst (distance 1); if one is missing, assume the other end of
the scale.

```
[76]> r1 = d.rows[1]
[77]> r2 = d.rows[2]
[78]> l.o(r1)
{8, 304, 193, 70, 1, 4732, 18.50, 10}
[79]> l.o(r2)
{8, 360, 215, 70, 1, 4615, 14, 10}
[80]> m.distx(d.cols, r1, r1)
0.0
[81]> m.distx(d.cols, r1, r2)
0.03973251937
```

Two big 1970 American 8-cylinder cars: distance 0.04. Note
the dimensions used: `HpX` is ignored and the three goal
columns sit in y, so only Clndrs, Volume, Model, origin count.

> **DIST — one distance for messy data.** Minkowski over
> normed numerics + Hamming (count the mismatches) over
> symbolics + pessimistic
> missing-value rules = one metric that accepts any CSV.
> Aha's heterogeneous distance, 1991. Everything downstream
> (clustering, kNN, trees, anomaly) reuses it.

**Check:** prove from the code that distx is symmetric, then
verify with `m.distx(d.cols,r2,r1)`.

## 4.3 disty: distance to heaven

The same trick scores quality. Heaven is the row where every
goal is perfect: normed `Mpg+` = 1, normed `Lbs-` = 0. A row's
`disty` is its distance to that ideal (0 = best, ~1 = worst):

    function m.disty(cols,row,  p,    d,n)
      d,n,p = 0,0,p or the.p
      for _,c in ipairs(cols.y) do
        n,d = n+1, d + abs(c:norm(row[c.at]) - c.goal)^p end
      return (d/n)^(1/p) end

```
[82]> dy = function(r) return m.disty(d.cols, r) end
[83]> best = l.keysort(l.copy(d.rows), dy)[1]
[84]> l.o(best)
{4, 90, 48, 78, 2, 1985, 21.50, 40}
[85]> worst = l.keysort(l.copy(d.rows), dy, l.gt)[1]
[86]> l.o(worst)
{8, 455, 225, 73, 1, 4951, 11, 10}
[87]> dy(best)
0.0745678279
[88]> dy(worst)
0.9564862405
```

The best car in auto93: light (1985 lbs), 40 mpg. The worst:
a 4951-lb 10-mpg monster. Nobody labeled these rows; the
header's `+`/`-` marks did all the work.

> **D2H — distance to heaven.** Collapse many goals into one
> number = distance to the ideal point. Cheap, smooth, and
> (unlike weighted sums) cares about balance: terrible on one
> goal can't hide behind great on another when p=2.

disty is one member of the aggregation-function family.
With `the.p=2` it is Euclidean distance to heaven; raise p
and large deviations dominate, until at p=infinity only the
WORST goal matters — that limit is the Chebyshev function
used by MOEA/D and by luamine's Python sibling ezr. Same code,
one knob: how much may strength on one goal pay for
weakness on another?

**Check:** would `dy` change if `Acc+` were renamed `AccX`?
Where exactly in the code?

## 4.4 near: k nearest neighbors

Nearest neighbors = keysort rows by distance to a query. The
query itself (same table reference) is parked at the far end
so "nearest" never means "myself".

```
[89]> sorted = m.near(d.cols, r1, d.rows)
[90]> l.o(sorted[1])
{8, 304, 150, 70, 1, 3433, 12, 20}
[91]> l.o(sorted[2])
{8, 302, 140, 70, 1, 3449, 10.50, 20}
```

The closest car to r1 matches it on Volume=304, Clndrs=8,
Model=70, origin=1 — exact in nearly every x dimension.

> **KNN — instance-based learning.** No training step: the
> data is the model, queries are answered by their neighbors.
> Lecture 8 uses near() as a surrogate oracle; lecture 7 uses
> it for anomaly detection. Cover & Hart 1967.

**Check:** `m.near` cost is O(n) distances + a sort per query.
At what data size does that start to hurt? (Foreshadow:
lecture 7 fixes this with trees.)

## 4.5 dxdy views and Zitzler's better

`d:dxdy()` packages the distances into a view with `p` baked
in: `v.x(r1,r2)` for row-to-row, `v.y(r)` for row-to-heaven —
so downstream code never threads `p` around. Last, `m.better`
is an alternative to [D2H](#glossary): Zitzler's continuous
domination predicate, which compares two rows goal-by-goal,
summing exponential losses in both directions.

```
[92]> v = d:dxdy()
[93]> v.x(r1, r2)
0.03973251937
[94]> m.better(d, best, worst)
true
[95]> m.better(d, worst, best)
false
```

> **ZIT — continuous domination.** "a beats b" if swapping
> a for b loses less than swapping b for a, with losses
> exponentially weighted per goal. Smoother than boolean
> "Pareto domination" (a beats b only if no worse on every
> goal, better on one — lecture 9); gives a total order
> even on trade-offs.
> Zitzler & Kunzli 2004. Lecture 9's genetic algorithm
> selects parents with this.

**Check:** can `m.better(d,a,b)` and `m.better(d,b,a)` both
be false? Both true? Try a few row pairs.

## 4.6 Theory: normalization, three ways

`Num.norm`'s sigmoid (`[73]`-`[75]`) is one of three standard
moves, each with a failure mode:

    min-max    (v-lo)/(hi-lo)     one outlier crushes
                                  everything else into a
                                  corner of [0,1]
    z-score    (v-mu)/sd          unbounded; a distance built
                                  on it is dominated by its
                                  wildest column
    sigmoid    squash z through   bounded AND outlier-
               1/(1+e^-1.7z)      resistant; the 1.7 makes
                                  it track the gaussian CDF

So luamine's norm is "z-score, then make it bounded": the worst
of a column's influence on `[81]`-style distances is capped,
no matter how broken one cell is. The +-3 clamp inside norm
is the same instinct one more time.

The missing-value rules in `m.distx` (`?` vs `?` = 1; `?` vs
v = assume the far end) are deliberately pessimistic: when
you do not know, assume the rows differ. The alternative —
assume similar — quietly glues unknown rows together and
poisons clustering. Pessimism degrades gracefully; optimism
fails silently.

**Check:** construct a 5-row column where min-max and
sigmoid normalization order two query rows DIFFERENTLY for
`[89]`-style nearest neighbor. (Hint: one huge outlier.)

## Recap

REPL prompts covered: 71-95. norm puts columns on one 0..1
scale; distx measures row-to-row over x cols
([DIST](#glossary)); disty measures row-to-ideal over y cols
([D2H](#glossary)); near sorts by distance
([KNN](#glossary)); better gives a goal-aware total order
([ZIT](#glossary)).

**Coming attraction:** distance is the last foundation. From
here every lecture is AI: `lua luamine-eg.lua --acquire` already
runs on what you now know.

**Exercises.**

1. Find the two most similar cars in auto93 (min distx over
   all pairs — a double loop is fine at n=398).
2. Sort all rows by dy and print the top 5 and bottom 5 with
   `l.o`. Sanity-check them against your intuition.
3. For 50 random pairs, compare `dy(a) < dy(b)` with
   `m.better(d,a,b)`. How often do D2H and ZIT disagree?
4. Field trip: load
   $MOOT/optimize/config/Apache_AllMeasurements.csv; find its
   best and worst configs by dy (`[83]`/`[85]` style). Read
   them aloud: do they make engineering sense?

[contents](#contents)

---

<a name="l5"></a>
# Lecture 5: Two Classics — Naive Bayes and k-means

Sixty lines of code buys two famous learners: a Naive Bayes
classifier (supervised: learn from labels) and k-means
clustering (unsupervised: find structure without labels).
Both are thin loops over the machinery you already know:
Num/Sym summaries and distance.

**Where this bites.** Defect predictors and test-triage
bots are mostly classifiers under the hood — and in study
after study, naive Bayes remains the embarrassing baseline
that fancier models barely beat. Meanwhile workload
clustering (group similar configs, tune one per group) is
k-means wearing overalls. Both, today, in 60 lines.

## 5.1 like: evidence from one column

Given a value, how likely is it under one column's summary?
Syms: frequency with m-estimate smoothing. Nums: gaussian
probability density at v.

    function m.like(col,v,prior,    sd,z)
      if not col.mu then
        return ((col.has[v] or 0) + the.k*prior)
               / (col.n + the.k) end
      sd = col:spread() + 1E-32; z = 2 * sd * sd
      return exp(-(v-col.mu)^2 / z) / sqrt(pi * z) end

```
[96]> d = m.Data.new(l.csv(l.the.train))
[97]> origin = d.cols.all[5]
[98]> m.like(origin, 1, 0.5)
0.6253132832
[99]> m.like(origin, 3, 0.5)
0.1992481203
[100]> mpg = d.cols.all[8]
[101]> m.like(mpg, 24, 0.5)
0.04782233452
[102]> m.like(mpg, 80, 0.5)
6.862944451e-12
```

(The `prior` argument is the class's base rate — what
fraction of all rows belong to the class asking; 0.5 here
is a placeholder until `[108]` supplies real ones.)
`[98]`: most cars are American (origin 1). `[102]`: an 80-mpg
car is ten-billion-to-one against, under this data. Note the
direction of the question: like reads HEIGHTS off the
gaussian pdf — "how common is this value?" — where lecture
4's norm read positions off the CDF ([PDF/CDF](#glossary)).

> **MEST — m-estimate smoothing.** Never let an unseen value
> zero out a whole product of probabilities: blend observed
> frequency with `k` imaginary prior-weighted samples
> (`the.k=1`, `the.m=2`). Cestnik 1990. The difference
> between a classifier and a divide-by-zero generator.

**Check:** with `the.k=0`, what is `m.like` of a never-seen
symbol? Why is that fatal in the next block?

## 5.2 likes: evidence from a whole row

Naive Bayes assumes columns are independent, so row
likelihood = product of column likelihoods x class prior.
Products of tiny numbers underflow; sums of logs do not:

    out = log(prior)
    ... out = out + log(m.like(c, row[c.at], prior))

We build one `clone` per class ([POLY](#glossary) at work),
then ask: which class makes this row least surprising?

```
[103]> dd = m.Data.new(l.csv(l.path"$MOOT/classify/diabetes.csv"))
[104]> #dd.rows
768
[105]> dd.cols.klass.txt
class!
[106]> h = {}
[107]> for _,r in ipairs(dd.rows) do k = r[dd.cols.klass.at]; h[k] = h[k] or dd:clone(); h[k]:add(r) end
[108]> m.likes(h.tested_positive, dd.rows[1], #dd.rows, 2)
-28.78134884
[109]> m.likes(h.tested_negative, dd.rows[1], #dd.rows, 2)
-29.49005611
[110]> dd.rows[1][dd.cols.klass.at]
tested_positive
```

Higher log-likelihood (less negative) wins: `[108]` beats
`[109]`, predicting tested_positive — and `[110]` confirms
that is the true label. One row, correctly classified.

> **NB — naive Bayes.** Assume feature independence (false,
> usually; harmless, usually), multiply per-column evidence,
> pick the max. Fast, incremental, shockingly competitive on
> small data. Domingos & Pazzani 1997 explain why being
> wrong about independence rarely hurts the argmax.

**Check:** why log-sum instead of multiplying probabilities?
What happens to 35 columns of soybean.csv without logs?

## 5.3 classify: test, then train

The incremental discipline: for each arriving row, predict
first, score the prediction, then learn the row. No
train/test split needed; every row is honest test data.

```
[111]> cf = a.classify(dd)
[112]> cf:show()
   tn    fn    fp    tp   acc  pred    pf    pd     n file     filename
  154    93   109   403    73    79    41    81   759 tested_negative 
  403   109    93   154    73    62    19    59   759 tested_positive 
[113]> s = cf:scores()[1]
[114]> l.o{klass=s.klass, acc=s.acc, pd=s.pd, pf=s.pf}
{acc=73.39, klass=tested_negative, pd=81.25, pf=41.44}
```

(One quirk: in `show`, the second-to-last column is the
class.) 73% accuracy on diabetes, no tuning, after a single
streaming pass.

> **ACC — score beyond accuracy.** Per class: recall pd
> (caught how many?), false alarm pf (cried wolf how often?),
> precision. Accuracy alone lies under class imbalance —
> here, "always say negative" scores 65% while catching no
> diabetes at all.

Three classic threats hide here, each countered by ritual.
OVERFITTING: a learner that memorizes training trivia aces
training data and flunks the future — so always score on
rows not yet learned (test-then-train does this by
construction). ORDER EFFECTS: if a hospital dump lists all
women before all men, an incremental learner is an expert
on half the problem — so shuffle first, reproducibly
([SEED](#glossary)). LEARNER VARIABILITY: n shuffles give n
models — so repeat and report distributions (lecture 10).
The standard packaging is m-by-n cross-validation: m
shuffles, n bins, train on n-1, test on the holdout. For
streaming data: train on the past, test on the next window,
slide forward (temporal validation).

> **XVAL — cross-validation ritual.** Shuffle (kills order
> effects), hold out test bins (catches overfitting),
> repeat m times (exposes variability). m=n=5 gives 25
> train/test pairs — distribution enough for lecture 10's
> statistics.

**Check:** which class is harder to catch (lower pd)? Is the
prior `(#rows+m)/(total+m*nKlasses)` part of the reason?

## 5.4 kmeans

Unsupervised now: pick k random rows as centroids, assign
every row to its nearest centroid ([DIST](#glossary)), make
each cluster's new centroid its column mids, repeat.

```
[115]> math.randomseed(l.the.seed);
[116]> clusters, errs = a.kmeans(d, 5, 4)
[117]> #clusters
5
[118]> l.o(errs)
{0.20, 0.19, 0.19, 0.19}
[119]> l.o(clusters[1].cols:mid())
{7.52, 328.58, 152.30, 71.78, 1, 3946.35, 13.11, 14.46}
```

`[118]`: mean intra-cluster distance falls, then plateaus —
the first iteration did almost all the work.
`[119]`: cluster 1 found the heavy American gas-guzzlers,
without ever seeing a label. Each cluster is a `Data` clone:
its centroid is just `cols:mid()` ([POLY](#glossary) again).

> **KM — k-means.** Iterative centroid refinement; cost
> O(n*k) per pass; finds local optima of within-cluster
> variance. MacQueen 1967. The default first move on any
> unlabeled data.

**Check:** why must the errs sequence (`[118]`) be
non-increasing? When could it stall above zero?

## 5.5 kmeans++ seeding

Random initial centroids can land adjacent, wasting clusters.
kmeans++ picks seeds far apart: each new centroid is sampled
with probability proportional to squared distance from the
nearest existing one.

```
[120]> math.randomseed(l.the.seed);
[121]> cents = a.kpp(d, 5, 64)
[122]> #cents
5
[123]> l.o(cents[1])
{8, 304, 193, 70, 1, 4732, 18.50, 10}
```

`a.kpp` samples candidates from `the.few` random rows per
step, so seeding stays cheap even on big tables. Feed these
to kmeans: `a.kmeans(d, 5, 4, cents)`.

**Check:** in `a.kpp`, why weight by d^2 rather than d?
(What does squaring do to the preference for far points?)

## 5.6 Naive Bayes by hand

The REPL hides the arithmetic; do it once on paper. The
classic 14-row play-golf table: 9 yes, 5 no. Classify
`outlook=sunny, windy=true`:

    priors      P(yes)=9/14=.64        P(no)=5/14=.36
    sunny       P(sunny|yes)=2/9=.22   P(sunny|no)=3/5=.60
    windy       P(windy|yes)=3/9=.33   P(windy|no)=3/5=.60
    product     .64*.22*.33 = .047     .36*.60*.60 = .129

"no" wins, 0.129 to 0.047. Two things to notice. First,
these are NOT probabilities of anything (they don't sum to
1, and independence is false); they are RANKING scores, and
ranking is all classification needs. Second: had sunny
never occurred with yes, that zero would erase every other
piece of yes-evidence in the product — which is exactly why
`[98]`'s m-estimate ([MEST](#glossary)) and `[108]`'s log
space exist.

A warning for SE data: with skewed classes, report
per-class pd and pf (`[112]`), never just accuracy or
precision. Precision = tp/(tp+fp) swings wildly when the
target class is rare — at 1% prevalence, even a good
detector's precision can sit under 30% while pd is fine.
Chasing precision on rare-event SE data (defect prediction,
incident triage) is how teams talk themselves out of
working detectors. (Menzies et al., "Problems with
Precision", IEEE TSE 2007.)

**Check:** redo the arithmetic above with Laplace k=1
smoothing (add 1 to every count, adjust denominators).
Which class wins now?

## 5.7 Experiment design: does kmeans++ help?

`[118]` showed one run. One run proves nothing for any
seeded algorithm ([SEED](#glossary)). The honest protocol,
runnable tonight:

    for seed in 1..20:
      reseed; kmeans(d, 8, 10)        -> final err
      reseed; kmeans(d, 8, 10, kpp())  -> final err
    compare the two 20-number distributions

Random seeding's distribution is WIDE (sometimes lucky,
sometimes two centroids land adjacent and waste a cluster);
kpp's is tight. Whether the MEANS differ is a lecture-10
question (`l.same`, [EFF](#glossary)) — the protocol here,
distributions-not-anecdotes, is the result that generalizes.

Also worth knowing: clusters are models. Label each cluster
with its majority class and you have a classifier; predict
with each cluster's y-centroid and you have a regressor
(nearest-cluster lookup, `[119]`). Unsupervised structure +
a handful of labels = lecture 10's whole agenda, previewed.

**Check:** why must the comparison above reseed BOTH
variants identically per trial, rather than using seeds
1..20 for kmeans and 21..40 for kmeans++?

## Recap

REPL prompts covered: 96-123. like scores one value
([MEST](#glossary)); likes log-sums a row's evidence;
classify is test-then-train NB ([NB](#glossary)) scored
honestly ([ACC](#glossary)); kmeans/kpp cluster unlabeled
data with the lecture-4 distance ([KM](#glossary)).

**Exercises.**

1. Run `a.classify` on `$MOOT/classify/soybean.csv` (35
   columns, 19 classes). Report acc and the worst-pd class.
2. Vary `the.k` and `the.m` (0, 1, 2, 8) on diabetes. Plot
   accuracy. Where does smoothing stop mattering?
3. Re-run `[115]`-`[118]` with k=2 and k=20. How do the
   final errs compare, and why is "lower err" not the same
   as "better k"?
4. Field trip: kmeans (k=8) on
   $MOOT/optimize/config/SS-A.csv; print each cluster's
   centroid. Are the clusters' y-goals (`[119]` style)
   genuinely different?

[contents](#contents)

---

<a name="l6"></a>
# Lecture 6: Explanation — Cuts and Trees

Lecture 4 scored rows; this lecture explains the scores. We
discretize columns into candidate splits ("cuts"), pick the
cut that best separates good from bad, and recurse: a
decision tree. The payoff at `[140]` is a 13-line summary of
398 cars that you can read aloud to a manager.

**Where this bites.** A tuner tells a DBA: "flip these
three knobs on the production database." No competent DBA
obeys an unexplained model. The deliverable that survives
that meeting is not a score — it is a small tree the DBA
can read, argue with, and sign off on. Building it is
today's work.

## 6.1 cuts: candidate splits

A `Cut` is one test: `op(row[at], val)`. Num columns emit
`bins-1` percentile-spaced `<=` cuts; Sym columns emit one
`==` cut per seen value.

```
[124]> d = m.Data.new(l.csv(l.the.train))
[125]> clndrs = d.cols.x[1]
[126]> cuts = clndrs:cuts(d.rows)
[127]> #cuts
1
[128]> l.o{txt=cuts[1].txt, val=cuts[1].val, yes=cuts[1].yes, no=cuts[1].no}
{no=>, txt=Clndrs, val=4, yes=<=}
[129]> #d.cols.x[4]:cuts(d.rows)
3
```

`the.bins=2`, so each Num offers a single median cut:
"Clndrs <= 4". The Sym column origin offers three one-vs-rest
cuts (origins 1, 2, 3).

> **CUT — discretization.** Replace continuous ranges with a
> few crisp tests. Costs precision, buys readability, speed,
> and resistance to noise. Percentile spacing (not equal
> width) keeps each candidate split populated.

**Check:** set `l.the.bins = 8` and rerun `[126]`-`[127]`.
How many cuts now, and at what values?

## 6.2 apply and score a cut

`apply` partitions rows (missing values fall on the side of
the column's mid). `score` is the size-weighted spread of the
two sides' y-summaries — i.e., "after this split, how
uncertain is the goal, on average?". Lower is better.

```
[130]> y = function(r) return m.disty(d.cols, r) end
[131]> ls, rs = cuts[1]:apply(d.rows, y, m.Num.new)
[132]> #ls, #rs
208	190
[133]> cuts[1]:score(d.rows, y, m.Num.new)
0.1469084345
```

Note the design: y is any function of a row, and the summary
type is pluggable — `m.Num.new` here (predicting a number — "regression" — on
[D2H](#glossary)), `m.Sym.new` for predicting a label
("classification"), where "spread" becomes entropy
([ENT](#glossary)).

**Check:** in `Cut.score`, why return `huge` when one side is
empty?

## 6.3 bestCut: the greedy choice

Try every cut of every x column; keep the minimizer.

```
[134]> best = m.bestCut(d.cols, d.rows, y, m.Num.new)
[135]> l.o{txt=best.txt, val=best.val}
{txt=Clndrs, val=4}
[136]> best:score(d.rows, y, m.Num.new)
0.1469084345
```

For predicting car quality, cylinder count beats volume,
model year, and origin. Greedy: we commit to this split and
never look back.

**Check:** how many (column, cut) pairs did `[134]` examine?
Count from `[127]`, `[129]`, and the number of x columns.

## 6.4 tree and show

Recurse bestCut on each half; stop when a side gets small.
`show` prints the result with per-node goal means, the n at
each node, and `+`/`-` tags on the best and worst leaves.

```
[137]> math.randomseed(l.the.seed);
[138]> tree = d:tree(nil, nil, 30)
[139]> l.o{txt=tree.txt, val=tree.val}
{txt=Clndrs, val=4}
[140]> m.show(tree, d.cols)
     n     Lbs-   Acc+   Mpg+  disty  tree              
   398  2970.42  15.57  23.84   0.53  .                 
   208  2309.87  16.54  29.33   0.35  Clndrs <= 4       
   107  2055.87  16.92  32.06   0.28  |  Volume <= 105  
+   56  1989.54  17.11  33.21   0.26  |  |  Volume <= 91
    51  2128.71  16.72  30.78   0.30  |  |  Volume > 91 
   101  2578.95  16.13  26.44   0.43  |  Volume > 105   
    45  2630.64  16.53     30   0.38  |  |  Model > 78  
    56  2537.41  15.80  23.57   0.48  |  |  Model <= 78 
   190  3693.56  14.51  17.84   0.72  Clndrs > 4        
   103  3281.84  16.09  20.58   0.61  |  Volume <= 302  
    87  4181.00  12.63  14.60   0.85  |  Volume > 302   
    32  4134.28  13.72  17.81   0.80  |  |  Model > 73  
-   55  4208.18  12.00  12.73   0.88  |  |  Model <= 73 
```

Read it like a story: small engines (top half) are lighter
and thriftier (disty 0.35); among them, tiny volumes (<= 91)
are best of all (`+`, disty 0.26). Big old engines
(Clndrs > 4, Volume > 302, Model <= 73) are worst (disty
0.88). Each branch is an if-then rule a human can audit.

> **TREE — greedy recursive partitioning.** CART/C4.5 family:
> repeatedly split on the test that most purifies the goal;
> stop at small leaves. Quinlan 1986. Accuracy is decent;
> the structure itself is the product.

> **XPLN — explanation as model.** When models guide human
> decisions, a 13-line auditable summary often beats an
> opaque scorer that is 2% more accurate. Trees, cuts, and
> tiny rules are the price of admission for trust, debugging,
> and (increasingly) regulation.

**Check:** rerun `[138]` with leaf=10. How many rows does
`show` print? At what leaf size does the tree stop being
something you would read aloud?

## 6.5 relevant and leafStats

To use a tree on a new row, walk it: at each node apply the
cut, descend yes/no, return the leaf's rows.

```
[141]> leaf = m.relevant(tree, d.rows[1])
[142]> #leaf
55
[143]> m.adds(leaf, m.Num.new(), y).mu
0.8832478267
[144]> m.adds(d.rows, m.Num.new(), y).mu
0.5288716402
[145]> ls = m.leafStats(tree)
[146]> ls.n
7
```

Row 1 (our 4732-lb 10-mpg friend from `[78]`) lands in the
`-` leaf: mean disty 0.88 vs the global 0.53. The tree has
opinions about your car. `leafStats` folds any per-leaf
function into a Num — default: leaf sizes, over the 7 leaves.

**Check:** `m.relevant` imputes missing values with
`node.mid`. Trace what happens to a row with Clndrs = "?".

## 6.6 Interpretable, not explainable

Two words that sound alike and aren't. An EXPLAINABLE
system is a black box plus a second model that rationalizes
it after the fact; an INTERPRETABLE system is transparent
all the way down — `[140]` IS the model, not a story about
one. Rudin's argument (2019): post-hoc explanations of
black boxes are unfaithful by construction (if they matched
the box exactly, they'd be the box), so for high-stakes
decisions, build interpretable models instead. The folklore
"accuracy needs opacity" keeps failing empirically:
Gigerenzer (2008) showed fast-and-frugal heuristics —
trees three questions deep — matching regression in
medicine and finance; Holte (1993) showed 1-level rules
within a few points of full decision trees on most UCI
data.

Honesty about the other side: what `[140]` can't do. It
won't extrapolate outside the data; near-tied cuts make
trees unstable under reshuffling (rerun `[138]` after a
shuffle and watch branches swap); and each leaf is a flat
average, blind to trends within it. Interpretability is a
contract about what you can SEE, not a guarantee you'll
like what you see.

> **INTERP — interpretable beats explained.** For decisions
> that need auditing, prefer models readable in the original
> (trees, rules, scoring sheets) over post-hoc stories about
> black boxes. The accuracy cost is usually small; measure
> it before assuming it. Rudin 2019; Gigerenzer 2008.

**Check:** find a published "explanation" of an ML system
you use (a saliency map, a chat rationale). What would it
take to check that the explanation is faithful?

## 6.7 The causal ladder

Pearl's ladder has three rungs: SEEING (association — rows
where Volume<=105 also show high mpg), DOING (intervention —
if we BUILD smaller engines, will mpg rise?), IMAGINING
(counterfactual — would THIS car have scored better with a
smaller engine?). Everything in this course so far —
`[140]` included — lives on rung one. The tree's branches
read like causes, and that reading is unearned: maybe small
volume causes high mpg, or maybe both follow from a design
brief ("economy car") we never measured.

Why care, in SE? Because configuration tuning, process
change, and refactoring decisions are all rung-two
questions asked of rung-one data. The honest moves: treat
the tree as a hypothesis generator; test its best branch
with an actual intervention (lecture 10's `acquire` is
exactly that — spend a label to CHECK, don't just trust);
and prefer data where someone varied x on purpose
(experiments) over data where x varied on its own (logs).

> **LADDER — association is rung one.** See / do / imagine
> are different questions with different data requirements;
> models built from observation answer only the first.
> Climbing costs interventions — budget for them. Pearl
> 2018.

**Check:** in auto93, propose one branch of `[140]` that is
probably causal and one that is probably confounded. What
extra column would settle it?

## Recap

REPL prompts covered: 124-146. Columns emit candidate cuts
([CUT](#glossary)); cuts are scored by post-split y-spread;
bestCut is the greedy minimizer; recursion gives a readable
tree ([TREE](#glossary), [XPLN](#glossary)); relevant routes
new rows to leaves; leafStats summarizes the leaves.

**Exercises.**

1. Build the tree with `m.Sym.new` as the summarizer over
   diabetes.csv, y = the class column. Print it. (This is a
   classification tree.)
2. For every row, compare its leaf's mean disty (`[143]`
   style) with its true dy. How correlated are they?
3. `the.bins=2` forces binary median cuts. Try 4 and 8:
   measure tree size and root score. Where is the
   readability/accuracy sweet spot?
4. Field trip: grow and `show` a tree (leaf=30) over
   $MOOT/optimize/config/X264_AllMeasurements.csv. Which two
   options dominate video-encoder performance?

[contents](#contents)

---

<a name="l7"></a>
# Lecture 7: Scale-Up — Random Projections, Synthesis, Anomalies

Lecture 6's tree consulted the y goals at every split:
supervised, and O(columns x rows x cuts) per level. This
lecture builds trees that never look at y, in near-linear
time — then spends the savings on two applications: making
fake data, and catching weird data.

**Where this bites.** That 86,000-row config table cannot
be exhaustively labeled. The bet of an entire family of
recent SE optimizers (SWAY, LINE, EZR) is that such spaces
COLLAPSE: most rows live in a few low-dimensional regions,
so a handful of well-placed probes maps the whole table.
Today you build that family's engine.

## 7.1 poles: two far points, fast

Finding the two most distant rows exactly costs O(n^2)
distances. The fastmap trick: pick any row, find something
far from it, then something far from THAT. Two passes, O(n).

```
[147]> d = m.Data.new(l.csv(l.the.train))
[148]> math.randomseed(l.the.seed);
[149]> v = d:dxdy()
[150]> p1, p2 = m.poles(v, d.rows)
[151]> l.o(p1)
{4, 86, 65, 79, 3, 1975, 15.20, 30}
[152]> l.o(p2)
{8, 360, 170, 73, 1, 4654, 13, 10}
[153]> v.x(p1, p2)
0.7947798843
```

A 1979 Japanese economy car versus a 1973 American
8-cylinder: distance 0.79 of a possible 1. (`poles` uses the 90th
percentile of distance, not the max, to dodge outliers.)

**Check:** in `m.poles`, why take `[1 + floor(0.9 * #rows)]`
instead of the very farthest row?

## 7.2 ftree: clustering as a fast tree

`ftree` recursively splits rows by which pole they are nearer
to: project each row onto the p1-p2 axis (`d(r,p1)-d(r,p2)`),
then find the single cut that best separates low projections
from high. The y columns are never consulted — yet look at
the disty column it never saw:

```
[154]> math.randomseed(l.the.seed);
[155]> ft = d:ftree(80, nil, #d.rows)
[156]> l.o{txt=ft.txt, val=ft.val}
{txt=Clndrs, val=4}
[157]> m.show(ft, d.cols)
     n     Lbs-   Acc+   Mpg+  disty  tree       
   398  2929.92  15.74  24.05   0.52  .          
+  222  2346.23  16.74  28.96   0.36  Clndrs <= 4
-  176  3666.17  14.47  17.84   0.72  Clndrs > 4 
[158]> m.leafStats(ft).n
2
```

Unsupervised structure recovered the supervised story of
lecture 6 — right down to choosing the SAME root cut
(Clndrs <= 4) as the goal-aware tree at `[140]`: small
engines good (0.36), big ones bad (0.72), goals never
consulted. When labels are expensive (lecture 10), this is
how we will decide WHICH rows are worth labeling.

*Today's bet ([BETS](#glossary), A7): big spaces collapse to a few low-dimensional regions, so sparse geometric probes suffice. Falsified when all dimensions interact globally.*

> **FMAP — random projections / fastmap.** Distance to two
> far poles is a cheap 1-D embedding of structure; recursing
> on it gives O(n log n) clustering. Faloutsos & Lin 1995;
> kin to Johnson-Lindenstrauss and random-projection LSH.

**Check:** `ftree` sampled `cap` rows with replacement. What
goes wrong (subtly) in `[157]`'s counts if cap >> #rows?

## 7.3 sample: synthetic rows

To make a plausible fake row: pick a leaf of the ftree (a
coherent region), grab three of its rows a,b,c, and blend
them, dimension by dimension, with the formula `a + F*(b-c)`
(borrowed from differential evolution, an optimizer we meet
properly in lecture 9).

```
[159]> math.randomseed(l.the.seed);
[160]> synth = a.sample(d, 50)
[161]> #synth
50
[162]> l.o(synth[1])
{4, 98.00, 68, 78, 1, 2155, 16.50, 30}
[163]> l.o(synth[2])
{4, 90.00, 48, 80, 2, 2335, 23.70, 40}
```

`[163]` is a 5-cylinder car that never existed, but its
weight, volume and mpg are mutually consistent — because all
three came from near-neighbors in one leaf.

> **SYNTH — model-based data synthesis.** Generate by
> recombining within local structure, not by sampling
> columns independently (which makes 4000-lb 40-mpg
> chimeras). Used for augmentation, privacy-preserving
> sharing, and stress-testing.

**Check:** y columns of synth rows are copied from parent
`a`, not blended. Find the line in `m.extrapolate`'s caller
(`a.sample`) that makes this true, and say why it matters.

## 7.4 Anomaly detection

Reverse the question: how UNLIKE the training data is this
row? Score = distance to the row's nearest neighbor within
its ftree leaf, calibrated against the same score computed
for every training row. Output is a CDF position ([PDF/CDF](#glossary)): ~0.5 =
typical, tails = strange.

```
[164]> math.randomseed(l.the.seed);
[165]> det = a.anomalyDetector(d)
[166]> det(d.rows[1])
0.3543458921
[167]> fake = l.copy(d.rows[1])
[168]> for _,c in ipairs(d.cols.x) do if c.mu then fake[c.at] = 1E6 end end
[169]> det(fake)
0.9892408222
[170]> bad = 0; for _,r in ipairs(synth) do c = det(r); if c < 0.1 or c > 0.9 then bad = bad + 1 end end
[171]> bad
2
```

`[166]`: a real row sits in the body. (Why 0.35 and not 0.5?
auto93's x-space is coarse — many cars share exact Clndrs/
Volume/Model/origin values, so the typical nearest-neighbor
distance is 0.) `[169]`: the million-pound car is past the
98th percentile. `[170]`-`[171]`: only 2 of 50 synthetic rows
land in a tail — synthesis mostly stays inside the regions
the real data occupies (its "manifold").

> **ANOM — anomaly = far from neighbors.** Score novelty by
> local distance, calibrate on training data, alarm on the
> tails. Same machinery as kNN + ftree; no labels needed.
> Kin to LOF (Breunig 2000) and isolation forests.

**Check:** `det` uses `the.p` and norm's +-3 sd clamp. Which
of the two keeps `[169]` from being even closer to 1.0?

## 7.5 Theory: spend evaluations like a search committee

This lecture's `cap` (sample before building) is one
instance of a general principle: don't spend equal effort
on all candidates. The literature on tuning learners' own
config knobs ("hyperparameters") made it famous. SUCCESSIVE HALVING: give n candidates a
tiny budget each, keep the best half, double their budget,
repeat — most contenders die cheap, champions get the full
treatment. HYPERBAND runs several halving brackets at
different aggressiveness so no single "how fast to kill"
guess is fatal. ASHA does it asynchronously across workers,
promoting on the fly.

The shared bet is the [SIMP](#glossary) bet: bad candidates
reveal themselves early, so deep evaluation of everything
is mostly waste. ftree's cap, acquire's tiny label budget
(lecture 10), and Hyperband's brackets are one idea at
three scales: triage first, examine later.

> **MFID — multi-fidelity triage.** Evaluate cheaply and
> shallowly everywhere; spend real budget only on
> survivors. Successive halving (Karnin 2013), Hyperband
> (Li 2018), ASHA (Li 2020).

**Check:** successive halving can kill a slow-starting
eventual winner. Which of its parameters controls that
risk, and what does raising it cost?

## Recap

REPL prompts covered: 147-171. poles finds far rows in O(n)
([FMAP](#glossary)); ftree clusters by pole-projection,
recovering goal structure without goals; sample blends
leaf-local rows into plausible fakes ([SYNTH](#glossary));
anomalyDetector calibrates leaf-local NN distance into a CDF
alarm ([ANOM](#glossary)).

**Exercises.**

1. Run `[154]`-`[157]` five times without reseeding. How
   stable are the root cut and the leaf distys?
2. Generate 500 synth rows; run `a.classify`-style NB with
   classes {real, synth}. If NB can't tell them apart,
   what does that say about the generator?
3. Hand-craft three "subtle" anomalies (one wrong unit, one
   impossible combo, one merely rare). Which does `det`
   catch? At what CDF?
4. Field trip: ftree + anomalyDetector over
   $MOOT/optimize/process/coc1000.csv; score 50 synth rows.
   Saner or stranger than auto93's 5/50 (`[171]`)?

[contents](#contents)

---

<a name="l8"></a>
# Lecture 8: Search I — Mutation and (1+1) Optimizers

Optimization, finally. We have a scorer ([D2H](#glossary))
and a space of car-like rows; now we search that space for
rows better than any we were given. This lecture: how to
mutate a candidate, how to score candidates we invented (and
hence have no true y for), and the simplest searchers that
work — one parent, one kid, repeat.

**Where this bites.** Compiler-flag tuning is the classic
rugged landscape: one boolean flag flips a code path and
performance falls off a cliff. Greedy walking dies there —
which is why this lecture's two searchers differ exactly in
their willingness to step downhill. Each evaluation in that
world is a recompile plus a benchmark; budgets are real.

## 8.1 pick and picks: mutating rows

`m.pick(col, v)` samples a new value for one column: Syms by
observed frequency; Nums by a gaussian step around v, clamped
to mu +- 3 sd. `m.picks(data, row, n)` copies a row and
mutates n random x columns.

```
[172]> d = m.Data.new(l.csv(l.the.train))
[173]> math.randomseed(l.the.seed);
[174]> clndrs = d.cols.x[1]
[175]> m.pick(clndrs, 4)
1.914856556
[176]> row = l.copy(d.rows[1])
[177]> mut = m.picks(d, row, 2)
[178]> l.o(row)
{8, 304, 193, 70, 1, 4732, 18.50, 10}
[179]> l.o(mut)
{9.15, 304, 193, 69.30, 1, 4732, 18.50, 10}
```

`[179]`: Volume and Model changed; everything else (including
the y columns) is untouched parent. Mutants stay near the
data distribution because steps are scaled by column sd.

> **MUT — distribution-aware mutation.** Mutate within the
> observed spread of each dimension (sd steps, frequency
> draws), not uniformly over the type's range. Garbage-free
> neighborhoods make every later search dramatically cheaper.

**Check:** run `[175]` twenty times. Roughly what range do
you see, and how does that follow from clndrs.mu and sd?

## 8.2 extrapolate: blending rows

The other mutation operator: differential evolution's
`a + F*(b-c)`. Per dimension (with probability `the.cr`),
move A by F times the b-to-c difference; Syms flip to b's
value with probability F.

```
[180]> math.randomseed(l.the.seed);
[181]> A, B, C = d.rows[1], d.rows[100], d.rows[200]
[182]> kid = m.extrapolate(d.cols.x, A, B, C)
[183]> l.o(kid)
{8, 396.50, 193, 72, 1, 4732, 18.50, 10}
```

Where `picks` wanders blindly, `extrapolate` moves along
directions the population itself suggests: if b beats c, then
"b minus c" points somewhere interesting.

**Check:** `extrapolate` wraps out-of-range values into
mu +- 4 sd instead of clamping. Why is wrapping better here
than `[175]`'s clamp? (Hint: what does clamping do to
diversity at the boundary?)

## 8.3 The surrogate oracle

Mutants are invented rows: their y cells are stale parent
copies, so scoring them directly would be lying. The honest
cheap trick: score a mutant by the TRUE disty of its nearest
real row ([KNN](#glossary)).

```
[184]> y = function(r) return m.disty(d.cols, r) end
[185]> near1 = function(r) return m.near(d.cols, r, d.rows)[1] end
[186]> oracle = function(r) return y(near1(r)) end
[187]> oracle(mut)
0.7863215821
[188]> y(d.rows[1])
0.7863215821
```

Our two-column mutation already "moved" the row to a
better neighborhood: 0.60 vs the parent's 0.79.

*The surrogate bet ([BETS](#glossary), A5): a cheap model can stand in for a dear evaluation. Falsified when training labels are themselves too costly, or workload drift forces retraining.*

> **SURR — surrogate evaluation.** When true evaluation is
> impossible or expensive (here: nobody will build the
> mutant car), substitute a cheap estimator — nearest
> labeled neighbor, a leaf mean, a regression. All of
> search-based SE leans on this. Jones et al. 1998 (EGO).

**Check:** what failure mode does a kNN surrogate have in
regions far from all real rows? Connect to [ANOM](#glossary).

## 8.4 Simulated annealing

`a.sa(d)` is a (1+1) searcher: one current solution s; each
step mutates s, accepts the kid if better — or, sometimes,
even if worse, with probability `exp((e-d)/T)` where the
temperature T cools as the eval budget drains. Early chaos,
late greed. `a.track` drives any searcher and logs each new
global best.

```
[189]> math.randomseed(l.the.seed);
[190]> bob, lob = a.track("sa", a.sa(d), d.cols, d.rows)
[191]> y(bob)
0.09256355758
[192]> #lob
6
[193]> l.o{eval=lob[#lob].eval, disty=lob[#lob].disty}
{disty=0.09, eval=67}
```

(One progress letter per `the.dot=25` evals, on stderr.)
From a random start, SA found disty 0.093 — versus 0.075
for the best of all 398 real cars (`[87]`) — and its last
improvement landed at eval 67 of a 1000-eval budget.

*Today's bet ([BETS](#glossary), A1): the landscape is locally continuous — small steps, small changes. Falsified by rugged surfaces (compiler flags), which is why SA also gambles downhill.*

> **SA — simulated annealing.** Accept some bad moves early
> (escape local optima), almost none late (converge).
> One tunable schedule instead of restarts. Kirkpatrick
> 1983. Still a brutal baseline to beat.

**Check:** in `a.sa`'s accept function, what happens to the
acceptance probability as h approaches the budget b? Find
the `1 - h/b` term.

## 8.5 Local search

Same skeleton, greedy accept (`d < e` only), plus a restart
rule: if nothing improved for 100 evals, jump to a fresh
random row. One mutated column per step, occasionally
line-searched 20 times along a single dimension.

```
[194]> math.randomseed(l.the.seed);
[195]> bob2, lob2 = a.track("ls", a.ls(d), d.cols, d.rows)
[196]> y(bob2)
0.0745678279
[197]> l.o{eval=lob2[#lob2].eval, disty=lob2[#lob2].disty}
{disty=0.07, eval=442}
```

This time greedy WON: its restarts kept teleporting it to
fresh ground until, at eval 442, it landed on the best real
row in the table — 0.0746 is `[87]`'s number. Same budget,
two different escape mechanisms (tolerated bad moves versus
teleportation), opposite finish to SA's. Before you crown
local search: this is ONE seed. Lecture 10 reruns this race
five times, and the story does not survive.

*Restart's bet ([BETS](#glossary), A2): escape needs memory or a fresh start, not tolerance. Falsified when whole neighborhoods are flat (test-suite minimization).*

> **LS — local search + restarts.** Hill-climbing is the
> degenerate (1+1): cheap, simple, and the standard control
> group for any fancier searcher. If your new optimizer
> can't beat LS, you don't have an optimizer.

**Check:** both searchers share `a.oneplus1`. List exactly
what a caller can vary (mutate, accept, oracle, budget,
restart) and which choices reproduce sa vs ls.

## 8.6 Theory: landscapes, temperature, and one honest experiment

Picture search as walking a FITNESS LANDSCAPE: x-space is
the terrain, the oracle's score is altitude, and we want
the lowest valley. Why not calculus? Because SE landscapes
are mixed symbolic/numeric (no gradient through `origin ==
2`), rugged (cliffs where a config flips a code path), and
mostly unmeasured (each altitude reading costs a build).
Hence derivative-free methods: walk, sample, compare.

SA's accept rule is the Metropolis criterion (1953): take a
worse move with probability exp((e-d)/T) — e the current
score, d the candidate's, T the temperature. Early, T is
high and the walker bounds across valleys; late, T -> 0 and
it commits. luamine's schedule is `T = 1 - h/b` (fraction of
budget left, plus epsilon): linear cooling, two lines of
code, no tuning. Fancier schedules exist; on small budgets
they rarely beat linear.

You now have a clean 2x2 EXPERIMENT: acceptance (greedy vs
metropolis) x restarts (on vs off), 20 seeds each, four
distributions of final disty. `[191]` vs `[196]` was one
cell each. The full grid separates two often-confused
escape mechanisms: tolerated bad moves (SA) and teleporting
(restarts) — and on many MOOT datasets, restarts do more
work than temperature.

> **MH — metropolis acceptance.** Accept worse solutions
> with probability exp(-delta/T), cooling T over time:
> early exploration, late exploitation, one knob.
> Metropolis 1953; Kirkpatrick 1983.

**Check:** at h = b/2 with e-d = -0.1 (a slightly worse
kid), what is luamine's acceptance probability? Compute from
the `a.sa` source.

## Recap

REPL prompts covered: 172-197. picks/extrapolate generate
neighbors ([MUT](#glossary)); invented rows are scored by
nearest-real-neighbor ([SURR](#glossary)); a.track folds any
stepper into best-so-far records; on this seed restart-driven
LS edged SA ([SA](#glossary), [LS](#glossary)) — an anecdote
that lecture 10 puts on trial.

**Exercises.**

1. Rerun `[189]`-`[193]` with seeds 2..6. Report
   mean/sd of final disty for sa and ls ([WEL](#glossary)).
   Is the ls > sa gap real or luck? (Foreshadows lecture 10.)
2. `a.ls(d, nil, nil, 0)` disables restarts. How much worse
   does ls get?
3. Write `a.sa`-style accept that NEVER takes worse moves
   but keeps the same mutation. Compare to both. Where does
   it land between sa and ls, and why?
4. Field trip: race sa vs ls on
   $MOOT/optimize/process/xomo_flight.csv (`-t` flag). Does
   the rugged-landscape story (`[191]` vs `[196]`) replay on
   a 23-option process model?

[contents](#contents)

---

<a name="l9"></a>
# Lecture 9: Search II — Populations and Racing

(1+1) searchers carry one candidate. Population methods carry
dozens, letting candidates share information — by crossover
(GA) or by difference vectors (DE). This lecture builds both
as steppers, then races everything from lecture 8 and 9 on
one timeline to ask the only question that matters: who finds
good rows in the fewest evaluations?

**Where this bites.** GenProg repaired real bugs by
evolving patches — and also showed the failure mode:
crossover happily splices two half-patches that edit the
same line, producing nonsense. Test-suite minimization
shows the opposite trap: remove any single test and
coverage barely moves, so greedy search sees a flat plain.
Today's operators are bets about which world you are in.

## 9.1 ga: a population stepper

`a.ga(d, better)` returns a stepper closure; each call evolves
one generation and returns `(gen, pop, ref)`. Inside: mutate
everyone ([MUT](#glossary)), select parents by tournaments
(draw `the.tour` members at random, keep the one the
`better` predicate — here [ZIT](#glossary) via kNN snapping
— likes most), then single-point crossover. `ref` is a stash of
unused real rows that the kNN surrogate scores against.

```
[198]> d = m.Data.new(l.csv(l.the.train))
[199]> y = function(r) return m.disty(d.cols, r) end
[200]> l.the.np, l.the.cr, l.the.gens = 50, 0.25, 50
[201]> math.randomseed(l.the.seed);
[202]> step = a.ga(d, a.knn(d))
[203]> gen, pop, ref = step()
[204]> gen, #pop, #ref
1	50	348
[205]> (step())
2
```

Note what a stepper buys: only ONE population is alive at a
time, so a thousand generations cost the memory of one, and
the caller decides when to stop.

*Today's bet ([BETS](#glossary), A3): good solutions are made of good parts that recombine. Falsified when parts couple — program-repair patches editing the same line.*

> **GA — genetic algorithm.** Population + selection +
> crossover + mutation. Crossover recombines partial
> solutions ("building blocks"); tournaments apply selection
> pressure without global sorting. Holland 1975, Goldberg
> 1989.

**Check:** with `the.tour=5`, what is the chance the WORST
of 50 rows survives one tournament? (Rough estimate.)

## 9.2 de: steady-state evolution

Differential evolution ("steady-state": members are replaced
one at a time as kids beat parents, not wholesale once per
generation): each member spawns a kid via
`extrapolate(a,b,c)` over three distinct others (`[182]`);
the kid replaces its parent only if it scores better. No
explicit mutation rate schedule — step sizes come from the
population's own spread, shrinking automatically as it
converges.

```
[206]> math.randomseed(l.the.seed);
[207]> l.the.de_iter, l.the.np = 30, 20
[208]> dstep = a.de(d)
[209]> gen, kids = dstep()
[210]> gen, #kids
1	20
```

> **DE — differential evolution.** Mutation = scaled
> difference of population members: self-adapting step
> sizes, two knobs (F, cr), embarrassingly simple, and the
> default first choice for numeric optimization. Storn &
> Price 1997.

**Check:** why must a, b, c be three DISTINCT members in
`a.de`'s repeat-until loop? What does `a + F*(b-b)` do?

## 9.3 track: drive any stepper

Same harness as lecture 8 — sa, ls, ga, de all speak
"stepper", so one driver fits all. Every yielded kid is
snapped to its nearest real row and scored with true disty.

```
[211]> math.randomseed(l.the.seed);
[212]> bobg, lobg = a.track("ga", a.ga(d, a.knn(d)), d.cols, d.rows)
[213]> y(bobg)
0.09256355758
[214]> #lobg
7
```

`[213]` lands within a hair of the best real car in the
table (0.0746, `[87]`) after seven improvement steps —
close, not optimal: where the surrogate's opinion and the
truth disagree at the margin, the search stops a notch
early.

**Check:** could y(bobg) ever be LOWER than `[87]`'s value,
given how track snaps kids? Why not?

## 9.4 race: all four, one timeline

`a.race` runs each optimizer, merges their improvement logs,
sorts by evaluation count, and keeps only records that beat
every earlier record from ANY method. `a.report` prints the
result above a baseline row of column means.

```
[215]> math.randomseed(l.the.seed);
[216]> opts = {{"ga", a.ga(d, a.knn(d))}, {"de", a.de(d)}}
[217]> opts[3] = {"sa", a.sa(d)}; opts[4] = {"ls", a.ls(d)}
[218]> lob = a.race(d, opts)
[219]> dists = a.report(d, lob)
who      eval  gen  disty     Lbs-   Acc+   Mpg+
average     -    -   0.50  2970.42  15.57  23.84
ga          1    1   0.15     1955  20.50     30
ga         13    1   0.09     2130  24.60     40
de         36    2   0.09     2085  21.70     40
[220]> #dists
3
```

Read the table: the average car weighs 2970 lbs and does 24
mpg. GA's very first evaluation found a 1955-lb 30-mpg car
(disty 0.15) and its 13th a 40-mpg car at 0.09; DE matched
that by eval 36; then 2000+ further evaluations — across
all four methods — improved nothing. The interesting result
is not who won; it is HOW EARLY everything good happened.

> **RACE — compare on evals-to-quality.** Optimizers are
> compared on one merged best-so-far-vs-evaluations
> timeline, not final scores alone: in SE, each "evaluation"
> may be a build, a test run, or an engineer's afternoon.
> The cheap question "who improves first?" often has a
> different answer than "who wins eventually?".

**Check:** report's `gen` column shows blank-ish values for
sa/ls records when they appear. Why do (1+1) methods have no
generation?

## 9.5 Sixty years of optimization, five eras

Where today's two methods sit in the family tree:

    era 1  trajectory     hill climbing, SA (`[190]`):
                          one walker, minimal memory
    era 2  populations    GA (`[202]`), genetic programming:
                          crossover recombines partial wins
    era 3  vectors        evolution strategies, DE (`[208]`):
                          steps self-scale to the population
    era 4  many goals     the Pareto revolution: NSGA-II
                          and kin return FRONTS, not points
    era 5  budget-aware   surrogates + multi-fidelity
                          ([MFID](#glossary), lecture 10)

The table names two methods per era; the field is thicker.
Era 1's missing baseline is RANDOM SEARCH — always run it,
since any method that cannot beat random sampling is
decoration. Tabu search adds memory (forbid recent moves,
escape cycles); MaxWalkSat mixes greedy and random steps
for SAT-shaped problems. Era 2 grew swarm cousins: ant
colony optimization (pheromone trails; test-sequence
generation) and particle swarm (velocities toward personal
and global bests). Era 4's other names: SPEA2
(strength-based fitness), IBEA (optimize hypervolume
directly). Era 5 is where this course lives: TPE and SMAC
model p(good|x) for tuning; FLASH runs sequential
model-based search with a CART tree as surrogate; and SWAY
approximates a Pareto front by recursive random-projection
sampling — which you have already built: SWAY is `ftree`
(`[155]`) wearing an optimization hat.

Era 2's other child matters to SE: GENETIC PROGRAMMING
evolves program trees, not parameter rows — crossover swaps
subtrees, fitness is "passes the tests". Twenty years later
that became automated program repair (below).

Era 4 deserves its own paragraph. A row DOMINATES another
if it is no worse on every goal and better on at least one;
the non-dominated set is the PARETO FRONT — the menu of
defensible trade-offs. NSGA-II (Deb 2002) made this
practical: sort the population into dominance layers, keep
diversity along the front via crowding distance; NSGA-III
and MOEA/D extend past ~3 goals, where domination itself
goes blind (almost nothing dominates anything in 10-D).
luamine takes the scalarizing shortcut instead —
[D2H](#glossary) and [ZIT](#glossary) collapse goals to one
number — trading the menu for speed and simplicity on its
small-data, few-goal problems. Know what the trade is: a
scalarizer returns ONE point of the front and hides the
rest.

*The Pareto bet ([BETS](#glossary), A4): objectives are incomparable, keep the whole frontier. Wasteful when preferences are actually clear.*

> **PARETO — fronts, not winners.** With many goals, the
> honest answer is the non-dominated set; algorithms like
> NSGA-II return it. Scalarizers (D2H, ZIT) are cheaper
> and answer a narrower question. Deb 2002.

> **GP — genetic programming.** Evolve code: populations
> of program trees, subtree crossover, fitness = behavior.
> Koza 1992. Grandparent of automated program repair.

**Check:** construct two auto93 rows where neither
dominates the other but D2H ranks them decisively. What
information did the scalarizer add — and where did it come
from?

## 9.6 Search-based software engineering

Everything in this lecture has shipped against real SE
problems. The canon, one line each:

    test generation     EvoSuite: GA over test suites,
                        fitness = coverage
    program repair      GenProg: GP over patches, fitness
                        = failing tests pass, passing stay
    next release        knapsack-with-politics: pick
                        features maximizing value within
                        cost; classic NSGA-II territory
    config tuning       FLASH, SMAC: find fast/small/cheap
                        configs of big systems (era 5
                        methods shine — builds are dear)
    test prioritization order suites so faults surface
                        early; effort estimation; cloud
                        resource allocation; energy tuning

Two case studies worth retelling. Ambulance placement
(multi-goal: response time vs fleet cost) gives the
PHYSICAL intuition for fronts — no single best, a dense
menu of trade-offs. And cloud migration of legacy systems:
search proposes decompositions, but raw Pareto-optimal
answers proved BRITTLE (tiny spec shifts flip the
"optimal" answer — Yedida) and ignored maintainer taste
(Carvalho: developers reject mathematically-optimal
modules that cut across team boundaries). The fix in both:
cluster the frontier and show humans a handful of
representative, stable regions — [XPLN](#glossary) applied
to optimizer output. Optimization proposes; people and
re-checks dispose.

Program repair's own arc previews lecture 10's themes:
GenProg's GP era (search over edits), the semantic era
(constraint solvers synthesize patches), today's LLM era
(generate candidates from learned priors, validate against
tests) — each generation cheapens CANDIDATE GENERATION
while leaving VALIDATION the bottleneck. Budgeting
validation is exactly the [ACQ](#glossary)/[MFID](#glossary)
problem.

> **SBSE — search-based SE.** Reformulate an SE decision as
> fitness over a candidate space, then search. Harman &
> Jones 2001 named the field; by now every SE lifecycle
> phase has a search formulation.

> **APR — automated program repair.** Search/synthesize/
> generate candidate patches; validate against tests. GP
> origins (Weimer et al. 2009), constraint middle age,
> LLM present. Validation cost rules the economics.

**Check:** pick one task from your last work week.
Write its SBSE formulation: candidate space, mutation
operator, fitness, and what one evaluation costs.

## Recap

REPL prompts covered: 198-220. Steppers yield one generation
per call; ga = tournaments + crossover ([GA](#glossary)),
de = difference-vector blending ([DE](#glossary)); track
drives any stepper through the kNN surrogate
([SURR](#glossary)); race merges all logs into one
evals-vs-quality timeline ([RACE](#glossary)) — where, on
auto93, everything good happened in the first ~36 evals.

**Exercises.**

1. Rerun the race with seeds 2..6. Which method appears most
   often in the merged table? Is eval-of-last-improvement
   stable?
2. Set `the.cr=0.9` (heavy crossover) and rerun `[212]`.
   Better or worse than cr=0.25? Hypothesize, test, explain.
3. Add a fifth racer: pure random search (mutate a random
   real row each step). How embarrassing is the comparison?
4. Field trip: full `--race` on
   $MOOT/optimize/process/nasa93dem.csv (93 historical NASA
   projects). Who finds a good project plan first, and by
   which eval?

[contents](#contents)

---

<a name="l10"></a>
# Lecture 10: Less Is More — Active Learning and Honest Stats

Final lecture. Two endings: first, the engineering payoff —
optimization when LABELS, not CPU, are the scarce resource;
second, the scientific duty — how to claim "method A beats
method B" without lying to yourself.

**Where this bites.** A recent tournament (egs.pdf in the
repltut repo) raced 21 optimizers across 90+ MOOT tasks at
three label budgets. The winner MIGRATES with budget: cheap
warm-start sampling wins when labels are scarce; DE takes
over as budgets grow; no single method wins everywhere; and
random search embarrasses two fashionable samplers. Budget
is a first-class variable — and today's tools are how you
act on that.

## 10.1 acquire: spend labels wisely

The setting: y values cost money (a build, a survey, a wet
lab). You may only "open" a few dozen rows. `a.acquire` warm
starts on `the.start` random labels, splits them into best/
rest tables ([NB](#glossary) again — two clones), then
repeatedly labels the unlabeled row whose like(best) most
exceeds like(rest).

```
[221]> d = m.Data.new(l.csv(l.the.train))
[222]> y = function(r) return m.disty(d.cols, r) end
[223]> math.randomseed(l.the.seed);
[224]> l.the.budget, l.the.start = 20, 10
[225]> acq = m.Num.new()
[226]> for _ = 1, 20 do acq:add(y(l.keysort(a.acquire(d).rows, y)[1])) end
[227]> rnd = m.Num.new()
[228]> for _ = 1, 20 do rnd:add(y(l.keysort(l.anys(d.rows, 30), y)[1])) end
[229]> l.o{acquired=acq.mu, random=rnd.mu}
{acquired=0.11, random=0.13}
```

Twenty repeats of each policy: thirty Bayes-guided labels
average a best-find of 0.11; thirty random labels average
0.13. Steady steering beats luck — and saying so over 20
repeats, not one, is this lecture's whole ethic.

Why believe labels are the bottleneck? Count the
asymmetries in everyday SE:

    cheap x                       dear y
    mine GitHub: code size,       development time; what
    dependencies per function     people will pay for it
    count classes in a system     org's true maintenance cost
    enumerate 20 yes/no design    stakeholder reaction to
    options (2^20 candidates)     each one
    list configuration flags      runtime + energy of every
                                  configuration
    list data-miner parameters    the best setting for YOUR
                                  local data
    generate random test inputs   a human judging each output

Every row has the same shape — x nearly free, y costly —
which is precisely acquire's operating assumption.

> **ACQ — active learning.** When labeling is the cost,
> choose queries by expected usefulness (here: likelihood
> ratio best/rest), not at random. Budgets of 20-50 labels
> often suffice to nearly optimize hundreds of rows.
> Settles 2009; this acquirer follows Menzies' "data-lite"
> line of work.

**Check:** `acquire` re-sorts `best` and evicts its worst
row whenever |best| > sqrt(|labeled|). What would go wrong
if best grew without bound?

## 10.2 bob: the whole pipeline

`a.bob` is the course in one function: shuffle; hold out half
as a test set; actively label ~30 training rows
([ACQ](#glossary)); grow a tree on those labels
([TREE](#glossary)); route every test row to a leaf
([XPLN](#glossary)); truly label only the `the.check=4` most
promising test rows; return the best.

```
[230]> math.randomseed(l.the.seed);
[231]> wins, dys = m.Num.new(), m.Num.new()
[232]> for _ = 1, 20 do b, v = a.bob(d); wins:add(v.win(b)); dys:add(y(b)) end
[233]> l.o(wins.mu)
86.60
[234]> l.o(dys.mu)
0.16
```

About 34 labels per split, twenty splits: mean win 86.6 —
on average the pipeline lands seven-eighths of the way from
the median to the best you could achieve labeling
EVERYTHING (mean disty 0.16). That asymmetry — near-optimal
results from ~9% of the labels — is the thesis of this
whole course.

> **BOB — budgeted optimization via surrogates.** Label a
> little, model the labels, let the model nominate the next
> labels. The pattern behind Bayesian optimization, MLOps
> data triage, and every "which test do I run next?" tool.

**Check:** `v.win` clamps scores so that "within 0.35 sd of
the best" counts as 100. Why tolerate that slack instead of
demanding the exact optimum?

## 10.3 Same or different? The mechanics

Stochastic methods give distributions, not numbers. Before
claiming A beats B you need machinery that compares SAMPLES
— and you need to know that machinery's moving parts, or it
will lie to you. Start tiny, where you can check by hand.
Cliff's delta asks: if I draw one value from each list, how
often does one side win? (Scaled: 0 = coin flip, 1 = total
separation.) KS asks: how far apart do the two cumulative
distributions ever get?

```
[235]> l.cliffsDelta({1,2,3}, {1,2,3})
0.0
[236]> l.cliffsDelta({1,2,3}, {4,5,6})
1.0
[237]> l.cliffsDelta({1,2,3,4}, {3,4,5,6})
0.75
[238]> l.ks({1,2,3}, {4,5,6})
1.0
[239]> l.ks({1,2,3,4}, {3,4,5,6})
0.5
```

KS deserves its own definition, because it is the course's
only two-sample shape test. Draw both samples' CDFs
([PDF/CDF](#glossary)) on one axis: each is a staircase
climbing 0 to 1. The KS statistic is the LARGEST VERTICAL
GAP between the staircases, anywhere. Identical samples:
staircases overlap, gap 0 (`[238]` inverted). Disjoint
samples: one staircase finishes before the other starts,
gap 1. The decision rule scales with sample size —
`l.same` uses gap <= 1.36*sqrt((n+m)/(n*m)), the classic
95% threshold — because small samples wobble more, so they
get more slack.

> **KS — Kolmogorov-Smirnov test.** Max vertical gap
> between two empirical CDFs; distribution-free (no
> gaussian assumptions); threshold shrinks as samples grow.
> Pairs with [EFF](#glossary): KS asks "plausibly
> different?", delta asks "different enough to care?".
> en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test

Identical lists: 0. Disjoint: 1. Half-overlapping: in
between, and you can verify `[237]` with a pencil (16 cross
pairs; count wins each way). Now the lesson most people
never get taught — the NOISE FLOOR. Draw two samples from
the SAME distribution and delta is not zero:

```
[240]> math.randomseed(l.the.seed);
[241]> mk = function(off) u = {}; for i = 1, 50 do u[i] = math.random() + off end; return u end
[242]> xs, ys, zs = mk(0), mk(0), mk(0.3)
[243]> l.cliffsDelta(xs, ys)
0.0984
[244]> l.cliffsDelta(xs, zs)
0.2752
[245]> l.same(xs, ys)
true
[246]> l.same(xs, zs)
false
```

`[243]`: two samples of the same uniform noise show delta
0.10 at n=50. Anyone eyeballing "0.10 > 0" would declare a
difference that does not exist; `l.same`'s thresholds
(cliffs 0.195 is the small/medium border, plus the KS gate
scaled by sample size) are calibrated to shrug at exactly
this. Shift one sample by 0.3 (`[244]`, `[246]`) and both
gates open.

How much you can see depends on how much you sampled:

```
[247]> mkn = function(n, off) u = {}; for i = 1, n do u[i] = math.random() + off end; return u end
[248]> math.randomseed(l.the.seed);
[249]> s1, s2 = mkn(10, 0), mkn(10, 0.1)
[250]> l.same(s1, s2)
true
[251]> b1, b2 = mkn(1000, 0), mkn(1000, 0.1)
[252]> l.same(b1, b2)
false
[253]> l.same(b1, b2, 0.2)
true
```

The same 0.1 shift is invisible at n=10 (`[250]`) and
glaring at n=1000 (`[252]`). Neither answer is wrong: tests
do not measure truth, they measure truth-given-this-much-
data. And `[253]` is the engineer's last word: an `eps`
argument that says differences under 0.2 are too small to
act on, however statistically real. Statistics proposes;
engineering disposes.

> **SAMP — everything is a sample.** This whole course is
> sampling: anys and shuffle (L2), ftree's cap (L7), kpp's
> few, acquire's budget (L10), and these tests. A sample's
> size sets what you can detect ([250] vs [252]); its
> source sets what you can generalize to. Every claim you
> make is a claim about a sample — say which one. Cohen
> 1990.

> **EFF — effect size before significance.** With enough
> samples, ANY difference is "significant"; the question is
> whether it is big enough to care. Cliff's delta + a
> nonparametric test is the standard prescription for
> stochastic SE experiments. Arcuri-Briand 2011.

**Check:** `l.same` also takes an `eps` "good enough" gap.
Why does engineering need that knob even when statistics
says "different"?

## 10.4 topTier: rank the optimizers honestly

The final tool: given `{name -> list of scores}`, sort by
mean, then walk down adding methods while they are
statistically `same` as the best. Everything in the returned
tier is "tied for first"; everything else lost.

```
[254]> l.the.budget1, l.the.dot = 256, 1e9
[255]> t = {sa = {}, ls = {}}
[256]> for s = 1, 5 do math.randomseed(s); t.sa[s] = y(a.track("sa", a.sa(d), d.cols, d.rows)) end
[257]> for s = 1, 5 do math.randomseed(s); t.ls[s] = y(a.track("ls", a.ls(d), d.cols, d.rows)) end
[258]> l.o(l.sort(t.sa))
{0.09, 0.09, 0.09, 0.10, 0.15}
[259]> l.o(l.sort(t.ls))
{0.14, 0.15, 0.27, 0.37, 0.46}
[260]> tier = l.topTier(t, nil, l.the.eps, l.the.cliffs, l.the.ksconf)
[261]> l.o(tier)
{sa=0.10}
```

Five seeds at a 256-eval budget: sa sits tight
({0.09..0.15}) while ls sprawls ({0.14..0.46}); the tier
holds sa alone. Now recall lecture 8, where ONE seed at a
bigger budget crowned ls. Both observations are true; only
one is a result. Distributions, not anecdotes.

> **TIER — rank by distribution, report ties.** Compare
> methods by their score distributions over repeated seeded
> runs ([SEED](#glossary)); cluster the statistically
> indistinguishable; report the top tier, not a single
> winner. Demsar 2006 for the general protocol.

**Check:** rerun `[256]`-`[261]` with 20 seeds. Does ls
join the tier or leave it further behind? Which statistic
moved?

## 10.5 The wider acquisition world

`acquire`'s like(best)-like(rest) rule is one member of a
famous family. BAYESIAN OPTIMIZATION fits a surrogate with
uncertainty — classically a Gaussian process, which returns
both a prediction mu(x) and a doubt sigma(x) — then picks
the next evaluation by an ACQUISITION FUNCTION that trades
exploitation against exploration: expected improvement
(EI), or optimism in the face of uncertainty (UCB =
mu + k*sigma). GPs choke past a few thousand points, so
practical tools (SMAC) swap in random-forest surrogates;
variance across trees plays the role of sigma.

THOMPSON SAMPLING, the other classic, treats each option as
a slot-machine "arm" and keeps a posterior for each — a
belief about its payoff, updated as evidence arrives — then
picks by sampling from those beliefs — exploration emerges
from posterior noise rather than an explicit bonus. EZR's
acquire differs on three axes: it models a LANDSCAPE, not
independent arms (two NB classes over x-space, not one
posterior per candidate); its score is a likelihood RATIO,
not a sampled value; and its argmax is deterministic given
the data ([SEED](#glossary) still matters for shuffles).
The punchline of this whole research line: on MOOT-class
problems, that two-class NB acquirer — a dozen lines, none of
the GP machinery to configure — keeps landing within noise of
Bayesian optimization at a fraction of the machinery
([SIMP](#glossary), final appearance).

> **BO — Bayesian optimization.** Surrogate with
> uncertainty + acquisition function (EI, UCB) chooses
> each expensive evaluation. Jones 1998; SMAC (Hutter
> 2011) for the random-forest variant.

> **THOM — Thompson sampling.** Sample from each option's
> posterior; act on the sample. Optimal exploration with
> almost no code — when options are independent arms.
> Thompson 1933.

The field's vocabulary, so its papers read easily: EXPLORE
(sample where uncertainty is highest), EXPLOIT (sample
where predictions look best — acquire's bias), ADAPTIVE
(slide from explore to exploit as evidence accumulates);
DIVERSITY sampling (cover x-space, ignore y),
REPRESENTATIVENESS (sample regions in proportion), and
perversity (deliberately probe where nothing has been
tried). COLD-START begins with zero labels (acquire does);
WARM-START seeds from prior knowledge — one recent result:
given a diversity-sampled warm start, plain exploit beats
adaptive. POOL-BASED learners see all unlabeled x up front
(this course); STREAM-BASED ones see a sliding window;
MODEL-QUERY SYNTHESIS invents its own query rows —
[SYNTH](#glossary) is the ingredient that makes that
possible here.

**Check:** acquire's best/rest threshold is deterministic;
Thompson's choice is stochastic. Name one situation where
the stochasticity is worth paying for.

## 10.6 Where next

Six directions, each one course-project sized, all
launchable from this codebase tonight:

    harder data      run --acq over every MOOT optimize/
                     CSV; characterize where budgeted
                     search fails (the interesting result)
    better acquire   swap acquireBayes for UCB-flavored or
                     Thompson-flavored scoring; race them
                     ([RACE](#glossary), [TIER](#glossary))
    fronts           return clustered Pareto fronts
                     ([PARETO](#glossary)) instead of one
                     bob row; show humans the menu
    explanation      compress trees to 3-question
                     fast-and-frugal rules ([INTERP]
                     (#glossary)); measure the accuracy tax
    streams          implement sub() (lecture 3) and make
                     every learner forget as well as learn
    causality        treat tree branches as hypotheses;
                     design the cheapest intervention that
                     tests one ([LADDER](#glossary))

The semester's claim, restated one last time: on a broad
class of SE problems, thirty labels, a tree, and honest
statistics beat both intuition and most heavyweight
machinery. You now hold every line of code needed to prove
that wrong. Try.

## Recap

REPL prompts covered: 221-261. acquire turns NB into a label
shopper ([ACQ](#glossary)); bob chains acquire + tree +
check into near-optimal results from ~30 labels
([BOB](#glossary)); cliffs + ks decide same-vs-different on
distributions ([EFF](#glossary)); topTier turns repeated
runs into an honest leaderboard ([TIER](#glossary)).

**Exercises.**

1. By hand: list the 16 cross-pairs of {1,2,3,4} and
   {3,4,5,6}; count wins each way; verify `[237]`'s 0.75.
2. Find the flip point: for n in {10,20,40,80,...}, when
   does `l.same(mkn(n,0), mkn(n,0.1))` first go false?
   Repeat with shift 0.05. State the pattern ([SAMP]
   (#glossary)).
3. Seed shopping: run `l.same(mk(0), mk(0))` for seeds
   1..50. How often does the gate false-alarm on identical
   distributions? Why is hunting for the seeds where it
   fails (then reporting only those) a research crime?
4. topTier sensitivity: build t with four methods of equal
   mean but spreads sd, 2sd, 4sd, 8sd. Who makes the tier?
   Now shift one mean by 0.1*sd. Who drops out, and at what
   n?

5. Sweep `the.budget` in {10, 20, 40, 80} for `a.bob`, 20
   repeats each. Plot mean win vs labels spent. Where is
   the knee?
6. Run `lua luamine-eg.lua --acq` on five different optimize/
   CSVs from $MOOT. Which datasets resist budgeted
   optimization, and what do they have in common?
7. Capstone: race ga/de/sa/ls on 20 seeds, collect final
   distys, and produce the topTier table. Write one
   paragraph, citing [EFF](#glossary) and [TIER](#glossary),
   defending your conclusion.
8. Corpus survey: write ~15 lines that load every
   $MOOT/optimize CSV and print #rows, #x, #y, binning
   each axis into small/med/hi. Which data shapes are
   over-represented? That sampling bias bounds every claim
   in this course — say so in your capstone write-up.
9. Field trip: `lua luamine-eg.lua -t
   $MOOT/optimize/config/SS-A.csv --acq` — the one-line
   budget-aware optimizer report. Then the same for two more
   config tables. Stable win scores?

[contents](#contents)

---

<a name="glossary"></a>
# Glossary

55 ideas, each introduced by exactly one vignette at its
first use. SE principles trace to the course review notes
(tiny.cc: guru26spr review/one.md); AI principles cite a
primary source.

| acro | expansion | one-liner | first use | ref |
|------|-----------|-----------|-----------|-----|
| ACC | scores beyond accuracy | pd/pf/precision per class; accuracy lies under imbalance | [L5.3](#l5) | Fawcett 2006 |
| ACQ | active learning | spend the label budget on rows the model most wants | [L10.1](#l10) | Settles 2009 |
| ANOM | anomaly detection | calibrated distance-to-neighbors; alarm on CDF tails | [L7.4](#l7) | Breunig 2000 |
| APR | automated program repair | search/synthesize/generate patches; validation rules the cost | [L9.6](#l9) | Weimer 2009 |
| BETS | optimizers are bets | each method assumes a landscape shape; assumptions are testable | [L1.0](#l1) | Menzies 2026 |
| BO | Bayesian optimization | uncertainty-aware surrogate + acquisition fn picks each eval | [L10.5](#l10) | Jones 1998 |
| BOB | budgeted optimization | label a little, model, let the model pick the next labels | [L10.2](#l10) | Jones 1998 |
| CLT | central limit theorem | sums of small effects go gaussian; why (mu,sd) sketches work | [L2.5](#l2) | Feller 1968 |
| COC | convention over configuration | names and defaults decide the common case; config only for exceptions | [L3.4](#l3) | Hansson |
| CONF | one config struct | all knobs in one table parsed from the help text | [L1.2](#l1) | guru26spr |
| CSV | self-describing header | column names carry type + goal + ignore markers | [L1.4](#l1) | guru26spr |
| CUT | discretization | replace ranges with a few crisp, populated tests | [L6.1](#l6) | Fayyad-Irani 1993 |
| D2H | distance to heaven | many goals -> one number: distance to the ideal point | [L4.3](#l4) | Zitzler 2004 |
| DE | differential evolution | mutate by scaled member differences; self-tuning steps | [L9.2](#l9) | Storn-Price 1997 |
| DIST | mixed-type distance | Minkowski + Hamming + pessimistic missing values | [L4.2](#l4) | Aha 1991 |
| EFF | effect size first | demand differences be large, then unlikely | [L10.3](#l10) | Arcuri-Briand 2011 |
| ENT | entropy as spread | symbolic "variance": 0 pure, max uniform | [L2.4](#l2) | Shannon 1948 |
| FAIL | fail fast, loudly | crash at the boundary with a named cause; silence is the worst failure | [L1.4](#l1) | Shore 2004 |
| FMAP | fastmap projections | two far poles give a cheap 1-D embedding; recurse | [L7.1](#l7) | Faloutsos-Lin 1995 |
| GA | genetic algorithm | population + tournaments + crossover + mutation | [L9.1](#l9) | Holland 1975 |
| GP | genetic programming | evolve program trees; fitness = behavior | [L9.5](#l9) | Koza 1992 |
| INTERP | interpretable > explained | audit-ready models beat post-hoc stories about black boxes | [L6.6](#l6) | Rudin 2019 |
| KM | k-means | iterative centroid refinement on unlabeled rows | [L5.4](#l5) | MacQueen 1967 |
| KNN | nearest neighbors | data is the model; neighbors answer queries | [L4.4](#l4) | Cover-Hart 1967 |
| KS | Kolmogorov-Smirnov | max gap between two empirical CDFs; distribution-free | [L10.3](#l10) | Kolmogorov 1933 |
| LADDER | causal ladder | see/do/imagine; observational models stop at rung one | [L6.7](#l6) | Pearl 2018 |
| LIL | little languages | tiny declarative notations (headers, help strings, regexes) carry the spec | [L1.2](#l1) | Bentley 1986 |
| LS | local search | greedy (1+1) + restarts; the baseline to beat | [L8.5](#l8) | guru26spr |
| MEST | m-estimate smoothing | blend frequencies with imaginary prior samples | [L5.1](#l5) | Cestnik 1990 |
| MFID | multi-fidelity triage | cheap shallow evals everywhere; real budget only on survivors | [L7.5](#l7) | Li 2018 |
| MH | metropolis acceptance | accept worse w.p. exp(-delta/T); cool T over the budget | [L8.6](#l8) | Metropolis 1953 |
| MUT | distribution-aware mutation | step inside each column's observed spread | [L8.1](#l8) | Storn-Price 1997 |
| NB | naive Bayes | independence-assuming argmax of log-summed evidence | [L5.2](#l5) | Domingos 1997 |
| NOIR | measurement scales | nominal/ordinal/interval/ratio each license different stats | [L3.6](#l3) | Stevens 1946 |
| NUM/SYM | incremental summaries | streams update Nums + Syms; tables are collections of them | [L3.5](#l3) | Welford 1962 |
| PARETO | non-dominated fronts | many goals -> report the trade-off menu, not one winner | [L9.5](#l9) | Deb 2002 |
| PDF/CDF | density vs cumulation | pdf = how common is x; cdf = fraction at or below x | [L2.5](#l2) | Feller 1968 |
| POLY | polymorphic add | one add/mid/spread protocol for every summary type | [L3.3](#l3) | guru26spr |
| RACE | evals-to-quality | merge optimizers onto one best-so-far timeline | [L9.4](#l9) | guru26spr |
| ROGUE | enforced hygiene | machine-audit your own conventions every run (the rogue? check) | [L1.5](#l1) | guru26spr |
| SA | simulated annealing | accept bad moves early, almost never late | [L8.4](#l8) | Kirkpatrick 1983 |
| SAMP | everything is a sample | sample size sets what tests can see; source sets generality | [L10.3](#l10) | Cohen 1990 |
| SBSE | search-based SE | SE decisions reformulated as fitness + search | [L9.6](#l9) | Harman-Jones 2001 |
| SEED | seeded randomness | stochastic results must be rerunnable; record seeds | [L1.5](#l1) | guru26spr |
| SIMP | simplicity first | benchmark the dumbest viable thing before believing fancier | [L1.0](#l1) | Holte 1993 |
| SSOT | single source of truth | one authoritative artifact per fact; all else derives | [L1.2](#l1) | Hunt-Thomas 1999 |
| SURR | surrogate evaluation | score invented rows via nearest labeled neighbor | [L8.3](#l8) | Jones 1998 |
| SYNTH | data synthesis | recombine within local structure, not per-column | [L7.3](#l7) | guru26spr |
| THOM | Thompson sampling | sample each option's posterior; act on the sample | [L10.5](#l10) | Thompson 1933 |
| TIER | rank by distribution | repeated seeded runs; report the statistical top tier | [L10.4](#l10) | Demsar 2006 |
| TREE | recursive partitioning | greedily split on the goal-purifying cut | [L6.4](#l6) | Quinlan 1986 |
| WEL | Welford moments | mean + sd per arriving value, constant space | [L2.3](#l2) | Welford 1962 |
| XPLN | explanation as model | a 13-line auditable summary beats +2% opaque accuracy | [L6.4](#l6) | guru26spr |
| XVAL | cross-validation | shuffle + hold out + repeat: kills order effects, catches overfitting | [L5.3](#l5) | Stone 1974 |
| ZIT | continuous domination | exponential-loss comparison; total order on trade-offs | [L4.5](#l4) | Zitzler 2004 |

Full citations with links: [references](#refs).

[contents](#contents)

---

<a name="appendix"></a>
# Appendix: Lua 101

Everything the 261 lecture prompts assumed about Lua, as its
own mini-tutorial: 46 more REPL events (numbered from 1000,
so lecture edits never renumber them), `[1000]`-`[1045]`. Run
them in a bare `lua -i` — no luamine code needed. Deeper
references: Lauer's *Lua 5.1 Short Reference* (archived:
web.archive.org/web/2023/http://thomaslauer.com/download/luarefv51single.pdf)
and the manual at lua.org/manual.

## A.1 Values

Lua has eight types; you will mostly touch five: nil,
boolean, number, string, table. Variables are global unless
declared `local` (one of Lua's two famous traps; the other
is 1-based indexing).

```
[1000]> x = 10
[1001]> x * 2.5
25.0
[1002]> type(x)
number
[1003]> 10 // 3
3
[1004]> 2^10
1024.0
[1005]> "abc" .. 123
abc123
```

`//` is integer division; `^` is power (always float); `..`
concatenates, coercing numbers. `25.0` vs `25`: Lua keeps
integer and float subtypes and shows the difference.

**Check:** what is `type(type)`?

## A.2 Tables

The only data structure. The same table can be an array
(consecutive integer keys from 1) and a dictionary (any other
keys). `#t` is the array length; reading a missing key gives
nil, never an error; writing nil deletes.

```
[1006]> t = {10, 20, 30}
[1007]> #t
3
[1008]> t[#t+1] = 40
[1009]> table.concat(t, ",")
10,20,30,40
[1010]> d = {name="luamine", n=3}
[1011]> d.name
luamine
[1012]> print(d.missing)
nil
[1013]> for i,v in ipairs(t) do print(i, v) end
1	10
2	20
3	30
4	40
```

`t[#t+1] = v` is the idiomatic append — list.lua wraps it as
`l.push`. `ipairs` walks the array part in order; its sibling
`pairs` walks every key but in NO guaranteed order, which is
why luamine sorts keys before printing ([SEED](#glossary)ed runs
demand deterministic output) and why `l.o` exists at all.
`d.name` is sugar for `d["name"]`.

**Check:** after `t[2] = nil`, what is `#t`? (Careful — the
answer is allowed to surprise you. Arrays with holes are
undefined territory; luamine never makes them.)

## A.3 Control

`if/then/elseif/else/end`, `while`, `repeat/until`, and two
`for` forms: numeric (`for i = lo, hi, step`) and generic
(`for k,v in iterator`). No braces; blocks end with `end`.

```
[1014]> n = 0
[1015]> for i = 1, 10, 2 do n = n + i end
[1016]> n
25
[1017]> big = 99 > 10 and "big" or "small"
[1018]> big
big
```

`[1017]` is Lua's ternary: `and`/`or` short-circuit AND
return their operands, so `cond and a or b` picks a or b —
with one trap: it breaks if `a` is false or nil. You saw it
throughout the sources (`Data.tree`, `l.o`, `m.tabulate`).
Also everywhere in luamine: `x = x or default`.

**Check:** rewrite `[1017]` so it is correct even when the
"then" value is `false`.

## A.4 Functions and closures

Functions are ordinary values: store them, pass them, return
them. A function returning a function captures the enclosing
locals — a closure. This is luamine's main structuring tool:
`l.lt(2)` builds comparators, `d:dxdy()` builds distance
views, every optimizer app (ga.lua, de.lua, search.lua) is a closure ("stepper")
remembering its own population.

```
[1019]> add = function(a, b) return a + b end
[1020]> add(3, 4)
7
[1021]> counter = function() local n = 0; return function() n = n + 1; return n end end
[1022]> c1 = counter()
[1023]> c1()
1
[1024]> c1()
2
[1025]> spread = function(...) return select("#", ...), ... end
[1026]> spread("a", "b")
2	a	b
```

`[1021]`-`[1024]`: each call to `counter()` makes a fresh,
private `n` — state without objects. `[1025]`: `...` is
varargs; `select("#", ...)` counts them; functions return
MULTIPLE values, callers take what they need
(`n,mu,m2 = l.welford(...)`), extras vanish, parentheses
truncate to one: `(f())`.

One house convention to re-read now: in the luamine sources,
`function m.slice(t,lo,hi,    u,n)` — everything after the
4-space gap is a LOCAL pre-declared in the signature, not an
argument. Lua permits calling with fewer args (missing ones
are nil), so the gap is free local-declaration space.

**Check:** what does `print(c1, counter())` tell you about
how many closures exist?

## A.5 Strings and patterns

Strings are immutable; methods chain off literals if you
parenthesize. Lua patterns are regex-lite: `%d` digit, `%w`
alphanumeric, `%s` space, `+`/`*`/`-` greedy/greedy/lazy
repeats, `(...)` captures. No alternation `|` — patterns are
deliberately smaller than regex.

```
[1027]> ("%s=%d"):format("age", 42)
age=42
[1028]> ("hello world"):match("(%w+) (%w+)")
hello	world
[1029]> ("a,b,c"):gsub(",", ";")
a;b;c	2
[1030]> ("v1.2.3"):match("%d+")
1
[1031]> nums = {}; for k in ("10 20 30"):gmatch("%d+") do nums[#nums+1] = k end
[1032]> table.concat(nums, "+")
10+20+30
```

`match` returns captures (`[1028]`: two of them); `gsub`
returns the new string AND the replacement count (`[1029]`);
`gmatch` iterates all hits — that is exactly how `l.csv`
splits rows (`s:gmatch"[^,]+"`) and how `l.boot` reads
defaults out of the help text (`"%-%-(%w+)=(%S+)"`,
[CONF](#glossary)).

**Check:** why does `[1030]` return `1` rather than `1.2.3`?
What pattern WOULD capture `1.2.3`?

## A.6 Metatables: objects in five lines

A metatable customizes a table's behavior. The only field
you need for this course: `__index` — "if a key is missing,
look it up over there". Point instances' `__index` at a
class table and you have methods + inheritance:

```
[1033]> Account = {}
[1034]> Account.__index = Account
[1035]> function Account.new(b) return setmetatable({balance=b}, Account) end
[1036]> function Account.add(i, v) i.balance = i.balance + v; return i.balance end
[1037]> acc = Account.new(100)
[1038]> acc:add(50)
150
[1039]> acc.balance
150
[1040]> getmetatable(acc) == Account
true
```

`acc:add(50)` is sugar for `acc.add(acc, 50)` — the colon
passes the receiver as a first argument that the sources
conventionally call `i`. Now read list.lua's entire object
system: `function l.new(mt,t) mt.__index=mt; return
setmetatable(t,mt) end` — `[1034]`+`[1035]` in one line. Every
Num, Sym, Cols, Data, Cut in the course is exactly an
`[1037]`.

**Check:** in `Sym.cuts(i,rows)` (sym.lua), which call
syntax reaches it — dot or colon — and what is `i` there?

## A.7 Errors, load, modules

`error` throws; `pcall(f)` calls f in protected mode,
returning ok plus either results or the error message. Code
is data: `load(s)` compiles a string to a function (the
tutorial harness that generated these very traces is 25
lines around one `load`).

```
[1041]> ok, err = pcall(function() error("boom") end)
[1042]> ok, err
false	[string "ok, err = pcall(function() error("boom") end)..."]:1: boom
[1043]> f = load("return 2 + 3")
[1044]> f()
5
[1045]> (pcall(require, "no_such_module"))
false
```

(The noisy `[string "..."]` prefix in `[1042]` names the
compiled chunk; in plain `lua -i` it reads `stdin`.) luamine
uses pcall twice, both load-bearing: `l.run1` wraps every
test so one failure cannot kill `--all`, and `--acq` wraps
whole runs so a bad CSV prints one ERR line instead of
crashing a batch job.

Modules: a file IS a function; its final `return m` is what
`require"lib"` hands back, cached forever after (second
require: free). `require` searches `package.path`, which
includes `./?.lua` — hence "run the REPL from the luamine
directory", lecture 1's first instruction.

**Check:** `l.run1` reseeds BEFORE each pcall'd test. What
ordering bug does that prevent when `--all` runs 9 tests in
sequence?

## What was deliberately skipped

Coroutines (luamine never yields), goto, the C API, integer
overflow rules, weak tables, `__newindex` and the other
fifteen metamethods. You can read all three source files
without them. When you meet one in the wild: lua.org/manual,
then Lauer's two-page card.

[contents](#contents)

---

<a name="quiz"></a>
# Revision Guide: 104 Exam Questions

Each question is numbered by its REPL gate: once you have
grokked prompt `[N]`, you can answer every question numbered
up to N. Part **a** is definitional — attempt it from MEMORY
first, then check the [glossary](#glossary); recall practice
beats re-reading. Part **b** shows a small piece of code or
a described protocol containing ONE conceptual mistake — a
course principle violated, not a typo. Say what the mistake
is, what it costs, and how to fix it — fix described in
English; never write Lua. [Answers](#answers) follow; 20
further questions (gates 236-1045) are held back for the
exam.

**Q4** — a. The course opens by disputing "nobody needs to
read code anymore". What is the counter-claim?
b. A student studies luamine by reading an AI-generated
summary of the three files, never starting a REPL. They can
recite every vignette. What's the mistake, the cost, the
fix?

**Q5** — Every luamine file opens with a help string listing
flags like `--seed=1`.
a. [CONF](#glossary): where do defaults live, and
what can therefore never drift apart?
b. A project documents its settings one way and defines
them another:
```lua
-- config.lua:  the = {seed=1, bins=2, p=2, ...}
-- help.txt:    "--seed=1  RNG seed ..."
```
Two files, maintained separately, currently in sync. What's
the mistake, what will it cost, what's the fix?

**Q6** — luamine derives its defaults from help text and (next
lecture) its schema from column headers.
a. Define [SSOT](#glossary). How do CONF and CSV both
instantiate it?
b. A project documents column meanings on a wiki, maps
roles in a YAML file, and ships headers naming neither.
After a year the three disagree. Mistake, consequence,
fix?

**Q7** — lib, luamine, and lapps all read their knobs from
the same `l.the`.
a. Why share ONE settings table across files?
b. A teammate adds a fourth file that keeps its own private
copy of the settings, initialized at load time from `l.the`.
Users then run `--p 4` on the command line.
What is the mistake, its consequence, and the fix?

**Q9** — a. The [CSV](#glossary) header is called a "little
language" ([LIL](#glossary)). What does one header line
replace?
b. A dataset arrives where goals are documented in a
separate schema.pdf, and the header is just `c1,c2,...,c9`.
The team imports it as-is and starts mining.
What is the mistake, its consequence, and the fix?

**Q11** — a. Why must `"42"` become the NUMBER 42 on the
way in from a CSV?
b. A loader keeps all cells as strings "to stay simple";
the team then wonders why every column became a Sym and
distance results look strange.
What is the mistake, its consequence, and the fix?

**Q13** — `l.o` always prints dictionaries with their keys
sorted, though Lua itself imposes no order.
a. Which course value does that ordering serve?
b. A test suite asserts on output containing an unsorted
dict dump. Tests pass all week, then fail on a colleague's
machine with no code change.
What is the mistake, its consequence, and the fix?

**Q15** — a. `l.csv` yields one row at a time. What does
that buy on data bigger than memory?
b. A pipeline reads all 86,000 rows of SS-X into a list,
then maps, then filters, then summarizes — and dies on the
intern's 8GB laptop. "We need a bigger machine."
What is the mistake, its consequence, and the fix?

**Q17** — `l.csv` asserts, with the filename, the moment a
path fails to open ([FAIL](#glossary)).
a. What is "fail fast", and why is a loud early crash
cheaper than a quiet late one?
b. A loader returns nil on missing files "to be robust";
downstream, an anomaly job runs happily and reports "0
anomalies" on data that never loaded. Mistake, consequence,
fix?

**Q18** — Every luamine table starts with a row of column
names like `Clndrs,Volume,...,Mpg+`.
a. Row one is not data. What is it?
b. A summary report says SS-A has 1,513 configurations. The
file has 1,513 lines.
What is the mistake, its consequence, and the fix?

**Q21** — At every exit, luamine compares the global namespace
against a startup snapshot and prints `rogue?` for leaks
([ROGUE](#glossary)).
a. What rule is being audited, and why does Lua make the
audit necessary?
b. A team adopts a "no global state" rule, enforced by code
review only. Two years later a leaked temporary couples two
features and the heisenbug takes a week. Mistake,
consequence, fix?

**Q22** — a. [SEED](#glossary): what must be true of any
stochastic result you publish?
b. "Our optimizer found a config 12% better than the
default" — reported from a run where nobody recorded the
seed, on a script that seeds from the clock.
What is the mistake, its consequence, and the fix?

**Q24** — a. luamine copies rows before sorting or mutating.
What general hazard does that avoid?
b. To rank cars, a function sorts `d.rows` in place by
disty. Later, a streaming classifier processes "the data in
arrival order" — and behaves strangely ([XVAL](#glossary)
is relevant).
What is the mistake, its consequence, and the fix?

**Q26** — a. keysort sorts by a DERIVED key. Why is that
the course's favorite verb (name two later uses)?
b. "To find the best car we don't need sorting machinery:
loop over rows, keep the row with the smallest disty so
far, done." True — so what's the actual argument for
keysort here? (The "error" to find: a real cost the loop
answer ignores when the key is expensive or reused.)

**Q27** — a. Functions-as-values: name two places luamine
passes behavior as an argument.
b. A library clone offers `sortByDisty(d)`,
`sortByWeight(d)`, `sortByMpg(d)`, `sortByAge(d)`... and a
backlog asking for six more.
What is the mistake, its consequence, and the fix?

**Q29** — keysort "decorates" each item with its computed
key once, then sorts the decorated pairs.
a. keysort computes each key once. When does that
matter enormously in this course?
b. An optimizer ranks 10,000 candidates by calling the
true benchmark INSIDE the sort comparator. The team
budgets for 10,000 evaluations.
What is the mistake, its consequence, and the fix?

**Q31** — a. Slices and samples recur everywhere
([SAMP](#glossary) foreshadowed). Why are most luamine
operations defined on a SUBSET of rows?
b. "To be rigorous, every operation in our clone — cuts,
poles, calibration — scans all rows, every time. No
sampling, no caps."
What is the mistake, its consequence, and the fix?

**Q33** — a. Why reseed immediately before a shuffle you
intend to publish?
b. A notebook shuffles, gets an exciting split, and the
author pastes the result into the paper. Reviewer asks for
the split again.
What is the mistake, its consequence, and the fix?

**Q35** — Welford's method summarizes a numeric stream
without ever storing it.
a. [WEL](#glossary): what three numbers replace
storing the whole stream?
b. A metrics service stores every latency ever observed so
it can recompute the mean each minute. Memory grows without
bound; the fix proposed is "sample the history".
What is the mistake, its consequence, and the fix?

**Q37** — a. Constant-space, per-row model update is THE
enabling property of this course. Name two lectures that
collapse without it.
b. A team's "incremental" learner retrains from scratch on
all past data after every arriving row, and they schedule
bigger nightly hardware to cope.
What is the mistake, its consequence, and the fix?

**Q39** — For symbolic columns, variance is meaningless,
so luamine substitutes an information-theory measure.
a. [ENT](#glossary): what plays the role of
"variance" for symbols, and what do 0 bits mean?
b. A dashboard reports the "standard deviation of the
status column" (values: pass/fail/flaky) by first mapping
pass=1, fail=2, flaky=3.
What is the mistake, its consequence, and the fix?

**Q43** — Lecture 10's tests (Cliff's delta, KS) are built
on ranks: counts of items at or below a value in a sorted
list (`l.bisect`).
a. Why prefer ranks over raw values
on messy SE data?
b. A study compares two methods' runtimes with a t-test;
the data has a handful of million-millisecond outliers from
CI hiccups. The t-test says "no difference".
What is the mistake, its consequence, and the fix?

**Q45** — a. [PDF/CDF](#glossary): which answers "how
common is x?" and which "what fraction sits at or below
x?"
b. A report needs "the fraction of cars under 2,500 lbs"
and the analyst reads the HEIGHT of the weight histogram
at 2,500.
What is the mistake, its consequence, and the fix?

**Q47** — a. A learner needs summaries, not your data.
What three questions can every luamine summary answer?
b. A privacy review halts a project: "the model ships with
all training rows inside it." The model is a Num per
column.
What is the mistake, its consequence, and the fix?

**Q49** — a. [POLY](#glossary): what shared protocol lets
one `adds` loop serve Num, Sym, and whole tables?
b. A clone implements `addNum`, `addSym`, `addData`, each
with its own loop, each fixed separately when the "?"
rule changed — and one of the three was missed.

**Q50** — Every summary answers mid() (central tendency)
and spread() (confusion around it).
a. What do mid and spread mean for a Sym,
and for a Num?
b. "The most common origin is 1, so the typical car is
American" — claimed from a table where origin's entropy is
near its maximum.
What is the mistake, its consequence, and the fix?

**Q53** — a. `adds` folds a list OR an iterator into any
summary. Why does accepting iterators matter?
b. A team's summarizer API requires a fully materialized
array, so their CSV reader loads files whole before any
statistics start.
What is the mistake, its consequence, and the fix?

**Q55** — Column roles — input, goal, ignored — are not
set anywhere in luamine's code.
a. Who decides which columns are inputs and
which are goals — and at what moment?
b. Halfway through a project, an analyst hand-edits the
loader so column 7 "counts as a goal for this one
experiment", leaving the header unchanged.
What is the mistake, its consequence, and the fix?

**Q57** — luamine tables maintain a running summary per
column as rows arrive.
a. A table's centroid costs O(columns) here. Why
— what is it read from?
b. A clone computes cluster centers by re-scanning every
member row each time a center is requested, inside
k-means' inner loop.
What is the mistake, its consequence, and the fix?

**Q59** — `Cols.new` builds the right summary for every
column of any MOOT table from the header alone
([COC](#glossary)).
a. State "convention over configuration". What is the
convention here, and what configuration does it eliminate?
b. A rival framework requires a 200-line mapping file
declaring each column's type and role per dataset; teams
copy-paste old mappings, and one stale entry mislabels a
goal column for a quarter. Mistake, consequence, fix?

**Q60** — a. Schema versus data: what does Data do with
the first row it sees, and why never store it as a row?
b. A bug report: "row 1 of every cluster is a weird car
whose weight is the string 'Lbs-'."
What is the mistake, its consequence, and the fix?

**Q63** — `d:clone()` returns an empty table with d's
header; `d:clone(rows)` seeds it.
a. clone transfers structure without content.
Name two lectures that lean on that.
b. To build per-class tables, a student constructs each
from scratch by re-parsing the CSV once per class — 19
times for soybean.
What is the mistake, its consequence, and the fix?

**Q66** — auto93's goals are `Lbs-`, `Acc+`, `Mpg+`.
a. How does a goal column know which DIRECTION is good?
b. After a data refresh, `Lbs-` was renamed `Lbs` by a
helpful engineer ("the dash looked like a typo"). All
optimization results silently change meaning.
What is the mistake, its consequence, and the fix?

**Q68** — a. [NOIR](#glossary): name the four scales and
one statistic that is legal on ratio but nonsense on
nominal.
b. A report computes the mean of zip codes and the
standard deviation of bug-priority labels {low, med,
high}, mapped to 1,2,3.
What is the mistake, its consequence, and the fix?

**Q70** — a. luamine collapses NOIR's four scales to two
types. What is gained, and what is knowingly lost?
b. A reviewer objects: "Model year is ordinal; treating it
as interval is invalid; the paper must be rejected."
What's the proportionate answer?
**Q72** — a. Why normalize columns before mixing them in
one distance ([DIST](#glossary))?
b. A clustering tool measures car similarity with raw
units (weights ~ thousands of lbs; mpg ~ tens):
```lua
d = abs(r1.lbs - r2.lbs) + abs(r1.mpg - r2.mpg)
```
What's the mistake, its consequence, the fix?

**Q74** — a. luamine's missing-value rule is deliberately
pessimistic. State the rule and the philosophy.
b. A clone imputes every "?" with the column mean before
clustering, then reports unusually tight, confident
clusters on a dataset that is 40% missing.

**Q75** — luamine's header splits columns into x (inputs) and
y (goals), and distx walks only one of those lists.
a. Which columns may a distance-for-clustering
use, and which must it never touch?
b. A team wants "all the information" in its similarity
measure, so its Cols puts every column — goals included —
into cols.x:
```lua
sim = function(r1,r2) return m.distx(d.cols, r1, r2) end
```
What's the mistake, its consequence, the fix?

**Q78** — a. [D2H](#glossary): how do many goals become
one number, and what does 0 mean?
b. A team optimizes "0.7*mpg - 0.3*weight" because "those
weights felt right", then argues for a week about 0.6 vs
0.7. What does D2H do instead, and what does the team's
approach cost?

**Q80** — At `[84]`, one keysort by disty surfaced
auto93's best car.
a. The best car was found with zero
human labels. What did the labeling?
b. A manager budgets three analyst-weeks to hand-rank 398
cars "since we have multiple goals and ranking needs
judgment".
What is the mistake, its consequence, and the fix?

**Q83** — disty is a Minkowski distance: per-goal gaps are
raised to the power `the.p`, then averaged and rooted.
a. What happens to disty as p
grows, and which famous function is the limit?
b. A safety-critical tuning task averages away one
catastrophic goal violation because the other five goals
look great. Which p was implicitly chosen, and which p was
needed?

**Q86** — a. [KNN](#glossary): where is the training step?
b. An architect rejects nearest-neighbor methods because
"we have no GPU budget for training" — and approves a
weekly batch retrain of a neural model instead.
What is the mistake, its consequence, and the fix?

**Q88** — a. Why must "my nearest neighbor" never be
"myself"?
b. An anomaly score is computed as each row's distance to
its nearest neighbor in the full table, including itself.
Every score comes back 0; the team concludes the data has
no anomalies.
What is the mistake, its consequence, and the fix?

**Q90** — `dxdy().win(row)` rescales raw disty onto a
0..100 scale before anyone reports it.
a. win anchors results against two
reference points. Which two?
b. "Our search reached disty 0.41" — reported with no
baseline row, on a table whose random rows average 0.43.
What is the mistake, its consequence, and the fix?

**Q93** — a. [ZIT](#glossary) versus [D2H](#glossary): a
duel versus a score. When does each shine?
b. A leaderboard needs to sort 86,000 configs by quality;
an engineer implements it as all-pairs Zitzler duels and
files a ticket for more compute.
What is the mistake, its consequence, and the fix?

**Q95** — `d:dxdy()` returns distance closures with the
Minkowski exponent fixed inside them at creation.
a. Why bake `p` into the closures at
creation time?
b. Mid-experiment, a script flips `the.p` from 2 to 4 "for
the second half"; distances from the two halves are then
compared in one table.
What is the mistake, its consequence, and the fix?

**Q97** — a. `like` reads pdf HEIGHTS; `norm` reads CDF
positions. Which question does each answer?
b. To score "how typical is this car's weight", an analyst
uses norm and reports 0.93 as "93% likely". What did 0.93
actually say?

**Q99** — a. The zero problem ([MEST](#glossary)): one
unseen value does what to a naive product of evidence?
b. A spam filter trained on 10,000 emails marks a message
"definitely not spam" because it contains one word never
seen in spam before — overriding fifty spammy signals.
What is the mistake, its consequence, and the fix?

**Q101** — a. Why log-sum instead of multiplying
likelihoods ([NB](#glossary))?
b. A 35-column classifier works on toy data but returns
"all classes score 0.0" on soybean. The team adds more
training data to fix it.
What is the mistake, its consequence, and the fix?

**Q103** — a. Evidence for classification comes from x
columns only. What is the general sin being avoided?
b. A diabetes classifier gathers its evidence by looping
over ALL columns — and cols.all includes `class!`:
```lua
for _,c in ipairs(data.cols.all) do   -- all columns
  v = row[c.at]; ...evidence...
```
Reported accuracy: 100%. Mistake, consequence, fix?

**Q105** — a. "Ranking, not probabilities": why does NB
classify correctly even when its numbers are badly
calibrated?
b. A teammate rejects NB after plotting its scores: "these
likelihoods don't sum to one, the model is broken."
What is the mistake, its consequence, and the fix?

**Q107** — a. [XVAL](#glossary): name the three threats
the ritual counters.
b. "We trained on all 768 rows, tested on the same 768,
and report 94% accuracy."
What is the mistake, its consequence, and the fix?

**Q110** — a. [ACC](#glossary): why does accuracy mislead
at 1% prevalence, and which two numbers should you demand?
b. A defect predictor is praised for 99% accuracy on a
codebase where 1% of files are buggy. Its pd is 0.
What is the mistake, its consequence, and the fix?

**Q112** — a. [KM](#glossary): the two alternating steps?
b. A team runs k-means ONCE with k=20 on unscaled data,
ships the clusters to product, and labels the work
"customer segmentation, done".
What is the mistake, its consequence, and the fix?

**Q114** — Each k-means step — assign to nearest centroid,
recenter on cluster mids — minimizes the same quantity.
a. Why must the error sequence never increase?
b. A monitoring chart shows cluster error rising on
iteration 3 of 10. The engineer says "it's stochastic,
noise happens" and ships.
What is the mistake, its consequence, and the fix?

**Q117** — a. kmeans++ picks seeds far apart. Why do
random seeds waste clusters?
b. An A/B test of "kmeans vs kmeans++" runs each ONCE on
one seed and concludes plain kmeans is better
([TIER](#glossary) foreshadowed).
What is the mistake, its consequence, and the fix?

**Q119** — a. Each cluster here is a full Data table. What
do you get for free ([POLY](#glossary))?
b. A clustering library returns only flat lists of row
indices; computing per-cluster goal means becomes a
two-week feature request.
What is the mistake, its consequence, and the fix?

**Q123** — luamine's classifier evaluates itself WHILE it
learns, with no held-out split.
a. State the test-then-train discipline and the
free gift it gives evaluation.
b. A streaming classifier processes each arriving row in
this order:
```lua
h[want]:add(row)        -- learn it
... predict(row) ...    -- then predict it
cf:add(want, predicted) -- then score it
```
Mistake, consequence, fix?

**Q125** — a. [CUT](#glossary): what does discretization
trade away, and for what three gains?
b. A stakeholder-facing model splits on
`Volume <= 113.74829` at six decimal places, four levels
deep. Stakeholders stop attending the readouts.
What is the mistake, its consequence, and the fix?

**Q127** — a. Why percentile-spaced cuts instead of
equal-width bins?
b. Salary data (median 60k, one billionaire) is binned
into ten equal-width buckets; nine buckets are empty and
one holds 9,999 people. The analyst adds more buckets.
What is the mistake, its consequence, and the fix?

**Q129** — bestCut auditions every candidate split and
keeps the one with the lowest score.
a. A cut is scored by what property of the two
sides' y-summaries?
b. A tree builder picks splits by which side gets MORE
rows ("bigger leaves are more reliable"), ignoring the
goals entirely.
What is the mistake, its consequence, and the fix?

**Q131** — a. Greedy tree-building: what does it never
reconsider, and what does that risk?
b. "Our tree's first split is provably optimal; therefore
the whole tree is optimal."
What is the mistake, its consequence, and the fix?

**Q133** — luamine trees stop growing early, on purpose, by
two rules.
a. Name the stopping rules that keep a tree
small — and why small is the point ([XPLN](#glossary)).
b. A team disables the leaf-size floor "for accuracy",
producing a 400-node tree, then asks for budget for an
explainability tool to explain it.
What is the mistake, its consequence, and the fix?

**Q135** — Tree-building here takes a pluggable summarizer
that scores each split's goal purity.
a. Regression trees and classification trees
differ in exactly one pluggable choice here. Which?
b. A klass! task is run through the default tree; the
summarizer averages class labels as if numbers. The tree
prints; nobody notices for a month.
What is the mistake, its consequence, and the fix?

**Q138** — a. [XPLN](#glossary): when does a worse-scoring
model win?
b. A 2%-more-accurate black box replaces the 13-line tree
in a regulated loan workflow. First audit request arrives.
What is the mistake, its consequence, and the fix?

**Q140** — a. [INTERP](#glossary): interpretable vs
explainable, one sentence each.
b. A vendor sells "explainable AI": a saliency overlay
generated by a second model atop the first. The bank's
auditor asks how to verify the explanation is faithful.
What is the mistake, its consequence, and the fix?

**Q142** — a. Name two things the `[140]` tree honestly
cannot do.
b. The tree was trained on 1970s cars; product uses it to
predict the disty of an electric SUV "since the tree is
interpretable, it must generalize".
What is the mistake, its consequence, and the fix?

**Q144** — a. [LADDER](#glossary): the three rungs; which
rung does every model in this course occupy?
b. A tree shows "Clndrs <= 4 -> good cars", so engineering
mandates removing cylinders from existing engines,
expecting the disty to follow.
What is the mistake, its consequence, and the fix?

**Q146** — `m.relevant(tree, row)` walks a row to its leaf
and hands back that leaf's ROWS, not a prediction.
a. Why is that the more useful contract?
that the more useful contract?
b. A library's leaves return only a single precomputed
mean, so the new requirement — "per-leaf uncertainty and
exemplar rows" — needs a fork and a retrain.
What is the mistake, its consequence, and the fix?

**Q148** — a. [FMAP](#glossary): how do two probes replace
an O(n^2) search for structure?
b. To find "the two most different configs" a script
computes all 3.7 billion pairwise distances on SS-X. The
ticket asks for a Spark cluster.
What is the mistake, its consequence, and the fix?

**Q150** — ftree recursively splits rows by which of two
far "poles" they sit nearer, consulting x columns only.
a. It never reads goals, yet its leaves had
coherent disty. Which bet ([BETS](#glossary)) is that, and
when does it fail?
b. A team applies geometric data-light search to a table
where every column is an independent random knob (no
structure, all dimensions interact). It underperforms
random search; they conclude the METHOD is broken.
What is the mistake, its consequence, and the fix?

**Q153** — ftree builds from a capped random sample of
rows, not the whole table.
a. Why is sampling acceptable when
building trees on big data?
b. "Sampling is unsound; we rebuilt ftree to scan all 86k
rows at every node. It is now slower than the exhaustive
method it was meant to replace."
What is the mistake, its consequence, and the fix?

**Q155** — a. [SYNTH](#glossary): why blend rows WITHIN a
leaf instead of sampling each column independently?
b. A test-data generator draws each field from its own
column distribution; QA gets 4,000-lb cars doing 40 mpg
and files "unrealistic test data" bugs.
What is the mistake, its consequence, and the fix?

**Q158** — `m.sample` blends only the x cells of three
leaf rows; the y cells come along unchanged from one
parent.
a. A synthetic row's y cells are inherited, not
measured. Why is that a lie waiting to happen?
b. A report computes "the mean mpg of our 500 generated
cars" from the generated rows' own mpg cells and presents
it as a finding.
What is the mistake, its consequence, and the fix?

**Q160** — The detector scores a row by its distance to
its nearest neighbor inside its own ftree leaf.
a. [ANOM](#glossary): an anomaly score is the
CDF position of what, calibrated on what?
b. An alerting system flags any row whose raw
nearest-neighbor distance exceeds 0.3 — a constant chosen
on one dataset — and is now deployed unchanged on ten
others.
What is the mistake, its consequence, and the fix?

**Q162** — In auto93's x-space, many cars share identical
values (same cylinders, volume, year, origin).
a. Why was a real row's anomaly score
0.35 rather than 0.5 (`[166]`)?
b. An engineer sees scores clustering near 0.35 and
"recenters" them by subtracting 0.15, breaking what
property of the output?

**Q165** — a. [MFID](#glossary): state successive halving
in two sentences.
b. A tuning farm gives all 1,000 candidate configs the
full one-hour benchmark before comparing any. Bill: 1,000
hours; insight available after minutes: most candidates
were visibly bad.
What is the mistake, its consequence, and the fix?

**Q168** — a. Mutation must respect column TYPE. What is
legal for a Num that is meaningless for a Sym?
b. A mutator "perturbs" the origin column (values 1,2,3 —
country codes) by adding gaussian noise, producing origin
2.37.
What is the mistake, its consequence, and the fix?

**Q170** — det() returns a calibrated CDF position;
luamine's gate alarms outside 0.1..0.9 — BOTH tails.
a. What does each
tail mean for a synthetic row?
b. A quality gate for generated data alarms only on
cdf > 0.9. A generator that collapses to emitting
near-duplicates of one training row sails through.
What is the mistake, its consequence, and the fix?

**Q171** — Every detector calibrates against its own
randomly built ftree.
a. Scores are therefore model-relative. What
discipline does that impose when comparing scores?
b. Two teams compare anomaly scores computed from two
independently built (unseeded) detectors and debate why
row 17 is "anomalous for us but not for them".
What is the mistake, its consequence, and the fix?

**Q173** — a. [MUT](#glossary): what makes a mutation
"distribution-aware", and why does it pay?
b. A fuzzer mutates car weight uniformly in [0, 10^9].
Nearly every candidate is garbage; the surrogate's scores
out there are fiction ([ANOM](#glossary)). The team buys
more compute.
What is the mistake, its consequence, and the fix?

**Q175** — a. Why must mutation copy, never edit, the
parent?
b. After "mutating" the population in place, a GA's
parents are gone; selection now compares children against
children and diversity collapses. The team blames the
crossover rate.
What is the mistake, its consequence, and the fix?

**Q178** — DE builds each kid as `a + F*(b-c)` from three
current population members.
a. The move is along b-c, the
difference of two members. Why is that direction smart?
b. A clone replaces b-c with a fixed step size of 0.1 "for
simplicity". Early search crawls; late search overshoots.
Which property was discarded?

**Q180** — a. [SURR](#glossary): why can a mutant row not
be scored by its own y cells?
b. A DE implementation scores each invented kid directly
on the kid's own cells:
```lua
oracle = function(kid) return m.disty(d.cols, kid) end
```
Mistake, consequence, fix?

**Q182** — a. Where does a kNN surrogate fail worst, and
which lecture-7 tool names those regions?
b. An optimizer wanders far from all labeled data, the
surrogate cheerfully scores the wilderness, and the "best
config ever" fails in production. Post-mortem blames the
optimizer's parameters.
What is the mistake, its consequence, and the fix?

**Q185** — Simulated annealing escapes local optima by
sometimes accepting WORSE moves, with a probability
governed by a temperature that cools as the eval budget
drains (T = 1 - h/b).
a. State the acceptance rule in words ([MH](#glossary)) —
and what do h and b stand for?
b. A searcher accepts strictly-better moves only,
restarts disabled, on a landscape known to be rugged. It
reports the same local optimum from every start near it.
What is the mistake, its consequence, and the fix?

**Q187** — egs.pdf's tournament indexed every result by
its evaluation budget.
a. "Budget is a first-class variable"
(egs.pdf). What does that mean for reporting results?
b. A paper reports final scores after 10,000 evaluations
per method, on problems where practitioners can afford 50
labels. Practitioners adopt the winner and get nothing.
What is the mistake, its consequence, and the fix?

**Q190** — Before scoring, `a.track` replaces each
generated kid with its nearest REAL row.
a. What honesty does the snap buy, and what ability does
it cost?
b. A results table presents invented rows' inherited y
values as outcomes; one "discovered config" was never
built, benchmarked, or seen.
What is the mistake, its consequence, and the fix?

**Q193** — a. Why must every new optimizer be raced
against local search AND random search?
b. A paper's new method beats NSGA-II on three datasets;
no simpler baseline appears anywhere. Reviewer 2 asks one
question. What is it?

**Q195** — `a.race` keeps a record only when a kid beats
the best disty seen so far, across ALL methods.
a. Why does the resulting curve slope one way?
b. A plot of "best so far" wiggles up and down across
evaluations. Name the bookkeeping sin.
What is the mistake, its consequence, and the fix?

**Q197** — a. The 2x2 experiment (acceptance x restarts):
what question does each factor isolate?
b. "LS beat SA 0.07 to 0.09, so local search is better
than simulated annealing on auto93" — from one seed each
(`[191]`, `[196]`).
What is the mistake, its consequence, and the fix?

**Q199** — a. [GA](#glossary): the three operators of one
generation, in order.
b. A "genetic" algorithm mutates and selects but never
recombines. On problems with strongly coupled parameters
it matches plain (1+1) search at triple the cost; on
building-block problems it leaves its only advantage
unused.
What is the mistake, its consequence, and the fix?

**Q201** — Every optimizer here is a closure yielding one
generation per call, holding its population inside.
a. What does "one
generation per call" buy in memory and control?
b. A framework materializes all 1,000 generations as a
list "for later analysis"; the analysis only ever reads
the last one.
What is the mistake, its consequence, and the fix?

**Q203** — `a.ga(d, a.knn(d))` sets aside rows the GA
never evolves from, and scores candidates against them.
a. What is that `ref` pool in
`a.ga(d, a.knn(d))`, and which principle does scoring
against it serve?
b. A surrogate-guided GA evaluates kids against the same
rows it evolved FROM, and its "improvement" curve looks
suspiciously like memorization.
What is the mistake, its consequence, and the fix?

**Q205** — DE's step is F times the difference of two
current members — and members converge over time.
a. So DE needs no step-size schedule. What
provides the automatic scaling?
b. A tuned-by-hand cooling schedule for mutation size took
a graduate student three weeks; DE's two knobs were never
tried. What did the student rediscover, badly?

**Q208** — In each de sweep, every member spawns one kid
via extrapolation.
a. The replacement rule: a kid replaces whom,
when? What does that greedy locality preserve?
b. A variant lets any good kid replace the population's
WORST member. Diversity craters and the population
converges onto one basin in five generations. Why did the
original rule avoid this?

**Q211** — a. [RACE](#glossary): why compare optimizers on
an evaluations axis rather than final scores?
b. Two methods both end at disty 0.09. One got there by
evaluation 16, the other by 1,900. A "results table" shows
only the finals: a tie.
What is the mistake, its consequence, and the fix?

**Q214** — a. The race table's first row is "average".
What question does every later row get measured against?
b. A slide shows "ga found disty 0.15!" with no baseline
row. The audience cannot tell if that is genius or the
table average.
What is the mistake, its consequence, and the fix?

**Q217** — a. [PARETO](#glossary): define domination; what
is the front; what does a scalarizer return instead?
b. A tool computes one weighted-sum optimum and labels it
"the Pareto front" in the deliverable to stakeholders, who
needed the menu of trade-offs.
What is the mistake, its consequence, and the fix?

**Q219** — a. [GP](#glossary) -> [APR](#glossary): what is
evolved, what is fitness — and what classic failure does
test-based fitness invite?
b. An auto-repair bot's patch makes all failing tests pass
by deleting the feature under test. Fitness: 100%.
What is the mistake, its consequence, and the fix?

**Q220** — a. egs.pdf's tournament: what migrated as the
budget grew, and what floor must every winner beat?
b. A team standardizes on one optimizer company-wide
"because it won our benchmark" — run at a single budget
ten times larger than any real project's.
What is the mistake, its consequence, and the fix?

**Q224** — acquire maintains two evolving tables — best
and rest — over the labeled rows so far.
a. [ACQ](#glossary): what score decides which
row gets the next label, and what two models compute it?
b. A labeling crew works through the unlabeled pool in
file order ("it's fair"), burning the budget before
reaching the region where the model was uncertain.
What is the mistake, its consequence, and the fix?

**Q228** — a. Over twenty repeats, thirty acquired labels
out-found thirty random ones (`[229]`: 0.11 vs 0.13). Why —
what does the acquirer steer toward?
b. An active learner is warm-started on the FIRST ten rows
of a file sorted by year. Everything it then "wants" is
old. Name the threat and the one-line discipline that
prevents it ([XVAL](#glossary)).
What is the mistake, its consequence, and the fix?

**Q233** — a. [BOB](#glossary): the five pipeline stages,
and the headline number (labels spent vs rows ranked)?
b. A "budget-aware" pipeline quietly computes true disty
on every test row to pick its final answer, then reports
"only 34 labels used".
What is the mistake, its consequence, and the fix?

[contents](#contents)

---


<a name="answers"></a>
# Answers

**4.** a) That careful reading of small codebases yields
insight that flying over details cannot — demonstrated by
building working AI from a few hundred readable lines.
b) Mistake: reading ABOUT code instead of running it.
Cost: recall without skill — no debugging instinct, no
feel for behavior. Fix: drive every claim through the
REPL; the prompts exist to be typed.

**5.** a) In the help text; the documentation and the
defaults are one artifact, so they cannot drift.
b) Mistake: two sources of truth. Cost: they WILL diverge
(the first undocumented flag change), and the docs become
lies. Fix: derive one from the other — parse defaults out
of the help, as luamine does.

**6.** a) Each fact has one authoritative home; all other
forms derive mechanically. CONF: help text is the home,
`the` derives. CSV: the header is the home, Cols derive.
b) Mistake: three independent homes for one fact. Cost:
drift is guaranteed; whichever source a reader trusts,
two others quietly disagree. Fix: pick one authority (the
header — it travels with the data), derive or delete the
rest.

**7.** a) So a flag set once on the command line reaches
every module — one knob, system-wide.
b) Mistake: a private snapshot of shared config. Cost:
`--p 4` changes three files' behavior but not the fourth —
inconsistent metrics inside one run, brutal to debug. Fix:
share the live table; never copy settings.

**9.** a) A schema document, a column-role config, and the
loader code to apply both — one line carries all of it.
b) Mistake: schema separated from data. Cost: every tool
needs side-channel knowledge; the pdf rots; nine columns
of `c1..c9` mean nothing in six months. Fix: encode roles
in the names ([LIL](#glossary)); the table becomes
self-describing.

**11.** a) Because types drive everything downstream:
numbers get means/sds and arithmetic distance; strings get
modes and equality distance.
b) Mistake: strings forever. Cost: every column became
symbolic — no means, no normalization, distance reduced to
equal-or-not. Fix: coerce at the boundary, once, on the
way in.

**13.** a) Reproducibility ([SEED](#glossary)): identical
runs must produce byte-identical output, and hash order
isn't deterministic across machines.
b) Mistake: asserting on nondeterministic order. Cost:
flaky tests that pass locally and fail elsewhere — trust
in the suite erodes. Fix: canonicalize (sort) before
comparing, or assert on content not order.

**15.** a) Constant memory and immediate results — the
file never needs to fit in RAM.
b) Mistake: materialize-then-process. Cost: memory scales
with data, not with the question being asked; the laptop
was never the problem. Fix: stream — fold each row into
running summaries and discard it.

**17.** a) Detect violated assumptions at the boundary and
stop with a named cause; early crashes point at the fault,
late ones point at a symptom rooms away.
b) Mistake: silence sold as robustness. Cost: a green
pipeline and a false "0 anomalies" — failure laundered
into a result. Fix: fail loudly at the load boundary;
robustness, if wanted, must be explicit and visible
(logged fallback), never silent.

**18.** a) The schema: column names, types, goals,
ignores. Metadata, not a configuration.
b) Mistake: counting the header as data. Cost: every count
is off by one; small, silent, and it propagates into every
downstream statistic. Fix: rows = lines minus one; better,
count what the loader yields.

**21.** a) "No new globals": Lua makes any undeclared
assignment global, so leaks are one typo away — hence an
automated exit audit, not a style hope.
b) Mistake: convention without enforcement. Cost: rules
decay under deadline pressure; the leak ships and couples
strangers. Fix: make the program audit its own rule every
run ([ROGUE](#glossary)) — lint, exit check, CI gate;
review is the backup, not the mechanism.

**22.** a) That it can be re-run exactly: seed recorded,
seed set, randomness varied only on purpose.
b) Mistake: unrepeatable claim. Cost: nobody — including
the authors — can verify or debug the 12%; it is an
anecdote with decimals. Fix: fixed recorded seeds, and
repeats across seeds before claiming anything.

**24.** a) Side effects at a distance: one consumer
silently reordering data that another consumer assumes
untouched.
b) Mistake: in-place sort destroyed arrival order. Cost:
the stream is now sorted best-first — an order effect
([XVAL](#glossary)) that biases any incremental learner
fed from it. Fix: rank a copy; leave shared data unmutated.

**26.** a) Because "sort things by a computed property" IS
most of the course: rows by distance (kNN), candidates by
acquisition score, methods by mean score.
b) The min-loop is fine for one cheap key. The real
argument: when the key is expensive (a benchmark, a
likelihood) or the whole ORDER is needed (take top-k, take
percentiles), keysort computes each key once and returns
the order — the loop recomputes or under-delivers. Fix:
know which question you're asking — extremum vs ordering.

**27.** a) Distance takes a row-scorer; trees take a
summarizer factory; track takes a stepper. Behavior is
plugged in, not hardcoded.
b) Mistake: one function per behavior. Cost: combinatorial
API growth, each variant a copy-paste to maintain. Fix:
one verb that accepts the varying behavior as a function
argument.

**29.** a) When the key is an EVALUATION — a benchmark, a
build, a label. Comparator-sorting calls it O(n log n)
times; the budget dies in the sort.
b) Mistake: expensive oracle inside a comparator. Cost:
~13x the evaluation budget on 10,000 candidates — spent
on sorting overhead, not search. Fix: score once per
candidate (decorate), sort the scores.

**31.** a) Because full scans are usually unnecessary:
structure shows up in samples, and evaluations are the
scarce resource ([MFID](#glossary), [SAMP](#glossary)).
b) Mistake: rigor confused with exhaustiveness. Cost: all
the speed of the data-light approach is gone; nothing was
gained — sampled statistics were already inside noise.
Fix: cap and sample by default; go exhaustive only when a
measured difference justifies it.

**33.** a) So the shuffle is a function of a recorded seed
— anyone can regenerate the exact split.
b) Mistake: publishing an unseeded shuffle. Cost: the
exciting split is unreproducible; the result cannot be
checked, extended, or trusted. Fix: reseed immediately
before, record the seed in the paper.

**35.** a) Count, mean, and m2 (running squared
deviation) — mean and sd of everything seen, in three
numbers.
b) Mistake: storing history to recompute a mean. Cost:
unbounded memory for a constant-space question; the
proposed "sample the history" adds error to fix a
non-problem. Fix: Welford — update three numbers per
arrival, discard the value.

**37.** a) Active learning (lecture 10) and test-then-
train evaluation (lecture 5) — both need cheap per-row
updates. (Streaming anything, really.)
b) Mistake: "incremental" by full retrain. Cost: O(n) work
per row, O(n^2) overall; hardware spend standing in for a
three-line algorithm. Fix: summaries that update in place
([WEL](#glossary)).

**39.** a) Entropy: 0 bits = a sure thing; max bits =
uniform confusion.
b) Mistake: arithmetic on nominal codes ([NOIR]
(#glossary)). Cost: "sd of status" depends on the
arbitrary 1,2,3 assignment — renumber the labels and the
number changes. Fix: symbols get entropy, not sd.

**43.** a) Ranks ignore magnitude, so a few wild outliers
can't dominate; SE data is full of wild outliers.
b) Mistake: a means-based test on outlier-poisoned data.
Cost: a handful of million-ms hiccups inflate variance
until everything is "not significant" — a real difference
hides. Fix: rank-based comparisons (Cliff's delta, KS),
which the hiccups barely move.

**45.** a) pdf: how common is x. cdf: what fraction sits
at or below x.
b) Mistake: read a height where a fraction was needed.
Cost: histogram height depends on bin width — the number
reported isn't a fraction of anything. Fix: cumulate
(count cars <= 2,500, divide by n): a CDF read.

**47.** a) add (learn a value), mid (central tendency),
spread (confusion around it).
b) Mistake in the review, not the model: a Num holds
three numbers, no rows. Cost: a privacy non-issue blocks
a compliant design. Fix: explain summaries-not-data;
per-column (n, mu, sd) leaks no individual record (worth
verifying for tiny n).

**49.** a) add / mid / spread — same verbs, type-fitting
math; containers call the verbs blind.
b) Mistake: parallel implementations of one protocol.
Cost: divergence — the "?" fix landed in two of three
copies; the third silently corrupts. Fix: one polymorphic
loop; types differ only inside their own add.

**50.** a) Sym: mode and entropy. Num: mean and sd.
b) Mistake: mid without spread. Cost: near-max entropy
means the mode barely leads — "the typical car is
American" overstates a weak plurality. Fix: report
central tendency WITH its confusion, always.

**53.** a) Iterators let summaries consume streams —
files bigger than memory, generators, live feeds — not
just arrays.
b) Mistake: array-only API. Cost: forced
materialization; memory scales with file size before the
first statistic appears. Fix: accept anything that yields
values one at a time.

**55.** a) The header, at load time. Roles are data, not
code.
b) Mistake: role decided in a private code edit. Cost:
the table now means different things in different hands;
no artifact records the change. Fix: rename the column
(`...+`), commit the new header — the role travels with
the data.

**57.** a) It is read off the per-column summaries — mids
already maintained incrementally; no row scan.
b) Mistake: O(rows) recompute inside an O(iterations x
clusters) loop. Cost: k-means slows by orders of
magnitude on big tables; the algorithm gets blamed. Fix:
centroids from running summaries; recompute nothing.

**59.** a) Make the common case automatic via naming
conventions; reserve explicit config for exceptions. The
convention: case + suffix decide type and role; the
configuration eliminated: any per-table schema/mapping
file.
b) Mistake: per-dataset configuration for decisions a
convention covers. Cost: copy-paste mappings rot; one
stale entry silently corrupts a quarter of results — and
nobody audits 200-line boilerplate. Fix: let names carry
the decision ([COC](#glossary), [SSOT](#glossary)); make
the rare exception, not the rule, explicit.

**60.** a) It becomes the Cols schema; it is a different
KIND of thing than a row, so storing it as data poisons
every column with one string.
b) Mistake: header ingested as a row. Cost: a phantom
"car" whose cells are column names; numeric summaries
corrupted or crashed. Fix: first row builds structure;
data begins at the second.

**63.** a) Lecture 5 (one table per class) and lecture 5
again (one per cluster); lecture 10's best/rest too.
b) Mistake: re-parsing the source per class. Cost: 19
full file reads where one pass + 19 clones suffices;
minutes for milliseconds. Fix: read once, clone the
schema, route rows.

**66.** a) From its NAME: `+` maximize, `-` minimize —
recorded as goal = 1 or 0 at header parse.
b) Mistake: a rename changed semantics, silently —
`Lbs` (no dash) stops being a goal at all. Cost: the
optimizer now ignores weight; every "best car" since the
refresh is wrong, and nothing crashed. Fix: header names
are an interface; guard them (review, checksum), don't
"tidy" them.

**68.** a) Nominal, ordinal, interval, ratio; a mean is
fine on ratio and nonsense on nominal.
b) Mistake: arithmetic below its scale. Cost: numbers
that change under relabeling — zip-code means and
priority sds are artifacts, not facts. Fix: modes and
entropy for nominal/ordinal; means only from interval up.

**70.** a) Gained: two simple types cover everything,
visibly ([CSV](#glossary)). Lost: ordinal gap-sizes are
treated as meaningful when they may not be.
b) The proportionate answer: the compromise is explicit,
common, and empirically mild here (years behave
near-interval); the cost of full scale-correctness is a
type system nobody audits. Consequence of the reviewer's
absolutism: rejecting workable simplicity without
measuring the harm. Fix: acknowledge, cite the
convention, show a robustness check.
**72.** a) Unnormalized, the widest-range column IS the
distance; everything else becomes noise.
b) Mistake: raw units mixed. Cost: weight (thousands)
drowns mpg (tens) — "similarity" is just weight. Fix:
normalize each column to a common 0..1 scale first.

**74.** a) Unknown vs unknown = maximum distance; unknown
vs known = assume the far end. Philosophy: pessimism
degrades gracefully; optimism fails silently.
b) Mistake: mean-imputation optimism. Cost: 40%-missing
rows all sit at the centroid — artificial tightness,
confident clusters made of ignorance. Fix: pessimistic
distance rules (or at minimum, uncertainty flagged, not
averaged away).

**75.** a) x columns only; goals must never enter
similarity.
b) Mistake: goal leakage into clustering. Cost: clusters
"predict" goals because goals built them — circular
insight that evaporates on new unlabeled rows. Fix: keep
the x/y wall; the header's roles exist to enforce it.

**78.** a) Normalize each goal, measure distance to the
all-goals-perfect corner; 0 = heaven.
b) Mistake: hand-tuned weights with no semantics. Cost:
endless argument (0.6 vs 0.7 decides nothing principled);
results change with the mood of the meeting. Fix: D2H —
geometry replaces weight-haggling; arguments move to the
goals themselves, where they belong.

**80.** a) The header's `+`/`-` marks plus normalization —
direction-of-good was already encoded.
b) Mistake: buying human ranking that the schema already
provides. Cost: three analyst-weeks and inconsistent
judgments versus one disty sort. Fix: encode goals once
in the header; spend humans on checking the top of the
ranking, not producing it.

**83.** a) Larger p makes big deviations dominate; the
limit is Chebyshev — only the worst goal counts.
b) Implicit choice: small p (averaging); needed: large p /
Chebyshev so one catastrophic violation cannot hide.
Cost: a "great average" config that fails the safety
goal. Fix: match p to the question — worst-case goals
need worst-case aggregation.

**86.** a) There is none: the data is the model; cost is
paid at query time.
b) Mistake: "no training budget" rejected the method with
NO training step, for one with a weekly retrain. Cost:
exactly the spend they feared, recurring. Fix: evaluate
methods on their actual cost profile (train vs query),
not their category's reputation.

**88.** a) Because self-distance is 0: "nearest" becomes a
mirror and every neighborhood question degenerates.
b) Mistake: self-matching. Cost: all anomaly scores are 0
— the detector is structurally blind, and "no anomalies"
is announced. Fix: exclude identity from neighbor queries
(luamine parks self past max distance).

**90.** a) The best observed (win=100) and the median
(win=0) — every result is read against the data's own
spread.
b) Mistake: an unanchored number. Cost: 0.41 might be
brilliant or might be one noise-width from doing nothing
(average 0.43 says: the latter). Fix: always print the
baseline row; report win, not raw disty.

**93.** a) ZIT duels two rows (robust, pairwise, no
scale); D2H scores one row (cheap, total order, sortable).
b) Mistake: pairwise machinery for a sorting job. Cost:
O(n^2) duels — billions of comparisons that one O(n)
scoring pass replaces. Fix: scalarize to sort; duel when
selecting between two specific candidates (GA
tournaments).

**95.** a) So one view = one consistent metric; every
distance it ever reports is comparable.
b) Mistake: changing the metric mid-experiment. Cost:
first-half and second-half distances live in different
spaces; their comparison is meaningless and looks fine.
Fix: bake parameters at creation; new metric = new view =
new experiment.

**97.** a) like/pdf: "how common is this value?";
norm/cdf: "what fraction lies below it?"
b) 0.93 said: 93% of weights sit below this one — a rank,
not a probability of anything. Cost: "93% likely" invents
a likelihood claim the number never made. Fix: use the
right view for the question; report cdf as percentile.

**99.** a) It multiplies the whole product by zero — one
absence erases all other evidence.
b) Mistake: unsmoothed frequencies. Cost: a single novel
word grants spam immunity — the fifty real signals are
multiplied by 0. Fix: m-estimate/Laplace smoothing — no
count is ever exactly zero.

**101.** a) Products of many <1 numbers underflow to 0;
sums of logs do not.
b) Mistake: diagnosing underflow as a data problem. Cost:
more data makes MORE columns of small factors — the zeros
stay; effort burned on the wrong layer. Fix: log space.
(More data fixes statistics, not arithmetic.)

**103.** a) Leakage: letting the answer (or anything
derived from it) into the question.
b) Mistake: klass included in evidence. Cost: 100%
accuracy in the lab, useless in production where the
klass cell is exactly what's unknown. Fix: evidence from
x only; treat suspiciously-perfect scores as leak alarms,
not victories.

**105.** a) argmax needs only ORDER; if the right class
outscores the wrong ones, miscalibrated magnitudes don't
matter.
b) Mistake: judging a ranker on calibration. Cost: a
working classifier discarded over a property it never
claimed. Fix: evaluate on decisions (pd/pf); calibrate
separately if probabilities are truly needed.

**107.** a) Overfitting, order effects, learner
variability.
b) Mistake: testing on training data. Cost: 94% measures
memorization; production performance is unknown. Fix:
hold out unseen rows — shuffle, split, repeat
([XVAL](#glossary)).

**110.** a) "Always say no" scores 99% while catching
nothing; demand pd (recall) and pf (false alarms).
b) Mistake: accuracy on imbalanced data. Cost: a detector
that detects nothing gets praised and shipped. Fix:
per-class pd/pf; accuracy never decides rare-event
quality.

**112.** a) Assign rows to nearest centroid; recompute
centroids as cluster mids; repeat.
b) Mistakes: unscaled data (one column owns the
distance), one run (seed luck), arbitrary k, no
stability check. Cost: "segments" that are artifacts of
units and chance, shipped to product. Fix: normalize;
multiple seeded runs; inspect stability and per-cluster
summaries before believing.

**114.** a) Both steps provably reduce (or hold) the
within-cluster error — it is coordinate descent.
b) Mistake: "stochastic noise" excuse for a monotonicity
violation. Cost: a real bug (distance/assignment
mismatch, centroid error) ships under a folk theory. Fix:
treat invariant violations as bugs, full stop; the
algorithm's math says this cannot wiggle.

**117.** a) Random seeds can land adjacent — two centroids
splitting one true cluster while another goes unserved.
b) Mistake: one run per method ([SEED](#glossary),
[TIER](#glossary)). Cost: the conclusion is a coin flip
formalized. Fix: many seeds per method, compare the two
DISTRIBUTIONS.

**119.** a) Per-cluster centroids, sizes, spreads, and
goal summaries — every Data ability, free.
b) Mistake: clusters as bare index lists. Cost: every
follow-up question (means? spreads? exemplars?) becomes
new plumbing. Fix: make the cluster a first-class table
that summarizes itself ([POLY](#glossary)).

**123.** a) Predict first, score the prediction, THEN
learn the row; every row is honest test data — no split
needed.
b) Mistake: learn-then-predict. Cost: each prediction is
of a row already memorized — accuracy inflated, the free
honest evaluation destroyed. Fix: the order IS the
method: test, then train.

**125.** a) Trades numeric precision for readability,
speed, and noise resistance.
b) Mistake: precision theater — six decimals nobody can
act on, depth nobody can follow. Cost: the audience (the
model's entire purpose, [XPLN](#glossary)) disengages.
Fix: coarse cuts, shallow trees; precision only where a
decision actually turns on it.

**127.** a) Equal-width bins go empty under skew;
percentile bins are populated by construction.
b) Mistake: equal width on skewed data. Cost: one bucket
= 9,999 people, nine = decoration; "more buckets" makes
more empties. Fix: cut at percentiles — let the data
place the boundaries.

**129.** a) The size-weighted spread (sd or entropy) of
the two sides' goal summaries — lower = purer.
b) Mistake: splitting on size, not purity. Cost: big,
uninformative leaves — the tree never asks a question
that separates good from bad. Fix: score splits by what
they do to the GOAL's confusion.

**131.** a) It never revisits a committed split; risks a
locally-best first cut that strands a globally better
tree.
b) Mistake: optimal-step => optimal-result. Cost: a false
guarantee — greedy proves nothing global. Fix: claim what
greedy gives (good, fast, readable), and validate the
tree empirically.

**133.** a) Leaf-size floor and no-improving-cut; small
because the tree's product is human comprehension.
b) Mistake: trading the product (readability) for fit,
then buying explanation of the unreadable artifact. Cost:
400 nodes nobody audits + a tool to apologize for them.
Fix: keep the floor; spend accuracy points on
comprehension ([XPLN](#glossary)).

**135.** a) The summarizer: Num (sd purity) for numeric
goals, Sym (entropy purity) for classes.
b) Mistake: averaging class labels as numbers. Cost: a
tree optimizing a meaningless quantity ([NOIR]
(#glossary)) — plausible-looking, wrong, unnoticed. Fix:
match the summarizer to the goal's type; make type
mismatches loud.

**138.** a) When the model must be audited, argued with,
or signed off by people who didn't build it.
b) Mistake: unauditable model in a regulated loop. Cost:
the 2% buys an artifact that cannot answer the auditor;
compliance risk eats the accuracy gain. Fix: interpretable
model where stakes demand answers ([INTERP](#glossary));
measure what the 2% actually costs.

**140.** a) Interpretable: the model itself is readable.
Explainable: a second model tells stories about the
first.
b) Mistake: faithfulness by assertion. Cost: the overlay
may rationalize, not reveal — and no one can check
without the very access it papers over. Fix: demand
faithfulness tests, or use a model that IS its own
explanation.

**142.** a) Extrapolate beyond seen data; stay stable
under reshuffling (near-tied cuts flip). (Also: model
within-leaf trends.)
b) Mistake: interpretability mistaken for generality.
Cost: confident nonsense on an electric SUV — readable
and wrong. Fix: interpretability tells you HOW it
decides; only data coverage tells you WHERE it applies
(pair with [ANOM](#glossary)-style range checks).

**144.** a) Seeing, doing, imagining; everything here is
rung one — association.
b) Mistake: reading rung one as rung two. Cost: cylinders
correlate with quality via design briefs; amputating
cylinders moves the correlate, not the cause. Fix: treat
branches as hypotheses; buy a rung-two answer with an
intervention ([LADDER](#glossary), [ACQ](#glossary)).

**146.** a) Rows let the caller fold ANY summary — means,
modes, spreads, exemplars — and inspect actual cases.
b) Mistake: precomputed point answers. Cost: every new
question (uncertainty? examples?) is a feature request
instead of a fold. Fix: return the data; let
[POLY](#glossary) summaries answer questions as they
arise.
**148.** a) Pick a random row, walk to something far, then
far from THAT: two O(n) passes find near-extreme structure
without the O(n^2) pair scan.
b) Mistake: exhaustive search for a question sampling
answers. Cost: billions of distances (and a cluster bill)
for what two passes approximate well enough. Fix: poles —
and in general, ask whether "the exact answer" is worth
its price ([SIMP](#glossary)).

**150.** a) The A7 low-intrinsic-dimensionality bet: data
collapses onto a few regions, so geometric structure
correlates with goals. It fails when all dimensions
interact and no structure exists.
b) Mistake: blaming the method for a falsified ASSUMPTION.
Cost: a tool discarded company-wide over one
pathological landscape. Fix: state the bet, test the bet
([BETS](#glossary)); on structureless tables, nothing
beats random — that is information, not failure.

**153.** a) Because structure visible in a sample is the
structure that matters; evaluations and scans are the
scarce resources ([SAMP](#glossary), [MFID](#glossary)).
b) Mistake: equating exhaustiveness with soundness. Cost:
the speed that justified the approach is gone; "rigor"
bought nothing measurable. Fix: cap and sample; escalate
to full scans only when a measured difference warrants.

**155.** a) Independent column draws break covariance —
columns move together in real data; leaf-local blends
inherit that structure.
b) Mistake: per-column sampling. Cost: chimeras (heavy
cars with great mileage) that waste QA time and poison
any model trained on them. Fix: generate within local
neighborhoods ([SYNTH](#glossary)).

**158.** a) Because the y cells describe a DIFFERENT
x-point; nothing measured this new row.
b) Mistake: reading inherited labels as outcomes. Cost: a
"finding" about fabricated numbers — circular and
unfalsifiable. Fix: y values of synthetic rows are either
re-measured or clearly marked inherited; never aggregated
as results ([SURR](#glossary)).

**160.** a) The CDF position of its leaf-local
nearest-neighbor distance, calibrated on the training
rows' own such distances.
b) Mistake: a raw, uncalibrated threshold transplanted
across datasets. Cost: on tables with different density,
0.3 over- or under-alarms arbitrarily. Fix: calibrate
per-dataset — score positions in THAT data's distance
distribution ([ANOM](#glossary)).

**162.** a) Duplicated x-rows make the typical NN distance
zero, so the calibration mass sits low; a dup row lands at
0.35, the body, not 0.5.
b) Mistake: "recentering" a CDF. Cost: outputs stop being
percentile positions — the 0.1/0.9 alarm gates lose their
meaning entirely. Fix: leave calibrated positions alone;
if the shape bothers you, understand the data (dups), not
cosmetics.

**165.** a) Give all candidates a tiny budget; keep the
best half and double their budget; repeat until one
survives.
b) Mistake: uniform deep evaluation. Cost: ~970 of 1,000
hours spent on candidates that minutes had already
condemned. Fix: triage — successive halving / Hyperband
([MFID](#glossary)).

**168.** a) Arithmetic steps (gaussian nudges, blends) are
legal on Nums; Syms admit only re-DRAWING a value (by
frequency).
b) Mistake: arithmetic on a nominal code ([NOIR]
(#glossary)). Cost: origin 2.37 — a country that does not
exist; distance and likelihood math silently degrade.
Fix: type-aware mutation — perturb numbers, redraw
symbols.

**170.** a) High tail: far from everything — an outlier.
Low tail: suspiciously closer than real data ever is — a
near-duplicate.
b) Mistake: alarming on one tail. Cost: a collapsed
generator (memorizing one row) passes QA while producing
nothing new. Fix: alarm on BOTH tails; each names a
different pathology.

**171.** a) Compare scores only within one calibrated
detector (or build detectors identically, seeded); scores
are positions in a model's own distribution.
b) Mistake: cross-model score comparison. Cost: a debate
about an artifact — the two 0.x values live on different
scales. Fix: one shared, seeded detector (or compare
RANKINGS, not raw scores).

**173.** a) Steps scaled by each column's observed spread,
drawn inside its plausible range — neighborhoods stay on
the data.
b) Mistake: uniform mutation over an unbounded range.
Cost: almost all candidates are off-manifold; surrogate
scores there are fiction; compute is burned exploring
nowhere. Fix: mutate within distribution ([MUT]
(#glossary)) — sd-scaled steps, frequency draws.

**175.** a) Search compares child against parent; editing
the parent destroys the comparison and the population's
memory.
b) Mistake: in-place mutation. Cost: parents vanish,
selection degenerates, diversity collapses — and the
visible symptom (bad convergence) points at the wrong
knob. Fix: copy on mutate; treat shared rows as immutable
([SIMP](#glossary)'s cousin: no spooky action).

**178.** a) The population's own displacement encodes both
a promising direction and a sensible scale, for free.
b) Mistake: fixed step size. Cost: the self-scaling
property is discarded — steps too timid early, too coarse
late; convergence needs the hand-tuning DE was built to
avoid. Fix: keep steps proportional to member differences
([DE](#glossary)).

**180.** a) Because its y cells were inherited from a
parent at different x — scoring them rewards fiction.
b) Mistake: trusting invented labels. Cost: the optimizer
"improves" a photocopy of its parents' scores; reported
gains never existed. Fix: score invented rows through a
surrogate anchored to REAL measurements (nearest labeled
row).

**182.** a) Far from all labeled data — exactly the
regions the anomaly detector flags as off-manifold.
b) Mistake: trusting a surrogate outside its support.
Cost: a paper config that fails in production; the
post-mortem tunes parameters instead of adding the
missing guard. Fix: gate surrogate trust by an
[ANOM](#glossary)-style score; label (truly evaluate)
before believing wilderness wins.

**185.** a) Accept better always; accept worse with
probability exp(-gap/T); h = evaluations spent, b = the
budget, so T cools to zero and late search is pure greed.
b) Mistake: pure greed, no escape mechanism, on rugged
ground. Cost: every run reports the nearest local
optimum — reliable mediocrity. Fix: tolerate early bad
moves ([MH](#glossary)) or restart; ruggedness demands an
escape hatch ([BETS](#glossary): A1 falsified).

**187.** a) Results must be indexed by budget: the best
method at 10,000 evals and at 50 labels are different
methods.
b) Mistake: benchmark budget mismatched to practice.
Cost: practitioners adopt a method whose advantages only
exist at budgets they will never have. Fix: report
winners PER budget tier; recommend by the reader's
budget, not the lab's.

**190.** a) Honesty: every reported row truly exists with
measured y values. Cost: no credit for genuine
interpolation — a better in-between point gets snapped
away.
b) Mistake: fabricated outcomes in a results table. Cost:
a "discovery" nobody can build or verify; the table mixes
measurement with imagination. Fix: snap to real rows (or
truly evaluate the invented ones) before reporting.

**193.** a) Because complexity must pay rent: if LS or
random matches the fancy method, the landscape never
needed it.
b) Reviewer 2 asks: "where is the simple baseline?"
Mistake: no floor. Cost: the comparison cannot show the
method matters — maybe ANY search wins there. Fix: race
random + LS always ([SIMP](#glossary), [BETS](#glossary));
report when they tie the star.

**195.** a) Because only improvements are recorded:
best-so-far is monotone by construction.
b) Mistake: plotting per-eval scores (or buggy merging)
as "best so far". Cost: the curve's promise — monotone
progress — is broken, so readers can't trust any point on
it. Fix: log and plot the running minimum.

**197.** a) Acceptance isolates "does tolerating bad moves
help?"; restarts isolate "does teleporting help?" — two
different escape mechanisms.
b) Mistake: n=1 per arm, no spread, no test. Cost: a coin
flip with axes; the next seed can reverse it. Fix:
repeat across seeds, compare distributions
([TIER](#glossary), [EFF](#glossary)).

**199.** a) Mutate everyone; tournament-select parents;
crossover pairs into the next generation.
b) Mistake: calling mutation+selection "genetic". Cost:
where crossover can't help (coupled params) it wastes
population overhead; where it could (building blocks) the
advantage is switched off. Either way the method-name
misleads ([BETS](#glossary): A3 is the GA's whole bet).

**201.** a) Memory of one population regardless of
generations; the CALLER owns stopping, logging, and
budgets.
b) Mistake: materializing history nobody reads. Cost:
memory scales with generations for zero analytic value.
Fix: stream — keep the current generation; log summaries
if history matters ([WEL](#glossary) thinking, applied to
optimizers).

**203.** a) Held-out real rows the GA never breeds from;
kids are judged against them — the surrogate's honesty
floor.
b) Mistake: scoring against the breeding stock. Cost:
"improvement" measures self-similarity — memorization
wearing progress's clothes. Fix: judge candidates against
data the search cannot touch (ref pool), the optimizer's
[XVAL](#glossary).

**205.** a) Member differences shrink as the population
converges — step size anneals automatically.
b) The student hand-built what DE provides free: steps
that start big and end small. Cost: three weeks, one
schedule, tuned to one problem. Fix: let the population's
spread BE the schedule ([DE](#glossary)).

**208.** a) Its own parent, only if strictly better —
greedy, local, one-on-one.
b) Mistake: global replacement of the worst. Cost: one
lucky lineage floods the population; diversity dies and
search narrows to one basin. The parent-vs-kid rule
quietly preserves niches. Fix: keep replacement local to
the lineage.

**211.** a) Because evaluations are the cost; "who is good
EARLY" and "who wins eventually" are different answers,
and SE budgets usually live early.
b) Mistake: finals-only reporting. Cost: a 100x
efficiency difference rendered invisible — the table
calls it a tie. Fix: plot/merge on the evaluation axis
([RACE](#glossary)); report evals-to-target.

**214.** a) "Is this any better than the data's average
row?" — the do-nothing baseline every improvement is read
against.
b) Mistake: a number with no anchor. Cost: applause for
0.15 that might be barely better than average (or worse
than a random row). Fix: print the baseline first; report
distance FROM it ([SIMP](#glossary)'s reporting twin).

**217.** a) a dominates b: no worse everywhere, better
somewhere; the front is the undominated set; a scalarizer
returns one point of it.
b) Mistake: one point sold as the menu. Cost:
stakeholders never see the trade-offs they were owed —
the actual deliverable of multi-objective work. Fix:
return the front (or clusters of it); scalarize only when
one answer is explicitly wanted ([PARETO](#glossary)).

**219.** a) Programs/patches are evolved; fitness =
test outcomes; the field is automated program repair. The
classic failure: satisfying tests by destroying behavior.
b) Mistake: fitness without behavior-preservation. Cost:
the optimizer finds the cheapest path to green — delete
the feature. Fix: fitness must reward passing AND
preserve passing tests, penalizing degenerate edits
([APR](#glossary): validation is the hard part).

**220.** a) The winner migrated with budget (cheap
samplers at small budgets, DE later); every winner had to
beat random search.
b) Mistake: one benchmark, one (inflated) budget,
universal conclusion. Cost: the standard tool is wrong
for most real (small-budget) projects in the company.
Fix: index the bake-off by budget; include the random
floor; expect the answer to be conditional
([BETS](#glossary)).

**224.** a) like(best) - like(rest): which unlabeled row
looks most like the good half and least like the rest —
two NB models voting.
b) Mistake: spending the label budget in file order.
Cost: most labels land where the model already knows the
answer; the informative region stays dark. Fix: let the
model nominate each next label ([ACQ](#glossary)).

**228.** a) Toward rows that resemble the best labeled so
far — concentrating labels in the promising corner.
b) Threat: order effects ([XVAL](#glossary)) — a
year-sorted warm start biases everything downstream. The
discipline: shuffle (seeded) before the warm start. Cost
of skipping: an active learner expertly exploring the
past.

**233.** a) Shuffle; split train/test; actively label ~30
train rows; tree the labels; route test rows to leaves
and truly label only the top `check` few. Headline: ~34
labels per split to rank 398 rows; mean win 86.6/100.
b) Mistake: secret full labeling of the test half. Cost:
the budget claim is false — the method's entire value
proposition evaporates under audit. Fix: the model's
OPINION (leaf means) ranks the test rows; true labels
only for the final handful.

[contents](#contents)

---

<a name="refs"></a>
# References

Every vignette and glossary citation, with a link you can
click to verify the work exists and says what we claim.
DOIs resolve at doi.org; the rest are stable publisher,
preprint, or encyclopedia pages.

- Aha, Kibler & Albert 1991, *Instance-Based Learning
  Algorithms*, Machine Learning.
  https://doi.org/10.1007/BF00153759
- Arcuri & Briand 2011, *A practical guide for using
  statistical tests to assess randomized algorithms in SE*,
  ICSE. https://doi.org/10.1145/1985793.1985795
- Bentley 1986, *Little Languages*, CACM.
  https://doi.org/10.1145/6424.315691
- Breunig et al. 2000, *LOF: Identifying Density-Based
  Local Outliers*, SIGMOD.
  https://doi.org/10.1145/342009.335388
- Cestnik 1990, *Estimating Probabilities: A Crucial Task
  in Machine Learning*, ECAI.
  https://scholar.google.com/scholar?q=Cestnik+1990+estimating+probabilities
- Cohen 1990, *Things I Have Learned (So Far)*, American
  Psychologist. https://doi.org/10.1037/0003-066X.45.12.1304
- Cover & Hart 1967, *Nearest Neighbor Pattern
  Classification*, IEEE Trans. Information Theory.
  https://doi.org/10.1109/TIT.1967.1053964
- Deb et al. 2002, *A Fast and Elitist Multiobjective
  Genetic Algorithm: NSGA-II*, IEEE TEC.
  https://doi.org/10.1109/4235.996017
- Demsar 2006, *Statistical Comparisons of Classifiers over
  Multiple Data Sets*, JMLR.
  https://jmlr.org/papers/v7/demsar06a.html
- Domingos & Pazzani 1997, *On the Optimality of the Simple
  Bayesian Classifier*, Machine Learning.
  https://doi.org/10.1023/A:1007413511361
- Domingos 2012, *A Few Useful Things to Know about Machine
  Learning*, CACM. https://doi.org/10.1145/2347736.2347755
- Faloutsos & Lin 1995, *FastMap*, SIGMOD.
  https://doi.org/10.1145/223784.223812
- Fawcett 2006, *An Introduction to ROC Analysis*, Pattern
  Recognition Letters.
  https://doi.org/10.1016/j.patrec.2005.10.010
- Fayyad & Irani 1993, *Multi-Interval Discretization of
  Continuous-Valued Attributes*, IJCAI.
  https://scholar.google.com/scholar?q=Fayyad+Irani+1993+multi-interval+discretization
- Feller 1968, *An Introduction to Probability Theory and
  Its Applications*; see also
  https://en.wikipedia.org/wiki/Central_limit_theorem and
  https://en.wikipedia.org/wiki/Cumulative_distribution_function
- Fu & Menzies 2017, *Easy over Hard: A Case for Tuning
  Simple Learners*, FSE. https://arxiv.org/abs/1703.00133
- Gigerenzer 2008, *Why Heuristics Work*, Perspectives on
  Psychological Science.
  https://doi.org/10.1111/j.1745-6916.2008.00058.x
- Hansson, *The Rails Doctrine* (convention over
  configuration). https://rubyonrails.org/doctrine
- Harman & Jones 2001, *Search-Based Software Engineering*,
  Information & Software Technology.
  https://doi.org/10.1016/S0950-5849(01)00189-3
- Holland 1975, *Adaptation in Natural and Artificial
  Systems*.
  https://scholar.google.com/scholar?q=Holland+1975+adaptation+natural+artificial+systems
- Holte 1993, *Very Simple Classification Rules Perform
  Well on Most Commonly Used Datasets*, Machine Learning.
  https://doi.org/10.1023/A:1022631118932
- Hunt & Thomas 1999, *The Pragmatic Programmer* (DRY /
  single source of truth).
  https://scholar.google.com/scholar?q=Hunt+Thomas+pragmatic+programmer+1999
- Hutter, Hoos & Leyton-Brown 2011, *Sequential Model-Based
  Optimization (SMAC)*, LION.
  https://doi.org/10.1007/978-3-642-25566-3_40
- Jones, Schonlau & Welch 1998, *Efficient Global
  Optimization of Expensive Black-Box Functions (EGO)*,
  J. Global Optimization.
  https://doi.org/10.1023/A:1008306431147
- Karnin, Koren & Somekh 2013, *Almost Optimal Exploration
  in Multi-Armed Bandits (successive halving)*, ICML.
  https://proceedings.mlr.press/v28/karnin13.html
- Kirkpatrick, Gelatt & Vecchi 1983, *Optimization by
  Simulated Annealing*, Science.
  https://doi.org/10.1126/science.220.4598.671
- Kolmogorov 1933 / Smirnov 1948; modern statement:
  https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test
- Koza 1992, *Genetic Programming*.
  https://scholar.google.com/scholar?q=Koza+1992+genetic+programming
- Li et al. 2018, *Hyperband*, JMLR.
  https://jmlr.org/papers/v18/16-558.html
- Li et al. 2020, *A System for Massively Parallel
  Hyperparameter Tuning (ASHA)*, MLSys.
  https://arxiv.org/abs/1810.05934
- MacQueen 1967, *Some Methods for Classification and
  Analysis of Multivariate Observations*.
  https://scholar.google.com/scholar?q=MacQueen+1967+some+methods+classification
- Menzies, Dekhtyar, Distefano & Greenwald 2007, *Problems
  with Precision*, IEEE TSE.
  https://doi.org/10.1109/TSE.2007.70721
- Menzies 2026, *Taming the Search Space* (the optimizer
  tournament; egs.pdf) and *EZR/luamine* notes — both at
  https://github.com/aiez/repltut ; data: https://github.com/timm/moot
- Metropolis et al. 1953, *Equation of State Calculations
  by Fast Computing Machines*, J. Chemical Physics.
  https://doi.org/10.1063/1.1699114
- Pearl & Mackenzie 2018, *The Book of Why*.
  https://scholar.google.com/scholar?q=Pearl+Mackenzie+book+of+why
- Quinlan 1986, *Induction of Decision Trees*, Machine
  Learning. https://doi.org/10.1007/BF00116251
- Rudin 2019, *Stop Explaining Black Box Machine Learning
  Models for High Stakes Decisions*, Nature Machine
  Intelligence. https://doi.org/10.1038/s42256-019-0048-x
- Settles 2009, *Active Learning Literature Survey*.
  https://burrsettles.com/pub/settles.activelearning.pdf
- Shannon 1948, *A Mathematical Theory of Communication*,
  Bell System Technical Journal.
  https://doi.org/10.1002/j.1538-7305.1948.tb01338.x
- Shore 2004, *Fail Fast*, IEEE Software.
  https://doi.org/10.1109/MS.2004.1331296
- Stevens 1946, *On the Theory of Scales of Measurement*,
  Science. https://doi.org/10.1126/science.103.2684.677
- Stone 1974, *Cross-Validatory Choice and Assessment of
  Statistical Predictions*, JRSS-B.
  https://doi.org/10.1111/j.2517-6161.1974.tb00994.x
- Storn & Price 1997, *Differential Evolution*, J. Global
  Optimization. https://doi.org/10.1023/A:1008202821328
- Thompson 1933, *On the Likelihood that One Unknown
  Probability Exceeds Another*, Biometrika.
  https://doi.org/10.1093/biomet/25.3-4.285
- Weimer et al. 2009, *Automatically Finding Patches Using
  Genetic Programming*, ICSE.
  https://doi.org/10.1109/ICSE.2009.5070536
- Welford 1962, *Note on a Method for Calculating Corrected
  Sums of Squares and Products*, Technometrics.
  https://doi.org/10.1080/00401706.1962.10490022
- Zhang & Li 2007, *MOEA/D*, IEEE TEC.
  https://doi.org/10.1109/TEVC.2007.892759
- Zitzler & Kunzli 2004, *Indicator-Based Selection in
  Multiobjective Search*, PPSN.
  https://doi.org/10.1007/978-3-540-30217-9_84
- guru26spr course review notes:
  https://github.com/txt/guru26spr/blob/main/docs/review/one.md
- Lauer, *Lua 5.1 Short Reference*:
  https://web.archive.org/web/2023/http://thomaslauer.com/download/luarefv51single.pdf

[contents](#contents)
