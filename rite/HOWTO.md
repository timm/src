# HOWTO: the paper loop

Fourteen steps. The right column names the prompt
division that drives each step (divisions defined
below). Every prompt in this repo obeys one format
rule: short list first, full detail after, so a paper
describing this method can quote the short form and
cite the long one.

| #  | step                                          | prompts           |
|----|-----------------------------------------------|-------------------|
| 1  | define your area of interest                  | choose            |
| 2  | define "recent" (field velocity: 10yr         | search            |
|    | default; 2-3yr for LLM-speed fields)          |                   |
| 3  | list your best / most exciting recent papers  | choose            |
| 4  | define what you are good at (auto-extract     | choose            |
|    | from 3)                                       |                   |
| 5  | assemble critics (auto: above-knee papers     | critics           |
|    | from top venues, CFP reviewer-2, ACM          |                   |
|    | empirical standards, nearest-10 papers)       |                   |
| 6  | search: knee -> recents + classics; code      | search, encode    |
|    | full text at thr; find interesting subsets    |                   |
| 7  | define the most relevant problem (from 6) --  | choose            |
|    | or the strangest (Wheeler slice)              |                   |
| 8  | i=0; write paper[0] = title + abstract +      | prose, structure  |
|    | elevator speech; can't? not ready -> goto 7   |                   |
| 9  | i=i+1; write paper[i]; rest stays headers     | structure, prose  |
| 10 | go away, social media off; read 30-60 min     | critics           |
|    | making comments (critic 1 = you)              |                   |
| 11 | apply the other critics; split their fixes    | critics           |
|    | into auto and manual                          |                   |
| 12 | discuss with other humans                     | critics           |
| 13 | check + apply auto fixes; work the manual;    | encode, prose     |
|    | recode own title+abstract -- must match the   |                   |
|    | body's thr coding, zero flips                 |                   |
| 14 | self-test fails -> goto 9; passes -> ship     | ship              |
|    | with replication package                      |                   |

## Prompt divisions

Seven. Today they live as sections of etc/style.md plus
CLAUDE.md and the etc/ pipeline; the map:

| division  | drives steps | contents                        | lives in                        |
|-----------|--------------|---------------------------------|---------------------------------|
| choose    | 1,3,4,7      | Newell springboard; Wheeler     | style.md: Newell, Wheeler       |
|           |              | counterweight; toolkit audit    |                                 |
| search    | 2,6          | goal + years SSOT; knee;        | README.md; CLAUDE.md pipeline;  |
|           |              | snowball; download-rate rule    | fetch/snowball/getpdfs.py       |
| encode    | 6,13         | two flag facets; thr not        | flags.py; code/recode.py;       |
|           |              | binary, never abstract-only;    | style.md: ABSTRACT CARRIES      |
|           |              | cutoff sensitivity; Venn        |                                 |
|           |              | subset reading                  |                                 |
| structure | 8,9          | skeleton; section duties;       | style.md: skeleton, Section     |
|           |              | where each coding artifact      | order and duties, Widom's five  |
|           |              | lands (tech facet -> Methods)   |                                 |
| prose     | 8,9,13       | sentence mechanics; banned LLM  | style.md: mechanics, tells,     |
|           |              | tells; LaTeX; abstract rules;   | LaTeX, ABSTRACT CARRIES,        |
|           |              | elevator speech                 | opening moves                   |
| critics   | 5,10,11,12   | assemble-your-critics; Shaw     | style.md: Assemble your         |
|           |              | reader questions; Laurie's      | critics, Shaw, Laurie           |
|           |              | Laws; human discussion          |                                 |
| ship      | 14           | self-test checklist; repro      | style.md: Quick self-test;      |
|           |              | package; contributions end in   | practices.md (stats gates)      |
|           |              | URL                             |                                 |

Rule of the loop: steps 1-7 are cheap and mostly
automatic; step 10 is the expensive one and cannot be
delegated; step 13's recode check is automatic again.
Spend human time where only humans work.
