---
name: tut-repl-events
description: Use when adding, extending, or repairing numbered [n]> REPL events in ezr-lua/tut.md (or a sibling course transcript), or when a lecture needs new executable material with glossary terms.
---

# Adding REPL events to tut.md

The transcript is machine-generated, never hand-typed. Each
lecture N has `etc/tut/lN.in` (one statement per line;
`#### x.y title` lines pass through); `etc/tut/repl.lua`
numbers the statements and prints real output. tut.md's
```lua fenced blocks are verbatim paste from that run.

## The append recipe (events 1..K are FROZEN)

1. Baseline: `EZR=$(pwd) lua etc/tut/repl.lua etc/tut/lN.in S`
   where S = the lecture's first event number (from the
   contents table). Confirm the last event's output matches
   tut.md, note "next event: [K+1]".
2. Append statements to lN.in ONLY at the end — the RNG
   stream is sequential, so appending never disturbs
   earlier events. Never insert or edit mid-file.
3. Rerun; diff the prefix against the baseline (must be
   byte-identical); run under BOTH `lua` and `luajit` and
   diff (must be identical — everything routes through the
   shared Park-Miller rand; never math.random).
4. Paste the new `[n]> ...` lines + outputs verbatim into a
   new `## N.x` tut.md section. Prose between blocks; a
   "Notice:" pointer sentence; a **Check.** question after.

## Statement gotchas (repl.lua semantics)

- Results print via `tostring`, not `show` — wrap tables
  and floats: `show{...}`, `round(x)`.
- `load("return "..s)` is tried first; multi-statement
  lines (`n = 0; for ... end`) fall through to plain load.
- Session state persists across the whole lN.in: reuse `t`,
  avoid clobbering names later statements need.
- repl.lua requires ezr-apps (which chains ezr -> lib), so
  app functions are in scope at the REPL.

## Bookkeeping (all of it, every time)

- New acronyms: vignette `> **[XX](#g-xx) — ...**` at first
  executable use; glossary row APPENDED in discovery order
  with `<a name="g-xx"></a>` anchor; every mention linked
  `[XX](#g-xx)`; References entry (MLA-ish, DOI verified —
  see the cite-check skill).
- Contents table: lecture's event range + Ideas links.
- Recap "events covered", and the standing-homework
  "reproduce every event 1–K" count.
- Final check: anchors == link targets (grep both sets),
  and every pasted [n]> line + output greps in the fresh
  trace.

## Common mistakes

- Hand-editing an output ("just fix the float") — the next
  replay diff fails CI. Regenerate instead.
- Inserting events mid-lecture: renumbers everything after
  and shifts the RNG stream. Append only.
- Testing only one interpreter: PUC/LuaJIT print floats
  differently unless everything goes through round/show.
