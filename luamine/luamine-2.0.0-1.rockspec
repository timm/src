rockspec_format = "3.0"
package = "luamine"
version = "2.0.0-1"
source = {
  url = "git+https://github.com/timm/src.git"
}
description = {
  summary = "LUAMINE = LUA MINing Engines: lots of useful learners",
  detailed = [[
Small files, no dependencies beyond Lua 5.3+: three modules
assembled from page-sized topic files -- generic helpers
(lib), AI primitives (Num, Sym, distance, trees, Bayes --
luamine), and apps (clustering, classification, active
learning, GA/DE/SA/LS optimizers, synthetic data, anomaly
detection -- lapps). Includes tut.md, a ten-lecture REPL
tutorial. Run `lua luamine-eg.lua --all` to test.]],
  homepage = "https://github.com/timm/src",
  license = "MIT",
  labels = { "ai", "machine-learning", "optimization", "teaching" },
  maintainer = "Tim Menzies <timm@ieee.org>"
}
dependencies = {
  "lua >= 5.3"
}
build = {
  type = "builtin",
  modules = {
    lib      = "luamine/lib.lua",
    luamine  = "luamine/luamine.lua",
    lapps    = "luamine/lapps.lua"
  },
  -- ship the tutorial (tut.md only; tut.html is a build artifact)
  install = {
    conf = { "luamine/tut.md" }
  }
}
