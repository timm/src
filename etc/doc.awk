# lispdoc preprocessing for pycco (lisp -> .scm):
#  - "#| ... |#" blocks -> markdown prose (tutorial stanzas)
#  - ";;; ## name"      -> markdown heading comment
#  - ";;;" art lines    -> dropped (figlet banners)
#  - ";;;;" prose       -> plain comment
#  - "; vim:" line      -> dropped (editor modeline)
#  - "; text" col 0     -> plain comment (function notes)
#  - one-line docstrings lift ABOVE their defun as comments
#    (tests keep docstrings; engine uses "; text" notes)
BEGIN { n = 0 }
/^#\|/      { md = 1; next }
/^\|#/      { md = 0; next }
md          { print ";; " $0; next }
/^;;; ## /  { print ""; print ";; " substr($0, 5); next }
/^;;;;/     { print ";; " substr($0, 6); next }
/^;;;/      { next }
/^; vim:/   { next }
/^; /       { print ";;" substr($0, 2); next }
/^\((defun|defmethod|defmacro) / {
  n = 1; buf[n] = $0; next }
n && /^ +".*"$/ {
  doc = $0
  gsub(/^ +"|"$/, "", doc)
  print ";; " doc
  for (i = 1; i <= n; i++) print buf[i]
  n = 0; next }
n {
  if (n > 4 || $0 !~ /^ /) {
    for (i = 1; i <= n; i++) print buf[i]
    n = 0; print; next }
  buf[++n] = $0; next }
{ print }
