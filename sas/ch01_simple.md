\part{The Substrate}

# Simple Ain't Stupid

Much recent press says that developers no longer need to read code. The creator of
Node.js suggests the era of human-written code is ending. Nvidia's CEO advises
against learning to code at all [@menzies26ezr]. The claim behind the phrasing is
always the same: AI is the new compiler, and nobody reads what a compiler emits.

We disagree. This book is our evidence.

The evidence is 400 lines of Python that implement Naive Bayes, k-means clustering,
decision trees, anomaly detection, active learning, and multi-objective optimization
on one shared substrate. Tested on 120+ tasks from the MOOT repository, these tiny
tools perform as well as or better than SHAP, LIME, and the SMAC3 optimizer, while
running 500 times faster than SMAC3 and using orders of magnitude fewer labels
[@menzies26ezr]. That result was found by reading: years of taking learners apart,
noticing that distant parts of different algorithms were the same part, and deleting
the copies. Reading code is not nostalgia. It is a research method, and it works.

## The axiom

One economic fact organizes everything that follows. Tables of data are cheap;
*labels* are dear. Anyone can list 10,000 configuration options. Knowing which one
compiles fastest costs a compile per option. Hence the question this book asks, over
and over: how few labels buy a good row, plus an explanation of why it is good?

Our running example is auto93: 398 cars, 8 columns. Four columns are cheap to observe
(cylinders, engine volume, model year, origin). Three are goals we must pay to know:
minimize Lbs-, maximize Acc+ and Mpg+. One (HpX) we ignore. That is 4 + 3 + 1 = 8.
When we say a method is good, we mean it finds near-best cars after paying for few
labels.

## The ritual

**Every claim in this book can be re-run from a seed, and
any claim that cannot is not in this book.** Each demo (a)
resets the random stream; (b) runs; (c) prints; (d)
asserts. The printed output is captured by the build tool
at build time, so what you read is what the code did, on
the day this book was compiled. Chapter 15 shows the
statistics that police the stronger claims: no "X beats Y"
without effect size and significance agreeing.

## The map

Part I (Chapters 3 to 5) builds the substrate: cells, columns, tables, distance. Part
II reads the world: six applications that predict, detect, monitor, diagnose, triage,
and explain. Part III changes the world: eight applications that optimize, plan,
repair, generate, compress, negotiate, and learn on streams. Part IV earns trust:
certification by statistics, and the onboarding of an AI colleague. Chapter 2 relates
all this to prior work. Skip it for now.

One convention, used throughout. Where a lesson has a canonical name, that name
appears in bold at first use (e.g. **SSOT**, single source of truth). Where a lesson
has no canonical name, none is invented. The unnamed ones are the new ones.
