---
name: writing-eg-lua
description: Use when creating or extending any xxx-eg.lua file, adding demos to an eg table, or turning demos into tutorial material in timm/src lua projects (ezr-lua, luamine style).
---

# Writing xxx-eg.lua demo files

## Overview

Demos are the test suite, the book's transcripts, and the
tutorial — one artifact, three jobs. Every demo must earn
all three. Copy shapes from `ezr-lua/ezr-eg.lua` (file
shape) and `attic/luamine/tut.md` (tutorial shape — that
file is PROTECTED: read it, never edit it).

## File shape

```lua
#!/usr/bin/env lua
-- xxx-eg.lua: demos/tests for xxx.lua. Every demo
-- reseeds, prints, then asserts. --all runs everything.
local abs        = math.abs        -- only what demos use
local rand,srand = math.random, math.randomseed

-- find xxx.lua beside this file, whatever the cwd
package.path = (arg and arg[0] or ""):gsub("[^/]*$","")
               .. "?.lua;" .. package.path
local _ENV = setmetatable({}, {__index = require"xxx"})
if setfenv then setfenv(1, _ENV) end

eg = {}

eg["--all"] = function(    bad) -- fail if any demo does
  bad = 0
  for _,k in ipairs(keys(eg)) do
    if k ~= "--all" and run(eg, k) == false then
      bad = bad + 1 end end
  print("failures: " .. bad)
  assert(bad == 0) end

eg["--thing"] = function(    t) -- one-line intent here
  t = Tbl(csv())
  print(...)          -- something a tutor can point at
  assert(...) end     -- no crash + assert = pass

go(eg)      -- lib's runner: cli flags, reseed per demo,
return _ENV -- os.exit(#failures). Fires only when this
            -- file is the main script, so `require` stays
            -- silent: split x.lua/x-eg.lua ONLY for size
            -- (~10+ demos); else demos live in x.lua.
```

## Hard rules (from sas/CLAUDE.md; never break silently)

- Every demo: reseeded (run() does it), prints something,
  ends in an assert.
- Never change an existing assert or seed without asking.
- New knobs go in the settings help string, nowhere else.
- Lines <= 65 chars; locals declared in the 4-space slot
  of the arg list; transcripts are never hand-typed —
  chapters capture demo output via %%run.

## Tutorial shape (for demo GROUPS graduating to lessons)

Each group of demos carries, in order:
1. A few lines of context prose — and a "where this
   bites" sentence: the real SE situation it serves.
2. The glossary terms this group illustrates (SMALL CAPS,
   linked; definitions live in glossary.md, defined once).
3. The code/demos, as numbered events (`[1]>` style) —
   the numbers are addresses; recaps, exercises, and quiz
   questions all cite them.
4. An inline **Check:** question right after each demo
   (small, sometimes adversarial: "why does X crash?").
5. End of group: a Recap ("events covered: n-m; you can
   now: ..."), tutorial questions, and one small
   synthesis task that reuses the numbered events.

Theory sections come AFTER practice, never before.
Course-scale extras (see tut.md): stakes-numbers up front,
an early "whole movie" preview, a revision quiz whose
questions unlock at numbered events, and the standing
homework — reimplement in another language, graded by
diff (portable seeded RNG makes outputs reproducible).

## Common mistakes

| Mistake | Fix |
|---|---|
| Demo with print but no assert | Add assert; no crash = pass |
| Demo output hand-edited into prose | Only %%run captures |
| New file pair for 1-2 demos | Single file; go() guard |
| --all swallowing failures | Count run()==false, assert 0 |
| Sample output that drifts | Seeded; diff is the grader |
