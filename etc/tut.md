# tut.md -- recipe: restructure an idea dir into house style

Meta-prompt. Give an agent this file plus a target project
dir; it should reproduce what tiny-xai got on 2026-07-11.
Worked exemplar: the tiny-xai/ dir (27 files). Shape and
rationale: style.md.

## The three layers (never mix altitudes)

    file header   ;;;;-style prose: what this file is for
    function note one-line comment ABOVE each definition
                  (contract facts the name can't carry:
                  "w<0 removes", "? = yes"); tests keep
                  these as DOCSTRINGS instead (-h and
                  test-op read them at runtime)
    eg stanza     motivation + story, paragraphs + tables,
                  in block-comment markdown

## 1. Split the library into page-sized files

Each engine file = ONE topic, sized to a printed page
column (~60 lines, 65 chars wide). One `<topic>-eg` twin
per engine file. Typical topics, in reading order (this
order answers a reader's questions in sequence):

    xx.*        loader: package, constants, help text,
                settings, structs; loads all other engine
                files, macros first, each exactly once
    macros      accessors, reader macros (compile-time
                constraint: must load first)
    lib         strings, csv, $MOOT path expansion
    rand        seeded randomness (reproducible everywhere)
    cols/query/tbl   construct / update / query the data
    <domain>    what the idea actually DOES (dist, acquire,
                bins, tree, ...)
    stats       how results are judged
    main        cli, help, top-level rigs

Rules:

- Loading is centralized: no per-file package lines, no
  load guards. Only the loader loads.
- A helper sits beside its only caller. Files need not be
  equal-sized; they must not exceed a page column.
- Reorder mechanically: move toplevel forms, assert every
  form placed exactly once. Never retype code. Pinned test
  asserts make the refactor a provable no-op.
- INSTALL.md: FILES lists every file, reading order first
  (engine, then -eg files in tutorial order). Everything
  keys off `sh INSTALL.md list`: doc page order, prev/next,
  README toc, badge counts.

## 2. The tutorial files (<topic>-eg.*)

A tutorial is made of DEMONSTRATIONS, not explanations.
Prose only says "now watch this" and "notice that".
Stanza skeleton, every stanza:

    #|                      (lang's block comment = markdown)
    ## Heading
    motivation prose, K&R voice ("you", direct, admits limits)
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

## 3. Wire into the shared tooling

- .github/workflows/tests-<dir>.yml: copy an existing one;
  paths-filter to the dir; own badge.
- `make doc` picks the dir up automatically once
  INSTALL.md exists (pycco pages into docs/<dir>/, badges,
  toc, prev/next, README doc-toc block). etc/doc.awk may
  need the language's comment syntax taught to it (lisp
  done; python/lua pending).
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
    TODO not yet built: output splicing the other way --
    run each demo, paste its output back under the stanza

## Voice calibration

K&R ch1: direct, "you", tiny concrete examples first,
admits what is left out. The SPE/EZR paper:
conversational-but-terse, `names` backticked inline. Not:
lecture-notes voice that explains without showing.
