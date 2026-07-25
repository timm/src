#!/usr/bin/env python3
"""Backward snowball: find the older papers everyone in
our above-knee reading list cites.

Reruns the README search (same pages, same year filter),
takes the above-knee set, harvests every reference list,
counts how many of our papers cite each work, then
resolves the most-shared ancestors to titles. Writes
classics.tsv: seen, cites, year, doi, title -- where
seen = how many of our papers cite it."""
import os, json, urllib.request, urllib.parse
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from collections import Counter
from fetch import GOAL, YEARS, API

def get(url):
  with urllib.request.urlopen(url) as r:
    return json.load(r)

def search(page, select):
  q = urllib.parse.urlencode(dict(
      search=GOAL, per_page=200, page=page, select=select,
      filter="publication_year:" + YEARS,
      mailto="timm@ieee.org"))
  return get(f"{API}?{q}")["results"]

sel = "id,cited_by_count,referenced_works"
papers = []
for page in (1, 2, 3):
  papers += search(page, sel)
papers = sorted(papers[:500],
                key=lambda p: -p["cited_by_count"])

cites = [p["cited_by_count"] for p in papers]
n = len(cites)
x1, y0, y1 = n - 1, cites[0], cites[-1]
dist = lambda i: abs((y1-y0)*i - x1*cites[i] + x1*y0)
knee = max(range(n), key=dist)
top  = papers[:knee + 1]
print("snowballing", len(top), "papers")

seen = Counter(w for p in top
               for w in p["referenced_works"])
best = [w for w, k in seen.most_common(100) if k >= 3]

rows, sel2 = [], "id,title,publication_year,cited_by_count,doi"
for i in range(0, len(best), 50):
  ids = "|".join(w.split("/")[-1] for w in best[i:i+50])
  q = urllib.parse.urlencode(dict(
      filter="openalex:" + ids, per_page=50, select=sel2,
      mailto="timm@ieee.org"))
  rows += get(f"{API}?{q}")["results"]

rows.sort(key=lambda p: -seen[p["id"]])
with open("classics.tsv", "w") as f:
  f.write("seen\tcites\tyear\tdoi\ttitle\n")
  for p in rows:
    f.write("%s\t%s\t%s\t%s\t%s\n" % (
      seen[p["id"]], p["cited_by_count"],
      p["publication_year"],
      (p["doi"] or "").replace("https://doi.org/", ""),
      (p["title"] or "").replace("\t", " ")))
keep = [p for p in rows if seen[p["id"]] >= 5]
with open("read-classics.tsv", "w") as f:
  f.write("seen\tcites\tyear\tdoi\ttitle\n")
  for p in keep:
    f.write("%s\t%s\t%s\t%s\t%s\n" % (
      seen[p["id"]], p["cited_by_count"],
      p["publication_year"],
      (p["doi"] or "").replace("https://doi.org/", ""),
      (p["title"] or "").replace("\t", " ")))
print(len(rows), "classics;", len(keep),
      "kept at seen >= 5")
