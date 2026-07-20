FILES="xai.lisp
       xai-eg.lisp
       xai-eg.out
       dtlz.lisp
       xaiplus.lisp
       xaiplus-eg.lisp
       xaiplus-eg.out
       report.lisp"
: <<'DOCS'

# ezr-lisp

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr-lisp/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr-lisp/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
