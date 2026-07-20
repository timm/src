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
`path()` expansion (see ezr-py/ezr2.py, ezr-lisp/tiny-xai.lisp,
luamine/lib.lua).
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
  the tutorial; their asserts ARE the tests (full shape:
  see "-eg: tutorials that are tests" below).
- No subdirs inside an idea dir. Uniform shape keeps all
  tooling a single loop over dirs; guard it jealously.
- One app per dir. INSTALL.md, README.md and the manifest
  are dir-scoped, and the doc/badge tooling keys on
  `PROJ = basename(dir)` -- so a dir is exactly one
  shippable idea. Two languages = two apps = two dirs.
  sandbox/ is the sole exception: a multi-app scratch area,
  exempt from the scaffold and the doc pipeline (it renders
  nothing). A play idea graduates by moving to its own dir
  and gaining the scaffold (abc -> ezr-lua did this).

## comments: three altitudes, never mixed

    ;;;; / """ / --[[   file header: what this file is for
    docstrings          one line per function, where the
                        language has them (python, lisp);
                        lua uses a `-- note` line above.
                        One-liner defs (python) keep a
                        `# note` above instead.
    ## sections         a formfeed (^L) line precedes every
                        section marker, so make xx.pdf
                        paginates per section

No figlet banners. Section markers (`-- ##` etc) divide
the library file into topics; the ONLY form feeds are the
ones before markers (a DOUBLED form feed `\f\f` before a
marker forces a hard column break in `make xx.pdf`; the
single ones just pack greedily).

Signature convention (the big newcomer trap): in lua and
awk, parameters after the wide gap in a parameter list are
LOCALS, not arguments — `function f(a,b,    c,d)` takes
two arguments; c,d are scratch space. Callers never pass
them.

Prose stanzas (block comments / bare
`"""` blocks) open with a sentence, never a blank line; a
python block opening `word: ...` (e.g. `ezr2.py: ...`,
`INSTALL: ...`) is help text and doc.awk renders it
fenced verbatim.

## -eg: tutorials that are tests

Language agnostic (exemplars: ezr-lua/xai-eg.lua,
ezr-py/ezr2-eg.py). Every idea dir pairs xx.ext with
xx-eg.ext; there is no xx-doc -- a course keeps its
contents table in the -eg how-to stanza, and its
definitions and references in glossary.md.
The doc pipeline pyccos BOTH xx.ext and xx-eg.ext
(block-comment prose stanzas lift into the docs column;
see doc.awk).

Shape of xx-eg.ext:

- Sections mirror xx.ext's `## sections`, reordered
  simplest to hardest: lib sections first, then the
  domain code. One eg sub-table per section. Two extras
  bracket the lessons: an opening "how to run this
  course" stanza (FIRST: links to its own rendered pages
  on the site -- the pycco htmls and the glossary -- then
  install lines + four reading levels:
  skim beside xx-eg.out, run one test, retype at the
  REPL, port and diff + a contents table, lesson |
  section | ideas in lesson order, linking the glossary),
  and a lesson 0 teaching the
  implementation language to incomers from the course's
  assumed language ("lua for the impatient pythonista":
  trap demos, each printed and asserted, ending with a
  tiny self-auditing static analyzer).
- Each section is one lesson: an opening markdown stanza
  (a few lines of background, ending in
  `**Core ideas:** [key](../glossary.md#key)` join keys --
  keys short, github auto-anchors the headings); then
  dot-lists (`- **fn(sig)** one-two lines`, naming ONLY
  functions the tests call); then demos that print a
  tutor-pointable line BEFORE 1+ asserts (no crash =
  pass); then a closing stanza of exercises:
  0 = port this section's examples to another language,
  1 = (simple) tweak, predict, rerun,
  2 = write new code against this section's verbs.
- Runners derive from the structure: a section name runs
  its tests, --all walks the sections, -h prints the map.
  The file returns the eg table; its cli fires only when
  run as main.
- glossary.md (REPO ROOT, shared by every course --
  concepts are repo-level, courses sample them) holds one
  short `## key` entry per idea: grouped into coarse
  regions (coding / se / data / distance / optimize /
  labels / llm-era), alphabetical within a region, each
  entry opening with a *taught in* line pointing back at
  every lesson that links it, each region closing with
  the concepts still awaiting entries. Nobody reads it
  top to bottom: arrive by Core-ideas link, leave by
  back-pointer.
- No xx-doc: the contents table (lesson | section | ideas,
  in lesson order) lives in the -eg how-to stanza, and the
  references live in glossary.md as a *see:* line inside
  each entry (any general source in its tail section).
- Doc claims are executable (exemplar: xai-eg.lua):
  `--join` verifies lesson links land on doc headings,
  headings are all linked, and dot-list signatures
  resolve in the module (reflection; language builtins
  fall back to _G, so lesson 0 may teach them) -- plus a
  coverage line, taught/exported verbs. `--transcript` freezes the
  printed `--all` output to xx-eg.out (from a real run,
  never hand-edited; needs deterministic ties -- stable
  keysort, lexical tie-break on mode); `--check` diffs a
  fresh run against it. Lesson 2's exercise 0 pins the
  16807 generator (pseudocode + first three seeds), so
  student ports self-grade against xx-eg.out by diff.

Maintenance: -eg files (and glossary entries) are AUDITED,
never regenerated. If absent, create; ever after, edits only
ADD missing bits (new function -> dot-list line + test;
new idea -> glossary key). Deleting or rewriting existing
-eg or glossary content needs explicit per-item signoff from the
author: these files accrete hand-tuned teaching material
that regeneration would destroy (cf. luamine/tut.md).

## versions: tags, never dirs

- No v13/ dirs. Versions are git's job:
    latest:  raw.githubusercontent.com/timm/src/main/ezr-py/ezr2.py
    pinned:  raw.githubusercontent.com/timm/src/ezr-py-v13/ezr-py/ezr2.py
- Tags are namespaced per idea: ezr-py-v13, xomo-v12.
- A breaking rewrite is a NEW idea dir with a new name
  (ezr -> ezr-py), not a version bump; the old dir moves to
  attic/.

## attic/, not deletion

Retired ideas move to attic/<name>/. Still greppable, still
browsable, marked dead by location.

## docs (all generated; never hand-edit outputs)

- `make doc` (repo root) loops every dir with an INSTALL.md:
  etc/doc.awk turns each source file into pycco input;
  etc/pyccot.py runs pycco with markdown tables enabled;
  etc/nav.py injects badges (home, src, code, tests, live
  per-dir ci, license, ...) -- or, if a dir's README has a
  `<!-- badges -->` block, that block verbatim (a
  human-authored SSOT) -- plus prev/next in INSTALL.md
  order, per-page prose alignment (code pages right,
  tests/tutorial pages left) and links the title to the
  file on github; etc/toc.py rewrites README's
  <!-- doc-toc --> block (page order falls back to a
  glob for dirs without INSTALL.md).
  glossary.md is copied to the site root and, via the
  jekyll-relative-links plugin, every ../glossary.md#key
  link lands on glossary.html. One page per SOURCE FILE
  (we tried one page per ## section, and a grouped toc
  atop each page, and reverted both: whole-file pages
  are simpler and the markers still render as headings).
  Output: docs/<dir>/*.html, COMMITTED to main
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
    git sparse-checkout set ezr-py
