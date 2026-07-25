# style.md -- how a Menzies PAPER reads (rite edition)

Synthesis of two sources. (1) The proposal-voice style.md
(SLES/DRR/BINGO/EZR, amended July 2026) -- its rules carry
over unless overridden here. (2) Habits observed in the
published/preprint papers now in pdf/ and pdf/mine/:
Agrawal ICSE'18, Chakraborty FSE'21, Ganguly's optimizer
tournament (2607.11705), SNAP2 (2607.02583), the fuzzing
IST preprint (2512.18102). Target: text that passes as a
first-draft Menzies paper, not LLM output.

## Before any of this: Newell's springboard

Everything below is about reporting research. This part
is about choosing it, and it comes first because no
amount of style rescues the wrong project. Allen Newell's
research heuristics (as passed down through his talks and
the Newell Award tradition; see also his "Desires and
Diversions") reduce to two lists and a collision:

- Good techniques: the tools you are unusually good at,
  honed until reliable.
- Good problems: questions of the current era whose
  answers matter, in theory or in practice.

Neither list alone is research. Technique without a
problem is a hammer collection; a problem without
technique is a wish. The move is to force the collision:
take the thing you do better than most people and aim it
at a bottleneck that is live right now.

The procedure, run before any paper starts:

1. Audit the toolkit. Name, specifically, what we are
   good at that others are not. (Here: frugal AI --
   tiny incremental learners, label-economics, active
   learning on 100+ public SE tasks, statistics that
   gate claims.)
2. Scan the era's bottlenecks. Not eternal problems;
   current ones. This is what the lit pipeline is FOR:
   the search, the knee, the coding grid, and the
   open-issues pivot are a bottleneck scanner.
3. Map one onto the other and write the collision down
   as one sentence. That sentence is the elevator
   speech (page 1, \begin{quote}{\em ...}\end{quote}).
   If step 3 produces no sentence, return to step 2
   with a different bottleneck; do not lower the bar by
   inflating the toolkit.

Newell's working adages, which the house already
practices under other names:

- Respond to real phenomena. Anchor to observable
  problems and real data, not abstractions. (Hence MOOT
  tasks, not synthetic suites.)
- Dive into the details. The insight is in the messy
  implementation, which is why we read code and show
  code. (Hence %%code and seeded transcripts.)
- Fly into the wind. Do not chase the consensus trend;
  radical improvement usually means bucking it. (Hence
  "Is better data better than better data miners?" and
  frugal methods in a scale-obsessed era.)
- Just do something. Build the throw-away script, run
  the small case, expose the flaw early. (Hence
  fetch.py before a review protocol, a demo before a
  theory section.)

## The Wheeler counterweight (keep this tension; do not
## resolve it)

Against Newell's "most relevant problems of the era"
stands Wheeler's advice: in any field, find the strangest
thing, and explore it. The historical record backs
Wheeler more often than is comfortable. Boole's logic
waited some eighty years for Shannon to make it switching
circuits. Perceptrons waited half a century to become
deep learning, surviving two winters on the way. Logic
programming looked like a dead end until its ideas
resurfaced in Erlang's telecom systems. None of these
were the relevant problems of their era; all of them were
the strangest thing in the room.

So the house holds both, unreconciled:

- Newell prices the work by the era: relevance now,
  impact now. His procedure (above) is the default; most
  projects should pass his audit.
- Wheeler prices the work by the anomaly: the result that
  does not fit, the question nobody thinks to ask. Some
  fraction of the portfolio -- a chapter, a side study,
  one RQ in a larger paper -- should pass HIS audit
  instead: which strange thing, and why is nobody else
  looking at it?
- The two meet more often than they fight: a strange
  thing found inside a live bottleneck is the best
  project there is (an anomaly in a relevant place is
  both a Wheeler find and a Newell bottleneck). The
  Observations subsection exists partly to catch these:
  a surprise in our own results is a Wheeler seed for
  the next paper.

Audit line for any new project, now two-headed: EITHER
say in one breath which technique, which bottleneck, and
why now -- OR say which strange thing, and why nobody
else is looking. A project that can say neither is not a
project. A project that can say both, start immediately.

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

## Opening moves (pick one, page 1)

- Cost hook with arithmetic shown: "one system we studied
  has 460 binary flags, a space of 2^460 options (more
  configurations than there are stars in the observable
  universe)". Numbers never round away the working.
- Field-disagreement hook: enumerate the contradictory
  verdicts ("Reports range from limited advantage, to
  useful only on small problems, to too slow to be
  practical"), then the turn: "We argue this disagreement
  reflects an evidence base too small to settle its own
  disputes."
- Ethics/duty hook (sparingly): "It is the ethical duty
  of software researchers..."
- Quote a truism from a big name, then push on it: Berk's
  "impossible to achieve fairness and high performance"
  followed by "we argue that assumption may not even be
  necessary."

## Argument habits (carried from proposal style, seen in
## papers too)

- Praise prior work, then storm out: "While these
  approaches were certainly useful... these methods are
  'dumb' in a way because they do not take advantage of
  domain knowledge."
- Digression flags: "Before beginning, we digress to
  clarify two points. Firstly... Secondly..."
- Inline enumeration (a) (b) (c) inside sentences,
  heavily. "Firstly/Secondly" for two-part bad news.
- Repetition flagged honestly: "Just to repeat a point
  made above..."
- Pre-empt reviewers in asides and FAQs; state success
  AND failure criteria for the experiments.
- Cite own prior work by result, not ceremony: "prior
  results [20, 24] show that..."

## Sentence mechanics (unchanged from proposal style.md)

- Mix lengths hard; 5-word sentence beside a 40-word one.
- Short declaratives as pivots: "But there is a catch."
  "Enter active learning." "We disagree."
- Rhetorical questions drive sections.
- One idea per sentence. Semicolons rare. Paragraphs may
  end flat.
- Connectives, in house frequency order: "Hence", "That
  said,", "Also,", "Further,", "Note that", "To say that
  another way,".

## LaTeX conventions

- List macros: \bi ... \ei (itemize), \be ... \ee
  (enumerate). Never mix a macro opener with a raw closer
  (\bi ... \end{itemize} does not compile).
- Cross-references via \tion{label}, \fig{label},
  \tbl{label}.
- Editorial markers: \need{...} renders red [TIMM: ...].
  These stay visible in working drafts; they are for the
  PI, not comments. Red flag symbol: {\redflag}.
- Captions carry a guided read for dense figures: name
  the parts, walk the example, land the point
  ("Everything else stays untouched").
- Wrapfigures: environment a touch wider than the image
  (2.6in around a 2.5in image); \centering inside; place
  at paragraph starts; two wrapfigures at least a page
  apart.

## Banned: LLM tells (the full law, from proposal
## style.md)

- Verbless sentence fragments used as punchy caps: "One
  substrate, again." "Speed, again." "The loop, closed."
  Too terse even for this house style. Rewrite as full
  clauses or delete. On any full-text pass, sweep for the
  shape noun-phrase-comma-adverb-period and kill it.
- Short sentences must still be sentences: complete
  clauses with verbs.
- No em-dash pairs ("---like this---"). No spaced
  en-dashes. The unspaced double hyphen as a single
  trailing interruptor is native ("runtime adaption--
  which is akin to fixing a problem after creating it")
  but at most once or twice per document.
- No "X is not Y, it is Z" mic-drop constructions.
- No triads for rhythm ("reproducible, teachable, and
  energy-frugal"). One list of three per page, only when
  the three things are real.
- No parallel-scaffold runs: three sentences in a row
  with identical "A does X but not Y" shape.
- No thesis-announcement filler: "This is timely and
  feasible", "This approach is significant because", "In
  today's rapidly evolving...".
- No consultant nouns: "defensible basis", "growing
  industrial risk", "actionable insights", "robust
  framework", "landscape" as metaphor (landscape as a
  technical term for loss/data topology is fine).
- No adjective-stacked noun phrases doing verb work
  ("lightweight learner-agnostic region-level
  monitors"). Use a verb.
- No "delve", "crucial", "pivotal", "seamless",
  "holistic", "leverage" (as a verb), "harness",
  "underscore", "foster".
- No perfectly uniform paragraph shapes. Vary: some
  paragraphs are two sentences.
- Do not end every paragraph with a summary sentence.
- Semicolons rare; prefer a period and a new sentence.
  Colons introduce lists and definitions, not dramatic
  reveals.

## Shaw's rules (Mary Shaw, "Writing Good Software
## Engineering Research Papers", ICSE 2003;
## pdf/shaw-icse03.pdf)

Three questions every paper must answer, and the reader
should never have to hunt for them: (1) What, precisely,
was your contribution? (2) What is your new result?
(3) Why should the reader believe it?

Her taxonomies (candidate coding columns for our lit
review): question types (method of development, method of
analysis, design/evaluation of an instance,
generalization, feasibility); result types (procedure or
technique, qualitative model, empirical model, analytic
model, tool or notation, specific solution, report);
validation types (analysis, evaluation, experience,
example, persuasion, blatant assertion). ICSE 2002
acceptance rates by validation: analysis 23%, experience
24%, realistic example 20%, evaluation 5%, persuasion 0%,
no mention 7%. Moral: validate by analysis, lived
experience, or a "slice of life" example from a real
system; toy examples and passion do not survive review.

Her claim-wording ladder. KEEP THESE EXAMPLES; they are
the best teaching device in the paper:

    Awful:  "I completely and generally solved..."
            (unless you actually did!)
    Bad:    "I worked on galumphing."
    Poor:   "I worked on improving galumphing."
    Good:   "I showed the feasibility of composing
            blitzing with flitzing." / "I significantly
            improved the accuracy of the standard
            detector."
    Better: "With a novel application of the blivet
            transform, I achieved a 10% increase in speed
            and a 15% improvement in coverage over the
            standard method."

Use verbs that show results and achievement, not effort
and activity (worked on, participated in, helped with are
all bad verbs). Her citation for this rule: "Try not.
Do, or do not. There is no try." -- Yoda. (Hence Laurie's
Law #10.)

Her related-work ladder, same device:

    Awful:  "The galumphing problem has attracted much
            attention [3,8,10,18,26,32,37]"
    Bad:    "Smith [36] and Jones [27] worked on
            galumphing."
    Poor:   "Smith [36] addressed galumphing by blitzing,
            whereas Jones [27] took a flitzing approach."
    Good:   "Smith's blitzing approach to galumphing [36]
            achieved 60% coverage [39]. Jones [27]
            achieved 80% by flitzing, but only for
            pointer-free cases [16]."
    Better: all of Good, then "We modified the blitzing
            approach to use the kernel representation of
            flitzing and achieved 90% coverage while
            relaxing the restriction so that only cyclic
            data structures are prohibited."

Cite rivals by their numbers, then state yours against
them. (This is our lit review's respect-then-disrespect
move, at sentence scale.)

Her thesis-clause heuristic: take the one-sentence
statement of the result; each clause is a separate
validation problem. A global clause ("always", "fully")
needs analysis; a qualified clause ("a 25% improvement",
"for noncyclic structures") needs evaluation or
experience; an existential clause ("we found an
instance") can ride on one good example. Restate claims
until each clause matches evidence you actually have.

Her abstract shape: two or three sentences on the state
of the art, identifying a particular problem; one or two
on what this paper contributes to improving the
situation; then the result and its evidence. The abstract
tells the reader what to expect; PCs code papers from
abstracts alone.

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
grid on our own title plus abstract. Every flag the full
paper earns, the abstract must earn on its own. If the
abstract of our paper would be miscoded by our own
pipeline, rewrite the abstract, not the pipeline.

(Aside: it has not escaped our attention that we spent a
career coding other people's abstracts, then wondered
what the heck we were writing in our own.)

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

## Laurie's Laws (Laurie Williams; from the framed sheet,
## pdf/laurie-laws.pdf; cf. her PROMISE 2011 Banff keynote)

1.  Know thy audience.
2.  Keep it positive.
3.  Just say it in plain English.
4.  Define it before you use it.
5.  Be consistent.
6.  Who will benefit from your work?
7.  Papers can always improve.
8.  Make use of bulleted lists.
9.  Data talk. Statistics shout.
10. Trust Yoda. Do. Or do not. There is no try.
11. Never use superlatives.
12. Their perception is your reality.
13. What are you telling people to do next?
14. If you don't believe your work, who will?
15. Nobody is above feedback.
16. Don't ask your audience to read another paper to
    understand yours.
17. Presentation is as important as good research.
18. Don't oversell.
19. An unpublished dissertation might as well not exist.
20. These laws are merely suggestions. The final decision
    is yours.

Where the laws touch house rules: #3 is the whiteboard
voice test; #4 is the gloss-at-first-use rule; #9 is why
results lead with numbers and stats gate the claims; #11
and #18 pair with the no-superlatives, hedge-by-knowledge
scale claims; #16 means every paper is self-contained
(define BINGO-class terms locally, never by pointer to
another paper).

## Assemble your critics

Before submission, manufacture the harshest review the
paper will ever get. Four sources, all procedural:

- (a) Award-winner delta. Download the last ten years of
  best/distinguished papers from the target conference.
  Ask, per paper: what do they have that we lack --
  sample sizes, baselines, proofs, user studies, artifact
  badges, writing moves? The recurring lacks are the
  to-do list.
- (b) Reviewer 2 on demand. Fetch the target venue's
  current CFP and review criteria. Then commission a
  hostile read of the draft against exactly that text:
  "you are Reviewer 2 at <venue>; here is the CFP; reject
  this paper." Fix what the rejection cites; keep the
  rebuttals that survive as the FAQ asides.
- (c) The standards. Score the draft against the ACM
  SIGSOFT Empirical Standards checklists that apply
  (here: SystematicReviews, OptimizationStudies,
  Benchmarking; see practices.md). Every unmet Essential
  is a desk-reject risk; say which Desirables were
  skipped and why.
- (d) Nearest-neighbor delta. Find the ten papers nearest
  this work in the literature (citation overlap or
  tf-idf similarity -- the lit pipeline already computes
  both). For each, one sentence: the delta them-to-us.
  If a delta sentence cannot be written, the paper has a
  novelty problem; better to learn that now. These ten
  sentences are also the core of the related-work
  section, in Shaw's Good-or-better ladder form.

The order matters: (d) finds the novelty holes, (c) finds
the rigor holes, (a) finds the ambition holes, (b) finds
everything else. Run all four while there is still time
to act on them, not the week of the deadline.

## Quick self-test before shipping

- Read aloud; whiteboard-voice or rewrite.
- Lit review ends with "Based on the above... open
  issues:" and every later section traces to that list?
- Discussion has Observations / Threats to Validity /
  Future Work, in that order? Do the Observations say
  something no single results table says?
- Conclusion = intro claims + the method and result that
  earned each? Nothing new there?
- Is the title a question? Should it be? Any hyphen in
  it? Remove.
- Are the RQ answers in the intro, with bold numbers?
- Elevator speech on page 1, in its \begin{quote}{\em}
  block, 2-3 lines, problem-move-payoff?
- Widom audit: all five questions answered somewhere in
  the intro? Especially (3), why the naive approach
  fails, and (5)'s limitations?
- Run the coding grid on our own title+abstract: does it
  earn every flag the full paper earns?
- Does the thesis figure's caption walk the argument?
- Last contribution bullet = replication URL?
- Count dashes. More than two? Cut.
- Count lists of three. More than one per page? Cut.
- Find the shortest sentence. If it is over 10 words,
  add a short one. If it has no verb, fix that first.
- Is the main claim bolded once, inline, mid-paragraph?
  If not, do it.
- Does every tool name have a gloss at first use? Grep
  for capitalized acronyms; check each one's debut.
- Numbers shown with their arithmetic?
- Sweep for bare "This/That/It shows..." -- every pronoun
  has a named antecedent?
- Grep "various reasons" and "etc." -- replace or
  justify.
- Any \bi without a matching \ei? Any \ref to a label
  that moved?
