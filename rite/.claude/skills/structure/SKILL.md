---
name: structure
description: Shape the paper: skeleton, section duties, where each coding artifact lands, Widom as audit. Use at HOWTO steps 8, 9.
---

# structure

## Short form

- Intro owns RQs (answered inline) + contributions; last contribution = repro URL.
- Lit review = respect then disrespect, ending in the open-issues pivot.
- Discussion = Observations / Threats / Future Work; papers live or die on Observations.
- Conclusion = intro with receipts; nothing new.
- Coding artifacts: topic Venn -> intro/lit review; tech facet -> Methods; instrument tables -> Threats.
- Widom's five: answer all, never write her five paragraphs.

## Detail

## Paper skeleton (observed in every sample)

- Title is a question, or question-pair, when honest:
  "Is 'Better Data' Better Than 'Better Data Miners'?";
  "Which Optimizer, At What Budget?"; "Why? How? What to
  Do?". A flat declarative title needs a reason.
- No hyphens in the title. Citation databases (Scopus,
  WoS, IEEE, ACM DL) mis-match reference strings on
  hyphenated titles, splitting or losing citation
  records; shown by metamorphic robustness testing in
  Zhou, Tse and Witheridge, "Metamorphic Robustness
  Testing: Exposing Hidden Defects in Citation Statistics
  and Journal Impact Factors", IEEE TSE,
  doi:10.1109/TSE.2019.2915065. (Their correlational
  claim -- more hyphens, fewer cites -- drew rebuttals on
  confounds; the defect demonstration itself, same paper
  retrieved differently with and without its hyphen,
  stands.) Write "multi objective" or recast; never
  "multi-objective" in a title.
- Page 1 carries a thesis figure: one cartoon (Venn,
  two-panel plot) whose caption walks the whole argument
  and ends by pointing at the paper ("For this reason,
  this paper builds..."). Captions do work; they never
  just name the figure.
- RQs appear in the intro AND are answered on the spot,
  each answer one clause with its headline number bolded:
  "RQ2: Does the budget change which optimizer wins?
  Yes, the winner migrates from EZR when labels are
  scarce to DE when they are plentiful." No suspense.
- Page 1 carries the elevator speech: 2-3 lines, set as
      \begin{quote}{\em ...}\end{quote}
  It states the whole paper -- problem, move, payoff --
  in whiteboard voice. Example of the form: "The open
  question in SE optimization is never whether to
  optimize, only which optimizer earns those few dozen
  labels." Write it early; if the elevator speech cannot
  be written, the paper is not ready.
- Key claims sit in displayed boxes ("Result 1", "The
  gap.") or italic epigrams set off from the text. One or
  two per paper, no more, and the elevator speech counts
  toward that budget.
- Contributions are a short bullet list whose last bullet
  is always the replication package with its URL.
- Scale claims are made outright, hedged only by
  knowledge: "the largest such SBSE study we are aware
  of"; "To the best of our knowledge... one of the
  largest studies on bias mitigation yet presented".
- Inventory tables arrive early (page 2): the tasks, the
  algorithms, the datasets, each with a caption that
  explains what the table is FOR ("the menu of the
  tournament of Section IV").
- Journal venues get the structured abstract
  (Context / Objective / Method / Results / Conclusion);
  conference venues get 3-4 short paragraphs, one per
  RQ-and-answer.
- Methods get christened: SMOTUNED, Fair-SMOTE, SNAP2,
  EZR. Name the thing once, gloss it at first use, use
  the name ever after.

## Section order and duties

- Intro: hooks, then the RQs (answered on the spot), then
  the contributions list. Both RQs and contributions live
  in the intro, nowhere else.
- Lit review comes straight after the intro, and it has
  one shape: respect, then disrespect. First the respect:
  here is this great work, these are our ancestors, this
  is the SOTA. Then the turn: show how none of it is
  relevant to our task (wrong assumptions, wrong data,
  wrong question -- name the mismatch precisely). The
  section MUST end with the pivot paragraph: "Based on
  the above, there exist the following open issues:"
  followed by a numbered list, then "Accordingly, the
  rest of this paper will..." Everything downstream is
  motivated by that list; if a section does not trace to
  an open issue, cut it or fix the list.
- Reading the coding Venn (the Table-4/Figure-2 device):
  the empty cell is not automatically the story. Four
  subsets to check, in order:
  (a) the subset no one occupies AND that matters -- run
  it past all four tests: Wheeler (is it strange?),
  Newell (is it a live bottleneck?), Shaw (can its claim
  be validated?), Williams (who benefits?). An empty cell
  failing those is empty for a reason;
  (b) the subset everyone occupies and does wrong -- a
  correction paper (the SMOTUNED move: 85% used SMOTE,
  untuned);
  (c) the subset everyone occupies where a small percent
  improvement pays hugely, because the practice is so
  common -- and a large improvement there pays more
  still;
  (d) only then the merely-empty cells, which are usually
  empty because nobody cares.
- After Results comes a Discussion section with exactly
  three subsections, in this order: "Observations",
  "Threats to Validity", "Future Work".
- Papers live or die on Observations. This is where the
  real lessons land: the surprises, the result that
  contradicts folklore, the pattern seen across tables
  that no single table shows. Not a recap of the results;
  what the results MEAN. Budget real writing time here;
  a reviewer who skims everything else reads this.
- Conclusion tells the same story as the intro, but now
  with receipts: restate the claims, attach each to the
  method and the result that earned it. No new material
  in the conclusion. If intro and conclusion disagree,
  one of them is lying; fix it.
- Where the coding artifacts land: topic-facet groups
  and the Venn -> intro + lit review (they ARE the gap
  argument); technology facet -> Methods (what rivals
  use vs what we use); abstract-vs-fulltext agreement,
  threshold choice, download rate -> Threats (instrument
  validity, selection bias). A table in the wrong
  section argues the wrong point.

## Widom's five (audit, not outline)

Widom's rule: an intro is five paragraphs answering (1)
what is the problem, (2) why is it interesting and
important, (3) why is it hard -- why do naive approaches
fail, (4) why hasn't it been solved before -- what is
wrong with prior solutions, (5) what are the key
components of my approach and results, with specific
limitations.

House position: we answer all five, we never write the
five paragraphs. Our intros are answer-first and
question-driven; hers is suspense-shaped, and five
same-shaped paragraphs trips our uniform-paragraph ban.
Use her five as a completeness audit on any drafted
intro. The one we historically skimp is (3): make sure
some sentence says, explicitly, why the naive approach
fails. And (5)'s tail -- limitations stated in the intro
-- pairs with our stated-failure-criteria habit; keep it.

## Imports from Widom (cs.stanford.edu/people/widom/
## paper-writing.html). Subordinate: where these touch a
## rule above, the rule above wins.

Imported:

- A clear, novel technical contribution must be on the
  page by one quarter of the way through the paper. (We
  usually do it by page 1; treat page 3 as the hard
  deadline.)
- Ban nonreferential pronouns: no "this", "that", "it"
  without a clear antecedent noun. Sweep for "This
  shows..." and name the thing that shows it.
- Never "for various reasons" -- give the reasons. Avoid
  "etc." unless the remaining items are obvious.
- "That" defines, "which" digresses; keep the
  distinction.
- Division of labor for type styles: bold is for the
  load-bearing claim (house rule); italics are for
  definitions and epigrams only, never for emphasis.
- Run one worked example through the whole paper
  (auto93 in the book; galumphing in Shaw). Introduce it
  once, reuse it everywhere.
- Preliminaries section holds notation that is not a
  contribution; nothing novel hides there.
- Appendices carry only what most readers can skip
  (proofs, long algorithms). Anything needed to
  understand the contribution stays in the body --
  pairs with Laurie's Law #16.
- Citations complete and consistent; never paste junk
  BibTeX from the web (house refs.bib rule: verify DOIs
  by hand).
- Figures and tables sit at page tops, on the same page
  as their first reference or the next; figure fonts
  match body size.
- Online versions carry a date and a tech-report
  designation; never a "submitted to X" reference or a
  borrowed copyright block.
- Experiments to consider beyond the main comparison:
  parameter sensitivity and scalability, plus absolute
  numbers (not only relative wins).

Refused, house rule wins:

- Her related-work placement option ("maybe near the
  conclusions"). No: lit review sits after the intro and
  ends with the open-issues pivot, always.
- Her five-paragraph intro: audit, not outline (above).
- Her "conclusions should not repeat the introduction":
  ours deliberately retell the intro with receipts. One
  nuance adopted: retell means restate against results,
  never copy sentences verbatim.
