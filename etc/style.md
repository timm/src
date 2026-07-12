# style.md -- how timm/src is organized, and why

Decisions from the 2026-07 repo consolidation (including
trying, then reverting, many-tiny-files). Read this
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

## one flat dir per idea, few files

    xx/
      xx.*           the library: ONE file, sectioned by
                     `-- ##` / `;;; ##` / `#--` markers,
                     one topic per section
      xx-eg.*        tutorial + tests: markdown stanzas +
                     demos, one section per library section
      dtlz.* etc     demos; report.* rebuilds REPORT.md
      INSTALL.md     curl installer; FILES = reading order
      README.md      intro + generated doc-toc block
      pyproject.toml | xx.asd | *.rockspec  ~10-line pointer

- Install promise: `curl <raw>/xx/INSTALL.md | sh` fetches
  the whole idea (a handful of files).
- We tried many tiny files (2026-07-11/12) and reverted:
  section markers give the same reading units without the
  file sprawl; the doc pipeline renders markers as
  headings either way.
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

No figlet banners. No form feeds. Section markers
(`-- ##` etc) divide the library file into topics.

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
