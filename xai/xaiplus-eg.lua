#!/usr/bin/env lua
-- xaiplus-eg.lua: demos and tests for xaiplus.lua, the
-- applications layer over xai. One eg sub-table per app,
-- ordered simplest to hardest. On the command line:
--
--     --key=val, -k val    set an option
--     --knn, --kmeans ...  run one app's tests
--     --all                run every app
--
-- Each test is reseeded, prints something a tutor can point
-- at, then asserts it: no crash = pass.
--
--     lua xaiplus-eg.lua --seed=2 --kmeans
--
--[[
### How to run this course

xaiplus is the applications layer over [xai](xai.lua): the
core stays tiny, the learners and optimizers live here.

(Easier read: this file, rendered --
[xaiplus-eg.html](https://timm.github.io/src/xai/docs/xaiplus-eg.html);
its library
[xaiplus.html](https://timm.github.io/src/xai/docs/xaiplus.html);
the shared dictionary
[glossary](https://timm.github.io/src/glossary.html).)

Install [lua 5.4+](https://lua.org) (mac:
`brew install lua`), then fetch the code and its data:

    git clone https://github.com/timm/src
    git clone https://github.com/timm/moot ~/gits/moot
    cd src/xai
    lua xaiplus-eg.lua --all      # ends "all pass"

Then read a lesson here beside its printed output in
[xaiplus-eg.out](xaiplus-eg.out), run its tests
(`lua xaiplus-eg.lua --kmeans`), then retype a demo at the
REPL (`lua -i`, `xp = require"xaiplus"`).

### Contents

The apps in order, simplest first, and the ideas each lands
in the [glossary](../glossary.md). Run
`lua xaiplus-eg.lua -h` for the section/test map.

| lesson | app | core ideas |
|--------|-----|------------|
| 1 | Knn      | [knn](../glossary.md#knn) [mode](../glossary.md#mode) |
| 2 | Kmeans   | [kmeans](../glossary.md#kmeans) [centroid](../glossary.md#centroid) |
| 3 | Kmeanspp | [kmeanspp](../glossary.md#kmeanspp) [centroid](../glossary.md#centroid) |
| 4 | Bayes    | [bayes](../glossary.md#bayes) [gauss](../glossary.md#gauss) |
| 5 | Classify | [bayes](../glossary.md#bayes) [confusion](../glossary.md#confusion) [mode](../glossary.md#mode) |
| 6 | Mutate   | [mutate](../glossary.md#mutate) [gauss](../glossary.md#gauss) |
]]
local xai = require"xai"
local xp  = require"xaiplus"
local the,lst,rnd,str = xai.the, xai.lst, xai.rnd, xai.str
local Tbl = xai.Tbl

local eg    = {}
local order = {"knn","kmeans","kmeanspp","bayes",
               "classify","mutate"}

-- the shared running dataset: a small numeric classification
-- table (9 cell-measurement x cols, a benign/malignant klass)
local DATA = "$MOOT/classify/breast.w.csv"

-- ## Knn
--[[
### Lesson 1: nearest-neighbor classification

The simplest learner has no training step at all: to label
a new row, find the rows most like it and let them vote. Ask
`distx` (from xai) for the k closest rows, take the mode of
their klasses, done. The data IS the model. On breast.w --
nine cell measurements, a benign/malignant klass -- a bare
3-NN already scores in the high 90s.

**Core ideas:** [knn](../glossary.md#knn),
[mode](../glossary.md#mode)
]]
eg.knn = {}

-- - **xp.knn(data,r0,k)** predicts r0's klass as the mode of
--   the klasses of its k nearest rows (distx, then Sym mode).
eg.knn["--acc"] = function(    d,rows,h,tr,te,at,ok)
  d    = Tbl.new(DATA)
  rows = rnd.shuffle(lst.slice(d.rows))
  h    = 490                            -- ~70% train
  tr   = d:clone(lst.slice(rows, 1, h))
  te   = lst.slice(rows, h + 1)
  at, ok = d.cols.klass.at, 0
  for _,r in ipairs(te) do
    if xp.knn(tr, r) == r[at] then ok = ok + 1 end end
  print("3-NN accuracy on breast.w:", str.o(ok/#te))
  assert(ok/#te > 0.9)                  -- easy data, easy win
  assert(xp.knn(tr, tr.rows[1]) ~= nil) end

--[[
**Exercises (lesson 1).**

0. In your own favorite language (not lua), write a knn
   classifier over this section's split and reproduce the
   accuracy line.
1. (simple) Rerun `--acc` with `--knn=1`, then 7, then 15.
   Which k is best on breast.w, and does bigger always help?
2. Weight each neighbor's vote by 1/dist (closer = louder)
   using `Sym.add(i,v,w)`. Does weighting beat the plain
   mode at k=15?
]]

-- ## Kmeans
--[[
### Lesson 2: clustering by repetition

No labels this time -- just group similar rows. Seed k
centroids at random, drop every row into its nearest one,
move each centroid to its members' middle (`mids`), and
repeat. A cluster is just a xai Tbl clone, so each one
carries its own honest column summaries for free. The catch
is the random seed: a bad start makes bad clusters, which is
what lesson 3 fixes.

**Core ideas:** [kmeans](../glossary.md#kmeans),
[centroid](../glossary.md#centroid)
]]
eg.kmeans = {}

-- - **xp.kmeans(data,k,iter)** returns k clusters (Tbl
--   clones); iter passes of assign-then-recentre.
eg.kmeans["--cluster"] = function(    d,cl,tot,ns)
  d  = Tbl.new(DATA)
  cl = xp.kmeans(d, 5)
  tot, ns = 0, {}
  for _,c in ipairs(cl) do
    tot = tot + #c.rows; lst.push(ns, #c.rows) end
  print("5 clusters, sizes:", str.o(lst.sort(ns)))
  assert(#cl >= 1 and #cl <= 5)
  assert(tot == #d.rows) end            -- every row placed once

--[[
**Exercises (lesson 2).**

0. In your own favorite language (not lua), implement kmeans
   and print your cluster sizes.
1. (simple) Rerun with `--kluster=3` then 12. How do the
   sizes spread, and does `--iter=1` differ much from 20?
2. Report each cluster's purity: the fraction of its rows
   sharing the majority klass (reuse `Sym`). Do the
   unsupervised clusters line up with the real classes?
]]

-- ## Kmeanspp
--[[
### Lesson 3: seeding clusters far apart

Random seeds clump; kmeans++ spreads them. Draw the first
centroid at random, then each next one from a small pool
with probability proportional to its SQUARED distance to the
nearest centroid so far -- so far-away rows are far likelier
to be picked. Better seeds mean fewer wasted iterations for
lesson 2's kmeans.

**Core ideas:** [kmeanspp](../glossary.md#kmeanspp),
[centroid](../glossary.md#centroid)
]]
eg.kmeanspp = {}

-- - **xp.kpp(data,k,few)** returns k seed rows chosen by
--   kmeans++ (d^2-weighted picks from a `few`-row pool).
eg.kmeanspp["--seed"] = function(    d,cs,spread,gap)
  d  = Tbl.new(DATA)
  cs = xp.kpp(d, 5)
  spread, gap = 0, 0
  for i = 1, #cs do for j = i + 1, #cs do
    gap = gap + 1; spread = spread + d:distx(cs[i], cs[j]) end end
  print("5 kmeans++ seeds, mean pair distance:",
        str.o(spread/gap))
  assert(#cs == 5)
  assert(spread/gap > 0) end            -- seeds are distinct

--[[
**Exercises (lesson 3).**

0. In your own favorite language (not lua), write the d^2
   seeding and print the mean pair distance.
1. (simple) Compare the mean pair distance of `xp.kpp` seeds
   against 5 random rows (`rnd.some`). By how much does
   kmeans++ spread them?
2. Feed `xp.kpp`'s seeds to `xp.kmeans` as its start (add a
   `cents` argument). Does a kmeans++ start lower the final
   assignment error versus a random start?
]]

-- ## Bayes
--[[
### Lesson 4: likelihoods, the Bayes way

Before classifying, learn to score. `like` answers P(v|col):
for a Num column it is the gaussian bell (peak at the mean,
thin tails), for a Sym a smoothed frequency. `likes`
multiplies a row's per-column likelihoods (in log space, so
it sums) to score a whole row under one klass's model. A
value at the column mean is far likelier than one three sd
out -- exactly the signal the classifier leans on.

**Core ideas:** [bayes](../glossary.md#bayes),
[gauss](../glossary.md#gauss)
]]
eg.bayes = {}

-- - **xp.bayes.like(col,v,prior)** P(v|col): Sym m-estimate, Num
--   gaussian pdf.
-- - **xp.bayes.likes(h,row,n,nh)** log-likelihood of a row under a
--   klass model h (a Tbl of that klass's rows).
eg.bayes["--like"] = function(    d,c,near,far)
  d    = Tbl.new(DATA)
  c    = d.cols.x[1]                    -- a numeric feature
  near = xp.bayes.like(c, c.mu, 0.5)          -- value at the mean
  far  = xp.bayes.like(c, c.mu + 3*c:spread(), 0.5)   -- 3 sd out
  print("like at mean vs 3sd out:", str.o(near), str.o(far))
  assert(near > far)                    -- typical = likelier
  assert(near > 0) end

--[[
**Exercises (lesson 4).**

0. In your own favorite language (not lua), write `like` for
   Num and Sym columns and reproduce this line.
1. (simple) Print `xp.bayes.like` for a klass Sym at `--k=1` then
   `--k=1000`. What does heavy smoothing do to rare values?
2. Split breast.w by klass into two Tbls; show `xp.bayes.likes`
   scores a benign row higher under the benign model than
   under the malignant one.
]]

-- ## Classify
--[[
### Lesson 5: naive Bayes, test-then-train

Now the classifier. Walk the rows once: for each, first
PREDICT its klass (whichever model gives the highest
[likes](../glossary.md#bayes)), score that guess in a
confusion matrix, and only THEN train the true klass's
model. So every row is tested on models that never saw it --
an honest running accuracy from a single pass. On breast.w
that lands in the mid-90s.

**Core ideas:** [bayes](../glossary.md#bayes),
[confusion](../glossary.md#confusion),
[mode](../glossary.md#mode)
]]
eg.classify = {}

-- - **xp.classify(data,wait)** incremental naive Bayes;
--   returns a Confuse matrix (`:acc()` = its accuracy).
eg.classify["--acc"] = function(    d,cf)
  d  = Tbl.new(DATA)
  cf = xp.classify(d)
  print("naive Bayes accuracy on breast.w:", str.o(cf:acc()))
  assert(cf:acc() > 0.9)
  assert(cf.n > 600) end                -- scored most rows

--[[
**Exercises (lesson 5).**

0. In your own favorite language (not lua), write the
   test-then-train loop and reproduce the accuracy.
1. (simple) Vary `--wait` (10, 50, 200). Does a longer
   warm-up before scoring raise or lower the reported acc,
   and why?
2. From the Confuse `cells`, print the two most common
   mistakes (want|got pairs off the diagonal). Which klass
   is hardest to tell apart?
]]

-- ## Mutate
--[[
### Lesson 6: making new rows

The optimizers coming next must INVENT rows, not just pick
them. Three mutators do it. `pick` samples one new cell (a
Sym by frequency, a Num nudged by a [gauss](../glossary.md#gauss)
and clamped near its mean); `picks` mutates a few cells of a
copied row; `extrapolate` is differential evolution's move
-- blend three rows as a + F*(b - c) -- but it always keeps
at least one column straight from `a`, so a child never
wholly forgets its base.

**Core ideas:** [mutate](../glossary.md#mutate),
[gauss](../glossary.md#gauss)
]]
eg.mutate = {}

-- - **xp.mutate.pick(col,v)** one fresh value for a column.
-- - **xp.mutate.picks(data,row,n)** copy row, mutate n of its x cells.
-- - **xp.mutate.extrapolate(cols,a,b,c)** DE blend a+F*(b-c); one
--   column always kept from a.
eg.mutate["--picks"] = function(    d,r,m,diff)
  d    = Tbl.new(DATA)
  r    = d.rows[1]
  m    = xp.mutate.picks(d, r, 3)              -- mutate 3 x cells
  diff = 0
  for _,c in ipairs(d.cols.x) do
    if m[c.at] ~= r[c.at] then diff = diff + 1 end end
  print("cells changed by picks(n=3):", diff, "of", #d.cols.x)
  assert(#m == #r)
  assert(diff <= 3) end                 -- at most n changed

eg.mutate["--extrapolate"] = function(    d,a,b,c,kid,same)
  d = Tbl.new(DATA)
  a, b, c = d.rows[1], d.rows[2], d.rows[3]
  kid, same = xp.mutate.extrapolate(d.cols.x, a, b, c), 0
  for _,col in ipairs(d.cols.x) do
    if kid[col.at] == a[col.at] then same = same + 1 end end
  print("x cols kept from base a:", same, "of", #d.cols.x)
  assert(#kid == #a)
  assert(same >= 1) end                 -- keep guarantees >=1

--[[
**Exercises (lesson 6).**

0. In your own favorite language (not lua), write the three
   mutators and reproduce these lines.
1. (simple) Rerun `--extrapolate` with `--cr=0.1` then 0.9.
   How does the crossover rate change how many columns the
   child keeps from a?
2. Show `xp.mutate.picks` never leaves a Num cell outside mu +-3sd:
   mutate one column 1000 times and check the range.
]]

-- ## Main
eg.main = {}

-- run one test, reseeded
local function run(fn) rnd.seed(the.seed); fn() end

-- flags of one section in SOURCE order, parsed from this
-- file (pairs() loses definition order).
local egsrc
local function keysof(name,    seen,out)
  egsrc = egsrc or io.open"xaiplus-eg.lua":read"*a"
  seen, out = {}, {}
  for k in egsrc:gmatch('eg%.'..name..'%["(%-%-%w+)"%]') do
    if eg[name][k] and not seen[k] then
      seen[k] = true; lst.push(out, k) end end
  for k in pairs(eg[name]) do
    if not seen[k] then lst.push(out, k) end end
  return out end

-- run one section's tests, in source (reading) order
local function section(name)
  for _,k in ipairs(keysof(name)) do
    print("\n-- " .. k)
    run(eg[name][k]) end end

eg.main["-h"] = function()
  print(xp.help .. "\nApps (and their tests):\n")
  for _,n in ipairs(order) do
    print("  lua xaiplus-eg.lua --" .. n .. "   # or: " ..
          table.concat(keysof(n), " ")) end
  print("\nAlso: --all -h --join --transcript --check")
  end

eg.main["--all"] = function()
  for _,n in ipairs(order) do
    print("\n---- " .. n .. " " .. ("-"):rep(40))
    section(n) end
  print("\nall pass") end

-- freeze the printed pedagogy to xaiplus-eg.out (from a real
-- run, never hand-edited); --check diffs a fresh run to it
eg.main["--transcript"] = function()
  assert(os.execute(
    "lua xaiplus-eg.lua --all > xaiplus-eg.out"))
  print("xaiplus-eg.out frozen") end

eg.main["--check"] = function(    ok)
  ok = os.execute(
    "lua xaiplus-eg.lua --all | diff - xaiplus-eg.out")
  print(ok and "transcript ok" or "TRANSCRIPT DRIFT")
  assert(ok) end

-- join checker (per-course half): every glossary link in a
-- lesson lands on a heading, and every dot-list signature
-- names a real function (in xp or xai). The repo-wide "is
-- every heading taught" check is `make check` (etc/join.py).
-- walk "xp.knn" through nested tables; nil if absent
local function deref(root, name,    r)
  r = root
  for w in name:gmatch"[%w_]+" do
    r = type(r) == "table" and r[w] end
  return r end

eg.main["--join"] = function(    doc,src,keys,ok,ns)
  doc = io.open"../glossary.md":read"*a"
  src = io.open"xaiplus-eg.lua":read"*a"
  keys, ok = {}, true
  ns = {xp=xp, xai=xai}                  -- resolve xp.* / xai.*
  for k in doc:gmatch"\n## ([a-z]+)\n" do keys[k] = true end
  for k in src:gmatch"glossary%.md#([a-z]+)" do
    if not keys[k] then ok=false; print("no heading:",k) end end
  for line in src:gmatch"[^\n]+" do
    if line:find"^%-%- %- %*%*" then
      for sig in line:gmatch"%*%*([%w_./]+)%(" do
        for nm in sig:gmatch"[%w_.]+" do
          if not (deref(ns,nm) or deref(_G,nm)) then
            ok = false; print("missing fn:", nm) end end end end end
  assert(ok) end

-- cli: --key=val sets an option, --name runs a section, other
-- names run one test. Flags steer only the egs that follow.
local function cli(    k,v)
  for i,s in ipairs(arg) do
    k,v = s:match"^%-%-(%w+)=(%S+)$"
    if v then
      if the[k] == nil then error("unknown --" .. k) end
      the[k] = str.what(v) end
    for key,_ in pairs(the) do
      if s == "-" .. key:sub(1,1) and arg[i+1] then
        the[key] = str.what(arg[i+1]) end end
    if eg[s:sub(3)] then section(s:sub(3))
    else
      for _,sect in pairs(eg) do
        if sect[s] then run(sect[s]) end end end end end

if arg and arg[0] and arg[0]:find"xaiplus%-eg" then cli() end
return eg
