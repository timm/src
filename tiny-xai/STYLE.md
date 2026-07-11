# STYLE.md — how tiny-xai gets written

Tiny functions. Beautiful code. Lines fit 65 chars
(`awk 'length > 65' *.lisp`).
Routine testing is sbcl only (`make tests`, ~0.1s);
CLISP (~200x slower) is an occasional pre-commit
portability gate. Code stays portable to both.

## Conventions

- **Lots of small functions.** One job each, ~10 lines.
  Helpers earn a name on second use; single-caller
  helpers get folded back in.
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
  `&aux (i (make-data ...))`).
- **Settings slots ARE the CLI flags.** `settings` uses
  `(:conc-name)` and `--seed`-style slot names; `cli`
  string-matches argv against slot names and `-h` prints
  them as OPTIONS. Rename a slot = rename a flag; a slot
  nothing reads is a lie in the help text.
- Structs needing smart construction hide the default
  constructor as `%make-foo` and hand-write a public
  `make-foo` (see cols, data).
- Numeric guards: `(+ denom +tiny+)` blocks
  divide-by-zero; `+big+` / `(- +big+)` seed min/max
  scans.
- Randomness is a hand-rolled Lehmer `rand`/`rint` plus
  a seeded `shuffle` over `*seed*`; never CL `random`.
  Reset `(setf *seed* (? *my* --seed))` before every
  test, study, or model run so runs reproduce.
- Portability rides on `#+sbcl` / `#+clisp` reader
  conditionals (slot listing, argv, warning muffling).
- Header roles: trailing `-`, `+`, `!` mark goals (`-`
  sets weight 0, others 1), trailing `X` = ignore,
  leading uppercase = numeric.
- Every file opens with a one-line vim modeline;
  Makefile targets carry trailing `## help` comments.
- lisp-lang.org style guide: earmuffs on specials
  (`*my*`, `*seed*`, `*label*`); `-p` predicates
  (`grow-p`, `has-p`); `+tiny+`/`+big+` constants;
  `when`/`unless` over one-armed `if`; `;;;;` file
  purpose, `;;;` section, `;;` block, `;` inline;
  license lives ONLY in the .asd, LICENSE.md and README.
- Tests: `eg--*` = unit tests (`--all`); `study--*` =
  experiment sweeps (`--study` or per flag). Every test
  asserts; dataset-specific numbers gate on
  `(search "auto93" ...)`. Tests print a diagnostic
  line (`~&...`) BEFORE asserting; study docstrings
  start `Rq0:`/`Rq1:`/`Rq2:`; big inputs get capped
  first via `few` and `--cap`.
- Reference implementation: `../ezr2/ezr2.py`. Prefer
  its shapes; no `--bins`-style approximations for
  numeric cuts; pinned asserts make every refactor a
  provable no-op.

## Files

    tiny-xai.lisp       script entry: loads src + t, runs
                        cli inside (eval-when (:execute))
                        so ASDF loads stay pure
    src/tiny-xai.lisp   the engine (package :tiny-xai)
    t/tiny-xai.lisp     eg--* tests, study--* sweeps
    dtlz.lisp       external-model demo (*label* hook)
    tiny-xai.asd        metadata; long-description reads
                        README.md at load time
    tiny-xai-test.asd   test-op runs eg--all
    etc/doc.awk         docs preprocessor
    etc/header.txt      badge strip injected into docs
    etc/init.lisp, ide  emacs setup and launcher
    Makefile            tests/study/doc + sweep lanes
    REPORT.md           the RQ0-RQ2 study write-up

## Documentation (read before touching docs)

The website (`docs/*.html`) is GENERATED. Never edit it.
`make doc` rebuilds it from these sources, in this order:

1. **Docstrings** in every .lisp file. Every defun,
   defmethod and defmacro has a one-line docstring,
   **first letter capitalized, no trailing period**. These are load-bearing
   three ways: (a) `etc/doc.awk` lifts each one above its
   definition as a comment, so pycco renders it as prose
   beside the code; (b) `help` (-h) prints them as the
   TESTS and STUDIES lists; (c) they are the API docs a
   human reads in the source. Change a function's
   behavior => update its docstring => rerun `make doc`.
2. **Section markers**: `;;; ## Name` lines (capitalized)
   sit above each figlet banner. doc.awk turns the marker
   into a markdown heading and DROPS the figlet art
   (`;;;` lines). New section = figlet -f mini -W for the
   source + one `;;; ##` marker for the docs.
3. **etc/doc.awk** rewrites a .lisp into a .scm that
   pycco (`pycco -d docs`) can chew: `;;;;` prose -> `;;`
   comments, markers -> headings, docstrings lifted.
4. **pycco** writes docs/NAME.html and REGENERATES
   docs/pycco.css on every run, clobbering any custom
   rules. So after each pycco call the Makefile must
   re-append `p { text-align: right; }` (right-aligns
   the prose column against the code). The append guard
   must grep for the EXACT rule, not just "text-align" -
   pycco's own css contains that substring, which once
   silently disabled the append. It also injects
   **etc/header.txt** (the shields.io badge strip)
   before the first `<h1`.
5. **etc/header.txt** badge links must stay in sync with:
   LICENSE.md (license badge), the github repo paths
   (download + report badges), timm.fyi (author), and
   .github/workflows/tests.yml (the live CI badge).
6. **README.md** is the github landing page AND the asd's
   `:long-description` (read at asd load). Usage examples
   there must match the real flags (`-h` is the truth).
   It is ALSO the website's landing page: GitHub Pages
   serves the repo ROOT of main (not docs/), so live urls
   are `.../tiny-xai/docs/NAME.html` and the bare
   `.../tiny-xai/` renders README. The README Documentation
   toc and header.txt's home badge must keep those paths.
7. **REPORT.md** numbers come from `make holdouts`,
   `make budgets`, `make deltas`. If the algorithm
   changes, rerun the lanes and refresh the histograms;
   never hand-edit results.
8. **\*help\*** (in src) is the -h banner; OPTIONS,
   TESTS, STUDIES sections are generated live from
   slot-names and docstrings, so only the prose at the
   top can go stale.

**TL;DR for claude: after any code change run
`make tests doc`; after any algorithm change also rerun
the sweep lanes and refresh REPORT.md; keep docstrings
one-line, capitalized, and truthful, because -h and the
website are generated from them; never edit docs/*.html,
README's long-description ride-along, or badge links
without checking their upstream source of truth.**
