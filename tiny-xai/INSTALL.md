FILES="bins-eg.lisp
       bins.lisp
       cols-eg.lisp
       cols.lisp
       dist-eg.lisp
       dist.lisp
       dtlz.lisp
       landscape-eg.lisp
       landscape.lisp
       lib-eg.lisp
       lib.lisp
       macros-eg.lisp
       macros.lisp
       main-eg.lisp
       main.lisp
       query-eg.lisp
       query.lisp
       rand-eg.lisp
       rand.lisp
       stats-eg.lisp
       stats.lisp
       tbl-eg.lisp
       tbl.lisp
       tiny-xai-eg.lisp
       tiny-xai.lisp"
: <<'DOCS'

# tiny-xai

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/tiny-xai/INSTALL.md | sh

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/tiny-xai/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
