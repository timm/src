# doc preprocessing for pycco; invoke: awk -v ext=py|lisp
# lisp (emit .scm):
#  - "#| ... |#" blocks -> markdown prose (tutorial stanzas)
#  - ";;; ## name"      -> markdown heading comment
#  - ";;;" art lines    -> dropped
#  - ";;;;" prose       -> plain comment
#  - "; vim:" line      -> dropped (editor modeline)
#  - "; text" col 0     -> plain comment (function notes)
#  - one-line docstrings lift ABOVE their defun as comments
# py (emit .py):
#  - bare `"""` lines toggle markdown prose blocks
#  - col-0 "# " notes pass through (already pycco prose)
#  - one-line docstrings lift ABOVE their def as comments
BEGIN { n = 0 }
ext == "py" && /^#!/   { next }
ext == "py" && /^"""$/ { md = !md; next }
ext == "py" && md      { print "# " $0; next }
ext == "py" && pd {
  if ($0 ~ /^  ".*"$/) {
    doc = $0; gsub(/^  "|"$/, "", doc)
    print "# " doc; print pd; pd = ""; next }
  print pd; pd = ""; print; next }
ext == "py" && /^def / { pd = $0; next }
ext == "py"            { print; next }
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
END { if (pd) print pd
      for (i = 1; i <= n; i++) print buf[i] }
