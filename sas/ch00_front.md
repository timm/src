# Preface {.unnumbered}

Much of what we do in software engineering and AI comes from a small number of core
ideas, wrapped in vast amounts of ceremony. This book tries to show the core without
the ceremony. So we set ourselves a task: teach 200 heuristics, tips, tricks, and
traps from scripting, SE, and AI, using as little code as possible. Chasing that task
produced EZR (an incremental active learner whose conclusions are small decision
trees), about 400 lines of Python with no dependencies beyond the standard library
[@menzies26ezr]. We do not say EZR is the only good toolkit. It is the one this hunt
left us, and it is small enough to read. Around it we hang 123 lessons. Many appear
more than once, seen from different heights, so the count of sightings runs past 200.

In the age of large language models, it is said that software is free: ask, and code
appears. We agree, in part. Most software is now cheap. Good software is very, very
expensive. Good software is maintainable, clear enough for a stranger to understand,
and built so the next feature has somewhere to go. Good software is not rushed out
the door and left to gather dirt. It is inspected with care, cleaned regularly, and
refactored, over and over, to be made simpler. That work is the expensive part, and
that work is what this book teaches.

Every chapter follows the same ritual: (a) set a seed; (b) run a small program; (c)
paste its output, untouched; (d) end in an assert. Nothing you read here was typed
from memory. The build tool re-runs every example and fails if the output drifts.^[If
you find a transcript in this book that does not reproduce, that is a bug. Please
report it.]

## How to read this book {.unnumbered}

Read Chapter 1, then skip Chapter 2. That chapter places this book against fifty
years of prior work and it will mean more after you have met the code. Come back to
it late, or never.

Chapters 3 to 5 build the substrate: a little Python, a little maths, then columns,
tables, and distance. All later chapters stand on these three. After that, each
chapter is one application with a fun name and a serious bracket (e.g. "The Bouncer
(anomaly detection)"). The bracketed term is the index entry that joins that chapter
to the standard literature. Read the applications in any order.

You need Python 3.12 or later, curl, and make. You do not need pip. The number of
packages this book installs is 0 + 0 = 0. Example data comes from MOOT (a public
collection of 120+ multi-objective SE optimization tasks)^[`github.com/timm/moot`;
fetched by `make data`.] and one table runs through most demos: auto93, 398 cars,
where we want to minimize weight while maximizing acceleration and miles per gallon.
