# tut.md -- recipe: restructure an idea dir into house style

Meta-prompt. Give an agent this file plus a target project
dir; it should reproduce what ezr-py/ezr-lisp/luamine got in
2026-07. Worked exemplars: ezr-py/xai.py + xai-eg.py. Shape
and rationale: style.md.

## The three layers (never mix altitudes)

    file header   ;;;;-style prose: what this file is for
    docstring     one line per function (python, lisp):
                  contract facts the name can't carry
                  ("w<0 removes", "? = yes"); lua uses a
                  -- note line above; -h and test-op read
                  test docstrings at runtime
    eg stanza     motivation + story, paragraphs + tables,
                  in block-comment markdown

## 1. The library file (xx.py / xx.lisp / xx.lua)

ONE file, sectioned by markers (`#-- name ----`,
`;;; ## name`, `-- ## name`); each section is one topic,
sized to a printed page column (~60 lines, 65 chars wide).
Canonical section order (a reader's questions in sequence):
lib (strings, csv, $MOOT paths) -> rand -> cols/query/tbl
(construct / update / query) -> the domain story (dist,
acquire, bins, tree, ...) -> stats -> main. A helper sits
beside its only caller. Reorder mechanically: move toplevel
forms, never retype; pinned test asserts make the refactor
a provable no-op. (We tried one-file-per-topic and
reverted; markers beat file sprawl.)

## 2. The tutorial file (xx-eg.*)

A tutorial is made of DEMONSTRATIONS, not explanations.
Prose only says "now watch this" and "notice that".
Stanza skeleton, every stanza:

    ;;; ## name                    <- section marker (after \f)
    #|                      (lang's block comment = markdown)
    motivation prose, K&R voice ("you", direct, admits limits)
                            (marker IS the heading; stanza
                             opens with prose, NEVER blank)
    pasted REAL output, indented   <- when data must be SEEN
    "Notice: ..." pointer sentence
    | call | returns | what |      <- signature table
    |#
    (defun eg--name ...)           <- the demo

- ONE RUNNING EXAMPLE, RE-VIEWED. Show a small concrete
  dataset in the first stanza; every later concept acts on
  that same data. Each new idea = a new thing happening to
  data the reader already knows.
- No noun without an instance: say "table", show rows.
- Tutorial order (the -eg load list in xx-eg) is cognitive
  load order, NOT the engine's dependency order.
- Demo code must be simpler than the thing it demonstrates.
  Traces are pasted from real runs; NEVER hand-typed.
- Demos both PRINT (convinces the reader) and ASSERT
  (convinces the machine). Keep every existing assert.
- eg-- functions found by introspection; no registration.
- Arc: zero -> someplace cool. Last demo = the whole rig;
  studies after; runners and CLI entry live in xx-eg.

Lesson-course variant (exemplar: ezr-lua/xai-eg.lua; full
spec in style.md "-eg: tutorials that are tests"). When the -eg is taught
as a weekly course, each section additionally gets:

- a "how to run this course" stanza up top (links to
  its own rendered site pages first, then install + the
  four reading levels + a contents table, lesson | section
  | ideas, linking the glossary) and a lesson 0 teaching the
  implementation language to incomers from the assumed
  language, traps demoed and asserted;
- an opening stanza `### Lesson N: title` ending in
  `**Core ideas:** [key](../glossary.md#key)` join keys
  into the repo-root shared glossary;
- dot-lists (`- **fn(sig)** 1-2 lines`) naming ONLY the
  functions that section's tests call;
- a closing exercises stanza: 0 = port these examples to
  another language (lesson 2's exercise 0 pins the 16807
  generator + its first three seeds, so ports self-grade
  by diff against xx-eg.out), 1 = (simple) tweak+predict,
  2 = write code against the section's verbs;
- one eg sub-table per section; runners, --all and -h are
  DERIVED from that structure, never hand-listed; the
  file returns the eg table, cli fires only when main.

## 2b. The lecture notes (glossary.md)

Definitions live in the REPO-ROOT glossary.md, shared by
every course: one `## key` entry per idea, region-grouped,
alphabetical within a region, each entry carrying a
*taught in* back-pointer line, a *see:* [^key] footnote
where one applies -- citing a well-cited, peer-reviewed
paper in MLA style with a DOI or stable link (so a reader
can verify the paper is real), all such `[^key]:`
definitions collected in a `# references` block at file
end -- and each region listing the concepts still awaiting
entries. There is no xx-doc: the contents table (lesson |
section | ideas, in lesson order) lives in the -eg how-to
stanza. All of it audited, never regenerated (style.md
maintenance rule).

## 3. Wire into the shared tooling

- .github/workflows/tests-<dir>.yml: copy an existing one;
  paths-filter to the dir; own badge.
- `make doc` picks the dir up automatically once
  INSTALL.md exists (pycco pages into docs/<dir>/, badges,
  toc, prev/next, README doc-toc block). etc/doc.awk may
  need a NEW language's comment syntax taught to it
  (lisp, python, lua done).
- README.md: intro, REPORT.md pointer if any, Install
  lines, `<!-- doc-toc -->` block (generated; do not
  hand-edit).

## 4. Gates (all must pass before commit)

    the dir's own suite (make eg runs all dirs)
    second runtime if the language has one (sbcl AND clisp)
    line length: awk 'length > 65' <dir>/*.*  -> nothing
    every pre-existing assert still present
    package manifest still loads (asdf/pip/luarocks)
    make doc; python3 etc/doc.py; check the pages render
    if the dir carries a REPL-transcript tutorial: port the
    replay checker (exemplar: luamine/tutchk.lua) and add it
    to the dir's tests workflow -- every [n]> event
    re-executed, outputs diffed, env-specific events skipped
    if the dir carries a lesson course: --join passes (its
    own doc links land, its dot-list signatures resolve) and
    --check passes (a fresh --all reproduces the frozen
    xx-eg.out transcript); both are eg verbs, exemplar
    ezr-lua/xai-eg.lua. `make check` adds the repo-wide half
    (etc/join.py): every glossary heading is taught by SOME
    course -- since the glossary is shared, no single course
    can own that check
    TODO not yet built: output splicing the other way --
    run each demo, paste its output back under the stanza
    (xx-eg.out now captures the output; the splice remains)

## Voice calibration

K&R ch1: direct, "you", tiny concrete examples first,
admits what is left out. The SPE/EZR paper:
conversational-but-terse, `names` backticked inline. Not:
lecture-notes voice that explains without showing.
