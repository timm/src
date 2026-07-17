rockspec_format = "3.0"
package = "xai"
version = "1.0.0-1"
source = {
  url = "git+https://github.com/timm/src.git"
}
description = {
  summary = "xai: explainable multi-objective optimization, tiny-ly",
  detailed = [[
One Lua file, no dependencies beyond Lua 5.4: Num/Sym column
summaries, distance, bins, trees, active learning and stats
-- the engine behind a 14-lesson course (xai-eg.lua) whose
asserts are its tests and whose concepts live in the repo
glossary. Run `lua xai-eg.lua --all` to test.]],
  homepage = "https://github.com/timm/src",
  license = "MIT",
  labels = { "ai", "machine-learning", "optimization", "teaching", "xai" },
  maintainer = "Tim Menzies <timm@ieee.org>"
}
dependencies = {
  "lua >= 5.4"
}
build = {
  type = "builtin",
  modules = {
    xai     = "xai/xai.lua",
    xaiplus = "xai/xaiplus.lua"
  }
}
