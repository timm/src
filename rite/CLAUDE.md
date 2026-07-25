# CLAUDE.md

This repo builds one research paper. It is also a
template: to start a new paper, copy the whole dir,
rewrite the per-project files below, rerun the pipeline.

## Read before editing

README.md (the goal; scripts parse it), then HOWTO.md
(the 14-step loop and the eight prompt divisions), then
the skills under .claude/skills/ -- they govern ALL
prose, including the banned-LLM-tells list (prose), the
shipping self-test (ship), and the benchmark norms this
paper will be judged against (bench).

## Template vs per-project

Template -- reuse unchanged on a new topic:

    CLAUDE.md, HOWTO.md, .claude/skills/ (except bench),
    etc/*.py (except flags.py)

Per-project -- rewrite or regenerate per topic:

    README.md      goal: and years: lines; SSOT for the
                   literature search (fetch.py reads it)
    etc/flags.py   coding vocabulary; SSOT for the flags
    .claude/skills/bench/
                   benchmarking norms of the target
                   field, with [verify] marks
    lit/           pipeline output + hand-written notes
    pdf/           hand-archived source/method papers

## Pipeline (run from etc/, in order)

    1 fetch.py     OpenAlex search of README goal ->
                   papers.tsv, cites.txt (knee marked),
                   read.tsv (above-knee reading list)
    2 snowball.py  backward snowball over above-knee
                   refs -> classics.tsv,
                   read-classics.tsv (seen >= 5)
    3 stubs.py     lit/{recent,classics}/: index.tsv +
                   one note-stub .md per paper (reruns
                   never overwrite stubs)
    4 code.py      draft keyword coding over abstracts
                   -> lit/*/coding.tsv, lit/coding.md
    5 getpdfs.py   fetch open-access PDFs ->
                   lit/*/pdf/NN.pdf (NN = index.tsv row)
    6 recode.py    full-text recode, per-1k thresholds,
                   tf-idf + stemming -> lit/coding-full.md

## Hard rules

1. Search goal lives in README.md only; coding vocabulary
   lives in etc/flags.py only. Never restate either in a
   script.
2. Never code papers from title+abstract alone. Measured
   here (n=22, lit/coding-full.md): abstracts missed
   about half the topic flags. Code full text.
3. Naive binary matching over full text saturates (every
   10-page PDF mentions everything once). Use recode.py's
   per-1k threshold; binary columns are shown only to
   document the artifact.
4. Keyword coding is a draft. Hand-audit rows while
   reading. Hand-written material lives in the lit/*/
   note stubs and lit/coding-notes.md; no script may
   overwrite it.
5. Expect roughly half the recents and a fifth of the
   classics to have open-access PDFs. The download rate
   is itself a finding: report it, never silently drop
   the missing papers.
6. All prose, including this file, obeys the prose and
   structure skills in .claude/skills/.
