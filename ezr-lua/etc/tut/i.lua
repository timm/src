-- Interactive ezr REPL: everything loaded as globals.
--   cd ezr-lua && lua -i etc/tut/i.lua
-- (plain `lua -i ezr-eg.lua` exits: its go() calls os.exit when main.)
local here = (arg[0] or ""):gsub("[^/]*$","")      -- .../etc/tut/
local root = here .. "../../"                       -- .../ezr-lua/
package.path = root.."?.lua;"..package.path
for _,m in ipairs{"ezr-lib","ezr","ezr-apps","ezr-dtlz"} do
  local ok,M = pcall(require, m)
  if ok then for k,v in pairs(M) do if _G[k]==nil then _G[k]=v end end end
end
the.DATA = (os.getenv("PWD") or ".") .. "/data/"  -- absolute, cwd-proof
print('ezr loaded. try:  t=Tbl(csv()); print(#t.rows)')
