# style.md -- how timm/src is organized, and why

Decisions from the 2026-07 repo consolidation, revised after
the tiny-xai many-small-files split (2026-07-11). Read this
before adding or restructuring anything. Recipe for
converting a dir to this shape: tut.md.

## the two-repo rule

Everything lives in exactly two repos:

    timm/src    code: one flat dir per idea (this repo)
    timm/moot   data (tiny.cc/moot)

Data is NEVER copied into src. Code reaches it via a leading
`$MOOT` in file names: the MOOT env var if set, else
`~/gits/moot`. Every language implements the same tiny
`path()` expansion (see ezr2.py, tiny-xai/lib.lisp, lib.lua).
Copies of moot data in other repos were a mistake; do not
recreate them.

## one flat dir per idea, many small files

    xx/
      xx.*           the loader: settings, structs, help
                     text; loads every other engine file,
                     macros first, each exactly once
      <topic>.*      engine files, ONE topic each, sized to
                     one printed page column (~60 lines);
                     lines fit 65 chars
      <topic>-eg.*   tutorial + tests twin, one per engine
                     file (prose in block-comment markdown
                     stanzas; every demo asserts)
      xx-eg.*        test loader + CLI entry; loads the -eg
                     files in tutorial order
      INSTALL.md     curl installer; its FILES list IS the
                     reading order (`sh INSTALL.md list`)
      README.md      intro + generated doc-toc block
      pyproject.toml | xx.asd | *.rockspec  ~10-line pointer
                     (points at the loader; loader fans out)

- Install promise: `curl <raw>/xx/INSTALL.md | sh` fetches
  the whole idea. (This replaces the old one-wget-able-file
  rule: page-sized files beat one big file for reading,
  printing (`make xx.pdf`), and doc pages.)
- Loading is centralized: only the loader loads files; no
  per-file package lines, no load guards. New engine file =
  loader list + its -eg twin + INSTALL.md FILES.
- `-eg` files are executable transcripts: running them IS
  the tutorial; their asserts ARE the tests.
- No subdirs inside an idea dir. Uniform shape keeps all
  tooling a single loop over dirs; guard it jealously.

## comments: three altitudes, never mixed

    ;;;; / """ / --[[   file header: what this file is for
    ; / # / --          one-line note ABOVE each definition
                        (capitalized, no trailing period)
    docstrings          tests/demos ONLY: -h help text and
                        test-op read them at runtime

No figlet banners. No form feeds. The file split replaced
section markers: one file = one section.

## versions: tags, never dirs

- No v13/ dirs. Versions are git's job:
    latest:  raw.githubusercontent.com/timm/src/main/ezr2/ezr2.py
    pinned:  raw.githubusercontent.com/timm/src/ezr2-v13/ezr2/ezr2.py
- Tags are namespaced per idea: ezr2-v13, xomo-v12.
- A breaking rewrite is a NEW idea dir with a new name
  (ezr -> ezr2), not a version bump; the old dir moves to
  attic/.

## attic/, not deletion

Retired ideas move to attic/<name>/. Still greppable, still
browsable, marked dead by location.

## docs (all generated; never hand-edit outputs)

- `make doc` (repo root) loops every dir with an INSTALL.md:
  etc/doc.awk turns each source file into pycco input;
  etc/pyccot.py runs pycco with markdown tables enabled;
  etc/nav.py injects badges (home, src, code, tests, live
  per-dir ci, license, ...), a grouped toc (code pages on
  code pages, test pages on test pages), prev/next in
  INSTALL.md order, and links the title to the file on
  github; etc/toc.py rewrites README's <!-- doc-toc -->
  block. Output: docs/<dir>/*.html, COMMITTED to main
  (the site action only runs doc.py, not pycco).
- etc/doc.py builds the markdown site into _site/; the
  docs.yml action force-pushes it to gh-pages on every main
  push. gh-pages is bot-owned: never commit to it by hand.
- Study conclusions (REPORT.md style) stay hand-written,
  in-repo, beside the code, pointed to from README.

## tests: central runner, per-dir CI

- `make eg` runs every idea's tests. One workflow per dir
  (.github/workflows/tests-<dir>.yml), paths-filtered to
  that dir, so each dir gets its own live badge.
- Every test prints a diagnostic line BEFORE asserting;
  data-specific numbers gate on the dataset name.
- Long-form tutorials with REPL transcripts (tut.md style)
  get a REPLAY CHECKER (exemplar: luamine/tutchk.lua):
  re-execute every `[n]>` event in one session, diff each
  output against the transcript (floats at 10 significant
  digits — the grading rule), and run it as a step in that
  dir's tests workflow, so transcript rot fails CI.
  Environment-specific events (interpreter version,
  absolute paths) still execute but skip the diff.
  Transcripts are regenerated from real runs, never
  hand-edited.

## daily driving

    make sh     bash tuned by etc/bashrc (MOOT set; mace =
                `make -C ..` runs root targets from a dir)
    make xx.pdf one file -> pretty-printed pdf, a2ps
    sh xx/INSTALL.md list   the canonical file order

## taking one idea without the rest

    curl -fL <raw>/xx/INSTALL.md | sh    (whole idea), or
    git clone --filter=blob:none --sparse https://github.com/timm/src
    git sparse-checkout set ezr2
