---
name: critics
description: Assemble and apply critics: Shaw's reader questions, Laurie's Laws, reviewer-2, standards, humans. Use at HOWTO steps 5, 10, 11, 12.
---

# critics

## Short form

- Critic 1 is you: offline, social media off, 30-60 minutes of comments.
- Auto critics: above-knee papers from target venues; CFP reviewer-2 pass; ACM empirical standards; nearest-10 papers, delta them-vs-you.
- Shaw's three reader questions: what contribution, what new result, why believe it.
- Split critic fixes into auto and manual; discuss with other humans before applying.
- Laurie: data talk, statistics shout; never superlatives.

## Detail

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
