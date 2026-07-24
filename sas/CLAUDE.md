# CLAUDE.md

Book sources for "Simple Ain't Stupid: 200 Lessons in SE,
AI, and Python from 2000 Lines of Code" (Menzies). Prose
in ch*.md, code in src/, weaver in etc/, output in build/.

## TL;DR for claude

After every edit: `make check` (all demos must pass), then
`make weave` (directives must expand), then `make lines`
(no code line over 65 chars). A change that breaks any of
these does not ship.

## Read before editing

Read README.md, then etc/style.md, then this file, in that
order. style.md governs all prose, including its list of
banned LLM tells. Worked exemplars, by path:

- chapter shape:    ch04_maths.md
- demo/test shape:  src/lib_eg.py
- library shape:    src/lib.py
- config shape:     src/about.py (the ONLY settings file)

Copy shapes from these files. Do not invent new shapes.

## Hard rules

1. Transcripts are never hand-typed. Program output enters
   a chapter only via a %%run directive, captured by
   etc/weave.py at build time. If you find yourself typing
   sample output into prose, stop.
2. build/ is bot-owned. Never hand-edit anything in it.
   Regenerate via make.
3. data/ is fetched (make data), never edited.
4. refs.bib is add-only. Entries are hand-typed, so any
   entry you add must carry real bibliographic data you
   have verified. Never delete or "clean up" existing
   entries without being asked.
5. Chapters are audit-and-add. Never regenerate a whole
   chapter; that destroys hand-tuned teaching. Edit the
   smallest span that fixes the problem.
6. Every new demo in src/*_eg.py must (a) reseed at the
   top of test_all's loop, (b) print something, (c) end in
   an assert.
7. All new knobs go in src/about.py and nowhere else.
8. Reorder code mechanically, never retype it. Move
   top-level forms whole.

## Stop and ask

Stop and ask the human before: deleting any file; changing
a seed; changing an existing assert; touching meta.yaml's
documentclass; or any task that seems to require breaking
a hard rule above.

## Directives (read by etc/weave.py)

    %%file PATH        include a whole file
    %%code PATH NAME   include one def or class, by name
    %%run  CMD...      run CMD from repo root; include
                       stdout. Failure kills the build.

## Book conventions

- Chapters in Parts II-IV are applications: fun title plus
  a bracketed canonical task name, e.g. "The Bouncer
  (anomaly detection)". The bracket is the index entry.
- Lessons with canonical names get the name in bold at
  first use (e.g. **SSOT**, **EAFP**). Core technical
  terms are defined exactly once, in one flagged
  paragraph; elsewhere, point to it.
- Each chapter ends with a short "Lessons sighted"
  section.
- Streaming variants appear as "...on the night shift"
  sections inside chapters, not as separate chapters.
- No diagrams. Prose, code, transcripts only.

## State of the book

DONE (Part I, The Substrate):
  ch00_front.md      preface, how to read
  ch01_simple.md     thesis, the axiom, the ritual
  ch02_before.md     related work (flagged skippable)
  ch03_python.md     the Python floor
  ch04_maths.md      the maths floor
  ch05_substrate.md  tables, roles, distance to heaven
  src/about.py, src/lib.py, src/lib_eg.py: all green.

NEXT (Part II, Reading the World), in order:
  ch06 The Fortune Teller (prediction)      kNN + leaf
  ch07 The Bouncer (anomaly detection)      centroid dist
  ch08 The Smoke Detector (drift)           add(inc=-1)
  ch09 The Mechanic (diagnosis)             leaf contrast
  ch10 The ER Nurse (triage)                complement NB
  ch11 The Tour Guide (explanation)         tree + rules
       + section: The Gossip Columnist (feature assoc.)

THEN (Part III, Changing the World):
  ch12 The Bargain Hunter (optimization / active learning)
  ch13 The Travel Agent (planning)
  ch14 The Cheap Fix (repair)
  ch15 The Kitbasher (synthesis; incl. what-if)
  ch16 The Curator (compression / prototypes)
  ch17 The Marriage Counselor (multi-objective trade-off)
  ch18 The Short-Order Cook (streaming)
       + section: The Specials Board (trends)
  ch19 The Beat Reporter (lifelong active learning)

THEN (Part IV, Trusting the World):
  ch20 The Referee (statistical certification)
  ch21 The Apprentice (agent onboarding; this file is its
       primary exhibit)

New engine code goes in new src files (e.g. src/knn.py
with src/knn_eg.py), importing from lib. Keep lib.py under
250 lines; if a function serves only one chapter, it lives
in that chapter's engine file, not in lib.
