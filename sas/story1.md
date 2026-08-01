## Story 1: the tutorial chapters (working draft) {.unlisted}

(Note to us: story.md holds the front matter; the book is
"Sophisticated AI: Simple Ain't Stupid -- dozens of
reusable AI skills from a few hundred lines of Python".
Built together with it via `make story1`. Its sections 1 and 2
give the sales pitch and the maths. This file drafts everything
after that: one warm-up chapter on the data model, then one short
chapter per row of the task table from the introduction. Each
chapter is a few lines of code plus the prose needed to read them.
The test_xxx demos will be reverse-engineered later. Program
output never appears here by hand; where a chapter needs a
transcript, a %%run directive marks the spot and the weaver will
fill it in.)

Two house rules govern every line of code shown below, so we name
them once, here. **BOB** is Bob's rule: functions stay small,
about five lines, plus or minus four (after Robert Martin's
clean-code books). **TIM** is timm's rule: no code line runs past
65 characters, so every function fits on a phone screen, a slide,
or a page of this book without reformatting. When a snippet in
this book carries a comment like `# ③`, the nearby prose has a
matching note "③" that explains that line; the markers ride
outside TIM's 65-character count, so the code underneath is
lib.py verbatim. Nothing else needs decoding.

> SE tip #1: pick rules you can check by machine. BOB and TIM are
> enforced by a five-line script in the Makefile. A style rule
> that needs a human referee is a style rule that will be broken.

## 3. Warming Up (rows, columns, tables)

Before any AI, we need a way to hold data. This chapter builds
that: cells, columns, tables, and a ruler that measures the
distance between rows. It is the longest chapter in the book.
Everything after it is short, because everything after it is
built from it.

Recall the car lot from the introduction. Our data is a CSV file.
The first line names the columns. Every other line is one car:

    Clndrs, Volume, HpX, Model, origin, Lbs-, Acc+, Mpg+
         4,    140,  92,    76,      1, 2572, 14.9,   30
         8,    454, 220,    70,      1, 4354,    9,   10

The header is a tiny language, and it is the only schema this
book will ever need. Uppercase first letter means numeric
(`Volume`); lowercase means symbolic (`origin`). A trailing `X`
means "ignore me" (`HpX`). A trailing minus means "minimize me"
(`Lbs-`); a trailing plus means "maximize me" (`Acc+`, `Mpg+`).
That is the whole schema language: one letter of case, one
optional trailing mark.

> SE tip #2: this header is **SSOT**, a single source of truth.
> What is a goal? Read the header. What can we change? Read the
> header. No second config file can drift out of sync with the
> data, because there is no second config file.

> Code tip #1: this is also the Rule of Representation: fold
> knowledge into data, so program logic can be stupid and
> simple. The payoff is flexibility. Because the schema rides
> in the data, the reader we are about to write can swallow
> ANY table wearing this header: new dataset, zero new code.
> Chapter 5 cashes that in, running one loop over a hundred
> unseen tables. The cleverness sits in one header line; the
> code that reads it, as we will see, is barely twenty lines.

### 3.1 Cells

A CSV file gives us strings. We want numbers when the string
looks like a number, booleans when it says True or False, and
strings otherwise:

    def thing(s):                                    # ①
      for fn in (int, float):
        try: return fn(s)                            # ②
        except ValueError: pass
      s = s.strip()
      return {"True": True, "False": False}.get(s, s)  # ③

Line ① takes one string. Line ② just tries the conversion
and catches the failure. Line ③ handles the two boolean words,
then gives up gracefully: anything else stays a string.

> Python tip #1: line ② is **EAFP**: easier to ask forgiveness
> than permission. Pythonic code attempts the cast and catches
> the exception. The look-before-you-leap alternative (regular
> expressions that recognize "well-formed" numbers) is longer
> and wrong more often.

With `thing` in hand, reading a whole file is four lines:

    def csv(file):                                   # ①
      with open(file) as f:
        for line in f:
          if (line := line.split("%")[0].strip()):   # ②
            yield [thing(s) for s in line.split(",")]

Line ① opens the file. Line ② strips comments (everything
after `%`) and skips blank lines. And the last line does not
say `return`; it says `yield`.

> Python tip #2: line ② uses the walrus operator `:=`,
> which assigns and tests in one move: strip the line, keep
> the result, and skip the row when nothing is left. Without
> it, the same logic needs an extra statement and a spare
> variable name.

> Python tip #3: that `yield` makes `csv` a generator: a
> function that does not build a pile of answers and hand
> the pile back, but instead hands out one answer at a
> time, on request, pausing in between. Generators are this
> book's default shape for every data source, and later
> chapters lean on them hard. That is important enough to
> earn the idea its own section, right now.

### 3.2 Generators: data on demand

An ordinary function runs, returns one value, and dies. A
function whose body contains `yield` behaves differently, and
the difference starts at the call. Calling `csv("x.csv")`
runs none of csv's body. No file opens. Instead, Python hands
back a small paused machine, called a generator, frozen at
the top of the function, holding its arguments and waiting to
be asked.

The asking is done by the built-in `next`. Each `next` call
wakes the machine, which runs until it reaches a `yield`,
hands out that value, and freezes again right there, with
every local variable intact. Watch it on something simpler
than a file:

    def evens():                                     # ①
      n = 0
      while True:                                    # ②
        yield n                                      # ③
        n += 2

Call `g = evens()` and nothing runs; `g` just sits, paused at
line ①. The first `next(g)` runs the body until `yield` at
③ and hands back 0. The second wakes it right after the
`yield`, adds 2, loops, and hands back 2. The third hands
back 4. Note that line ② declares an infinite loop, and no
harm follows: the loop only ever runs between pauses, one lap
per request. A generator is a promise of values, kept one at
a time, only on demand.

Three more pieces complete the picture. A `for` loop is
repeated `next` with manners: `for row in csv(f)` wakes the
machine once per lap, and when a finite generator runs out of
body it signals it is done (Python calls that signal
StopIteration) and the loop ends quietly. The built-in `iter`
turns anything loopable (a list, an open file, a generator)
into a machine that `next` can drive; we use it whenever we
want one value by hand before looping over the rest, and the
very next section's `Tbl` does exactly that with a header
row. And generators compose: a generator can loop over
another generator, so readers, filters, and batchers chain
into pipelines where nothing runs until the far end pulls.

Now the point, plainly. Everything this book builds learns
incrementally: the column summaries of the next section
swallow one value at a time, and they are correct after
every swallow. Generators are the matching way to feed
them. The usual style bunches data up: one function builds
a whole list here, another function unpacks that whole list
there, and the pile between them costs memory and forces
the consumer to wait until the producer is done. With
generators **there is no pile in the middle**. `csv` hands
one row across, the table folds it in, and that row is gone
before the next one arrives. Producer and consumer run in
lockstep, item by item, from here to there. A gigabyte file
therefore costs kilobytes to read; better, code fed this
way cannot peek ahead, cannot take a second pass, cannot
ask how many rows are coming, so nothing we build can
quietly assume the data sits still. Hence Chapter 7, where
these skills run on endless live streams without one line
changing: it was never doing anything else.

### 3.3 Columns that summarize themselves

We rarely want raw rows. We want summaries: what is typical,
and how much do values vary? So we give every column a little
memory. Two kinds exist. `Num` watches a numeric column. `Sym`
watches a symbolic one.

First, a word on `o`. All our structs come from one tiny class
in about.py (the settings file, of which more below). `o` is a
bag of named slots with dot access and a pretty print. It is
the only "class" machinery this book uses.

    def Col(name="", at=0):                          # ①
      return (Sym if name[:1].islower() else Num)(name, at)

    def Num(name="", at=0):                          # ②
      return o(it=Num, at=at, name=name, n=0, mu=0, m2=0,  # ③
               heaven=0 if name.endswith("-") else 1)

    def Sym(name="", at=0):                          # ④
      return o(it=Sym, at=at, name=name, n=0, has={})

`Col` ① is where the header's case rule becomes code: look at
the first letter of the column's name, then call the matching
maker, `Sym` for lowercase, `Num` for anything else. (Functions
are values in Python, so the parenthesized test picks a maker,
and the trailing `(name, at)` calls whichever one won.) Now the
two makers it chooses between. A `Num` ② knows its name, its
position `at`, and three running numbers seen at ③: a count
`n`, a mean `mu`, and `m2`, a helper for variance that we
explain in a moment. It also knows its `heaven`: 0 if we want
this column small, 1 if we want it large. Heaven will matter
enormously in later chapters; for now, just note that the
header's `+` and `-` marks land here. A `Sym` ④ is simpler: a
count and a dictionary of seen symbols.

> Code tip #2: `Col` is a dispatcher, and it is one line. Read
> it aloud and it is the schema rule of this chapter's opening:
> "lowercase makes a Sym; else a Num". When a policy fits in
> one readable line, put that line up front and let it
> introduce the parts it chooses between.

Columns learn one value at a time:

    def count(sym, v):                               # ①
      sym.n += 1; sym.has[v] = 1 + sym.has.get(v, 0)

    def welford(num, v):                             # ②
      num.n += 1; d = v - num.mu; num.mu += d / num.n
      num.m2 += d * (v - num.mu)                     # ③

`count` ① is a tally. `welford` ② is the famous one-pass
update of Welford[^welford]: each new value nudges the mean,
and line ③ accumulates `m2`, the sum of squared distances
from that moving mean. From `m2` we can read off the standard
deviation at any moment, without storing any of the numbers.

[^welford]: B. P. Welford, "Note on a method for calculating
corrected sums of squares and products", Technometrics
4(3):419-420, 1962. In the woven book this cite is
[welford62] in refs.bib.

> AI tip #1: incremental beats batch. `welford` never re-reads
> old data, so the same code serves a static table now and a
> live stream in Chapter 7. When you choose an algorithm,
> prefer the one that works one item at a time.

Now we can ask a column two questions: what is your center,
and how spread out are you?

    def entropy(sym):                                # ①
      f = lambda p: p*log(p,2)
      return -sum(f(n/sym.n) for n in sym.has.values() if n > 0)

    def mid(col):                                    # ②
     return col.mu if col.it is Num else max(col.has,key=col.has.get)

    def div(col):                                    # ③
      return entropy(col) if col.it is Sym else (
             0 if col.n < 2 else sqrt(max(col.m2, 0) / (col.n - 1)))

`mid` ② is the center: mean for numbers, mode for symbols.
`div` ③ is the diversity: standard deviation for numbers,
and for symbols the entropy of line ①, which is small when
one symbol dominates and large when the counts are even. One
mental model covers both: `mid` says "what to expect"; `div`
says "how often to expect surprises".

> Code tip #3: `mid` and `div` dispatch on type inside one
> function, and the rule underneath is about geography, not
> classes: group code by operation, not by type. A file
> that scatters one behavior's variants far apart is a junk
> drawer; to read one behavior you scroll everywhere. Kept
> together, every version of a verb shows its whole
> polymorphic story in one glance. Multi-dispatch languages
> (CLOS, Julia) make that layout standard, and Lua's
> metatables allow it; Python's class syntax fights it,
> since methods must live inside class bodies. Hence this
> book's Python style: functions over plain structs, so
> related behavior can sit side by side. (Tempero et al.
> report most inheritance in the wild is shallow and
> removable. We remove it.)

### 3.4 All numbers become 0..1

Columns come in wildly different units: pounds, years, miles
per gallon. Before we can compare or combine them, each value
gets mapped to 0..1:

    def norm(col, v):                                # ①
      if v == "?" or col.it is Sym: return v         # ②
      z = (v - col.mu) / (div(col) + TINY)           # ③
      return 1 / (1 + exp(-1.702 * max(-3, min(3, z))))  # ④

Line ② passes through missing values and symbols untouched.
Line ③ computes a z-score: how many standard deviations is
`v` from the mean? Line ④ squeezes that z-score through a
logistic curve (the 1.702 constant makes the logistic mimic
the Gaussian cdf). The result reads as a percentile: 0.5 means
average, 0.97 means bigger than nearly everything seen so far.
The clamp to plus or minus three keeps outliers from
saturating the arithmetic.

> AI tip #2: normalize by distribution, not by min and max.
> Min-max scaling breaks the day one outlier arrives. A cdf
> is stable, incremental (thanks to `welford`), and it gives
> every column the same units: probability.

### 3.5 Tables

A table is a list of rows plus one summary column per header
name:

    def Tbl(src):                                    # ①
      src   = iter(src)
      names = next(src)                              # ②
      all   = [Col(s, at) for at, s in enumerate(names)]  # ③
      cols  = o(names=names, all=all,
                x=[c for c in all if c.name[-1] not in "X+-"],  # ④
                y=[c for c in all if c.name[-1] in "+-"])       # ⑤
      return adds(src, o(it=Tbl, rows=[], cols=cols, mid=None))  # ⑥

Line ② reads the header, using the moves of Section 3.2:
`iter` makes the source drivable by hand, then one `next`
pulls exactly one row, the names. Line ③ builds one column
summary per name. Lines ④ and ⑤ split the columns into the
independent `x` (things we can observe or change) and the
dependent `y` (goals, the ones marked plus or minus). Ignored
`X` columns fall into neither list, so they cost nothing
downstream. Line ⑥ then pours every remaining row into the
new table via `adds`, which we show next:

    def add(i, v):                                   # ①
      if i.it is Tbl:
        i.rows += [v]; i.mid = None                  # ②
        for col in i.cols.all: add(col, v[col.at])  # ③
      elif v != "?":                                 # ④
        (count if i.it is Sym else welford)(i, v)    # ⑤
      return v

    def adds(lst, col=None):                         # ⑥
      col = col or Num()
      for v in lst: add(col, v)
      return col

`add` is the one verb of this whole substrate. Give it a table
and a row: line ② stores the row (and forgets any cached
centroid), and line ③ feeds each cell to its column. Give it
a column and a cell: line ④ skips the "?" marks that denote
missing data, then line ⑤ picks `count` or `welford` by
type. `adds` ⑥ just folds a whole list, defaulting to a
fresh `Num`, which makes one-liners like "summarize these
numbers" free.

Two tiny helpers complete the table machinery:

    def clone(tbl, rows=[]):                         # ①
      return Tbl([tbl.cols.names] + rows)

    def mids(tbl):                                   # ②
      tbl.mid = tbl.mid or [mid(col) for col in tbl.cols.all]
      return tbl.mid

`clone` ① makes a new empty table with the same header, then
fills it with any rows we pass. This is how we will summarize
any subset of the data: cluster members, recent arrivals,
suspicious cases. Same schema, fresh statistics. `mids` ②
returns the table's centroid: the row of all the column
centers, cached until the next `add` invalidates it.

> SE tip #3: `clone` is the Rule of Composition at table
> scale. Because every table answers the same questions (mid,
> div, distance), anything we learn to do on one table works,
> unchanged, on any subset. Most chapters in this book are
> one idea plus `clone`.

### 3.6 Distance

Now the ruler. How far apart are two rows? We compare them
column by column, on the `x` columns only, each gap normalized
to 0..1:

    def distx(tbl, row1, row2):                      # ①
      d,n = 0,TINY
      for col in tbl.cols.x:
        a, b = row1[col.at], row2[col.at]
        if a == "?" and b == "?": g = 1              # ②
        elif col.it is Sym:       g = a != b         # ③
        else:
          a, b = norm(col, a), norm(col, b)
          a = a if a != "?" else (0 if b > 0.5 else 1)
          b = b if b != "?" else (0 if a > 0.5 else 1)
          g = abs(a - b)                             # ④
        d, n = d + g ** the.p, n + 1
      return (d / n) ** (1 / the.p)                  # ⑤

Line ② is pessimism: when both values are missing, assume
the worst gap, 1. Line ③: symbols are either equal (gap 0)
or not (gap 1). Line ④: numbers are normalized, and a
missing value is assumed as far as possible from the known
one. Line ⑤ folds the per-column gaps into one number using
the Minkowski formula; with the default `the.p` of 2, that is
plain Euclidean distance, scaled to 0..1.

The same trick, run over the `y` columns, gives the single
most important number in this book. Each goal column knows
its heaven (0 for minimize, 1 for maximize). So each row has
a distance between where it is and where heaven is:

    def disty(tbl, row):                             # ①
      d,n = 0,TINY
      for col in tbl.cols.y:
        if (v := row[col.at]) != "?":
          d, n = d + abs(norm(col, v) - col.heaven)**the.p, n+1  # ②
      return (d / n) ** (1 / the.p)                  # ③

Line ② measures each goal's gap to its heaven; line ③
folds the gaps as before. The result, **distance to heaven**,
is 0 for a perfect row and 1 for a hopeless one. This
paragraph is the definition; every later chapter just says
"disty" and points here. A car with great mileage, quick
acceleration, and low weight scores near 0. A gas-guzzling
barge scores near 1.

> AI tip #3: collapsing many goals to one number is a choice,
> and this particular collapse keeps the choice visible. The
> policy (what is good) lives in the header marks. The
> mechanism (the folding maths) lives in ten lines you just
> read. Separate policy from mechanism, and both stay
> checkable. Chapter 16 pokes hard at this choice.

### 3.7 The knobs, the dice, and the defaults

Every tunable constant in this book lives in one file,
about.py, in one struct called `the`: a random seed, the
Minkowski coefficient `p`, a sampling size `few`, a halting
size `stop`, and a default data file. Nothing else, anywhere,
defines a setting. Any of them can be overridden on the
command line, e.g. `--p 1`.

> SE tip #4: one settings file is **SOC** (separation of
> concerns) plus **YAGNI** (you ain't gonna need it) in one
> move. New knob? It goes in about.py or it does not go in.
> The day you cannot list all your knobs on one screen is the
> day your experiments stop being repeatable.

Randomness gets the same discipline. Two helpers wrap the
standard library:

    def shuffle(lst):                                # ①
      lst = lst[:]; random.shuffle(lst); return lst

    def some(lst, k):                                # ②
      return random.sample(lst, min(k, len(lst)))

`shuffle` ① copies first, so no caller's list is mutated
behind their back (the Rule of Least Surprise, **POLA**).
`some` ② picks `k` items at random, quietly returning
everything when `k` is too big. Every experiment in this book
reseeds the random generator with `the.seed` before it runs.
Same seed, same shuffles, same story.

> SE tip #5: unseeded randomness is a bug generator. If a
> result cannot be replayed, it cannot be debugged, taught,
> or trusted. Seed first, then run. Always.

One fair question before we move on: why write all this
ourselves, when pandas and scikit-learn exist? Old-school
engineers sneer at that instinct; they call it NIH, "not
invented here". We answer with a different acronym: this code
is **VITAL**, very important to acquire locally. Two hundred
lines that we understand completely beat two hundred
megabytes that we do not. Everything downstream of this
chapter can be audited, by you, in an afternoon. That is the
point of the book.

### 3.8 The grammar under everything

Look back at this chapter's verbs. We kept some rows
(`clone`, `some`), we folded values into running summaries
(`add`, `welford`, `count`), and we sorted rows by
computed keys. Keep, fold, sort; then read an answer off a
summary (`mid`, `div`, `norm`). That four-word grammar is
the whole book. Every skill in every later chapter is a
short sentence in it. Prediction keeps the nearest rows,
folds them into a clone, reads the mids. Optimization
folds labels, sorts the pool, keeps half, repeats. When a
later chapter looks clever, parse it; it stops being
clever and becomes three verbs and a readout.

The old logicians had names for these moves. Building a
summary from cases is induction. Reading an answer back
off a summary is deduction. And picking the summary that
best explains a surprise, which is the work of diagnosis,
explanation, and repair, is abduction: the hunt for the
best available explanation. So when these skills feel
familiar, they should. They are the classical inference
triad, running on tables, five lines at a time.

### Lessons sighted

The header is the schema (SSOT, Rule of Representation).
Columns summarize incrementally (welford). All values map to
0..1 (norm). Tables clone. Distance to heaven turns many
goals into one number. All knobs in one place; all dice
seeded.

## 4. The Fortune Teller (prediction)

Someone shows us a car we have never seen. The sticker is
missing. What mileage should we expect? This chapter answers
with the oldest trick in machine learning: ask the neighbors.

The whole learner is three lines on top of Chapter 3:

    def around(tbl, row, rows=None):                 # ①
      rows = rows or tbl.rows
      return sorted(rows, key=lambda r: distx(tbl, row, r))  # ②

    def knn(tbl, row, k=5):                          # ③
      return mids(clone(tbl, around(tbl, row)[:k]))  # ④

Line ② sorts every known row by its distance to the new
one. `knn` ③ then takes the `k` nearest, pours them into a
fresh clone, and reads that clone's centroid ④. The
centroid's `y` slots are our predictions: expected weight,
expected acceleration, expected mileage, all at once. Note
what we did not write: no model, no training loop, no
coefficients. The table is the model.

> AI tip #4: k-nearest-neighbor is the baseline that refuses
> to die. Before you reach for anything with a loss function,
> ask the neighbors. If a fancy learner cannot beat knn on
> your data, the fancy learner is decoration. (Also, "Don't
> think, remember" is the moral of half this book.)

But there is a problem. Sorting all rows per query is slow on
big tables. Hence a second trick: cluster the table once,
then drop each query into its cluster. We build the clusters
by recursive halving. First, find two far-apart rows, the
poles. Then split everyone by which pole they are nearer:

    def project(tbl, row, a, b, c):                  # ①
      return (distx(tbl,a,row)**2 + c*c
              - distx(tbl,b,row)**2) / (2*c + TINY)

    def halve(tbl, rows=None):                       # ②
      rows = rows or tbl.rows
      far  = lambda r: max(some(rows, the.few),
                           key=lambda r2: distx(tbl, r, r2))
      a    = far(random.choice(rows))                # ③
      b    = far(a)
      c    = distx(tbl, a, b)
      if disty(tbl, b) < disty(tbl, a): a, b = b, a  # ④
      rows = sorted(rows, key=lambda r: project(tbl, r, a, b, c))  # ⑤
      n    = len(rows) // 2
      return a, b, rows[:n], rows[n:]

`project` ① is high-school geometry: given poles `a`, `b`
separated by distance `c`, it maps any row to a coordinate
along the a-to-b line (the cosine rule, if you want its
name). `halve` finds the poles cheaply at ③: pick any row,
find something far from it, then something far from that.
Line ④ swaps the poles so `a` is the one nearer heaven;
that small vanity pays off in Chapter 10. Line ⑤ sorts all
rows along the line and cuts at the middle.

Recursive halving gives a tree, and dropping a row down that
tree gives its natural group:

    def Node(tbl, rows=None):                        # ①
      rows = rows or tbl.rows
      node = o(it=Node, here=clone(tbl, rows),       # ②
               a=None, b=None, west=None, east=None)
      if len(rows) >= 2 * the.stop:                  # ③
        node.a, node.b, west, east = halve(tbl, rows)
        if west and east:
          node.west, node.east = Node(tbl,west), Node(tbl,east)
      return node

    def leaf(node, row):                             # ④
      while node.west:
        d = lambda pole: distx(node.here, row, pole)
        node = node.west if d(node.a) <= d(node.b) else node.east  # ⑤
      return node

Each `Node` ① carries a clone of its rows at ②, so every
part of the tree can answer the usual questions: mid, div,
distance. Line ③ stops splitting below `2 * the.stop` rows;
small leaves are noise, not knowledge. `leaf` ④ routes a
new row by a cheap question at each level ⑤: nearer pole
`a`, go west; nearer pole `b`, go east. For a table of `n`
rows that is about `log2(n)` distance calls, not `n`.

Prediction, tree style, is now one line: drop the row to its
leaf, then ask the leaf's clone for its centroid. Same answer
shape as `knn`, a fraction of the cost.

    %%run python3 src/skills_eg.py knn

(That directive will pull in a live transcript: a few held-out
cars, their true mileage, and the knn and leaf guesses. We
never hand-type output into this book.)

> Code tip #4: `leaf` recurses with a `while` loop, not with
> recursion, because walking down is a straight line. `Node`
> recurses properly, because building is a genuine tree. Match
> the control shape to the data shape.

### Lessons sighted

The table is the model. Ask the neighbors (knn). Recursive
halving buys log-time lookups. Small leaves are noise
(`the.stop`).

## 5. The Proving Grounds (the MOOT corpus)

One dataset proves nothing. Any trick can look clever on the
car lot. Before this book makes empirical claims, we need
terrain: many tables, from many domains, with many shapes.

**MOOT** (many multi-objective optimization tasks) is a
public corpus collected for exactly this duty (data at
tiny.cc/moot; the repository is github.com/timm/moot). Its
tables are plain CSV in the header dialect of Chapter 3,
which is no accident: the dialect was designed so that one
reader (`Tbl`) could swallow the whole corpus. The tasks
include software configuration (compilers, databases, video
encoders), hyperparameter tuning, process models, and
miscellaneous engineering trade-offs. Tables run from dozens
of rows to hundreds of thousands, from four columns to over
a hundred, from one goal to five.

Our code finds the corpus through one environment variable,
`$MOOT`, and `the.file` names one table within it. Hence
every experiment in the rest of this book is a loop of the
same shape: for each file in the corpus, build `Tbl`, run
the method, collect a number per repeat.

> SE tip #6: benchmarks are fixtures, so treat them like
> code: version them, fetch them with `make data`, and never
> edit a fetched file by hand. A benchmark you tweaked is a
> result you invented.

> AI tip #5: report distributions over corpora, not wins on
> a favorite table. A method that shines on one dataset and
> stinks on the corpus is a story about that dataset, and
> the referee of the next chapter exists to catch exactly
> that.

### Lessons sighted

Claims need terrain. One header dialect makes a hundred
datasets one loop. Fetched data is read-only.

## 6. The Referee (statistical certification)

Here is a turn, taken early on purpose. Until now, each
chapter showed machinery. From now on, chapters will also run experiments:
method A versus method B, over the MOOT corpus, many
repeats. The moment we do that, a hard question arrives:
when are two result sets actually different? Eyeballing two
means is how fields fool themselves. We need a referee.

Our referee asks the question backward. Instead of "are
these different?" we ask "are these the same?", because in
practice sameness is the common case and we want it cheap.
Three small judges measure; one verdict function, `same`,
compares each measurement to its threshold. Any judge
scoring under threshold makes the verdict same; only
results that get past all three may be called different.
Note the engineering consequence of that `or`: **we do not
always run all the tests**. The judges appear cheapest
first, and the first small-enough score stops the panel.

    def cohen(xsort, ysort):                         # ①
      mid = lambda a: a[len(a) // 2]
      spd = lambda a: (a[len(a)*9//10] - a[len(a)//10]) / 2.56  # ②
      return abs(mid(xsort) - mid(ysort)) / \
             ((spd(xsort) + spd(ysort)) / 2 + TINY)  # ③

    def ks(xsort, ysort):                            # ④
      nx, ny = len(xsort), len(ysort)
      d = i = j = 0
      while i < nx and j < ny:
        if xsort[i] <= ysort[j]: i += 1
        else:                    j += 1
        d = max(d, abs(i / nx - j / ny))             # ⑤
      return d / ((nx + ny) / (nx * ny)) ** 0.5      # ⑥

    def cliffs(xsort, ysort):                        # ⑦
      gt = lt = j = k = 0
      for x in xsort:
        while j < len(ysort) and ysort[j] <  x: j += 1
        while k < len(ysort) and ysort[k] <= x: k += 1
        gt += j; lt += len(ysort) - k
      return abs(gt - lt) / (len(xsort) * len(ysort))  # ⑧

    def same(xs, ys,                                 # ⑨
             Cohen=0.2,     # J. Cohen 1988
             Ks=1.36,       # F. Massey 1951
             Cliffs=0.197): # N. Cliff 1993
      xsort, ysort = sorted(xs), sorted(ys)          # ⑩
      return (cohen(xsort, ysort) < Cohen
              or ks(xsort, ysort) < Ks
              or cliffs(xsort, ysort) <= Cliffs)     # ⑪

All three judges expect sorted lists, and they say so in
their own signatures: parameters named `xsort` and `ysort`
arrive sorted, by contract. `same` does that sorting, once,
at ⑩; downstream, nobody sorts again. Judge one, `cohen`
①, is the pragmatist: line ② estimates the spread from
the 10th to 90th percentile gap (that range spans 2.56
standard deviations of a Gaussian), and line ③ returns the
gap between the two medians, measured in units of that
pooled spread. Judge two, `ks` ④, is the
Kolmogorov-Smirnov statistic: walk both sorted lists as
two cumulative distribution curves, track the largest
vertical gap between them ⑤, and return that gap scaled
by the classic critical-value denominator ⑥. Judge three,
`cliffs` ⑦, is Cliff's delta, a rank-based effect size:
walk two pointers up the sorted ys, counting how many sit
below and at each ascending x. The pointers never restart:
each x inherits the previous count and augments it, since
whatever sat below the last x still sits below this one.
And note that `gt += j` re-adds the inherited ys on
purpose: the delta sums over all pairs, and a y beneath
two xs loses two pairs, one to each. Line ⑧ returns the
imbalance, 0 to 1.

Note what the judges never do: they never say yes or no.
The verdicts live in `same` ⑨, one comparison per judge at
⑪, each against a named default in same's own signature,
its citation riding alongside as a comment. Cohen at 0.2
is Cohen's small effect, the same 0.2 that priced the
search back in story.md's maths: a gap too small for a
practitioner to care about, whatever a p-value says. Ks at
1.36 is the classic 95-percent critical multiplier. Cliffs
at 0.197 is this book's small-effect line for rank
imbalance (a house calibration; the widely cited
alternative is Romano's 0.147). Keeping thresholds in the
signature means any caller can tighten or loosen one judge
for one call, and the capital letters matter: lowercase
names would shadow the judge functions themselves. And
because the judges return magnitudes, later chapters can
reuse them as rulers (how much drift? which contrast
column differs most?), not only as gates.

The cost ordering is deliberate. After sorting, `cohen` is
constant time, while `ks` and `cliffs` each make one linear
pass; `cliffs` runs two pointers where `ks` runs one, so it
goes last. In the common case, `cohen` answers alone and
the panel adjourns.

Experiments compare many treatments, not two, so one more
helper tops off the referee. Give `top` a dictionary
mapping each treatment's name to its observed scores; back
comes the winner set:

    def top(d, max=False):                           # ①
      out, mid = [], lambda a: sorted(a)[len(a) // 2]
      for k in sorted(d, key=lambda k: mid(d[k]),
                      reverse=max):                  # ②
        if out and not same(d[out[0]], d[k]): break  # ③
        out += [k]
      return out

Line ② orders the treatments best median first: least by
default, since this book's scores are distances to heaven,
and greatest when the `max` flag says this score grows the
other way. Line
③ walks down that order, comparing each treatment to the
champion, and the first one the judges CAN tell apart ends
the walk: nobody below a loser is ever compared. So the
laziness runs two levels deep: `same` stops at its first
small-enough judge, and `top` stops at its first loser.
The break does place a bet: that once the medians drift
too far apart they do not drift back. That is the same bet
Scott-Knott rankings make, and on distance-to-heaven
scores it is a safe one.

And when a report wants every rank, not just the winners,
Scott and Knott's own procedure[^sk] is ten more lines:

    def sk(d):                                       # ①
      mu   = lambda a: sum(a) / len(a)
      mid  = lambda a: sorted(a)[len(a) // 2]
      vals = lambda ks: [v for k in ks for v in d[k]]
      out  = {}
      def grow(ks, M=0, b=0):
        if len(ks) > 1:
          M  = mu(vals(ks))
          b  = lambda l, r: (len(l) * (mu(l) - M)**2
                             + len(r) * (mu(r) - M)**2)
          at = max(range(1, len(ks)), key=lambda i:
                   b(vals(ks[:i]), vals(ks[i:])))    # ②
          if not same(vals(ks[:at]), vals(ks[at:])): # ③
            grow(ks[:at]); return grow(ks[at:])
        n = len(set(out.values()))
        for k in ks: out[k] = n                      # ④
      grow(sorted(d, key=lambda k: mid(d[k])))
      return out

Order the treatments by median; find the cut whose two
halves pull farthest from the parent mean ② (the
between-group sum of squares, argmax over every split
point); then let the referee veto ③: halves the judges
cannot tell apart never split. What survives unsplit is
one leaf, and ④ stamps every treatment in it with the
next rank id, numbered best first. `top` is the front of
this ranking bought lazily; `sk` is the whole thing.

[^sk]: A.J. Scott and M. Knott, "A cluster analysis method
for grouping means in the analysis of variance",
Biometrics 30(3):507-512, 1974. That list is the only ranking this
book ever reports: not first, second, third, but "these
won and the rest lost". When a later chapter's table shows
a verdict column, it is `top`, spoken.

> Code tip #5: line ⑪ is short-circuit evaluation doing
> statistics. An `or` chain, cheapest test first, is the
> lazy referee: it computes exactly as much evidence as the
> verdict needs and not one comparison more.

> SE tip #7: an earlier draft of the library shipped this
> logic in the mirror form, `differ`, as an `and` of three
> difference-tests. De Morgan says the two are one, but the
> `same` form is the one that gets the lazy evaluation
> right, so `same` is what lib.py ships.

> AI tip #6: certify with effect sizes plus a
> distributional test, never a p-value alone. With enough
> repeats, trivial gaps become "significant". The 0.2 and
> 0.197 thresholds encode a blunter, more useful question:
> is the gap big enough for anyone to care?

### 6.1 Reports: the skeleton

Every experiment from here on reports in one fixed shape,
borrowed from the lab notebooks of a sister project: a
research question, a method paragraph, one small table, and
a bold one-line answer. For example, certifying `hunt`,
the label-frugal optimizer Chapter 10 will build, over
the corpus:

**RQ: how close does a few-dozen-label hunt get to the best
row in the table?**

Method: for each MOOT table, 20 repeats: shuffle, run
`hunt`, record the disty of its answer, the labels spent,
and the disty of the true best row (peeked for scoring
only). Two result sets per table: `hunt` versus `all` (the
best found by exhaustive labeling). `top` picks the winners.

    %%run python3 src/skills_eg.py hunt

The table that lands here will have one line per dataset:

    dataset       rows    x   y   all   hunt  labels  same?
    auto93         xxx    4   3   xxx    xxx     xxx    xxx
    SS-N           xxx  xxx   x   xxx    xxx     xxx    xxx
    ...

**Answer:** xxx (to be written from the transcript, never
from memory).

That skeleton is the whole reporting standard: small enough
to read in a minute, strict enough that a missing repeat or
an uncertified claim has nowhere to hide.

> SE tip #8: decide the report format before running the
> experiment. A pre-committed table with an empty Answer
> line is a mild form of preregistration, and it kills the
> temptation to tour the numbers until one looks good.

### Lessons sighted

Ask "same?", not "different?". Three judges, cheapest
first, lazy `or`. Effect size beats p-value. One skeleton
for every report.

## 7. The Short-Order Cook (streaming)

Everything so far assumed the data would sit still. Now the
orders fly in and the grill is always on: rows arrive one at
a time, forever, and there is no disk big enough to keep
them all. The good news was planted back in Chapter 3:
`csv` is a generator, `welford` and `count` update one value
at a time, and `add` never looks backward. **The substrate
was streaming all along**; only `Tbl.rows` hoards memory.

So the one new skill is a fair way to keep a bounded sample
of an unbounded past:

    def reservoir(src, k=256):                       # ①
      keep = []
      for n, row in enumerate(src):
        if len(keep) < k: keep += [row]              # ②
        elif random.random() < k / (n + 1):          # ③
          keep[random.randrange(k)] = row            # ④
      return keep

Line ② fills the tank. After that, row number `n+1` earns
a seat with probability `k/(n+1)` ③, evicting a random
sitting tenant ④. A pretty induction shows every row ever
seen ends up in the tank with equal probability, so the
tank is an unbiased sample of the whole stream. Feed the
tank to `clone`, and every skill in this book, met or
still coming, runs unchanged on live data.

### The Specials Board (trends)

Cooks chalk up what is moving. For streams, we watch the
goal summaries window by window:

    def batches(src, k):                             # ①
      b = []
      for row in src:
        b += [row]
        if len(b) == k: yield b; b = []              # ②

    def trends(tbl, src, k=64):                      # ③
      b4 = None
      for rows in batches(src, k):
        now = clone(tbl, rows)
        if b4:
          print([(c1.name,
                  round(mid(c2) - mid(c1), 2))
                 for c1, c2 in zip(b4.cols.y,
                                   now.cols.y)])     # ④
        b4 = now

`batches` ① chops the stream into windows. `trends` ③
clones each window and, at ④, prints how each goal's
center moved since the previous window. Mileage drifting
down, weights creeping up: the specials board sees the
market turn, and the Smoke Detector (Chapter 17) will
confirm the turn statistically. Note again the absence of machinery for
forgetting: no decay weights, no delete operations. Windows
forget by construction, and rebuilding a window's summary
costs milliseconds.

> Python tip #4: generators compose like pipes. `csv` into
> `batches` into `clone` is a lazy pipeline; nothing runs
> until something downstream pulls. This is the Unix
> pipeline instinct, native in Python.

> AI tip #7: prefer forgetting by windows over forgetting
> by arithmetic. Decay factors and decrement tricks add
> knobs and bugs; a window plus a cheap rebuild has neither.

### Lessons sighted

The substrate streams natively. Reservoirs keep unbiased
bounded memories. Windows forget for free; trends are
window-to-window deltas.

## 8. The Mechanic (diagnosis)

Prediction says what will happen. Diagnosis says why. Our car
is slow and thirsty; which of its parts should we blame? The
answer in this chapter: grow the tree of Chapter 4, find its
best and worst leaves, and report where their summaries
disagree. Doctors call this a differential diagnosis. We call
it a contrast set.

    def leaves(node):                                # ①
      if node.west:
        yield from leaves(node.west)
        yield from leaves(node.east)
      else: yield node.here                          # ②

    def contrast(t1, t2):                            # ③
      return [(c1.name, mid(c1), mid(c2))
              for c1, c2 in zip(t1.cols.x, t2.cols.x)
              if mid(c1) != mid(c2)]                 # ④

    def mechanic(tbl):                               # ⑤
      lvs = sorted(leaves(Node(tbl)), key=lambda t:
                   disty(t, mids(t)))                # ⑥
      return contrast(lvs[0], lvs[-1])               # ⑦

`leaves` ① walks the tree and yields each leaf's clone ②;
recall from Chapter 4 that every node carries a full table of
its own rows. `contrast` ③ compares two tables column by
column and keeps only the `x` columns where the centers
disagree ④. `mechanic` ⑤ sorts the leaves by how close
each leaf's centroid sits to heaven ⑥, then contrasts the
best leaf against the worst ⑦. The output reads like a
mechanic talking: "the good ones have 4 cylinders and weigh
around 2200; yours has 8 and weighs 4300."

Note what made this cheap. The tree was already built for
prediction. Every node already carries a clone, and clones
already know their mids. Diagnosis fell out of parts we had.

> AI tip #8: explanations from contrast are short because
> most columns do not matter. The keys literature (see the
> introduction) says a few variables control the rest; a
> contrast set is how those few introduce themselves.

> Code tip #6: `contrast` compares summaries, not rows. Row
> versus row comparisons drown in noise. Summary versus
> summary comparisons say what is typical of each side,
> which is the question a diagnosis actually asks.

### Lessons sighted

Diagnosis is contrast between good and bad groups. Compare
summaries, not rows. Reuse the prediction tree; diagnosis
is a by-product.

## 9. The Tour Guide (explanation)

A skeptical buyer does not want our numbers. They want the
tour: what kinds of cars are on this lot, and what makes one
kind better than another? Chapters 4 and 7 built everything
needed; this chapter just teaches it to talk.

    def show(node, lvl=0):                           # ①
      if node:
        t = node.here
        print("|.. " * lvl, len(t.rows),
              round(disty(t, mids(t)), 2))           # ②
        show(node.west, lvl+1)
        show(node.east, lvl+1)

    def why(tbl, a, b):                              # ③
      return [(c.name, a[c.at], b[c.at])
              for c in tbl.cols.x
              if a[c.at] != b[c.at]]                 # ④

`show` ① prints the cluster tree as indented text: each
line gives a group's size and, at ②, how near its centroid
sits to heaven. Small numbers are the good neighborhoods.
`why` ③ explains any single split in pole language: the
split sent our row west because it looked like pole `a` and
unlike pole `b`, and line ④ lists exactly the columns
where those two poles disagree. A path from root to leaf is
then a story: "like this, unlike that; then like this,
unlike that", three or four sentences long.

    %%run python3 src/skills_eg.py tree

(The directive pulls in the printed tree for the car data,
so the reader can check the story against the transcript.)

Why does such a small explanation work? Because the tree is
shallow (depth is log of the row count) and because, as the
Mechanic found, only a few columns ever appear in the
contrasts. An explanation that fits in a paragraph is not a
lucky accident; it is what data with a few keys looks like.

The table of contents promised that this chapter would
justify any verdict on the lot, so let us collect. Every
verdict, already met or still ahead, routes through the
same geometry, and each inherits its story from it. The
Fortune Teller's guess (Chapter 4) reads "you resemble
these thirty cars; expect their mileage". The Mechanic's
blame list (Chapter 8) already is a contrast, spoken. And
the workers we have not met yet inherit the same tour:
when the Bouncer rejects a stranger (Chapter 14), that
will read "farther from typical than 95 percent of this
lot"; when the Smoke Detector fires (Chapter 17), "this
month's arrivals sit far from last month's center"; when
the Nurse ranks the queue (Chapter 15), "nearest the best
labeled so far, unlike the rest". Hence one tour guide
serves every worker on the lot: name the neighbors, then
show the contrast.

How deep do such justifications go? The standard yardstick
is Pearl's ladder of causation, three rungs of question:
association (what goes with what), intervention (what
happens if we act), and counterfactual (what would have
happened instead). XAI surveys collect the questions users
actually put to a model; each maps to a rung, and here,
to a skill:

    trigger                        rung            skill
    How does it work?              association     justify
    What did it just do?           intervention    blame
    What will it do next?          intervention    guess
    How much effort will it take?  intervention    guess
    What if it gets it wrong?      counterfactual  spot, watch
    What if x were different?      counterfactual  wish, fix
    Why didn't it do z?            counterfactual  blame, route

One honesty note travels with the bottom rows. Our
counterfactuals are matched neighborhoods: "a car like
yours, but with four cylinders" means "the leaf such a car
would join". That approximates rung three; it does not
prove it. True counterfactual identification needs causal
assumptions no table can check by itself, so this book's
what-ifs ship as hypotheses with a grading scheme
(Chapter 6) attached.

> SE tip #9: an explanation is a user interface. Its test is
> the same as any interface test: can a stranger, shown only
> the output, predict what the system will do next? Prose
> that fails that test is decoration, however accurate.

> Code tip #7: `show` is the Rule of Silence with a speaking
> part: print the few numbers a decision needs and nothing
> else. Debug dumps belong behind a flag, not in the tour.

### Lessons sighted

Explanation is clustering plus contrast, spoken aloud.
Shallow trees and few keys keep the story short. Test
explanations like interfaces.

## 10. The Bargain Hunter (optimization / active learning)

Now the profitable chapter. Four hundred cars sit on the
lot. Test-driving one car takes an hour. Find a great car by
Friday. This is optimization under a label budget, and the
maths of the introduction (equations 3 and 4) promised it
should take dozens of labels, not hundreds. Let us collect.

The trick is projection, aimed. Chapter 4's `halve` found
two poles that LOOK far apart, needing no labels at all. The
hunter changes one thing: its poles SCORE far apart. They
are the best and worst cars labeled so far. Each round buys
a few labels, redraws the line from best to worst, and keeps
only the half of the pool nearest the good end.

    def hunt(tbl, budget=24, chunk=4):               # ①
      rows, done = shuffle(tbl.rows), []
      while rows and len(done) < budget:             # ②
        done += [rows.pop() for _ in range(chunk)]   # ③
        done.sort(key=lambda r: disty(tbl, r))       # ④
        a, b = done[0], done[-1]                     # ⑤
        c = distx(tbl, a, b)
        rows.sort(key=lambda r:
                  project(tbl, r, a, b, c))          # ⑥
        rows = rows[:len(rows)//2]                   # ⑦
      return done[0], done

Line ② loops until the label budget is gone or the pool is.
Line ③ buys a few labels per round, taking rows from the
shuffled pool. Line ④ ranks everything labeled so far by
distance to heaven, so line ⑤ can name the poles: best
known, worst known. Line ⑥ then orders the whole unlabeled
pool along the best-to-worst line (the `project` of Chapter
4), and line ⑦ discards the bad half. Each round the pool
halves and, because the poles come from a growing labeled
set, the line itself sharpens as the hunt closes in. For 400
rows, the pool is gone in five or six rounds, and `done`
holds about two dozen receipts. **A few dozen labels, not
four hundred**, inside the NEO budget of equation (3), with
the halving of equation (4) doing the work at line ⑦.

Note the two kinds of poles now in play. Unsupervised
structure first (`halve`: far-apart looks, free), then
supervised steering (`hunt`: far-apart scores, two well
spent labels). That pairing, cheap geometry aimed by a few
dear labels, is the whole of active learning.

Does it work? That is an empirical question, and it needs
machinery: many datasets, many repeats, and a
statistician at the door. Chapters 5 and 6 built exactly
that; the war room of Chapter 20 runs this hunt at
scale. (Encouragement
meanwhile: a tuned cousin of this exact loop, in a sister
codebase, restarts when its pool runs dry and keeps 0.66 of
the pool instead of half; from around 45 labels it holds
its own against far heavier optimizers on the corpus of
Chapter 5.)

> AI tip #9: this is active learning in a dozen lines: the
> learner chooses what to label next, and chooses so that
> each label kills half the remaining candidates. When
> labels are the cost, the sampling policy is the learner.

> AI tip #10: the fancy name for the general family is
> sequential model-based optimization. The family's usual
> members carry Gaussian processes and acquisition
> functions. Before paying for those, check how far two
> poles and a sort can go.

> Code tip #8: keep the audit trail in the return value
> (`spent`), not in a log file. A function that returns its
> own receipts is testable: an assert can check the label
> budget was honored, mechanically, every build.

### Lessons sighted

Under a label budget, sampling policy is the learner. Label
a few, draw the best-to-worst line, keep the good half.
Count every label spent, and return the receipts.

## 11. The Travel Agent (planning)

Diagnosis (Chapter 8) told us what is wrong. Planning tells
us where to go instead, starting from where we actually are.
The difference matters. The Mechanic contrasts the globally
best and worst groups; the Travel Agent contrasts your group
against the best one, which yields a route rather than a
lecture.

    def plan(tbl, tree, row):                        # ①
      here  = leaf(tree, row).here                   # ②
      lvs   = sorted(leaves(tree), key=lambda t:
                     disty(t, mids(t)))              # ③
      return contrast(here, lvs[0])                  # ④

Line ② finds the traveler's current neighborhood: drop the
row down the tree, take that leaf's clone. Line ③ ranks
all neighborhoods by their distance to heaven. Line ④
reuses `contrast` from Chapter 8 to list the columns where your
neighborhood and the best one disagree. Each list item is
one leg of the journey: "your cars have 8 cylinders; over
there they have 4".

Two warnings belong in every itinerary. First, the plan
names correlates, not causes; the data says good cars look
like this, never that this change makes a car good. Acting
on a plan is an experiment, and Chapter 6 told us how to
grade experiments. Second, some columns cannot be changed
(a used car's model year is history). A practical planner
filters `contrast` to the columns you can actually steer.

> AI tip #11: separate observation from intervention.
> Prediction rides on correlation; planning flirts with
> causation. Ship plans as hypotheses with a grading scheme
> attached, and nobody gets hurt.

> Code tip #9: `plan` is three reused parts (`leaf`,
> `leaves`, `contrast`) and zero new ideas. When a new chapter
> costs no new mechanism, that is the Rule of Parsimony
> paying dividends.

### Lessons sighted

Plans are contrasts against the best reachable group. Plans
are hypotheses, not promises. Filter plans to steerable
columns.

## 12. The Cheap Fix (repair)

The Travel Agent proposes a grand tour. The Cheap Fix asks a
tighter question: what is the one smallest change that most
helps this one row? For that we need a what-if oracle: a way
to score a row that does not exist yet.

    def wish(tree, row):                             # ①
      t = leaf(tree, row).here
      return disty(t, mids(t))                       # ②

    def cheap(tbl, tree, row):                       # ③
      out, b4 = None, wish(tree, row)
      for name, _, better in plan(tbl, tree, row):   # ④
        at  = tbl.cols.names.index(name)
        new = row[:]; new[at] = better               # ⑤
        if (w := wish(tree, new)) < b4:
          out, b4 = (name, better), w                # ⑥
      return out

`wish` ① estimates any row's worth by the company it would
keep: route it to a leaf, and report how close that leaf's
centroid sits to heaven ②. No labels are spent. `cheap`
③ then tries each leg of the plan one at a time: line ⑤
copies the row and edits a single cell, and line ⑥ keeps
whichever single edit most lowers the wished-for distance.
The answer is one column, one new value, and an estimated
payoff.

Note that `cheap` can return `None`: some rows need the
full tour, and a repair shop that always finds something
to fix is called something else.

> AI tip #12: what-if estimates are interpolations. `wish`
> only knows neighborhoods it has seen, so an edited row
> that lands outside all of them gets a confident nonsense
> score. Chapter 14's Bouncer is the guard: strange
> hypotheticals should be flagged, not scored.

> Python tip #5: line ⑤ copies with `row[:]` before
> editing. Mutating a caller's row inside a scoring loop is
> the classic aliasing bug: cheap to avoid, expensive to
> find.

### Lessons sighted

What-if scoring is leaf lookup (`wish`). Repair is the
plan's best single leg. Guard what-ifs with the anomaly
detector.

## 13. The Kitbasher (synthesis)

Model shops sell kits. Kitbashers ignore the instructions
and glue the best parts of several kits into something new.
We now do that with rows: breed new candidate cars from
halves of good old ones, and score the offspring with the
what-if oracle of Chapter 12.

    def kitbash(r1, r2):                             # ①
      return [random.choice([a, b]) for a, b in zip(r1, r2)]

    def kitbashes(tbl, tree, n=20):                  # ②
      good = sorted(tbl.rows, key=lambda r: wish(tree, r))  # ③
      kids = [kitbash(*some(good[:the.stop], 2))
              for _ in range(n)]                     # ④
      return min(kids, key=lambda r: wish(tree, r))  # ⑤

`kitbash` ① makes a child row: each cell drawn from one
parent or the other, at random. `kitbashes` ranks the
existing rows by wish ③, breeds a small brood from pairs
of the best ④, and returns the most promising child ⑤.
Readers who know genetic algorithms will recognize uniform
crossover, minus the mutation, the generations, and the
population ceremony. On data with a few keys, one round of
crossover among the good rows already lands interesting
hybrids.

The same oracle answers customer questions directly. What if
we took this chassis with that engine? Build the row, call
`wish`, and read the estimate. Synthesis and what-if are the
same trick: score rows that never existed by the
neighborhoods they would join.

> AI tip #13: generate, then criticize. Cheap generators
> (crossover) plus a cheap critic (`wish`) beat elaborate
> generators with no critic. Most of the intelligence sits
> in the critic, and ours came free from Chapter 4's tree.

> SE tip #10: mark synthetic rows as synthetic if you keep
> them. A table quietly mixing observed and imagined data
> will eventually lie to you with a straight face. This is
> data provenance, **SSOT** applied to history.

### Lessons sighted

Breed from the good, score with `wish`. Crossover without
ceremony. Never let synthetic rows masquerade as
observations.

## 14. The Bouncer (anomaly detection)

A car arrives with 92 horsepower and a claimed 3 miles per
gallon. Typo? Scam? Either way, we want a doorman that says
"you're not on the list". Anomaly detection sounds grand, but
with Chapter 3 in hand it is a ruler plus a threshold:

    def strange(tbl, row):                           # ①
      return distx(tbl, mids(tbl), row)

    def bouncer(tbl, q=0.95):                        # ②
      d = sorted(strange(tbl, r) for r in tbl.rows)  # ③
      cut = d[int(q * len(d))]                       # ④
      return lambda row: strange(tbl, row) > cut     # ⑤

`strange` ① is the distance from a row to the table's
centroid. `bouncer` computes that distance for every known
row ③, finds the 95th percentile ④, and returns a
predicate ⑤: anything stranger than 95 percent of the
regulars gets flagged. No density estimation, no autoencoder.
One centroid, one sorted list, one cut.

Note the shape of line ⑤: `bouncer` returns a function.
We build the doorman once, then use him cheaply at the door,
row after row.

> Python tip #6: returning a lambda that closes over local
> state (`cut`, `tbl`) is the poor man's object, and it is
> often all the object you need. One behavior, no class.

> AI tip #14: calibrate thresholds from your own data, never
> from folklore. The cut at line ④ is whatever "strange"
> means on this lot, this month. On another table it will be
> another number, computed the same way.

For finer work, swap the global centroid for the tree of
Chapter 4: drop the row to its `leaf`, and measure strangeness
inside the leaf's clone. A pickup truck is normal on the
truck side of the lot and bizarre among the sports cars.
Global bouncer, local bouncer: same six lines, different
table.

### Lessons sighted

Anomaly is distance from typical. Thresholds come from
percentiles of the data itself. Local strangeness (per leaf)
beats global strangeness.

## 15. The ER Nurse (triage)

Four hundred cars arrived this afternoon. We have time to
inspect a dozen. Which first? This is triage, and it matters
whenever labels cost money: test drives, biopsies, code
reviews, security audits. The nurse does not diagnose; the
nurse ranks.

Assume a handful of rows are already labeled (we test-drove
a few cars, so we can compute their disty). Split those into
the best quarter and the rest. Then score every unlabeled
row by a simple pull: like the best, unlike the rest.

    def triage(tbl, done, todo):                     # ①
      done = sorted(done, key=lambda r: disty(tbl, r))  # ②
      n    = len(done) // 4
      best = clone(tbl, done[:n])                    # ③
      rest = clone(tbl, done[n:])
      f    = lambda r: (distx(tbl, mids(rest), r)
                      - distx(tbl, mids(best), r))   # ④
      return sorted(todo, key=f, reverse=True)       # ⑤

Line ② ranks the labeled rows by distance to heaven. Line
③ clones the top quarter into `best` and the remainder
into `rest`. The score at ④ is a difference of two
distances: far from the `rest` centroid is good, near the
`best` centroid is good. Line ⑤ hands back the queue,
most promising first. Readers who know naive Bayes will
recognize the shape: score by "like this class, unlike the
others". Ours swaps likelihoods for distances, which needs
no probability model at all.

> AI tip #15: triage does not need to be right. It needs to
> be less wrong than the arrival order. Even a rough queue
> means the dozen rows we can afford to label are spent
> where they might matter, and Chapter 10 turns exactly
> this loop into an optimizer.

> Python tip #7: `sorted(key=...)` with a scoring lambda is
> the whole "ranking model deployment" story at this scale.
> No pickle files, no serving layer. A function and a sort.

### Lessons sighted

When labels are dear, rank before you inspect. "Like best,
unlike rest" is a two-centroid score. Triage feeds active
learning.

## 16. The Marriage Counselor (multi-objective trade-off)

Fast, light, cheap: pick two. Every interesting table has
goals that pull against each other, and a book that hid that
tension inside one tidy number would be lying by averaging.
Time to reopen Chapter 3's boldest move: `disty` folds all
goals into one distance. When does that one number tell
the truth?

The counselor's first move is the menu. Instead of one best
row, show the trade-offs on offer:

    def counsel(tbl):                                # ①
      for t in sorted(leaves(Node(tbl)),
                  key=lambda t: disty(t, mids(t))):  # ②
        print(round(disty(t, mids(t)), 2),
              [(c.name, mid(c))
               for c in t.cols.y])                   # ③

One line per neighborhood ②: its distance to heaven, then
its typical value on every goal separately ③. Reading down
that list, the tensions become visible: the group that wins
on weight loses on acceleration; two groups tie overall
while splitting the goals differently. Couples counseling,
in the technical sense: nobody gets everything, and the
menu shows exactly who gives up what.

Two knobs tune the fold itself, and both live in plain
sight. The header's `+` and `-` marks say which way each
goal points. And `the.p` sets the Minkowski coefficient:
at 2, goals compromise smoothly; pushed high, the fold
approaches "judge by the worst goal", the Chebyshev stance
where no amount of extra mileage excuses terrible weight.
One knob, one settings file, and the policy question stays
a visible, versioned decision.

One caution from a sister study is worth its own sentence:
groups that certify as the same on the goals you measured
can differ wildly on a goal you did not fold in (there, it
was fairness across demographic groups). Hence the
counselor's rule: **after optimizing the goals you chose,
inspect the goals you did not choose**, then pick, among
the statistically tied, the candidate kindest to the
unfolded goals. That kindness is usually free.

> AI tip #16: ties are opportunities. Whenever the Referee
> calls several options `same` on the stated goals, spend
> the tie on an unstated goal: fairness, simplicity,
> energy. Selection within a tie costs no measured
> performance at all.

> SE tip #11: keep goal policy in data (header marks, one
> knob), never scattered through code. When the customer
> changes their mind about what matters, the diff should
> be one line long.

### Lessons sighted

Show the menu, not just the winner. The fold's policy is
visible and versioned. Spend statistical ties on the goals
you did not fold.

## 17. The Smoke Detector (drift)

The Bouncer checks one car. The Smoke Detector checks the
whole lot. Markets move: one season brings heavier cars,
another brings imports. A model trained in spring can be
quietly wrong by fall. We want an alarm that smells the
change early.

The trick: watch the distribution of strangeness. Take the
distances from the centroid to (a) a sample of the rows we
trained on, and (b) the rows that arrived recently. If the
two sets of numbers look alike, the world has not moved. If
they differ, smoke.

    def smoke(tbl, new):                             # ①
      old = [strange(tbl, r) for r in some(tbl.rows, the.few)]  # ②
      now = [strange(tbl, r) for r in new]           # ③
      return not same(old, now)                      # ④

Lines ② and ③ reduce "then" and "now" to two lists of
numbers. Line ④ asks whether the lists are statistically
the same. That `same` function is doing real work, and it
deserves a chapter of its own; it gets one (Chapter 6, The
Referee). For now, read it as "no statistician could
tell these apart". When `same` fails, the detector fires,
and the fix is blunt and cheap: `clone` a fresh table from
recent rows and retrain. At our scale, retraining costs
milliseconds, so we do not patch old models. We replace them.

> AI tip #17: monitor distributions, not accuracy. Accuracy
> needs labels, and labels arrive late or never. Distances
> to a centroid need no labels at all, so the smoke alarm
> works even when nobody is grading the predictions.

> SE tip #12: cheap retraining changes the architecture. When
> models cost milliseconds, "model management" collapses to
> `clone` plus a cron job. Complexity in the pipeline is
> usually rent paid on slow training.

### Lessons sighted

Drift is a change in the distribution of strangeness. Watch
it without labels. When in doubt, rebuild; do not patch.

## 18. The Curator (compression / prototypes)

Four hundred cars is a lot of lot. Which dozen rows would
summarize it? Museums answer with curation: keep exemplars,
store the rest in the basement. Our curator already exists;
we built it in Chapter 4 and never noticed.

    def curate(tbl):                                 # ①
      return clone(tbl, [mids(t) for t in leaves(Node(tbl))])  # ②

Grow the tree, take each leaf's centroid, and clone those
few rows into a new table ②. With `the.stop` at 32, four
hundred rows compress to about a dozen prototypes, each one
the typical member of a real neighborhood. The instance
selection literature (surveyed in the introduction's key
sightings) says most rows can be discarded without losing
the signal; `curate` is that finding as four lines.

Why bother, when four hundred rows already fit in memory?
Because every algorithm in this book walks rows. Prediction,
triage, hunting, planning: run them over the curated table
and they all speed up by the compression factor, usually at
little cost in answer quality. And that claim, like all
claims, is checkable:

    %%run python3 src/skills_eg.py curate

**RQ: does knn over a curated table certify as `same` as
knn over the full table?** (Skeleton per Chapter 6; the
Answer line waits for the transcript.)

> AI tip #18: prototypes are also an explanation device. A
> dozen named exemplars ("the thrifty import", "the muscle
> barge") give humans handles that four hundred rows never
> will. Compression is a communication tool wearing a
> performance costume.

### Lessons sighted

Leaf centroids are prototypes. Compression speeds every
downstream skill. Certify the compression with the Referee.

## 19. The Beat Reporter (lifelong active learning)

A beat reporter covers the same street for years: keeping a
compact file of sources, chasing a few leads a week, and
noticing when the neighborhood itself changes. That job
description is lifelong learning, and by now every part of
it is on our bench. Watch how much this chapter does not
have to build:

    def beat(tbl, weeks):                            # ①
      mem = curate(tbl)                              # ②
      for new in weeks:                              # ③
        if smoke(mem, new):                          # ④
          mem = curate(clone(tbl, mem.rows + new))  # ⑤
        yield hunt(mem)                              # ⑥

Line ②: memory starts as the curated prototypes of
Chapter 18, a dozen rows, not a data lake. Line ③: each
week brings a batch of fresh rows (Chapter 7 showed how to
window and sample them). Line ④: the Smoke Detector says
whether the world moved. If it did, line ⑤ folds the news
into memory and re-curates, so memory stays small forever.
Line ⑥: each week, the Bargain Hunter spends its few
labels on the current market and files its story, best find
plus receipts.

That is lifelong learning without the usual dread words.
Catastrophic forgetting? Memory is rows, not weights;
nothing interferes with anything. Replay buffers? The
curated table is one, chosen by clustering rather than
luck. Continual adaptation? A drift alarm plus a
milliseconds-cheap rebuild. **Composition did all the
work**: five chapters, one `yield`, no new mechanism.

    %%run python3 src/skills_eg.py beat

**RQ: over a years-long replay of a MOOT stream, does the
reporter's weekly pick certify as `same` as retraining
from all data each week?** (Answer from transcript.)

> AI tip #19: lifelong systems fail at their seams, so
> build them from parts that were tested solo. Every organ
> of `beat` ran alone, in its own chapter, under its own
> asserts, before joining the composition.

> SE tip #13: design streams so that replay is possible:
> log arrivals, seed samplers, version memory snapshots.
> A lifelong learner you cannot replay is a lifelong
> argument you cannot settle.

### Lessons sighted

Lifelong learning is curation plus drift alarms plus weekly
hunting. Rows do not catastrophically forget. Composition
beats invention.

## 20. The War Room (capstone: one project, every skill)

Every chapter so far taught one skill on one task. Real work
is not like that. Real work is a Tuesday afternoon where the
project is late, the boss wants a forecast, the new hire
asks why, and somebody must decide what to change by
Friday. So before this book hands over the keys (final
chapters), we rehearse: one world, every skill, called
in anger.

The world is coc.py, ninety lines that have sat quietly in
src/ all along. It is COCOMO II, Boehm's classic software
cost model: effort grows with size raised to a power, then
through a chain of multipliers for the usual suspects (team
skill, product complexity, schedule pressure; 22 drivers in
all, each rated 1 to 6). Beside it sits Madachy's risk
table: 34 pairs of settings that are dangerous together,
e.g. tightening the schedule while demanding more
reliability. Feed `coc2` a project; get back effort,
calendar months, and a risk score. In short, a simulator,
with the trade-offs of forty years of project folklore
folded into its tables.

Why rehearse on a simulator instead of yet another MOOT
table? Because here we know the truth. Chapter 5's corpus
is wide but blind: nobody knows any table's real best row.
coc.py is narrow but lit: the formula sits on the page, so
every skill's answer can be checked against the machinery
that generated it, and every demo can end in an assert.

Two functions put this world on the bench (they live in
skills.py with everything else):

    def ratings():                                   # ①
      lo = lambda t: [i+1 for i,v in enumerate(t)
                      if v is not None]
      return {k: random.choice(lo(t))
              for k,t in (SF | EM).items()}

    def projects(n=400):                             # ②
      names = [k.capitalize() for k in SF | EM]
      yield (names + ["Kloc",
             "Effort-", "Months-", "Risk-"])         # ③
      for _ in range(n):
        r    = ratings()
        kloc = 10 ** random.uniform(0, 2)            # ④
        y    = coc2(kloc, **r)                       # ⑤
        yield (list(r.values()) + [round(kloc, 1),
               round(y.effort), round(y.months),
               round(y.risk, 2)])

`ratings` ① picks a legal rating for every driver: the
manual leaves some slots undefined, and `lo` lists the
levels that exist. `projects` ② is a generator, of course:
header first ③, then one random project per lap. Line ④
spreads sizes evenly from 1 to 100 kloc on a log scale.
Line ⑤ asks the simulator for the three goals, all marked
minimize back at ③. No file is written; `Tbl(projects())`
drinks straight from the spout, the way Chapter 3 promised.

Then the shift begins. One directive replays the book:

    %%run python3 src/skills_eg.py warroom

That transcript will run, in order:

- **Forecast** (ch4): knn the effort of a proposed project;
  check the guess against coc2's own answer.
- **Bounce** (ch14): flag configurations far from anything
  this lot has seen.
- **Smoke** (ch17): mature the organization mid-stream
  (pmat ratings drift upward); the alarm fires or the
  build breaks.
- **Diagnose** (ch8): contrast the calm leaf against the
  disaster leaf. The assert: the contrast names drivers
  from Madachy's table, sced beside rely. From 400 random
  projects, the skill rediscovers pairs a human expert
  hand-coded.
- **Triage, then hunt** (ch15, ch10): pretend each
  simulation costs a year of somebody's project. On a
  budget of two dozen labels, find a configuration whose
  distance to heaven certifies as `same` as the best of
  thousands (ch6 referees it, 20 repeats).
- **Plan and repair** (ch11, ch12): for one troubled
  project, the route to the good leaf; then the cheapest
  single change. Relaxing schedule pressure one notch is
  usually cheaper than hiring analyst gods, and now we can
  say by how much.
- **Counsel** (ch16): the menu. sced compresses months and
  inflates risk; the leaves lay that bargain on the table.
- **Curate, then beat** (ch18, ch19): shrink the space to
  a dozen prototype projects, then keep hunting, week
  after drifting week.

Count the new mechanism in this chapter: two functions and
a driver. Everything else is calls into skills we already
built and tested one at a time. That is the capstone's
argument, made by arithmetic.

One caveat belongs in the room. COCOMO II was calibrated
on 161 projects, most finished before 2000. Whether its
constants fit your shop is exactly the kind of claim
Chapter 6 taught you to test. The war room certifies the
skills, not the model: swap in your own simulator (a
build system, a queueing model, a digital twin) and every
move above replays unchanged.

> AI tip #20: keep one world where you know the truth.
> Real data tests usefulness; synthetic worlds with known
> answers test correctness. A skill that has never been
> made to rediscover a formula is a skill on faith.

> SE tip #14: coc.py holds its knowledge as tables, not
> code (the Rule of Representation, one last time): scale
> factors, multipliers, risky pairs. Thirty lines of logic
> walk sixty lines of numbers. Models you can read are
> models you can argue with.

### Lessons sighted

One world, every skill, zero new mechanism. Simulators
are truth on tap. Certify the skills against known
answers,
then point it at your own shop.

## 21. The Morning Meeting (software analytics)

The war room rehearsed on a simulator. This second case
study rehearses on a job: running the morning meeting of a
software project, where a manager asks questions and wants
answers before the coffee cools. We did not invent the
questions. Buse and Zimmermann surveyed 110 developers and
managers at Microsoft about their information
needs[^buse], and distilled the answers into a grid of
nine analytics kinds: three time frames (past, present,
future) crossed with three intents (explore, analyze,
experiment). Their paper also reports what managers want
from any analytics tool: easy, fast, concise; able to
drill from summary down to artifact; and transparent,
because managers distrust predictions they cannot open.

[^buse]: R.P.L. Buse and T. Zimmermann, "Information Needs
for Software Development Analytics", ICSE 2012. The PDF
sits in this repo as buse-icse-2012.pdf.

This chapter rewrites their grid in our operators. Every
cell, one call:

    their cell     their example      our call        ch
    trends         regression         trends          7
    alerts         anomaly detection  bouncer, smoke  14,17
    forecasting    extrapolation      knn             4
    summarization  topic analysis     curate, show    18,9
    overlays       correlation        contrast        8
    goals          root-cause         plan            11
    modeling       machine learning   Tbl, Node       3,4
    benchmarking   significance       top             6
    simulation     what-if            wish            12

Nine research areas, nine calls. And that ratio, not any
single mapping, is the finding. Walking this book, each
chapter needed less than the one before: Chapter 3 built
about 150 lines, Chapter 4 twenty, most chapters a dozen,
and this chapter builds almost nothing, because the
machinery for skill i+1 was already built for skills 1
through i. Hence a claim worth stating plainly: **our
twenty names are not special**. Buse's nine cells, our
dispatch table, the kind tree, the old logicians' triad:
these are different ways of cutting the same territory,
and however the territory gets cut, each region costs only
a few lines, because the substrate under the cut does not
change. The taxonomy is vocabulary; the capability lives
in the substrate.

The data for the meeting is a project telemetry table:
rows are weekly snapshots of modules (size, churn,
owners, defect counts as goals), in the header dialect of
Chapter 3. The meeting itself is one function:

    def morning(tbl, week):                          # ①
      tree, ok = Node(tbl), bouncer(tbl)             # ②
      return o(
        alerts = [r for r in week if ok(r)],         # ③
        moved  = smoke(tbl, week),                   # ④
        next   = knn(tbl, week[-1]),                 # ⑤
        blame  = mechanic(tbl),                      # ⑥
        todo   = plan(tbl, tree, week[-1]))          # ⑦

Line ① takes the history and this week's rows. Line ②
builds the cluster tree and the doorman once. Then five
answers, one per survey trigger: which new rows look
strange ③; whether the project as a whole has quietly
moved ④; what next week probably looks like ⑤; what
separates the healthy modules from the sick ones ⑥; and
what to change first ⑦. Trends and the what-ifs join in
from their own chapters when the meeting runs long.

    %%run python3 src/skills_eg.py morning

Now hold their tool guidelines against what just
happened. Easy: each answer is one call into a five-line
skill. Fast and current: everything rebuilds in
milliseconds, so the dashboard is never stale. Concise:
the Rule of Silence; `morning` returns five values, not
five hundred. Drill-down, their strongest demand: every
answer above unwinds, because leaves carry clones and
clones carry rows; from "this module cluster looks sick"
to the offending rows is two hops, no extra machinery.
And transparency, their deepest finding: the managers
they surveyed would not act on a model they could not
open. Every skill here opens. That survey, from 2012,
reads today as the requirements document this book was
accidentally built against.

One more of their numbers deserves its own sentence: 89
percent of the decision scenarios they collected concern
the past and present, not the future. Managers would
rather remember than speculate. This book agrees; that is
the moral of Chapter 4, and the reason the meeting above
spends most of its answers on what already happened.

### Lessons sighted

A survey of real managers maps onto the skills, cell by
cell. Each new cut of the world costs a few lines,
because the substrate under the cuts is shared.
Drill-down is free when leaves carry clones. Transparency
was a requirement before it was a slogan.

## 22. The Drag Race (baselines)

The war room raced our skills against the truth. One race
remains: against the field. Nothing in this book stands if
a standard tool, used off the shelf, beats ours while we
were busy admiring our line count. So we line the rivals
up on the same strip, same fuel, public clocks, with the
Referee of Chapter 6 holding the stopwatch. (This
chapter's working title was Deathrace 2000; cooler heads
renamed it.)

Two races, because this book makes two kinds of claim.

**Race one: optimization.** The rivals, cheapest first.
Random search is the null rival: the same label budget,
spent blindly; the tuning literature keeps finding it
embarrassingly strong, which is exactly why it runs in
lane one. Then TPE (tree-structured Parzen estimators, the
engine inside the Optuna tuning library), and a
multi-objective genetic rig, NSGA-II (as shipped in the
pymoo library). The protocol: every MOOT table; every
method gets the same budgets (24, 50, 100 labels); 20
repeats; each run scored by the distance to heaven of the
best row it bought; `top` names each row's winner set.

    %%run python3 src/dragrace_eg.py --report optimize

The table that lands here, one line per dataset and
budget:

    dataset   budget  rand   tpe   nsga2  hunt  verdict
    auto93        24   xxx   xxx     xxx   xxx     xxx
    SS-N          24   xxx   xxx     xxx   xxx     xxx
    ...

**Answer:** xxx (from the transcript; the claim we hope to
earn is "hunt sits in the top rank at every budget", and
if it does not, that result prints too).

**Race two: explanation.** Harder, because explanations
have no ground truth to lap against. The rivals: SHAP and
LIME (which explain a prediction by weighting the features
that drove it) and Anchors (which bounds it with rules).
The scoring cannot be "which story sounds nicer", so we
race on utility and on stability. Utility: each method
names its top k columns; an independent learner trains on
just those columns; better selection, better downstream
score. Stability: rerun each method on 20 resamples and
count how often its top-k set survives; an explanation
that changes with the weather explains nothing. Size
prints too: a three-line contrast against a SHAP bar chart
of 24 weights is a difference the reader can judge without
us.

    %%run python3 src/dragrace_eg.py --report explain

**Answer:** xxx.

One rule keeps this race fair, and one keeps it cheap.
Fair: every rival runs twice, once with its shipped
defaults and once tuned, and both rows print; beating a
strawman teaches nothing. Cheap: the rivals import
half the Python ecosystem, so dragrace_eg.py is a guest,
living in its own virtual environment, entering this book
only through its transcripts. The 2000-line budget covers
our skills, not our opponents.

> SE tip #15: a baseline is a rival you tried to make win.
> Give it its defaults, give it a tuning, give it the same
> budget, and publish its best. Anything less converts
> your victory table into marketing.

> AI tip #21: score explanations by utility and stability,
> never by plausibility. Humans rate confident nonsense
> highly; downstream learners and resamples do not.

### Lessons sighted

Race the field, not a strawman; random search runs in lane
one. Explanations race on utility, stability, and size.
Rivals are guests: their transcripts enter, their imports
do not.

## 23. The Apprentice (agent onboarding)

The last worker on the lot is new: a coding agent, a large
language model with a shell. It is a fast intern with no
long-term memory and boundless confidence. This chapter is
about onboarding it, and the exhibit is this book's own
repository, which is largely maintained with such an
apprentice. The onboarding document is a file of plain
prose, CLAUDE.md, that the agent reads before touching
anything. Excerpts:

    After every edit: `make check` (all demos must
    pass), then `make weave` (directives must expand),
    then `make lines` (no code line over 65 chars).
    A change that breaks any of these does not ship.

    Transcripts are never hand-typed. Program output
    enters a chapter only via a %%run directive.

    Stop and ask the human before: deleting any file;
    changing a seed; changing an existing assert.

Look at what those rules are made of. Machine-checkable
gates, not adjectives (`make check`, TIM's 65-character
line). Provenance rules (output only via `%%run`), so the
apprentice cannot invent transcripts. And a stop-and-ask
list marking the decisions that stay human: seeds, asserts,
deletions. Nothing in the file says "write good code",
because the apprentice cannot check "good" and neither can
we; every rule is a test someone can run.

The deeper point: **onboarding an agent is the same
discipline this book applies to its own algorithms**. We
never trusted a learner's answer without the Referee; we do
not trust an intern's diff without the gates. We kept every
knob in one file for humans; the agent benefits from SSOT
even more than we do, because it re-reads the rules fresh
every session and drifts the moment truth has two homes.
The apprentice is not a new problem. It is the oldest
problem in this book, wearing a login: cheap guesses need
cheap, mechanical certification.

A short checklist for onboarding any agent onto any repo:
(a) one rules file, short enough to re-read every session;
(b) every rule machine-checkable, with the check named in
the rule; (c) an explicit stop-and-ask list; (d) protected
zones the agent must never touch; and (e) worked exemplars
to copy shapes from, because agents, like interns, imitate
far better than they invent.

> SE tip #16: write rules the way you write asserts: short,
> checkable, and colocated with what they protect. An
> agent's CLAUDE.md is a test suite for behavior.

> AI tip #22: give agents exemplars, not adjectives. "Copy
> the shape of ch4" outperforms "write clearly" every
> time. Retrieval beats invention; this was also the moral
> of Chapter 4, and of the whole book: don't think,
> remember.

### Lessons sighted

Onboard agents with checkable rules, protected zones, and
exemplars. Keep the human on the stop-and-ask list. The
apprentice needs the same referee everything else got.

## Glossary

Each entry opens with a tag saying what kind of thing the
term names: a (function) or (struct) in the code; a (rule)
of this book's craft; a (stat), one of the referee's
measures; an (AI), (SE), (Python), or (code) idea, matching
the four tip streams; or (data), something fetched or
simulated. Entries close with their nearest neighbors.
Some carry a self-test question, or the code itself when
the code is short enough to be its own definition.

**active learning** (AI). A learner that chooses which
rows to label next (Chapter 10). Q: in `hunt`, how many
labels does one round spend? (`chunk` of them, four by
default.) See also: triage, NEO.

**add** (function). The one verb of the substrate: fold a
value into a column, or a row into a table (Chapter 3.5).
Everything that learns, learns through `add`. See also:
Welford's algorithm, streaming.

**anomaly detection** (AI). Flagging rows far from typical
(Chapter 14). Distance to centroid, cut at a percentile.
See also: centroid, drift, what-if.

**assert** (code). An executable claim. This book's demos
all end in one, so every claim in prose has a tripwire in
code. See also: seed.

**baseline** (SE). A rival you tried to make win: same
budget, defaults and tuned, best result published
(Chapter 22). Random search is the mandatory first lane.
See also: same, MOOT.

**BOB** (rule). Bob's rule: functions of about five lines,
plus or minus four (after Robert Martin). Enforced by the
build. See also: TIM.

**centroid** (AI). A table's row of column centers.
See also: mid, clone.

    def mids(tbl):
      tbl.mid = tbl.mid or [mid(c)
                            for c in tbl.cols.all]
      return tbl.mid

**Cliff's delta** (stat). Rank-based effect: how often
values of one list sit above and below the other, returned
as an imbalance, 0 to 1. At or under `the.cliffs` (0.197),
same, to this judge (Chapter 6). The `xsort, ysort` names
announce the precondition: sorted input. See also: KS
test, Cohen's rule, same.

    def cliffs(xsort, ysort):
      gt = lt = j = k = 0
      for x in xsort:
        while j < len(ysort) and ysort[j] <  x: j += 1
        while k < len(ysort) and ysort[k] <= x: k += 1
        gt += j; lt += len(ysort) - k
      return abs(gt - lt) / (len(xsort) * len(ysort))

**clone** (function). A new empty table with an old
table's header, optionally refilled:
`Tbl([tbl.cols.names] + rows)`. The book's main
structuring trick (Chapter 3.5). See also: Tbl, curation.

**COCOMO** (data). Boehm's software cost model: effort =
a * kloc^e, scaled by 22 rated drivers; months and risk
ride along. src/coc.py holds the COCOMO II.2000
calibration plus Madachy's risky-pair table. The book's
known-truth world (Chapter 20). Q: why trust a 2000-era
calibration? (We do not; the war room certifies the
skills, not the model.) See also: baseline.

**Cohen's rule** (stat). Report the gap between two
middles in units of pooled spread; under `the.cohen`
(0.2), same (Chapter 6). Q: why prefer this to a p-value? (It
asks whether anyone would care, not whether n was large.)
See also: Cliff's delta, KS test, same.

**contrast set** (AI). The columns on which two groups'
summaries disagree; the output of `contrast` (Chapter 8).
The seed of diagnosis, explanation, planning, and repair.
See also: leaf, centroid.

**CSV** (data). Comma-separated values, plus this book's
header dialect: case gives type, trailing `+`/`-` mark
goals, trailing `X` means ignore (Chapter 3). See also:
Tbl, generator.

**curation** (AI). Compressing a table to its leaf
centroids (Chapter 18). A dozen prototypes standing in
for hundreds of rows. See also: leaf, centroid, clone.

**distance to heaven** (AI). `disty`: how far a row's
goal values sit from their ideals, 0 best, 1 worst.
Defined once, in Chapter 3.6; used by every chapter
after. See also: heaven, Minkowski distance.

**div** (function). A column's diversity: standard
deviation for numbers, entropy for symbols (Chapter 3.3).
See also: entropy, mid, Welford's algorithm.

**drift** (AI). The world changing under a model
(Chapter 17). Detected by comparing strangeness
distributions, then cured by rebuilding. See also:
anomaly detection, same, streaming.

**EAFP** (Python). Easier to ask forgiveness than
permission: try the operation, catch the exception.
Idiomatic Python (Chapter 3.1). Q: what is the
alternative called? (LBYL: look before you leap.)

**entropy** (stat). The diversity of a symbol
distribution: low when one value dominates, high when
counts are even (Chapter 3.3). See also: div.

**FASTNEO** (AI). Near-enough optimization sped by binary
chop (story.md, equation 4): about log2 of NEO's sample
count. Chapter 10's halving of the pool follows this
budget. See also: NEO, active learning.

**generator** (Python). A function that yields values on
demand (`csv`, `leaves`, `batches`, `beat`): calling it
builds a paused machine; each `next` runs it to the next
`yield` and freezes it there, locals intact (Chapter
3.2). A promise of data, not a pile of it. Q: why can
code fed by a generator never cheat? (No peeking ahead,
no second pass, no row count: streaming-ready by
construction.) See also: streaming, walrus operator.

**heaven** (AI). Per goal column: 0 if minimizing, 1 if
maximizing. Set by the header, stored in the `Num`, used
by `disty`. See also: distance to heaven.

**junk drawer file** (code). A file that scatters one
behavior's variants far apart (the Num add up top, the Sym
add far below), so no single scroll shows the whole
polymorphic flow. The cure: group by operation, all the
adds together (Chapter 3). Generic plumbing (map, sort,
print) may still pool in a utilities corner; the rule
guards verbs, not appendixes. See also: skill, Rules of
Unix programming.

**keys** (AI). The few variables or rows that control the
rest. The empirical bet of the whole book (story.md,
section 2). See also: contrast set, curation.

**kNN** (AI). k-nearest-neighbor prediction: answer with
a summary of the k most similar rows (Chapter 4). See
also: leaf, centroid.

    def knn(tbl, row, k=5):
      return mids(clone(tbl,
                        around(tbl, row)[:k]))

**KS test** (stat). Kolmogorov-Smirnov: walk two sorted
samples as cumulative distribution curves and return the
largest vertical gap, in critical-value units; under
`the.ks` (1.36), same (Chapter 6). Distribution-free, one
while-loop. See also: Cliff's delta, Cohen's rule, same.

    def ks(xsort, ysort):
      nx, ny = len(xsort), len(ysort)
      d = i = j = 0
      while i < nx and j < ny:
        if xsort[i] <= ysort[j]: i += 1
        else:                    j += 1
        d = max(d, abs(i / nx - j / ny))
      return d / ((nx + ny) / (nx * ny)) ** 0.5

**leaf** (AI). The tree node a row lands in after
recursive halving; its clone is the row's neighborhood
(Chapter 4). See also: kNN, curation, what-if.

**lifelong learning** (AI). Learning that continues
across drift without unbounded memory (Chapter 19):
curate, watch for smoke, hunt weekly. See also: drift,
curation, active learning.

**mid** (function). A column's center: mean for numbers,
mode for symbols. Q: why one function for both? (So all
downstream code can forget the type.) See also: div,
centroid.

**Minkowski distance** (stat). The family of distances
behind `distx` and `disty`; `the.p` picks the member. At
p=2, Euclidean; as p grows, judgment tilts to the worst
gap (Chapter 16). See also: distance to heaven, norm.

**MOOT** (data). Many multi-objective optimization tasks:
the public corpus (tiny.cc/moot) all experiments run over
(Chapter 5). See also: baseline, CSV.

**NEO** (AI). Near-enough optimization: settle for
solutions statistically indistinguishable from best
(story.md, equation 3). About a hundred labels, worst
case. See also: FASTNEO, Cohen's rule.

**norm** (function). Map a raw value to 0..1 via its
column's running mean and spread, through a logistic
curve (Chapter 3.4). See also: Welford's algorithm,
Minkowski distance.

**Num** (struct). The summary of a numeric column: count,
mean, m2, heaven (Chapter 3.3). See also: Sym, Welford's
algorithm.

**o** (struct). The one struct: named slots, dot access,
pretty print. Defined in about.py; used everywhere. See
also: the.

**POLA** (rule). Principle of least astonishment: code
should do what a reader expects (`shuffle` copies before
shuffling). See also: Rules of Unix programming.

**reservoir sampling** (code). Keeping a bounded,
unbiased sample of an unbounded stream (Chapter 7). Q:
with tank size k, what chance does row n have of being
kept? (k/n, all n.) See also: streaming, seed.

**Rules of Unix programming** (rule). As used here.
Composition: build parts that connect (`clone`,
generators). Parsimony: add mechanism only when nothing
else will do (Chapter 11's planner reused three old
parts). Representation: fold knowledge into data (the
header). Silence: print only what a decision needs
(`show`). Least surprise: see POLA.

**same** (function). The Referee's verdict (Chapter 6):
three judges return magnitudes, cheapest first; `same`
compares each to a cited default in its own signature, and
a lazy `or` ends the trial at the first small-enough
score. See also:
Cohen's rule, KS test, Cliff's delta.

    def same(xs, ys, Cohen=0.2, Ks=1.36, Cliffs=0.197):
      xsort, ysort = sorted(xs), sorted(ys)
      return (cohen(xsort, ysort) < Cohen
              or ks(xsort, ysort) < Ks
              or cliffs(xsort, ysort) <= Cliffs)

**Scott-Knott** (stat). Full ranking of many treatments:
sort by median, split where the halves pull farthest from
the parent mean, recurse only where `same` says the halves
differ; unsplit groups share one integer rank, best first
(`sk`, Chapter 6). See also: top, same.

**seed** (SE). The number that makes randomness
replayable. Set once in about.py; reset before every
demo. Changing it is a stop-and-ask event. See also:
assert, reservoir sampling.

**skill** (SE). A small, named, auditable capability: one
shared table type in, receipts out, about five lines each.
The introduction's table is the dispatch: its left column
names a situation; find your row, read your skill. Three
layers hold them all: representation (lib.py), skills
(skills.py), governance (the referee, the seeds, and
CLAUDE.md). See also: tips, baseline.

**SOC** (rule). Separation of concerns: settings in
about.py, substrate in lib.py, chapter code in skills.py.
See also: SSOT.

**SSOT** (rule). Single source of truth: every fact has
one home. The header for schema, about.py for knobs,
CLAUDE.md for agent rules. See also: SOC, CSV.

**streaming** (SE). Processing rows one at a time under
bounded memory (Chapter 7). The substrate's `add` was
built for this from day one. See also: generator,
reservoir sampling, Welford's algorithm.

**Sym** (struct). The summary of a symbolic column: count
plus a dictionary of seen values (Chapter 3.3). See also:
Num, entropy.

**Tbl** (struct). Rows plus self-summarizing columns,
split into x (observables) and y (goals) by the header
(Chapter 3.5). See also: clone, CSV.

**the** (struct). The settings struct in about.py: seed,
p, few, stop, file. All knobs, one place, all overridable
from the command line. (The referee's thresholds live in
same's signature instead: they are cited constants, not
tuning knobs.) See also: o, SSOT.

**TIM** (rule). timm's rule: no code line past 65
characters (the circled markers ride outside the count).
Q: why 65? (So code drops into books, slides, and
terminals without reflowing; reformatting is where
transcription bugs breed.) See also: BOB.

**tips** (rule). Four numbered streams run through the
margins: AI tips (learning and data), SE tips (the craft
around the code), Code tips (any language), Python tips
(this language). The glossary tags reuse the same four
names.

**top** (function). The referee at scale: given
{treatment: scores}, walk the treatments best median first
(least by default; greatest under its `max` flag) and
return everything until the first treatment that is not
`same` as the champion. The winner set that this book's
report tables print (Chapter 6). See also: same, baseline.

    def top(d, max=False):
      out, mid = [], lambda a: sorted(a)[len(a) // 2]
      for k in sorted(d, key=lambda k: mid(d[k]),
                      reverse=max):
        if out and not same(d[out[0]], d[k]): break
        out += [k]
      return out

**triage** (AI). Ranking unlabeled rows by expected value
of inspection: like the best seen so far, unlike the rest
(Chapter 15). See also: active learning, centroid.

**VITAL** (rule). Very important to acquire locally: the
counter to "not invented here" sneers. Two hundred
auditable lines beat two hundred opaque megabytes, when
understanding is the goal (Chapter 3.7).

**walrus operator** (Python). Python's `:=`: assign and
test in one expression, as in
`if (line := line.strip()):`. See also: generator.

**Welford's algorithm** (stat). One-pass, numerically
steady mean and variance (Chapter 3.3). The reason every
summary here is streaming-ready. See also: add, norm,
streaming.

**what-if** (AI). Scoring a row that does not exist by
the leaf it would land in (`wish`, Chapter 12).
Interpolation only; guard it with the Bouncer. See also:
leaf, anomaly detection.

**YAGNI** (rule). You ain't gonna need it: build the knob
when a chapter demands it, not before. about.py has five
entries, and that is a boast. See also: SOC.

## Note to us (not for print) {.unlisted}

Loose ends, in work order:

1. Reverse-engineer the test_xxx demos promised by the
   %%run stubs (knn, tree, hunt, curate, beat, warroom,
   morning),
   all in src/skills_eg.py. Each must reseed, print, and
   end in an assert (CLAUDE.md rule 6).
2. DONE: lib.py now ships `same` (cohen/ks/cliffs each
   reversed into a same-predicate; lazy or, cheapest
   first). test_stats and ch4's trust-test prose updated
   to match.
3. Layout decided: about.py, lib.py, lib_eg.py,
   skills.py, skills_eg.py, coc.py. All chapter code goes in
   src/skills.py (imports lib; capstone drives coc);
   demos in src/skills_eg.py. Promote a tools function to
   lib only if 2+ chapters use it and it carries no policy
   (candidates: leaves, contrast, strange, wish). lib.py
   stays under 250 lines. hunt's budget and chunk
   arguments become about.py knobs then (hard rule 7).
   dragrace_eg.py (Chapter 22) is a guest file with its
   own venv; it never imports into the 2000-line budget.
4. Chapter numbers here continue story.md's sections 1-2.
   Renumber both together or neither.
5. The experiment RQs (Chapters 12, 16, 19) have skeleton
   tables with xxx placeholders. Answers get written only
   from woven transcripts.

<!-- ============================================================
AUTHORING CAPSULE (invisible in render; keeps this file
self-contained for any future session or tool). Digest only;
authoritative sources: etc/style.md, ../CLAUDE.md, CLAUDE.md,
rite/etc/style.py (FAM2). Updated 2026-07-29.

VOICE. First person plural, plain, a little blunt. Mix
sentence lengths hard; short declarative pivots ("But there
is a problem."). Rhetorical questions drive sections.
Connectives: Hence / That said / Also / Note that. Inline
(a) (b) (c) enumeration. Bold the load-bearing claim once,
inline. Concrete numbers with their arithmetic.

BANNED. Em-dash pairs; "X is not Y, it is Z"; triads for
rhythm; verbless fragments; thesis-announcement filler;
consultant nouns; delve/crucial/pivotal/seamless/holistic/
leverage/harness/underscore/foster; sincerity words as
self-praise (honest(ly), genuinely, truly) and the rest of
rite FAM2 (police by density); perfectly uniform paragraph
shapes.

CODE. Shown code is src/lib.py (or future skills.py)
verbatim; circled markers # ① ② ③ ride outside TIM's
65-char limit and are explained by matching ① notes in
nearby prose. BOB: functions ~5 lines. Every identifier
glossed at first use; parts before wholes EXCEPT where a
one-line dispatcher reads as the schema rule (Col). Stats
functions take xsort/ysort: sorted by contract. Group code
by operation, not type: all variants of a verb sit
adjacent (Python: functions over structs; Lua: adjacent
metatable methods); generic plumbing may pool at the back.

PROVENANCE. Program output never hand-typed; transcripts
enter only via %%run directives (weaver: etc/weave.py).
Experiment tables pre-committed with xxx placeholders;
Answers written only from woven transcripts. Reports follow
the skeleton: RQ in bold, method paragraph, one small
table, one-line bold Answer (model: ../branch/REPORT.md).

STRUCTURE. story.md = front matter; title "Sophisticated
AI: Simple Ain't Stupid", subtitle "Dozens of reusable AI
skills from a few hundred lines of Python". Its ch2 runs a
three-rung ladder (cognitive: Simon/Gigerenzer; empirical:
Holte/Dawes/Hand; maths: NEO eqs), each layer explaining
the one above; NEO = satisficing with a price tag. The task
table is the chapter map, one row per chapter, chapters
3..23, approximately sorted by new-LOC within the
dependency DAG (four named sort-breaks under table 1). Chapter
shape: persona title + bracketed canonical task; a few
lines of code; tips as blockquotes (> AI tip #n / SE / Code
/ Python, numbered per stream); ends with "Lessons
sighted". Glossary entries: **term** (tag). body; See
also. Tags: function, struct, rule, stat, AI, SE, Python,
code, data. Source layout is fixed at six files: about,
lib, lib_eg, tools, tools_eg, coc (+ dragrace_eg as an
uninported guest).

BUILD. make story1 renders story.md + story1.md to
tmp/story1.html (pandoc, TOC from numbered ## headings;
{.unlisted} hides a heading from the TOC). make check /
weave / lines must stay green; python code in indented
blocks is lexed as python by the highlighter.
============================================================ -->
