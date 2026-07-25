# Coding observations (hand-written; scripts never touch)

Moved out of etc/code.py so the pipeline stays
topic-neutral. Drafted from the abstract-level pass;
re-check after full-text coding (coding-full.md).

- Only 1 of 43 recents flags SE+MO+EX together: the
  three-way intersection this paper aims to fill is
  (nearly) empty. Fig-2-style argument available.
- Classics are almost purely EX: the shared ancestry of
  this literature is the XAI canon. The multi-objective
  tradition contributes no widely shared classics --
  recents citing MO methods do not co-cite a common MO
  ancestor. The two parent literatures have not yet
  merged; that asymmetry is itself a finding.
- BM flags are rare in abstracts even where papers do
  benchmark; abstract-level coding under-reports
  methodology. Full-text pass required before any of
  these numbers reach the paper.
- Full-text pass done (coding-full.md): 22/54 PDFs
  downloadable (recents 47%, classics 18%). Abstracts
  missed roughly half the topic flags; naive binary
  full-text saturated on everything; per-1k thresholding
  + tf-idf restored signal. Title+abstract coding is not
  a cheap substitute for reading.
