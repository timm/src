-- Tutorial and tests for confuse.lua.
local eg, h, a, m, l, the = ...

--[[
## Scoring a classifier

Count (want,got) pairs into a confusion matrix; read back
per-klass accuracy, precision, false alarm and recall.

| call | returns | what |
|------|---------|------|
| `Confuse.new(file)` | cf | empty matrix |
| `cf:add(want,got)` | -- | count one prediction |
| `cf:show()` | -- | tn/fn/fp/tp + derived stats |
]]

eg["--confuse"] = function(    cf)
  cf = l.Confuse.new("data.csv")
  for _=1,50 do cf:add("yes","yes") end
  for _=1, 5 do cf:add("yes","no")  end
  for _=1, 3 do cf:add("no","yes")  end
  for _=1,40 do cf:add("no","no")   end
  cf:show(); return true end
