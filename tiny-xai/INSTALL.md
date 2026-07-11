FILES="tiny-xai.lisp
       macros.lisp
       lib.lisp
       rand.lisp
       cols.lisp
       query.lisp
       tbl.lisp
       dist.lisp
       landscape.lisp
       bins.lisp
       tree.lisp
       stats.lisp
       main.lisp
       dtlz.lisp
       tiny-xai-eg.lisp
       lib-eg.lisp
       macros-eg.lisp
       cols-eg.lisp
       query-eg.lisp
       rand-eg.lisp
       tbl-eg.lisp
       dist-eg.lisp
       stats-eg.lisp
       landscape-eg.lisp
       bins-eg.lisp
       tree-eg.lisp
       main-eg.lisp"
: <<'DOCS'

# tiny-xai

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/tiny-xai/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/tiny-xai/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
