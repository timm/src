---
name: choose
description: Pick what to work on: Newell's toolkit-x-bottleneck audit, plus the protected Wheeler slice for strange things. Use at HOWTO steps 1, 3, 4, 7.
---

# choose

## Short form

- Audit your toolkit: what are you reliably good at?
- Scan the era's bottlenecks; force the two lists to collide.
- Default = Newell (price work by the era).
- Protected slice = Wheeler (which strange thing, and why is nobody looking?).
- Keep the tension; do not resolve it.

## Detail

## Before any of this: Newell's springboard

Everything below is about reporting research. This part
is about choosing it, and it comes first because no
amount of style rescues the wrong project. Allen Newell's
research heuristics (as passed down through his talks and
the Newell Award tradition; see also his "Desires and
Diversions") reduce to two lists and a collision:

- Good techniques: the tools you are unusually good at,
  honed until reliable.
- Good problems: questions of the current era whose
  answers matter, in theory or in practice.

Neither list alone is research. Technique without a
problem is a hammer collection; a problem without
technique is a wish. The move is to force the collision:
take the thing you do better than most people and aim it
at a bottleneck that is live right now.

The procedure, run before any paper starts:

1. Audit the toolkit. Name, specifically, what we are
   good at that others are not. (Here: frugal AI --
   tiny incremental learners, label-economics, active
   learning on 100+ public SE tasks, statistics that
   gate claims.)
2. Scan the era's bottlenecks. Not eternal problems;
   current ones. This is what the lit pipeline is FOR:
   the search, the knee, the coding grid, and the
   open-issues pivot are a bottleneck scanner.
3. Map one onto the other and write the collision down
   as one sentence. That sentence is the elevator
   speech (page 1, \begin{quote}{\em ...}\end{quote}).
   If step 3 produces no sentence, return to step 2
   with a different bottleneck; do not lower the bar by
   inflating the toolkit.

Newell's working adages, which the house already
practices under other names:

- Respond to real phenomena. Anchor to observable
  problems and real data, not abstractions. (Hence MOOT
  tasks, not synthetic suites.)
- Dive into the details. The insight is in the messy
  implementation, which is why we read code and show
  code. (Hence %%code and seeded transcripts.)
- Fly into the wind. Do not chase the consensus trend;
  radical improvement usually means bucking it. (Hence
  "Is better data better than better data miners?" and
  frugal methods in a scale-obsessed era.)
- Just do something. Build the throw-away script, run
  the small case, expose the flaw early. (Hence
  fetch.py before a review protocol, a demo before a
  theory section.)

## The Wheeler counterweight (keep this tension; do not
## resolve it)

Against Newell's "most relevant problems of the era"
stands Wheeler's advice: in any field, find the strangest
thing, and explore it. The historical record backs
Wheeler more often than is comfortable. Boole's logic
waited some eighty years for Shannon to make it switching
circuits. Perceptrons waited half a century to become
deep learning, surviving two winters on the way. Logic
programming looked like a dead end until its ideas
resurfaced in Erlang's telecom systems. None of these
were the relevant problems of their era; all of them were
the strangest thing in the room.

So the house holds both, unreconciled:

- Newell prices the work by the era: relevance now,
  impact now. His procedure (above) is the default; most
  projects should pass his audit.
- Wheeler prices the work by the anomaly: the result that
  does not fit, the question nobody thinks to ask. Some
  fraction of the portfolio -- a chapter, a side study,
  one RQ in a larger paper -- should pass HIS audit
  instead: which strange thing, and why is nobody else
  looking at it?
- The two meet more often than they fight: a strange
  thing found inside a live bottleneck is the best
  project there is (an anomaly in a relevant place is
  both a Wheeler find and a Newell bottleneck). The
  Observations subsection exists partly to catch these:
  a surprise in our own results is a Wheeler seed for
  the next paper.

Audit line for any new project, now two-headed: EITHER
say in one breath which technique, which bottleneck, and
why now -- OR say which strange thing, and why nobody
else is looking. A project that can say neither is not a
project. A project that can say both, start immediately.
