#!/usr/bin/env python3
"""Build ../lit/recent/ and ../lit/classics/ from the two
reading lists: one index.tsv plus one note-stub .md per
paper. Reruns never overwrite an existing stub (notes
are hand-written; regeneration must not eat them)."""
import os, re
os.chdir(os.path.dirname(os.path.abspath(__file__)))

def slug(title, n=40):
  s = re.sub(r"[^a-z0-9]+", "-", title.lower())
  return s.strip("-")[:n].rstrip("-")

def build(src, dst):
  rows = [l.rstrip("\n").split("\t")
          for l in open(src)][1:]
  os.makedirs(dst, exist_ok=True)
  with open(f"{dst}/index.tsv", "w") as f:
    f.write("file\tcites\tyear\tdoi\ttitle\n")
    for i, r in enumerate(rows, 1):
      cites, year, doi, title = r[-4], r[-3], r[-2], r[-1]
      name = "%02d-%s-%s.md" % (i, year, slug(title))
      f.write("\t".join([name, cites, year, doi, title])
              + "\n")
      path = f"{dst}/{name}"
      if not os.path.exists(path):
        with open(path, "w") as g:
          g.write("# %s\n\n%s. %s cites. doi:%s\n"
                  "https://doi.org/%s\n\n## notes\n\n"
                  % (title, year, cites, doi, doi))
  print(dst, len(rows), "stubs")

build("read.tsv", "../lit/recent")
build("read-classics.tsv", "../lit/classics")
