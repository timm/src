---
name: cite-check
description: Use when adding references, DOIs, or paper links to docs (glossary.md footnotes, REPORT.md, course reading lists), or when asked to verify that cited papers and their URLs are real and resolve.
---

# cite-check: resolve and verify reference links

Goal: every citation carries a URL the reader can actually
check. Never emit a DOI or arxiv id from memory — resolve
it, then verify it. Style.md requires references to end in
a DOI or other stable link "so a reader can verify the
paper is real"; this is how.

## Gotchas first (they cost the most time)

- macOS system python3 `urllib` fails all HTTPS with
  `CERTIFICATE_VERIFY_FAILED` (no certifi). Shell out to
  `curl` via subprocess instead.
- Semantic Scholar API rate-limits hard (unauthenticated:
  minutes-long stalls). Prefer Crossref; it is fast and
  unauthenticated.
- Publisher landing pages (IEEE, Elsevier, UCL eprints)
  403 bots. A 403 on the landing page does NOT mean a dead
  link — verify DOIs against the handle registry instead
  (below). If the user must click the link, swap a
  bot-blocked URL for the DOI form.
- Crossref's top hit can be a reprint, companion-volume, or
  wrong-year variant (e.g. GECCO companion vs the ASE full
  paper; a 1987 book chapter vs Science 1983). Check year
  and venue; when wrong, re-query with `rows=3` and pick by
  eye.

## Resolve: title -> DOI (Crossref)

    curl -s -A "me/1.0 (mailto:YOU@example.com)" \
      "https://api.crossref.org/works?rows=3&select=DOI,title,issued&query.bibliographic=TITLE&query.author=SURNAMES"

Take `message.items[].DOI`, render as
`https://doi.org/<DOI>`. Loop this in python via
`subprocess.run(["curl",...])`, saving incrementally so a
timeout keeps partial results.

## Verify: every link, before publishing

- DOI: `curl -s https://doi.org/api/handles/<DOI>` ->
  JSON `responseCode == 1` means registered. No publisher
  involved, so no bot blocks, no false negatives.
- arxiv: `curl -s -o /dev/null -w '%{http_code}' https://arxiv.org/abs/<ID>`
  -> expect 200.
- Other URLs: same `%{http_code}` check with `-L`; treat
  403 as "exists but bot-blocked" — replace with a
  checkable link if readers will click it.

State in the doc when links were verified ("all links
resolve as of YYYY-MM-DD").

## Common mistakes

- Trusting a remembered DOI/arxiv id: plausible-looking
  ids are often off by one digit. Resolve, don't recall.
- Curling publisher pages to test DOIs: 403s read as dead
  links. Use the handle registry.
- Accepting Crossref hit #1 blind: verify year/venue
  against what you cite in the text.
