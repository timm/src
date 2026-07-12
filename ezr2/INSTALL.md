FILES="ezr2.py
       ezr2-eg.py
       dtlz.py
       report.py"
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
