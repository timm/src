FILES="xai.lua
       xai-eg.lua
       xai-eg.out"
: <<'DOCS'

# xai

Install:

    curl -fL https://raw.githubusercontent.com/timm/src/refs/heads/main/xai/INSTALL.md | sh

List the files (reading order; also the doc page order):

    sh INSTALL.md list

DOCS
BASE="https://raw.githubusercontent.com/timm/src/refs/heads/main/xai/"
if [ -n "$1" ]; then echo $FILES; else
  for f in $FILES; do
    echo "# $f"
    curl -fL "$BASE/$f" -o "$f"
    done; fi
