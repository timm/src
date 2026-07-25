#!/usr/bin/env python3
"""Fetch open-access PDFs for both reading lists, into
../lit/recent/pdf/ and ../lit/classics/pdf/. Reports how
many could be downloaded (finding #1 of the coding
study). Skips files already present."""
import os, json, time, urllib.request, urllib.parse
os.chdir(os.path.dirname(os.path.abspath(__file__)))

UA = {"User-Agent": "Mozilla/5.0 (research; timm@ieee.org)"}

def oa_url(doi):
  try:
    u = ("https://api.openalex.org/works/doi:%s"
         "?select=best_oa_location,open_access"
         "&mailto=timm@ieee.org" % doi)
    with urllib.request.urlopen(u) as r:
      w = json.load(r)
    loc = w.get("best_oa_location") or {}
    return loc.get("pdf_url")
  except Exception:
    return None

def grab(src, dst):
  os.makedirs(dst, exist_ok=True)
  rows = [l.rstrip("\n").split("\t")
          for l in open(src)][1:]
  ok = miss = 0
  for i, r in enumerate(rows, 1):
    doi, out = r[-2], "%s/%02d.pdf" % (dst, i)
    if os.path.exists(out): ok += 1; continue
    url = doi and oa_url(doi)
    if url:
      try:
        rq = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(rq, timeout=60) as f:
          data = f.read()
        if data[:4] == b"%PDF":
          open(out, "wb").write(data); ok += 1
        else: miss += 1
      except Exception: miss += 1
    else: miss += 1
    time.sleep(1)
  print("%s: %s of %s downloaded" % (dst, ok, len(rows)))
  return ok, len(rows)

a = grab("read.tsv", "../lit/recent/pdf")
b = grab("read-classics.tsv", "../lit/classics/pdf")
print("TOTAL %s of %s" % (a[0]+b[0], a[1]+b[1]))
