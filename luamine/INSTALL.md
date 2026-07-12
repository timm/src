FILES="lib.lua
       rand.lua
       list.lua
       stats.lua
       confuse.lua
       str.lua
       cli.lua
       luamine.lua
       cut.lua
       sym.lua
       num.lua
       cols.lua
       data.lua
       dist.lua
       bayes.lua
       mutate.lua
       tree.lua
       show.lua
       lapps.lua
       cluster.lua
       classify.lua
       acquire.lua
       sample.lua
       bob.lua
       race.lua
       ga.lua
       de.lua
       search.lua
       tutchk.lua
       luamine-eg.lua
       list-eg.lua
       rand-eg.lua
       stats-eg.lua
       confuse-eg.lua
       str-eg.lua
       cli-eg.lua
       cols-eg.lua
       data-eg.lua
       dist-eg.lua
       cut-eg.lua
       tree-eg.lua
       bayes-eg.lua
       mutate-eg.lua
       cluster-eg.lua
       classify-eg.lua
       acquire-eg.lua
       sample-eg.lua
       bob-eg.lua
       ga-eg.lua
       de-eg.lua
       search-eg.lua
       race-eg.lua"
: <<'DOCS'

# luamine

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/luamine/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/luamine/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
