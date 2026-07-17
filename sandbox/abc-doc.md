# abc-doc.md — lecture notes for abc.lua

(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

Companion to [abc.lua](abc.lua) (the code) and
[abc-eg.lua](abc-eg.lua) (the lessons: demos, tests,
exercises). Each lesson's stanza ends in **Core ideas**
whose links land in the repo-wide dictionary
[../glossary.md](../glossary.md); entries there carry
*taught in* back-pointers to the lessons. This file keeps
only the course-specific views: the contents table (the
lesson order) and the references.

## Contents

| lesson | section | run | core ideas |
|--------|---------|-----|------------|
|  0 | Lua     | `lua abc-eg.lua --lua`     | [truthy](../glossary.md#truthy) [onetable](../glossary.md#onetable) [closure](../glossary.md#closure) [patterns](../glossary.md#patterns) [bob](../glossary.md#bob) |
|  1 | Lst     | `lua abc-eg.lua --lst`     | [lists](../glossary.md#lists) [dsu](../glossary.md#dsu) [bisect](../glossary.md#bisect) |
|  2 | Rnd     | `lua abc-eg.lua --rnd`     | [seed](../glossary.md#seed) [shuffle](../glossary.md#shuffle) [gauss](../glossary.md#gauss) [roulette](../glossary.md#roulette) |
|  3 | Str     | `lua abc-eg.lua --str`     | [coerce](../glossary.md#coerce) [csv](../glossary.md#csv) [ssot](../glossary.md#ssot) |
|  4 | Num     | `lua abc-eg.lua --num`     | [welford](../glossary.md#welford) [stream](../glossary.md#stream) [minus](../glossary.md#minus) |
|  5 | Sym     | `lua abc-eg.lua --sym`     | [entropy](../glossary.md#entropy) [mode](../glossary.md#mode) [poly](../glossary.md#poly) [noir](../glossary.md#noir) |
|  6 | Cols    | `lua abc-eg.lua --cols`    | [schema](../glossary.md#schema) [goals](../glossary.md#goals) [xy](../glossary.md#xy) |
|  7 | Tbl     | `lua abc-eg.lua --tbl`     | [tables](../glossary.md#tables) [clone](../glossary.md#clone) [centroid](../glossary.md#centroid) |
|  8 | Dist    | `lua abc-eg.lua --dist`    | [norm](../glossary.md#norm) [minkowski](../glossary.md#minkowski) [missing](../glossary.md#missing) [heaven](../glossary.md#heaven) [knn](../glossary.md#knn) [anomaly](../glossary.md#anomaly) |
|  9 | Stats   | `lua abc-eg.lua --stats`   | [effect](../glossary.md#effect) [ks](../glossary.md#ks) [same](../glossary.md#same) |
| 10 | Acquire | `lua abc-eg.lua --acquire` | [budget](../glossary.md#budget) [active](../glossary.md#active) [poles](../glossary.md#poles) [explore](../glossary.md#explore) |
| 11 | Bins    | `lua abc-eg.lua --bins`    | [bins](../glossary.md#bins) [cost](../glossary.md#cost) [closure](../glossary.md#closure) |
| 12 | Tree    | `lua abc-eg.lua --tree`    | [tree](../glossary.md#tree) [predict](../glossary.md#predict) [explain](../glossary.md#explain) |
| 13 | Score   | `lua abc-eg.lua --score`   | [holdout](../glossary.md#holdout) [win](../glossary.md#win) [baseline](../glossary.md#baseline) [bets](../glossary.md#bets) [variability](../glossary.md#variability) |

## References

- Welford (1962), Technometrics 4(3) — incremental
  variance.
- Park & Miller (1988), CACM 31(10) — the 16807 minimal
  standard generator.
- Box & Muller (1958) — normal deviates from uniforms.
- Cliff (1993), Psych. Bulletin 114 — dominance
  statistics.
- Cohen (1988) — statistical power and effect size.
- Massey (1951), JASA 46 — the Kolmogorov-Smirnov test.
- Faloutsos & Lin (1995), SIGMOD — FastMap (the poles
  trick).
- Breiman et al. (1984) — CART: classification and
  regression trees.
- Settles (2009) — Active Learning literature survey.
- Menzies (2026) — luamine/tut.md: ten lectures on
  data-lite AI, the long-form ancestor of these notes.
