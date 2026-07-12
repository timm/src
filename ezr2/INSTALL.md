FILES="ezr2.py
       lib.py
       rand.py
       cols.py
       data.py
       dist.py
       acquire.py
       bins.py
       tree.py
       stats.py
       show.py
       main.py
       report.py
       dtlz.py
       ezr2-eg.py
       lib-eg.py
       rand-eg.py
       cols-eg.py
       data-eg.py
       dist-eg.py
       stats-eg.py
       acquire-eg.py
       bins-eg.py
       tree-eg.py
       show-eg.py
       main-eg.py"
: <<'DOCS'

# ezr2

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr2/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr2/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
