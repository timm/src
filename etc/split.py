#!/usr/bin/env python3
"""
split.py: cut each INSTALL.md source file into one piece per
## section marker, written to ../docs/<proj>/<slug>.<ext>.part
plus a .order manifest (name TAB source TAB group) that
drives doc.awk/pycco/nav/toc. A file's head (before its
first marker) keeps the file's own name; files without
markers stay whole. Run from inside a project dir (make doc
does).
"""
import os, re, subprocess

MARK = {".py":   r"^#-- +(.+?) -*$",
        ".lisp": r"^;;; ## +(.+)$",
        ".lua":  r"^-- ## +(.+)$"}

def slug(t):
  return re.sub(r"-+", "-",
                re.sub(r"[^a-z0-9]+", "-", t.lower())
                ).strip("-")

proj = os.path.basename(os.getcwd())
out  = os.path.join("..", "docs", proj)
os.makedirs(out, exist_ok=True)
srcs = subprocess.run(["sh", "INSTALL.md", "list"],
                      capture_output=True, text=True
                      ).stdout.split()
order, seen = [], set()
for src in srcs:
  stem, ext = os.path.splitext(src)
  group  = "tests" if stem.endswith("-eg") else "code"
  pieces = [(stem, [])]
  pat    = MARK.get(ext)
  for line in open(src).read().splitlines():
    if line == "\f": continue
    m = pat and re.match(pat, line)
    if m: pieces.append((slug(m.group(1)), []))
    pieces[-1][1].append(line)
  for name, lines in pieces:
    body = "\n".join(lines).strip()
    if not body: continue
    assert name not in seen, "slug clash: " + name
    seen.add(name)
    open("%s/%s%s.part" % (out, name, ext), "w"
         ).write(body + "\n")
    order.append("%s\t%s\t%s" % (name, src, group))
open(os.path.join(out, ".order"), "w"
     ).write("\n".join(order) + "\n")
print("split: %s -> %d pages" % (proj, len(order)))
