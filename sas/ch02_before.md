# Before Us (Skip This on First Read)

This chapter has one job: to say what is old here, so that what is new stands out
honestly. It cites much and proves nothing. Come back after Part II.

## Four crowded neighborhoods

Code with commentary, on one system, has a patron saint: Lions' commentary on UNIX,
the complete Edition 6 source plus a reading of it, bootlegged for decades and still
used in teaching [@lions77]. Spinellis later made code reading a discipline of its
own [@spinellis03]. We take from Lions the core structural move: print the system
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

Heuristics catalogs are the fourth: Hunt and Thomas [@hunt99], Glass's facts and
fallacies [@glass02], Ousterhout [@ousterhout18]. These argue by anecdote and
citation. We argue by flag: when this book says "always keep a baseline", that
baseline is one command-line option away, and you can run the ablation yourself.

Each neighborhood is crowded. Their intersection, as far as we can tell, is empty.
That intersection is this book.

## The grid and the ladder

Buse and Zimmermann once organized software analytics as a 3-by-3 grid: exploration,
analysis, and experimentation crossed with past, present, and future [@buse12]. It
was, and is, a useful catalog of what managers ask for. Yet we read the grid
differently. Its three rows are the three rungs of Pearl's ladder of causation:
seeing, explaining, and imagining alternatives [@pearl18]. Its three columns are a
clock. And a clock is a presentation dimension, not a reasoning one. Chapters 8, 9,
and 10 of this book make that point in code: planning, diagnosis, and repair turn out
to be one tree-difference mechanism pointed at the future, the past, and the
imperative. Time multiplies interfaces. It does not multiply mechanisms. Hence, in
this book, streaming is a crosscutting section in many chapters rather than a wing of
the taxonomy.

## Tasks, not tenses

For the taxonomy of tasks we reach further back, to knowledge engineering. Clancey
observed that expert systems mostly perform *heuristic classification* [@clancey85],
and the CommonKADS school cataloged the task types [@schreiber00]: analysis tasks
(predict, monitor, diagnose, classify, explain) and synthesis tasks (plan, design,
configure, repair). That catalog is finite. Part II covers the analysis tasks. Part
III covers the synthesis tasks, plus the modern additions (compress, negotiate,
stream). We know of no other short book that runs the whole KADS catalog on one
substrate.

There is one rung the old catalogs lack. Neither the grid nor the ladder nor KADS has
a place for *certification*: establishing that the seeing and the doing can be
trusted by another person, another runtime, or another kind of colleague. Buse and
Zimmermann tuck significance testing into a corner cell as a bullet point. We give it
Part IV. The 2026 problem, we will argue, lives on that rung, and it costs about
sixty lines.

## What is actually new

Firstly, the substrate: many seemingly different learners shown as one grouping idea
at different granularities, in runnable form. Secondly, the receipts: heuristics with
flags and seeds, not heuristics with anecdotes. Thirdly, the last two chapters: a
statistics gate and an agent-onboarding process, both demonstrated from one
repository's own history. To our knowledge the third item exists in no prior book at
all. That said, it may date the fastest. We accept the trade.
