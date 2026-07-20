# STYLE.md — how tiny-xai gets written

Tiny functions. Beautiful code. Lines fit 65 chars
(`awk 'length > 65' *.lisp`).
Routine testing is sbcl only
(`sbcl --script tiny-xai-eg.lisp --all`, ~0.1s; also
`make eg` at the repo root); CLISP (~200x slower) is an
occasional pre-commit portability gate. Code stays
portable to both.

## Conventions

- **Lots of small functions.** One job each, ~10 lines.
  Helpers earn a name on second use; single-caller
  helpers get folded back in.
- **One library file**, sectioned by `;;; ## Name` markers,
  one topic per section, each sized to a printed page
  column (`make tiny-xai.pdf` at the repo root prints it).
  New topic = new marker section + its egs in
  tiny-xai-eg.lisp + nothing else (INSTALL.md lists whole
  files, not sections).
- **cols = lists** (dolist, push + nreverse);
  **rows = list** (pushed, newest first);
  **each row = a vector** (O(1) `elt` by column index).
- `&aux` for locals; `aif`/`it` anaphora (`it` belongs to
  `aif`; the settings global is `*my*`); `$slot` reader
  macro = `(ats i 'slot)`; `?` macro for nested access;
  `add` returns the value added (chainable); num/sym
  summaries dispatch via CLOS, never type-ifs.
- **`$` hard-codes `i`.** Any function or method using
  `$n`, `$mu`, ... MUST bind its primary object to `i`
  (`(defmethod add ((i num) v) ...)`; tests use
  `&aux (i (make-tbl ...))`).
- **Settings slots ARE the CLI flags.** `settings` uses
  `(:conc-name)` and `--seed`-style slot names; `cli`
  string-matches argv against slot names and `-h` prints
  them as OPTIONS. Rename a slot = rename a flag; a slot
  nothing reads is a lie in the help text.
- Structs needing smart construction hide the default
  constructor as `%make-foo` and hand-write a public
  `make-foo` (see cols, tbl).
- Numeric guards: `(+ denom +tiny+)` blocks
  divide-by-zero; `+big+` / `(- +big+)` seed min/max
  scans.
- Randomness is a hand-rolled Lehmer `rand`/`rint` plus
  a seeded `shuffle` over `*seed*`; never CL `random`.
  Reset `(setf *seed* (? *my* --seed))` before every
  test, study, or model run so runs reproduce.
- Portability rides on `#+sbcl` / `#+clisp` reader
  conditionals (slot listing, argv, warning muffling,
  getenv).
- Header roles: trailing `-`, `+`, `!` mark goals (`-`
  sets weight 0, others 1), trailing `X` = ignore,
  leading uppercase = numeric. `--file` paths may start
  `$MOOT` (env var, else HOME/gits/moot; see `path`).
- Every file opens with a one-line vim modeline, then a
  `;;;;` prose block saying what the file is for. No
  figlet banners.
- **Function notes, not docstrings, in the engine.**
  Every engine defun/defmethod/defmacro carries a
  one-line column-0 `; Comment` directly ABOVE it, first
  letter capitalized, no trailing period. Tests
  (`eg--*`, `study--*`) instead keep one-line DOCSTRINGS
  (same rule) because `help` (-h) and asdf's test-op
  print the TESTS and STUDIES lists from
  `(documentation s 'function)`.
- lisp-lang.org style guide: earmuffs on specials
  (`*my*`, `*seed*`, `*label*`); `-p` predicates
  (`grow-p`, `has-p`); `+tiny+`/`+big+` constants;
  `when`/`unless` over one-armed `if`;
  license lives ONLY in LICENSE.md and README.
- Tests: `eg--*` = unit tests (`--all`); `study--*` =
  experiment sweeps (`--study` or per flag). Every test
  asserts; dataset-specific numbers gate on
  `(search "auto93" ...)`. Tests print a diagnostic
  line (`~&...`) BEFORE asserting; study docstrings
  start `Rq0:`/`Rq1:`/`Rq2:`; big inputs get capped
  first via `few` and `--cap`. The `-eg` files are also
  the tutorial: prose lives in `#| markdown |#` blocks,
  one block per demo, in reading order (the load list in
  `tiny-xai-eg.lisp`).
- Reference implementation: `../ezr2/ezr2.py`. Prefer
  its shapes; numeric bins come from exact sorted split
  points, never fixed-width approximations; pinned
  asserts make every refactor a provable no-op.

## Files

    tiny-xai.lisp     the engine: package, settings, structs,
                      then one ;;; ## section per topic
    tiny-xai-eg.lisp  tutorial + tests + script entry
    dtlz.lisp         external-model demo (*label* hook)
    report.lisp       rebuilds REPORT.md (worker + --hist)
    tiny-xai.asd      systems: tiny-xai, /eg, /dtlz
    INSTALL.md        curl installer; FILES = reading order
    REPORT.md         the RQ0-RQ2b study write-up

**TL;DR for claude: after any code change run
`sbcl --script tiny-xai-eg.lisp --all` (and clisp before
committing); after any algorithm change rerun report.lisp
and refresh REPORT.md; keep function notes (engine) and
test docstrings (eg) one-line, capitalized, truthful.**
