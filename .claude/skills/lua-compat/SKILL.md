---
name: lua-compat
description: Checklist to make Lua code run identically on PUC Lua 5.1-5.5 and LuaJIT. Use before claiming "any Lua" in docs or a rockspec, or when porting/moving Lua code in this repo.
---

# Lua cross-version compatibility checklist

Target: same behavior AND same printed output on PUC Lua
5.1..5.5 and LuaJIT. Verify by diffing full `--all` output
across interpreters (see ezr-lua for the worked example).

## Parse errors (code will not even load)

- `//` integer division: 5.3+. LuaJIT and 5.1 cannot parse
  it. Use `math.floor(a/b)`.
- Lua 5.5 makes for-loop variables const: `for s in ... do
  s = s:gsub(...)` fails to compile. Introduce a fresh
  local (`for s0 in ... do local s = s0:...`).

## Silent wrongness

- Two-arg `math.log(x, base)`: LuaJIT extension + 5.2+.
  PUC 5.1 silently ignores the base and returns ln. Use
  `log(x)/log(base)`.
- `math.random`/`math.randomseed` streams differ per
  implementation (LuaJIT Tausworthe, PUC 5.1-5.3 C rand(),
  5.4+ xoshiro). Same seed, different numbers. For
  reproducible streams ship your own PRNG; Park-Miller is
  exact in doubles: `Seed = (16807*Seed) % 2147483647`
  (16807*2^31 < 2^53, no precision loss). See
  ezr-lua/ezr-lib.lua rand/srand.
- `tostring` of a whole-number float: "15.0" on 5.3+,
  "15" on 5.1/LuaJIT. Re-floor after any rounding that can
  land on a whole number (see ezr-lib round()).
- Module env: use the pair
  `local _ENV = setmetatable({}, {__index = ...})`
  `if setfenv then setfenv(1, _ENV) end`
  which works on 5.1/LuaJIT and 5.2+ alike.
- `table.unpack or unpack` for slices.

## CSV/data traps (bit every reader here at least once)

- Strip UTF-8 BOM ("\239\187\191") from lines.
- `gmatch"[^,]+"` drops empty cells and desyncs rows from
  headers; use `(s..","):gmatch"(.-),"` and map empty to
  "?".

## Verify

Run every suite under both `lua` and `luajit`; require
zero failures AND byte-identical stdout (`diff` the
captured outputs). Homebrew `lua` moves fast (5.5 already)
so it doubles as a future-Lua canary.
