# fences.awk: fix and fill markdown code fences.
#
# 1. A bare opening ``` becomes ```py.
# 2. Inside a fence, a line "def xxx..." is replaced by
#    the full def of that name found in the *.py files
#    (a def runs to the next blank line).
#
# Usage: awk -f etc/fences.awk src/*.py chapter.md
# .py args are read for defs; .md args are rewritten to
# stdout.

FILENAME ~ /\.py$/ {
  if ($0 ~ /^def /) {
    cur = $2; sub(/\(.*/, "", cur); DEF[cur] = $0
  } else if (cur != "") {
    if ($0 == "") cur = ""
    else          DEF[cur] = DEF[cur] "\n" $0
  }
  next
}

/^```/ {
  if (!infence) { infence = 1; if ($0 == "```") $0 = "```py" }
  else            infence = 0
  print; next
}

infence && /^def / {
  name = $2; sub(/\(.*/, "", name)
  if (name in DEF) { print DEF[name]; next }
}

{ print }
