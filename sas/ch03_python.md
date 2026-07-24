# A Little Python

This chapter shows the Python that the rest of the book assumes. Not all of Python.
Just the dozen moves that let 400 lines carry twenty algorithms. Readers fluent in
the language should skim the transcripts and move on.

## Cells, and asking forgiveness

Csv cells arrive as strings. One function coerces each cell: "23" becomes an int,
"-1e2" a float (csv cells can hide exponents), "True" and "False" become bools, "?"
stays as our mark for missing, and anything else stays text.

%%code src/lib.py thing

Note the shape of the type test. We do not inspect the
string to decide if it is a number. We try the conversion
and catch the failure. Python calls this **EAFP** (easier
to ask forgiveness than permission), as opposed to
**LBYL** (look before you leap). EAFP is shorter here and,
more importantly, it delegates the definition of "looks
like an int" to the one authority that matters, which is
`int` itself.

%%run python3 src/lib_eg.py thing

## One struct, one settings object

The whole book uses one generic record type: a class `o` whose instances are
dot-accessible bags of slots, and whose repr prints those slots sorted.

%%code src/about.py o

Two Python facts do the work: (a) every object carries a `__dict__` of its slots, so
one line of reflection prints anything; (b) `__repr__` is a protocol, so every object
in this book can appear in a transcript. Also, all settings live in a single instance
called `the`, defined in about.py and nowhere else. That file is this book's first
sighting of **SSOT** (single source of truth): one place to look, one place to
change.

%%run python3 src/lib_eg.py the

The command line can override any knob, because the flag parser walks `vars(the)` and
matches names. Watch the same test, run with `--p=1`:

%%run python3 src/lib_eg.py the --p=1

No parser was written for that flag. The settings object is the parser's schema, by
reflection. Hence a new knob costs one line, in one file.

## Streams, sorts, and transposes

Files are read by a generator, so no table is ever loaded twice or held whole when a
stream will do:

%%code src/lib.py csv

The `yield` makes `csv` lazy: callers pull one row at a time. Later chapters lean
hard on this laziness (e.g. the streaming chapter treats an unbounded source exactly
like a file). Three more idioms appear on nearly every page of this book, so we test
them once here: sorting by a computed key, never in place; transposing a table with
`zip(*rows)`; and list comprehensions as the default loop.

%%run python3 src/lib_eg.py idioms

## Dispatch by name

Every code file in this book ships with a matching `_eg` file of demos. Each demo
runs by its bare name from the command line. The trick is four lines of reflection.
The caller hands over its `globals()` as `g`, a plain dict mapping names to the
things they name. On any dict, `g.get(key, default)` returns `g[key]` if the key is
present, else the default. Hence: look up `"test_" + word`, falling back to a
function that just complains.

%%code src/lib.py main

Note that the seed is reset before every test. Hence any demo reproduces in
isolation, in any order, on any machine. This one habit does more for reproducibility
than any tool we know, and it costs one line.

## Lessons sighted

**EAFP** and **LBYL**; **SSOT**; duck typing (previewed;
defined properly in Chapter 5); generators and laziness;
reflection via `vars` and `globals`; sort-by-key;
`zip(*rows)`; the seeded-demo ritual. Just to repeat a
point made above: none of this is advanced Python. That
is the point. Relentless basics, then one or two sharp
tricks.
