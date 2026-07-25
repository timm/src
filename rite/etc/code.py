#!/usr/bin/env python3
"""Draft coding grid (Table-4 style) for the reading
lists. For each paper, fetch its OpenAlex abstract and
flag four booleans by keyword:
  SE  mentions software engineering tasks
  MO  multi-objective / search-based / optimization
  EX  explanation / interpretability
  BM  benchmark / baseline / empirical comparison
Writes coding.tsv beside each index.tsv and prints the
group counts (the Figure-2 substitute). Keyword coding
is a DRAFT: hand-audit each row while reading."""
import os, re, json, urllib.request
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from flags import FLAGS, LEGEND

def abstract(doi):
  try:
    u = ("https://api.openalex.org/works/doi:%s"
         "?select=abstract_inverted_index,title"
         "&mailto=timm@ieee.org" % doi)
    with urllib.request.urlopen(u) as r:
      w = json.load(r)
    inv = w.get("abstract_inverted_index") or {}
    words = sorted((p, t) for t, ps in inv.items()
                   for p in ps)
    return (w.get("title") or "") + " " + \
           " ".join(t for _, t in words)
  except Exception:
    return ""

def code(src, dst):
  rows = [l.rstrip("\n").split("\t")
          for l in open(src)][1:]
  out, combos = [], {}
  for r in rows:
    doi, title = r[-2], r[-1]
    text = (abstract(doi) if doi else title).lower()
    got = {k: bool(re.search(p, text))
           for k, p in FLAGS.items()}
    out.append((title, got))
    key = "".join(k for k in FLAGS if got[k]) or "none"
    combos[key] = combos.get(key, 0) + 1
  with open(dst, "w") as f:
    f.write("SE\tMO\tEX\tBM\ttitle\n")
    for title, got in out:
      f.write("\t".join(
        ["y" if got[k] else "." for k in FLAGS]
        + [title]) + "\n")
  return combos

recent  = code("read.tsv", "../lit/recent/coding.tsv")
classic = code("read-classics.tsv",
               "../lit/classics/coding.tsv")

keys = sorted(set(recent) | set(classic),
              key=lambda k: -(recent.get(k, 0)
                              + classic.get(k, 0)))
with open("../lit/coding.md", "w") as f:
  f.write("# Draft coding stats (keyword pass over "
          "OpenAlex abstracts)\n\n"
          "Flags: %s."
          "\n'none' rows mostly = abstract withheld by "
          "publisher; hand-audit during full-text read "
          "(see practices.md, Brereton 2007).\n\n"
          "| group | recent (n=%s) | classic (n=%s) |\n"
          "|-------|-----:|------:|\n"
          % (LEGEND, sum(recent.values()),
             sum(classic.values())))
  for k in keys:
    f.write("| %s | %s | %s |\n"
            % (k, recent.get(k, 0), classic.get(k, 0)))
  f.write("\nObservations: hand-written, per topic; see "
          "coding-notes.md (never regenerated).\n")
print("wrote ../lit/coding.md")
