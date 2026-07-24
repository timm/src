style.md: how Menzies proposal prose actually reads

Reverse-engineered from SLES proposal + DRR/BINGO/EZR papers, then amended during the NUDGE drafting sessions (July 2026). Two halves: what to do, and what to never do. Target: text that passes as first-person Menzies draft, not LLM output.

This file supersedes all earlier versions of style.md.

Voice
First person plural: "we explore", "we say that", "we would start simple".
Confident, plain, a little blunt. State the problem, state the fix.
Occasional dry humor is fine ("mad scientists r'us") but rare; one per document, max.
Everyday analogies to ground abstractions (a used car lot; more options than stars in the sky). Concrete beats clever.
Sentence mechanics
Mix lengths hard. A 5-word sentence next to a 40-word one. LLMs write everything at 20-35 words; humans do not.
Short declaratives as paragraph pivots: "But there is a problem." "Hence, the rest of this proposal." "Enter active learning." "We disagree."
Short sentences must still be sentences. Complete clauses with verbs. See the fragment ban below.
Rhetorical questions drive sections: "But do all SE tasks need such complexity? Perhaps not."
It is fine for a paragraph to end flat, without a tidy landing.
One idea per sentence. When a sentence grows two clauses, split it.
Connectives (use these, in roughly this frequency order)
"Hence" (the workhorse), "That said,", "Also,", "Further,", "Note that", "To say that another way,", "Just to repeat a point made above,".
"Firstly, ... Secondly, ..." for two-part bad news; extends to "Thirdly, Fourthly, Fifthly" for evidence ledgers.
"The good news is... The bad news is two-fold."
Inline enumeration with (a) (b) (c) inside a sentence, heavily: "we can (a) label simulator output; then (b) build summaries."
Emphasis and structure
Bold the load-bearing claim, inline, mid-paragraph: "safety cannot be achieved by merely improving one learner".
Underline sparingly, only for "Success criteria:" style labels.
Key results go in a displayed box or block quote, one or two per paper.
Bullets are short; a bullet is one clause or two, not a paragraph. Exception: drawback-then-fix lists, where each bullet is a bolded drawback name, two or three sentences of drawback, then "Hence" plus a pointer to the RQ or section that fixes it.
Footnotes for asides and war stories; also "(Aside: ...)" in running text.
"(Aside: it has not escaped our attention that ...)" is a house move for pre-empting reviewers.
e.g. and i.e. appear mid-sentence, unceremoniously, often in parens.
Numbers are concrete and shown with their arithmetic: "60 * (1 + 185 + 26) = 6,180 options". Never round away the working.
Dashes and punctuation
Em-dash pairs ("---like this---") are banned.
The unspaced double hyphen as a single trailing interruptor is native: "runtime adaption-- which is somewhat akin to fixing a problem after it has been created." Use at most once or twice per document.
Semicolons: rare. Prefer a period and a new sentence.
Colons introduce lists and definitions, not dramatic reveals.
Argument habits
Name the tension early: assumption vs counter-evidence. "Much of SE research assumes X. Yet has this assumption been rigorously tested?"
Admit weakness plainly, then scope it: "in its current form it can hardly be called a proven theory."
After praising prior work (including our own), storm out of the gate: "While these methods succeeded in their test domains, those results have drawbacks that this research must fix", then a numbered drawback-then-fix list, each ending "Hence RQn / \tion{x}".
Repetition is a feature. Restate the core claim at section ends, flagged honestly: "Just to repeat a point made above...".
Cite own prior work by result, not by ceremony: "prior results by PI Menzies [20, 24] show that...".
Import humility with imported results: when citing a quasi-experimental result (e.g. the K-test), keep the original paper's own caution ("historical observation, not deterministic causality").
Pre-empt the reviewer with FAQs or asides. State success AND failure criteria in advance; say what redirection follows each failure.
Definitions and first use
Gloss every tool or method name at first use, even our own: "our EZR toolkit (an incremental active learner whose conclusions are small decision trees)". Same for others' tools: "SHAP, LIME, and Anchors (which explain a prediction by weighting or bounding the features that drove it)".
Never let an undefined acronym enter via an evidence bullet or a figure caption. If a term first appears inside a list, the gloss goes inside that list item.
Core technical terms (e.g. the BINGO effect) are defined exactly once, in one flagged place ("this paragraph is its definition"); everywhere else points there. No re-derivations, no repeated number dumps.
Pedagogy: code on the page
Never show a name before its introduction. Every identifier in a shown snippet -- function, class, argument, stdlib idiom (e.g. g.get) -- is either shown earlier via %%code or glossed in the prose of the same section. Before shipping a chapter, reread each snippet as a stranger; any name the reader cannot resolve from the page is a bug. This extends the gloss-at-first-use rule down into code.
Parts before wholes. Show the small named helpers first, then the dispatcher that only calls them (e.g. welford for Num, count for Sym, then an add that is one line of dispatch). If a shown function needs a paragraph of apology, split the function and teach the pieces first.
Every add has a sub. A summary that learns must be shown forgetting, in the same lesson: sub(i,v) is add(i,v,-1). Demo the round trip, then the composition add(i, sub(j,v)) that moves a value from summary j to summary i.
No quantity without its code. If the prose names a computed thing (entropy, standard deviation, cdf), the defining code appears in that same section via %%code. Worked arithmetic in prose supplements the code; it never substitutes for it.
Line widths: source code stays under 65 characters; prose in chapter files may run to 85. make lines polices both.
The toolkit is the vehicle, not the claim. The story is that much of SE and AI comes from a small number of core ideas plus vast amounts of ceremony, and we show the core without the ceremony. EZR is what fell out of chasing that; never write as if it were the point, or the only good tool.
LaTeX conventions (NUDGE proposal and kin)
List macros: \bi ... \ei (itemize), \be ... \ee (enumerate). Never mix a macro opener with a raw closer (\bi ... \end{itemize} does not compile).
Cross-references via \tion{label}, \fig{label}, \tbl{label}.
Editorial markers: \need{...} renders red [TIMM: ...]. These stay visible in working drafts; they are for the PI, not comments.
Red flag symbol: {\redflag}.
Captions carry a guided read for dense figures: name the parts, walk the example, land the point ("Everything else stays untouched").
Wrapfigures: environment a touch wider than the image (2.6in around a 2.5in image); \centering inside; place at paragraph starts; keep two wrapfigures at least a page apart.
Banned: LLM tells
Verbless sentence fragments used as punchy caps: "One substrate, again." "Speed, again." "The loop, closed." Too terse even for this house style. Rewrite as full clauses or delete. On any full-text pass, sweep for the shape noun-phrase-comma-adverb-period and kill it.
No em-dash pairs. No spaced en-dashes.
No "X is not Y, it is Z" mic-drop constructions.
No triads for rhythm ("reproducible, teachable, and energy-frugal"). One list of three per page, only when the three things are real.
No parallel-scaffold runs: three sentences in a row with identical "A does X but not Y" shape.
No thesis-announcement filler: "This is timely and feasible", "This approach is significant because", "In today's rapidly evolving...".
No consultant nouns: "defensible basis", "growing industrial risk", "actionable insights", "robust framework", "landscape" as metaphor (landscape as a technical term for loss/data topology is fine).
No adjective-stacked noun phrases doing verb work ("lightweight learner-agnostic region-level monitors"). Use a verb.
No "delve", "crucial", "pivotal", "seamless", "holistic", "leverage" (as a verb), "harness", "underscore", "foster".
No perfectly uniform paragraph shapes. Vary: some paragraphs are two sentences.
Do not end every paragraph with a summary sentence.
Quick self-test before shipping
Read it aloud. Any sentence you would not say to a grad student at a whiteboard gets rewritten.
Count dashes. More than two? Cut.
Count lists of three. More than one per page? Cut.
Find the shortest sentence. If it is over 10 words, add a short one. If it has no verb, fix that first.
Is the main claim bolded once, inline, mid-paragraph? If not, do it.
Does every tool name have a gloss at first use? Grep for capitalized acronyms; check each one's debut.
Any \bi without a matching \ei? Any \ref to a label that moved?