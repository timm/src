---
name: runtime-bench
description: Benchmark CPU and memory of Lua/Python runtimes over the moot model corpus, banded by size. Use to reproduce or extend REPORTcpu.md numbers.
---

# Runtime benchmark over moot models

Worked example: ezr-lua/REPORTcpu.md; raw data and scripts
in ezr-lua/etc/ (sweep*.sh, bench*.tsv).

## Procedure

1. Corpus: ~/gits/moot/optimize/*/*.csv (~128 models).
   Band by `wc -l`: small <1k, mid 1k-10k, large >=10k.
   Report N per band.
2. Task per model per runtime: ONE process runs the
   `tree` and `acquire` demos:
   `python3 xai-eg.py tree acquire --file=F`
   `lua xai-eg.lua -f F --tree --acquire`
   (lua flags must precede the demo names: flags only
   steer demos that follow them).
3. Measure with `/usr/bin/time -l` (macOS): real, user+sys
   as CPU, maximum resident set size. One TSV row per run:
   runtime, model, real, cpu, maxrss, exit.
4. Aggregate per band with awk: sum real/cpu, mean+peak
   RSS, fail count. Report a LuaJIT-speedup column =
   real(runtime)/real(LuaJIT).

## Known results shape (Apple M4, 2026-08)

- Small/mid models: LuaJIT 19-81x CPython; Lua runtimes
  hold 3-7 MB RSS, ~10x under pypy3.
- Large models the order flips: pypy3 fastest, PUC Lua
  slowest (GC pressure, ~589 MB peak). pypy3 needs
  seconds of one process to warm; many short processes
  hide it (~0.25 s startup each).
- Everything is CPU-bound: cpu ~= real.

## Traps

- Old xai-eg guards on its own filename
  (`arg[0]:find"xai%-eg"`): renamed copies silently run
  nothing. Keep the basename.
- Retired xai sources need three repairs to run everywhere
  (see .claude/skills/lua-compat and
  ezr-lua/etc/bench2/): // -> floor, BOM/empty-cell csv
  fix, 5.5 const loop var.
- Warm runs: run each cell twice, keep the second.
