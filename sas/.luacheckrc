-- luacheck config for sas lua (see src/CLAUDE.md: all Lua
-- targets LuaJIT / Lua 5.1 semantics).
std = "luajit"
allow_defined_top = true -- `function name` = export, via the
                         -- setfenv/_ENV module trick
max_line_length = 65     -- book line-width rule
unused_args = false      -- SYM.holds(i,x,v) etc: unused self
                         -- params keep polymorphic arity
ignore = {
  "312", -- args overwritten before use: the (a,b,    c,d)
         -- params-as-locals idiom
  "131", -- top-level "unused" globals: exports read by
         -- other files via the module table
  "43",  -- shadowing upvalues: nested same-names are house
         -- style
  "611"} -- whitespace-only lines: formfeed column breaks
         -- for a2ps listings
