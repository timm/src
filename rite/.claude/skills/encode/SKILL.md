---
name: encode
description: Code papers with the two flag facets at the thr threshold; never code from abstracts alone; check your own abstract the same way. Use at HOWTO steps 6, 13.
---

# encode

## Short form

- Two facets in etc/flags.py: topic (which literature) and technology (how the method works). SSOT; edit nowhere else.
- Never code from title+abstract: measured here, abstracts miss about half the flags (lit/coding-full.md, n=22).
- Binary matching over full text saturates; use the per-1k thr threshold (etc/recode.py).
- The cutoff value is ours, not the literature's: sensitivity-check it before publishing.
- Keyword coding is a draft; hand-audit while reading.
- Before submission: your own title+abstract must earn every flag your body earns at thr. Zero flips.

## Detail

## THE ABSTRACT CARRIES THE PAPER. ACT LIKE IT.

Our own measurement (lit/coding-full.md, n=22): coding
papers from title plus abstract missed roughly half the
topic flags that full-text coding found. Abstracts
systematically under-report what their papers contain.
Everyone who will ever judge our paper cheaply -- PC
members bidding, SLR authors coding, search engines
ranking, a practitioner skimming -- reads ONLY the title
and abstract. If a topic, method, dataset, or result is
not named there, then for most readers it is not in the
paper at all.

Hence the rule: before submission, run our own coding
grid on our own title plus abstract. Every flag the body
earns at the thr threshold (>=0.5 matches per 1k words;
etc/recode.py), the abstract must earn on its own. Same
coder, both texts, zero disagreement. If the abstract of
our paper would be miscoded by our own pipeline, rewrite
the abstract, not the pipeline.

(Aside: it has not escaped our attention that we spent a
career coding other people's abstracts, then wondered
what the heck we were writing in our own.)
