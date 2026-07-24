# Simple Ain't Stupid (book sources)

Markdown source, BibTeX refs, code included by build,
tufte-latex as the compile target.

## Layout

    ch*.md       chapter sources (prose + directives)
    src/         about.py (config), lib.py (substrate),
                 lib_eg.py (demos/tests)
    etc/weave.py expands %%file %%code %%run directives
    data/        example tables, fetched from MOOT
    refs.bib     back-of-book references (hand-typed;
                 spot-check DOIs before relying on them)
    meta.yaml    pandoc metadata (documentclass
                 tufte-book)
    build/       generated. Never hand-edit anything here.

## Build

    make data    # once: fetch auto93.csv
    make check   # run all demos; any assert kills it
    make weave   # build/book.md with live transcripts
    make pdf     # needs pandoc + xelatex + tufte-latex

## Rules of the house

1. Transcripts are captured at build time, never typed.
   If a demo's output drifts, the build fails. Good.
2. All settings live in src/about.py. One seed plus that
   file plus any --key=val flags fully describes any
   experiment in the book.
3. Code lines stay under 66 characters (make lines).
4. build/ is bot-owned. Edit sources, not outputs.
