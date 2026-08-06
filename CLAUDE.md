# CLAUDE.md

Before editing any file in this repo, read every etc/*.md
(start with etc/style.md), plus any STYLE.md in the dir you
are editing. The style files are the contract; do not
restructure dirs or add subdirs without checking them.

## Lua

All Lua targets LuaJIT, i.e. Lua 5.1 semantics. No `//`,
no `_ENV`-only tricks, `table.unpack or unpack` for slices.
Module capture is `local _ENV = setmetatable({}, ...)` plus
`if setfenv then setfenv(1, _ENV) end` (the pair runs on
5.1 and 5.2+ alike). LuaJIT extensions such as two-argument
math.log are fine. When 5.1 and newer Lua conflict, 5.1
wins. Never printf "%f" a float of uncontrolled magnitude:
LuaJIT's own string.format renders tiny doubles (say,
1e-170) as huge garbage integers. Route number display
through lib.lua's round/show instead.

## Protected files

sandbox/ is timm's personal play area. Leave it alone:
never clean, delete, restyle, or sync it with the real
project dirs, no matter how stale it looks.

attic/luamine/tut.md is a finished, hand-polished artifact
(5,000 lines, 307 machine-verified REPL events). NEVER
edit, reformat, regenerate, line-wrap, or "improve" it --
not even trailing whitespace. If a task seems to require
changing it, stop and ask instead.
