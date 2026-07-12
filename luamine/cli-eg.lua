-- Tutorial and tests for cli.lua.
local eg, h, a, m, l, the = ...

--[[
## The command line

Help text is the single source of truth: `section` pulls a
"## name" block out of it; `boot` seeds `the` from the
options found there; `main` maps --flag val onto `the` and
runs egs by name.

| call | returns | what |
|------|---------|------|
| `l.section(text,name)` | str | body of "## name" |
| `l.boot(eg,b4,name,help)` | -- | seed the; maybe CLI |
]]

eg["--cli"] = function(    txt,opts)
  txt = "# t\n## options\n  --zz=23  a knob\n## egs\n  --x  y"
  opts = l.section(txt,"options")
  return l.chk({"section",opts:find"zz" ~= nil,true},
               {"egs",l.section(txt,"egs"):find"%-%-x" ~= nil,
                true},
               {"the seeded",the.seed ~= nil,true}) end
