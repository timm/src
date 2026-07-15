
what are standard best practices for self documentaing code that i shiudl apply?

this repo in src/sandbox is doing its wown self documenting things. what issues does that address? what issues does it not address? how cou;ds/should i extend my approach to doc/tutoruing?

I'll look at the repo's style docs and the sandbox code to understand the existing self-documenting conventions before answering.


Ran a command, read 4 files
I've read etc/style.md and the three sandbox files (abc.lua, abc-eg.lua, abc-doc.md). Since this is a question, here's my assessment — no changes made (and sandbox is hands-off per CLAUDE.md anyway).

1. Standard best practices for self-documenting code
The conventional canon, roughly in order of leverage:

Intention-revealing names — a function's name says what it does, a variable's name says what it holds; if a comment restates the name, delete the comment.
Small units with one job — a reader can hold a 10-line function in their head; structure is documentation.
Comments explain why, never what — constraints, tradeoffs, and surprises the code can't show; the code itself shows the what.
Types and signatures as contracts — where the language has them; where it doesn't, a disciplined signature convention substitutes.
Executable examples — doctests, example files, snippets in docs that actually run, so examples can't rot silently.
Single source of truth — defaults, options, and schemas defined once, everything else derived, so docs and behavior can't disagree.
Predictable structure — uniform file layout and naming so a reader who's seen one module can navigate all of them.
Docs generated from source, never hand-edited outputs — proximity fights drift.
Tests as specification — test names and assertions state the behavioral contract.
2. What the sandbox approach addresses
Your abc.lua / abc-eg.lua / abc-doc.md triad hits most of that list, and goes past it in a few places:

Doc rot — the strongest theme. The -eg file is simultaneously tutorial, demo, and test suite: running the tutorial is running the tests, so a lesson that stops matching the code fails CI. Options SSOT (str.settings(help) parses defaults out of the help text) means usage docs can't drift from behavior. The doc pipeline generates HTML from source; outputs are never hand-edited. The luamine replay checker extends this to long-form transcripts.
Reading order and pedagogy — most codebases document what exists but not where to start. Section markers give one topic per unit; -eg reorders them simplest-to-hardest into 13 lessons; -h prints the map; join keys link lessons to a glossary. Standard practice has nothing this good for teaching.
Comment altitude discipline — the three-altitudes rule (file header / one-liner per function / section prose) prevents the usual mess of comments at random zoom levels. The prose stanzas carry the why ("labels cost money", "distance is all you need") while one-liners carry the contract.
Debuggable failure — every test prints a tutor-pointable line before asserting, so a failure arrives with its own context. That's better than most assert-only suites.
Reproducibility as a documentation property — the seeded Lehmer generator means printed outputs are stable claims, not one-off observations. This is what makes transcripts diffable at all.
Self-documenting data — the csv header-as-schema idea extends self-documentation past the code into the inputs.
3. What it does not address
Nothing verifies the cross-file joins. The **Core ideas:** [welford](abc-doc.md#welford) links and the ## key glossary anchors are held together by convention only. A renamed glossary heading, a typo'd key, or an orphaned glossary entry breaks silently — exactly the rot class the -eg asserts eliminate for code, still alive for the doc layer. Same for the dot-lists: **Num.add(i,v,w)** is prose; if the real signature changes, no test notices the stated signature is stale, only that behavior changed.
Coverage is opt-in and invisible. Style.md says dot-lists name "ONLY functions the tests call" — which is honest, but it means public verbs can exist untaught with no signal. E.g. lst.kap and lst.items are exported from abc.lua but appear in no lesson. Nothing reports what fraction of the module the tutorial covers.
"No crash = pass" documents the happy path. The asserts pin nominal behavior well, but edge cases, error behavior (str.csv's assert(io.open...) is the only error handling in the file), and invariants mostly live in prose or nowhere. Several strong prose claims — "constant time", "numerically stable", "reversible" — are stated, not tested (though your own lesson-4 exercise 2, the merge/without round-trip, is literally a property test waiting to be promoted).
Local convention isn't self-explaining. The four-space gap marking locals in signatures (function Num.add(i,v,w, d)) does real documentation work — it's how a reader tells the true arity — but it's explained nowhere in the file or in style.md. Self-documentation here presumes a reader already inducted; a newcomer reads d as a parameter.
It documents for students more than maintainers. The lessons teach concepts beautifully, but idea-level design rationale (why sway3 and not something else; what was tried and rejected inside this idea, the way style.md records the many-tiny-files reversal at repo level) has no designated home. REPORT.md covers study conclusions, not design decisions.
The tutorial is strictly linear. Someone who just needs "how do I compute distance" must know it's lesson 8. The glossary partially compensates, but there's no index from function name → lesson.
Incomplete against its own spec: style.md says xx-doc.md includes "contents, recaps, quiz, references" — abc-doc.md has contents and references but no recaps or quiz yet.
4. How I'd extend the doc/tutoring approach
In rough order of value-per-line, and all consistent with your accrete-never-regenerate rule:

A join checker, run in CI like tutchk. ~30 lines: every xx-doc.md#key referenced from -eg must match a ## key heading in -doc; every glossary heading must be referenced by at least one lesson; every **fn(...)** dot-list name must exist in the module's returned table (Lua reflection makes this trivial). This closes the last unverified drift channel and is the same move — "make the doc claim executable" — that made -eg work. It could also emit the coverage number: taught verbs / exported verbs.
Transcript-check the -eg output itself. You already print a diagnostic line per test and everything is seeded; capture --all output once from a real run and diff it in CI (the luamine tutchk pattern, pushed down to every idea dir, floats at 10 significant digits). Then the printed pedagogy — the numbers a tutor points at — is pinned, not just the asserts.
Promote one property test per lesson. Your exercise 2s are already properties (merge inverts without; doubling counts preserves entropy; bisect counts a CDF). Adding a --props section that runs a handful over seeded random inputs would let the prose claims ("reversible", "un-fold") become tested claims, without changing the lesson shape.
Exploit the seeded RNG for cross-language grading. Exercise 0 of every lesson is "port this to your language" — and the 16807 Lehmer generator produces the identical stream anywhere. Ship a tiny conformance transcript (seed, inputs, expected prints at 10 sig digits) per lesson, and a student's port self-grades by diff. That turns exercise 0 from honor-system into machine-checkable, and it's a natural extension of the grading rule you already use in tutchk. This is, I think, the highest-value tutoring extension available to you and nobody else's setup can do it as cheaply.
One stanza documenting the signature convention — a sentence in style.md's comments section (or the file-header of exemplars) saying "params after the wide gap are locals, not arguments". Cheapest fix on the list; removes the biggest newcomer trap.
A "decisions" stanza per idea dir — two or three lines in the file header or README recording what was tried and reverted within the idea (the style.md consolidation notes, at idea granularity). Maintainer-facing where everything else is student-facing.
Finish -doc to its own spec — add the recap/quiz sections style.md promises; quizzes can be generated from the glossary (key → "define this term / which lesson uses it") which keeps them accretive rather than hand-maintained.
The unifying principle behind 1–4: your approach's core insight is "a doc claim should be executable, and executed in CI." The code-level claims already are; the remaining gaps are exactly the claims that aren't yet (links, signatures, printed output, properties, ports). Extending the same insight to those closes most of section 3.

explain 4 a little more

Why it's possible at all
The whole thing rests on one fact: your RNG is part

for 4 do you mean lesson 0 has to be "how wro write 16807 seed Lehmer generator (psuedocode) and then all my services need example outputs that student scan strive to generate?

for 4 do you mean lesson 0 has to be "how wro write 16807 seed Lehmer generator (psuedocode) and then all my lessons need example outputs that student scan strive to generate?

Yes — that's exactly the shape, with two refinements.

The Lehmer generator becomes the bootstrap lesson. Not quite "lesson 0" — in your current ordering it's lesson 2 (Rnd), and lesson 1 (Lst) needs no RNG so it can stay first. But within the port-track, the generator is the gate: the student gets the pseudocode (multiply by 16807, mod 2³¹−1, seed 0 nudged to 1 — five lines in any language) plus a brutal little conformance check, something like

seed(1); first five draws =
0.0000000078, 0.1315378, 0.7556053, 0.4586501, 0.5327672
If those five numbers match, their generator is byte-for-byte your generator, forever. One subtlety worth stating in the lesson: 16807 × (2³¹−2) ≈ 3.6×10¹³, which fits exactly in a float64, so the recipe works even in languages with no integer type (JS, Lua 5.1) — no bignum, no care needed. That's why this generator and not a Mersenne twister.

Then every later lesson ships its expected prints. You mostly already have them — they're the tutor-pointable lines the -eg tests print before asserting. The extension is just: freeze those lines (at seed 1, on a named dataset) into a per-lesson transcript file, and the student's exercise 0 becomes "make your port emit these same lines." Grading is a float-aware diff at 10 significant digits — your existing tut.md grading rule, and tutchk is already the exemplar implementation. The lessons' simplest-to-hardest ordering does the pedagogical work for free: lesson 4's transcript only exercises Welford, so a mismatch there is a Welford bug, not a data bug or an RNG bug — those were certified in lessons 2–3. Failures self-localize.

The chain of trust is the point: once the generator matches, shuffle matches (same swaps), so some matches (same samples), so acquire matches (same labels), so the tree matches (same splits), so the capstone number matches. A student whose lesson-13 win comes out as 76 when yours is 76 has, in a very strong sense, reimplemented the whole system correctly — and verified it themselves, with no grader in the loop.

Three hazards to design around, all about accidental nondeterminism leaking into graded lines:

Dict iteration order. str.o already sorts keys, good — but Sym.mid with tied modes returns whichever key pairs() visits first. Either break ties (e.g. lexically) or keep tied-mode prints out of transcripts.
Unstable sorts. table.sort/keysort with equal keys can order differently across languages. Same remedy: deterministic tie-break, or don't grade lines that depend on the order of equals.
Environment-specific lines (paths, versions) execute but skip the diff — tutchk already has this rule; the per-lesson transcripts inherit it.
So concretely the deliverables are small: pseudocode + 5-draw check added to the Rnd lesson, one frozen transcript per lesson (generated from a real run of the section, never hand-edited — your existing rule), and a ~50-line grader that diffs floats at 10 sig digits, probably a generalization of tutchk. The transcripts also double as regression tests on the Lua reference itself: if a refactor changes any graded number, CI tells you before a student does.




