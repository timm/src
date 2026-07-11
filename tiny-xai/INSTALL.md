FILES="dtlz.lisp  
      tiny-xai-eg.lisp   
      tiny-xai.lisp"   
: <<'DOCS'

# tiny-xai

Install into the current dir:

    curl -fsSL http://tiny.cc/aiez/INSTALL.md | sh

List files only:

    curl -fsSL http://tiny.cc/aiez/INSTALL.md | sh -s -- list

DOCS
if [ -n "$1" ]
then echo $FILES
else for f in $FILES; do 
       echo "# $f"; curl -fL "http://tiny.cc/aiez/$f" -o "$f"; done
