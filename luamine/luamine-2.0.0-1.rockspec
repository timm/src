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
    lapps    = "luamine/lapps.lua",
    rand     = "luamine/rand.lua",
    list     = "luamine/list.lua",
    stats    = "luamine/stats.lua",
    confuse  = "luamine/confuse.lua",
    str      = "luamine/str.lua",
    cli      = "luamine/cli.lua",
    cut      = "luamine/cut.lua",
    sym      = "luamine/sym.lua",
    num      = "luamine/num.lua",
    cols     = "luamine/cols.lua",
    data     = "luamine/data.lua",
    dist     = "luamine/dist.lua",
    bayes    = "luamine/bayes.lua",
    mutate   = "luamine/mutate.lua",
    tree     = "luamine/tree.lua",
    show     = "luamine/show.lua",
    cluster  = "luamine/cluster.lua",
    classify = "luamine/classify.lua",
    acquire  = "luamine/acquire.lua",
    sample   = "luamine/sample.lua",
    bob      = "luamine/bob.lua",
    race     = "luamine/race.lua",
    ga       = "luamine/ga.lua",
    de       = "luamine/de.lua",
    search   = "luamine/search.lua"
  },
  -- ship the tutorial (tut.md only; tut.html is a build artifact)
  install = {
    conf = { "luamine/tut.md" }
  }
}
