# style.md -- how timm/src is organized, and why

Decisions from the 2026-07 repo-consolidation discussion.
Read this before adding or restructuring anything.

## the two-repo rule

Everything lives in exactly two repos:

    timm/src    code: one flat dir per idea (this repo)
    timm/moot   data (tiny.cc/moot)

Data is NEVER copied into src. Code reaches it via a leading
`$MOOT` in file names: the MOOT env var if set, else
`~/gits/moot`. Every language implements the same tiny
`path()` expansion (see ezr2.py, tiny-xai.lisp, lib.lua).
Copies of moot data in other repos were a mistake; do not
recreate them.

## one flat dir per idea

    xx/
      xx.py|.lisp|.lua   the library: ONE wget-able file
      xx-eg.*            examples + tests + CLI (loads xx)
      README.md          3-line stub: title, sentence, site link
      pyproject.toml | xx.asd | *.rockspec   ~10-line pointer

- The library file stands alone: `wget` one raw file and it
  works. That promise outranks every other convention here.
- `-eg` files are executable transcripts (KM-script style):
  running them IS the tutorial; diffing their output against
  a committed golden file IS the test.
- Packaging manifests are pointers, nothing more. All three
  ecosystems accept per-dir manifests in a monorepo:
  pip: `pip install "git+https://github.com/timm/src#subdirectory=ezr2"`
  quicklisp: clone into ~/quicklisp/local-projects (asdf scans subdirs)
  luarocks: rockspec build.modules maps `xx/xx.lua` to module `xx`
- No subdirs inside an idea dir. Uniform shape is what keeps
  all tooling a single loop over dirs; one exception and the
  loop grows flags forever. Guard the shape jealously.

## versions: tags, never dirs

- No v13/ dirs. Versions are git's job:
    latest:  raw.githubusercontent.com/timm/src/main/ezr2/ezr2.py
    pinned:  raw.githubusercontent.com/timm/src/ezr2-v13/ezr2/ezr2.py
- Tags are namespaced per idea: ezr2-v13, xomo-v12.
- CI attaches a per-dir zip to each release (git archive
  TAG DIR/) so nobody downloads the whole repo for one idea.
- A breaking rewrite is a NEW idea dir with a new name
  (ezr -> ezr2), not a version bump; the old dir moves to
  attic/.

## attic/, not deletion

Retired ideas move to attic/<name>/. Still greppable, still
browsable, marked dead by location. Deleting means git
archaeology later.

## docs

- Source docstring/header is the single source of truth:
  settings() parses it for CLI defaults; the site renders it;
  per-dir README is a 3-line stub that cannot drift.
- Generated html lives ONLY on the gh-pages branch, written
  by CI. Never commit generated files to main.
- Study conclusions (REPORT.md style) stay hand-written,
  in-repo, beside the code that produced them.

## literate layout inside a library file

(Full recipe for restructuring a project into this form,
with the tutorial-stanza skeleton and gates: see tut.md.)


- Prose per idea-block (every 4-5 functions), not per
  function. Lisp comment hierarchy: ;;;; file, ;;; block
  prose, ;; in-function.
- block[0] = preview: a motivating worked example.
  block[1] = theory: succinct ideas behind what follows.
- Blocks separated by form-feed (^L): editors page through
  them; a small awk turns them into html pages with
  prev/next links.

## taking one idea without the rest

    wget one file (see each dir's INSTALL), or
    git clone --filter=blob:none --sparse https://github.com/timm/src
    git sparse-checkout set ezr2
