# tut.md -- recipe: restructure xx + xx-eg into doc'd form

Meta-prompt. Give an agent this file plus a target project
dir; it should reproduce what tiny-xai got in 2026-07.
Worked exemplar: tiny-xai/tiny-xai.lisp + tiny-xai-eg.lisp.

## The three layers (never mix altitudes)

    docstring    contract, one line, machine-readable
    block prose  why these 4-5 functions exist together
    eg stanza    motivation + story, paragraphs + tables

## 1. The library file (xx.lisp / xx.py / xx.lua)

Reference document. Optimize for LOOKUP, not narrative
(the -eg file carries the story).

- Split into single-idea blocks. Markers by language:
  `;;; ## Title` / `#-- Title ----` / `-- ## Title`.
- A block = ONE idea. Lifecycle verbs get separate blocks
  (construction / update / query). A helper sits beside its
  only caller. Blocks need not be equal-sized.
- Block order answers a reader's questions in sequence:
  what exists? (structs) -> how do I touch it? (accessors,
  macros first -- compile-time constraint) -> how does data
  live? (construct/update/query) -> what does it DO?
  (domain story) -> how is it judged? (stats) -> what holds
  it up? (lib) -> how do I start it? (main).
- Each block: form feed line, marker, figlet banner
  (`figlet -f mini -W word`), then 2-5 lines of terse prose:
  the idea, its `functions` backticked, one non-obvious
  constraint. NO examples (they live in -eg).
- Keep one-line docstrings on every function: contract
  facts the name can't carry ("w<0 removes", "? = yes").
  The moment a docstring wants two lines, that content
  belongs to block prose or an eg stanza.
- Reorder mechanically: parse toplevel forms, reassemble,
  assert every form placed exactly once. Never retype code.

## 2. The tutorial file (xx-eg.lisp etc)

A tutorial is made of DEMONSTRATIONS, not explanations.
Prose only says "now watch this" and "notice that".

Stanza skeleton, in order, every stanza:

    form feed
    #|                      (lang's block comment = markdown)
    ## Heading
    motivation prose, K&R voice ("you", direct, admits limits)
    pasted REAL output, indented   <- when data must be SEEN
    "Notice: ..." pointer sentence
    | call | returns | what |      <- signature table
    |#
    (defun eg--name ...)           <- the demo

Rules:

- ONE RUNNING EXAMPLE, RE-VIEWED. Show a small concrete
  dataset in the first stanza; every later concept acts on
  that same data (fold ITS columns, re-sort ITS rows, label
  ITS rows). Each new idea = a new thing happening to data
  the reader already knows.
- No noun without an instance: say "table", show rows,
  within a screen.
- Order by demo difficulty (cognitive load), NOT by the
  library's dependency order. If the two files have the
  same order everywhere, the eg file is adding nothing.
- Comments carry the show; code stays dumb. Demo code must
  be simpler than the thing it demonstrates -- no helper
  plumbing before the first demo. Sample tables/traces go
  in the stanza, pasted from a real run (state that in the
  intro). NEVER hand-type a trace; every hand-copied trace
  eventually contains a fabricated cell.
- Signature table: real lambda lists as call forms, minus
  &aux/&optional noise; return value; one-liner each.
- Demos both PRINT (convinces the reader) and ASSERT
  (convinces the machine). Keep every existing assert when
  restructuring; move one to a truer home if needed.
- eg-- functions found by introspection; no registration.
- Arc: zero -> someplace cool. Last demo = the whole rig in
  one function; studies after; runners last.

## 3. Gates (all must pass before commit)

    sbcl suite (--all), and the other runtime (clisp etc)
    line length: awk 'length > 65' *.lisp  -> nothing
    every pre-existing assert still present
    form feed before every block/stanza
    ASDF / package load still works
    site render: python3 etc/doc.py _site; check the pages

## 4. Pipeline facts (already built; do not rebuild)

- etc/doc.py: `;;; ##`-style blocks -> reference pages;
  `#| markdown |#` stanzas -> tutorial pages. Pushing main
  rebuilds gh-pages via .github/workflows/docs.yml.
- make NAME.pdf: a2ps; form feeds start new columns, packed
  (break only when the block overflows the column; LPC knob).
- Data via $MOOT (env, else ~/gits/moot). Never copy data.
- TODO not yet built: Output: splicing -- run each eg--,
  paste its output under the demo, CI-diff to verify.

## Voice calibration

K&R ch1 (repltut/kr_ch1.md): direct, "you", tiny concrete
examples first, admits what is left out. The SPE/EZR paper:
conversational-but-terse, `names` backticked inline. Not:
lecture-notes voice that explains without showing.
