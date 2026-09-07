## AI ideas in y3.py

Nine AI ideas hiding in y3.py, easiest first. Each shown
small (this code) then big (a real-world system).

### 1. Labels are dear

Reading a row costs nothing; knowing how *good* it is costs
a build, a test, an experiment. Budget the second thing.

**Small.** y3 reads 10,000 rows free, but calls `ydist` on
at most `Stop=50` of them:

```py
while todo and len(best.rows) + len(rest.rows) < cap:
```

**Big.** ImageNet took 49,000 crowd-workers over two years
to label 14 million images. Medical imaging is worse: each
label is minutes of a radiologist's time. Whole companies
(Scale AI, Labelbox) exist only because labels are the
expensive part of modern AI.

### 2. Many goals, one number (aggregation functions)

Real decisions juggle goals that fight each other. An
*aggregation function* collapses them to one number: here,
normalize each goal to 0..1 and score a candidate by its
distance to "heaven" (all goals at their best). The
alternative is to skip aggregation and keep the *Pareto
frontier* — every candidate no other candidate beats on all
goals at once. Frontiers dodge the collapse but return a
set, not an answer, and cost far more evaluations
(NSGA-II-style optimizers run whole populations for many
generations).

**Small.**

```py
def ydist(tbl, row):
  return (sum(abs(norm(tbl.cols[at], row[at]) - w) ** the.P
             for at, w in tbl.y.items()) / len(tbl.y))**(1/the.P)
```

**Big.** Aircraft design trades lift against weight against
cost against noise; compiler flag selection trades speed
against binary size against build time. NASA and the
automotive industry run whole departments on multi-objective
trade-off studies; y3's `-` and `+` headers are that idea in
two characters.

### 3. Discretization

Continuous numbers usually matter only in bands. Finding the
few cut points that predict something is half of learning.

**Small.** `cutNum` sweeps sorted values, testing only the
boundaries where the value actually changes:

```py
if x != xy[i+1][0]: yield here, there, x
```

**Big.** Medicine runs on discretizations: hypertension
begins at 140/90; diabetes at HbA1c 6.5%; BMI has four
bands. Each cut point compresses a continuous measurement
into a decision — and choosing those cuts well or badly
moves millions of diagnoses.

### 4. Trees are recursive discretization

One cut splits a space in two. Recurse on each half and the
result is a decision tree: stacked discretizations, readable
as rules.

**Small.**

```py
node += [go, tree(tbl, yes, e1, y), tree(tbl, no, e2, y)]
```

**Big.** The Goldman criteria for chest pain — a tree of a
handful of yes/no questions — triaged emergency-room
patients as well as cardiologists did. Microsoft's Kinect
tracked your skeleton in real time with forests of decision
trees. Trees survive because the model *is* the explanation.

### 5. Train/test separation

A model that scores well on data it has seen proves only
that it can memorize. Hold some data back; test there.

**Small.**

```py
train, test = rows[:n][:the.Few], rows[n:]
```

**Big.** Kaggle keeps a private leaderboard hidden until
competition end precisely because teams overfit the public
one; final standings routinely reshuffle when the held-out
half speaks. Every drug trial's endpoint is a train/test
separation with lives attached.

### 6. Regularization by smallness

Fitting the training data too well means fitting its noise.
Forbidding detail — bigger leaves, shallower trees — often
*improves* accuracy on new data.

**Small.** One line forbids slivers:

```py
if the.Leaf <= size(here) <= len(xy) - the.Leaf:
```

**Big.** Gigerenzer's "fast and frugal" studies found
three-question trees matching or beating logistic models
and expert doctors at predicting heart attacks. Credit
scorecards are legally *required* to stay small enough to
explain — and lose little accuracy for it.

### 7. Active learning

Passive learners label rows at random. Active learners spend
each label where, given everything labeled so far, it will
teach the most.

**Small.** The whole acquire loop: label a few, model,
pick, repeat:

```py
label(tbl, best, rest, pop(tbl, best, rest, todo))
```

**Big.** Drug discovery screens libraries of millions of
compounds but can only assay thousands: modern pipelines
train on each batch of assays to choose the next batch.
Berkeley's A-Lab and self-driving "data engines" (label the
frames the current model finds hardest) run the same loop
at industrial scale.

### 8. Baselines, and wins as regret

Before trusting a clever method, race it against something
dumb — say, "label N random rows, keep the best". y3's
`wins` reports the complement of normalized regret: 100
means "as good as best", 0 means "no better than average".

**Small.**

```py
return lambda r: max(-100, min(100,
  100 * (1 - (ydist(tbl, r) - lo) / (b4 - lo + 1e-32))))
```

**Big.** The M forecasting competitions embarrassed decades
of methods: on thousands of series, the naive
"tomorrow = today, adjusted for season" baseline beat most
sophisticated entrants. A field that skips brutal baselines
publishes noise.

### 9. Budget accounting

Every label must be counted — including the ones spent
checking the model's suggestions. Splitting one budget
between learning and verifying is itself a design decision,
and often verification labels earn more.

**Small.** Acquire gets what checking leaves behind:

```py
tt = tree(tr, acquire(tr, the.Stop - the.Check))
```

**Big.** Clinical trials are budget accounting made law:
phases I–II learn (small n, exploratory), phase III verifies
(large n, confirmatory), and regulators count every patient.
In AutoML, papers now must report total compute — early
neural-architecture searches quietly spent 2,000 GPU-days
finding models that random search matched at a tenth the
cost.
