FILES="dtlz.lisp
       tiny-xai-eg.lisp
       tiny-xai.lisp"
: <<'DOCS'

# tiny-xai

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/tiny-xai/INSTALL.md | sh

DOCS
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do 
    echo "# $f"; curl -fL "$base/$f" -o "$f"; done; fi
