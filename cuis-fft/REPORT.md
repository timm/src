# fft: one algorithm, five runtimes

Fast-frugal multi-objective regression trees (`fft.lisp`,
Menzies 2026) ported line-faithfully to Python, Lua, and Cuis
Smalltalk, then benchmarked. Same algorithm, same Park-Miller
seed (1234567891), same knobs (p=2, bins=7, depth=4), same
data (auto93.csv, 398 rows, from `$MOOT/optimize/misc/`).

**Correctness gate**: every port's `--trees` output (all 16
trees: rules, biases, means, counts, errors — 112 lines) is
diff-identical to the SBCL original. What is compared below
is only the runtime, never the answer.

## Environment

- Apple M4, 16 GB, macOS Darwin 25.5.0
- SBCL 2.5.6
- Python 3.14.5
- Lua 5.5.0
- LuaJIT 2.1 (2026-01 snapshot)
- Cuis Smalltalk 7.6, OpenSmalltalk Cog VM 202501132308
- Measurement: `/usr/bin/time -l` (wall clock + peak RSS).
  RSS figures are MiB. Single runs; ~±10% jitter on the
  small numbers.

## Startup only (start, do nothing, quit)

| runtime | wall (s) | peak RSS (MB) |
|---------|---------:|--------------:|
| LuaJIT  | 0.00     | 1.6           |
| Lua 5.5 | 0.00     | 1.6           |
| Python  | 0.04     | 15.5          |
| SBCL    | 0.04     | 35.5          |
| Cuis    | 0.62     | 120.8         |

Cuis pays 0.6 s to map a 24 MB image and start a live
Morphic world, even headless. That cost is fixed: amortize
it (big jobs), or keep the image alive (its intended,
interactive use). Everyone else starts in the noise.

## Small task: egMain (grow 16 trees on 398 rows, pick best)

| runtime | wall (s) | peak RSS (MB) |
|---------|---------:|--------------:|
| LuaJIT  | 0.01     | 2.7           |
| Lua 5.5 | 0.04     | 2.4           |
| Python  | 0.05     | 17.9          |
| SBCL    | 0.11     | 88.7          |
| Cuis    | 0.82     | 116.8         |

At CLI-one-shot scale, startup dominates everything; the
work itself is milliseconds everywhere.

## Big run: egGrows, 2000 reps x 100-row samples (32,000 trees)

| runtime | per rep (ms) | wall (s) | peak RSS (MB) |
|---------|-------------:|---------:|--------------:|
| LuaJIT  | 0.5          | 0.9      | 3.3           |
| SBCL    | 1.1          | 2.3      | 99.1          |
| Lua 5.5 | 3.0          | 6.1      | 2.5           |
| Python  | 4.4          | 8.8      | 17.8          |
| Cuis    | 6.0          | 12.5     | 125.3         |

(SBCL wall includes one stray egMain run from loading
fft.lisp: ~0.05 s, <2%. Per-rep figures are each program's
own inner timer, so unaffected.)

## Source size

| file | language | lines | chars | notes |
|------|----------|------:|------:|-------|
| fft.lua | Lua | 329 | 9,837 | self-contained |
| fft.py | Python | 275 | 7,918 | self-contained |
| fft.st | Smalltalk | 573 | 12,347 | self-contained; chunk format, one method per name |
| fft.lisp + lithp.lisp | Common Lisp | 223+145 = 368 | 7,455+4,637 = 12,092 | original + its kit |

Python is tersest. Smalltalk is longest in lines but not by
much in characters — the chunk format spends lines on method
headers and accessors, not on logic.

## Readings

1. **LuaJIT wins compute outright**: 0.5 ms/rep, 2x faster
   than native-compiled SBCL, in 3 MB of memory. Tracing JIT
   on dynamic code with hot loops is a solved problem.
2. **SBCL is the best "compiled" citizen**: fast, but its
   runtime floor is ~35 MB and its heap grew ~64 MB under
   load — the biggest working-set growth of the five.
3. **Python 3.14 is no longer slow here**: 4.4 ms/rep, within
   1.5x of plain Lua, and only 18 MB. The old
   interpreter-tax folklore (10-100x) is stale for
   dict-and-small-object workloads.
4. **Cuis is the slowest and biggest — and the numbers still
   defend it.** 6 ms per 16-tree model. Its 125 MB is almost
   entirely the one-time cost of carrying a full live system
   (compiler, IDE, debugger, GUI); the 32,000-tree workload
   itself added only ~4.6 MB, the smallest load-delta of any
   runtime with a GC arena. The 1980s "Smalltalk is a
   resource hog" claim measured Smalltalk against 1 MB
   machines; against a 2026 laptop it is a rounding error,
   smaller than one browser tab.
5. **The answer never changed.** Five runtimes, byte-identical
   trees. The algorithm is the asset; the runtime is a
   deployment detail chosen by constraint: LuaJIT (speed +
   size), Python (ubiquity), SBCL (compiled ecosystem), Cuis
   (live interactive development).

## Reproduce

    make install   # unpack/download Cuis if missing
    make image     # bake FFT classes into fft-cuis.image
                   # (one brief window; Mac VM cannot create
                   # classes headless)
    make run       # best tree, headless, no window
    make bench     # this report's numbers -> bench.out

Needs: the moot repo at ~/gits/moot (or $MOOT) for
auto93.csv; whichever of sbcl/python3/lua/luajit are
installed (missing ones are skipped). Note fft.st also
hard-codes the csv path in `FFT class >> file`.

## Cuis headless notes (hard-won)

- The Mac Cog VM hangs under `-headless` on any class
  creation and on fileIn progress bars (both draw on
  Display). Therefore: build the image once WITH a display
  (`make image`, one window flash), then run headless
  forever from the baked image.
- Cuis CLI: bare `.st` args are ignored. Use `-l file.st`
  (fileIn), `-d "expr"` (evaluate), `-s file` (evaluate
  plain script). End with `-d "Smalltalk quitPrimitive"`.
- `Smalltalk saveAndQuitAs:` resolves names relative to the
  image directory, so `fft-cuis.image` lives next to
  `Cuis7.6.image`.
- `FFT prn:` writes stdout via `StdIOWriteStream` and skips
  the Transcript when `Smalltalk isHeadless` (the Transcript
  also draws on Display).
