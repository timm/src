#!/usr/bin/env python3
"""Full-text recode of the reading lists, compared to the
abstract-level coding in coding.tsv.

Flags (fixed vocab) are regex families, as before.
Stemming (Harman S-stemmer plus light suffix strip) is
used only for the open-vocabulary tf-idf keywords --
where the vocabulary is fixed, regex families already do
the conflation. (The IR literature says English stemming
buys little; included to keep the masses happy.)

Outputs ../lit/coding-full.md: download rates, per-flag
abstract-vs-fulltext agreement (binary and per-1k
thresholded), group tables, top tf-idf terms per paper."""
import os, re, math, subprocess
from collections import Counter
os.chdir(os.path.dirname(os.path.abspath(__file__)))
from flags import FLAGS, LONG, TECH, TECH_LONG
PER1K = 0.5   # matches per 1000 words to count a flag

STOP = set("""the a an and or of to in for with on by is
are was were be been this that these those we our it its
as at from can may not no than then which who whose what
their there here also into over under between each such
more most other others only some all any both new used
using use paper method methods result results model
models approach approaches data section table figure
have has had do does done els et al""".split())

def stem(w): # Harman S-stemmer + light suffixes
  if len(w) > 4 and w.endswith("ies"): return w[:-3]+"y"
  if len(w) > 3 and w.endswith("es") and \
     w[-3] not in "aeo": return w[:-1]
  if len(w) > 3 and w.endswith("s") and \
     w[-2] not in "us": return w[:-1]
  for suf in ("ation", "ing", "ed"):
    if len(w) > len(suf)+3 and w.endswith(suf):
      return w[:-len(suf)]
  return w

def words(text):
  return [stem(w) for w in
          re.findall(r"[a-z]+", text.lower())
          if len(w) > 3 and w not in STOP]

def fulltext(pdf):
  try:
    r = subprocess.run(["pdftotext", pdf, "-"],
                       capture_output=True, text=True,
                       timeout=60)
    return r.stdout if r.returncode == 0 else ""
  except Exception:
    return ""

def flags(text, n1k=False, fam=None):
  fam = fam or FLAGS
  n = max(1, len(text.split()))
  out = {}
  for k, p in fam.items():
    m = len(re.findall(p, text.lower()))
    out[k] = (m / n * 1000 >= PER1K) if n1k else m > 0
  return out

def group(g): return "x".join(k for k in FLAGS
                              if g[k]) or "none"

def load(src): # coding.tsv rows: SE MO EX BM title
  rows = [l.rstrip("\n").split("\t")
          for l in open(src)][1:]
  return [({k: r[i] == "y" for i, k in
            enumerate(FLAGS)}, r[4]) for r in rows]

report = ["# Abstract vs full-text coding", "",
  "## Flag legend (topic facet)", ""]
report += ["- %s: %s" % (k, LONG[k]) for k in FLAGS]
report += ["",
  "A group like SExMOxBM is an AND: that exact set of",
  "flags fired, no others. Each paper appears in exactly",
  "one group row.", "",
  "Columns: abs = fired in title+abstract; full-bin =",
  "any single match anywhere in the full text; full-thr",
  "= fired at >=%s matches per 1000 words of full text."
  % PER1K, "",
  "Length-normalised term frequency is standard IR",
  "practice (Salton & Buckley 1988); the %s cutoff" % PER1K,
  "itself is ours, not from the literature. Before any",
  "of these numbers reach a paper, sensitivity-check the",
  "cutoff (vary it; show the group table is stable).", ""]
docs, names = [], []
tbl = Counter(); flips = Counter(); n_pdf = 0
combA = Counter(); combB = Counter(); combT = Counter()
techB = Counter(); techT = Counter()

for lst in ("recent", "classics"):
  old = load("../lit/%s/coding.tsv" % lst)
  for i, (a_flags, title) in enumerate(old, 1):
    pdf = "../lit/%s/pdf/%02d.pdf" % (lst, i)
    if not os.path.exists(pdf): continue
    text = fulltext(pdf)
    if len(text) < 1000: continue
    n_pdf += 1
    fb, ft = flags(text), flags(text, n1k=True)
    combA[group(a_flags)] += 1
    combB[group(fb)] += 1
    combT[group(ft)] += 1
    for k in FLAGS:
      tbl[(k, a_flags[k], fb[k], ft[k])] += 1
      if a_flags[k] != ft[k]: flips[k] += 1
    tb = flags(text, fam=TECH)
    tt = flags(text, n1k=True, fam=TECH)
    for k in TECH:
      techB[k] += tb[k]; techT[k] += tt[k]
    ws = words(text)
    docs.append(Counter(ws)); names.append(
      "%s/%02d %s" % (lst, i, title[:48]))

report += ["%s PDFs with usable text." % n_pdf, "",
  "## Per-flag agreement, abstract vs full text",
  "(binary = any match; thr = >=%s per 1k words)" % PER1K,
  "", "| flag | abs=y | full-bin=y | full-thr=y |"
  " flips abs->thr |", "|---|---|---|---|---|"]
for k in FLAGS:
  ay = sum(v for (f,a,b,t),v in tbl.items()
           if f==k and a)
  by = sum(v for (f,a,b,t),v in tbl.items()
           if f==k and b)
  ty = sum(v for (f,a,b,t),v in tbl.items()
           if f==k and t)
  report += ["| %s | %s | %s | %s | %s |"
             % (k, ay, by, ty, flips[k])]

report += ["", "## Group tables (same %s papers)" % n_pdf,
  "", "| group | abstract | full-bin | full-thr |",
  "|---|---|---|---|"]
for g in sorted(set(combA)|set(combB)|set(combT),
    key=lambda g: -(combA[g]+combB[g]+combT[g])):
  report += ["| %s | %s | %s | %s |"
             % (g, combA[g], combB[g], combT[g])]

report += ["", "## Technology facet (same %s papers; "
  "DRAFT, hand-audit while reading)" % n_pdf, "",
  "Topic flags above say which literature a paper is in;",
  "these say how its method works. Full text only",
  "(abstracts under-report methodology).", "",
  "| tech | full-bin=y | full-thr=y | meaning |",
  "|---|---|---|---|"]
for k in TECH:
  report += ["| %s | %s | %s | %s |"
             % (k, techB[k], techT[k], TECH_LONG[k])]

df = Counter()
for d in docs:
  for w in d: df[w] += 1
N = len(docs)
report += ["", "## Top tf-idf terms per paper (stemmed)",
           ""]
for d, name in zip(docs, names):
  tot = sum(d.values())
  top = sorted(d, key=lambda w:
    -(d[w]/tot) * math.log(N/df[w]))[:5]
  report += ["- %s: %s" % (name, ", ".join(top))]

open("../lit/coding-full.md", "w").write(
  "\n".join(report) + "\n")
print("\n".join(report[:30]))
