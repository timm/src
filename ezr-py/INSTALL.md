FILES="xai.py
       xai-eg.py
       xaiplus.py
       xaiplus-eg.py
       dtlz.py
       report.py"
: <<'DOCS'

# ezr-py

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr-py/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/ezr-py/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
