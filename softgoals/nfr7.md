{% raw %}
nfr7: nfr6 made honest.  isamp returns TRUTH — a denied child
fails its parent, classically — and positive loops are, by
default, unfounded: a goal reached again while still being
argued fails, as in ASP's stable models.

## The loop mechanism

derive marks a head `open` before walking its body and closes
it on the way out: success overwrites `open` with t (the key is
already on the trail, so undo needs nothing new), failure
undoes the attempt and denies with f.  The memo line in isamp
reads three ways: t is t, f is f, and `open` — a goal met again
while still being argued — reports `*loops*`.  With `*loops*`
nil (the default) a positive loop is unfounded and fails; with
`*loops*` t the old coinductive reading returns, where a loop
proves itself.  One dynamic variable, both semantics, one line
of ablation.

Corpus fact: the knob changes nothing on the eight Horkoff
models (1146 heads).  Their goal graphs contain seven cycles,
but every one threads a contribution link, and links never
descend into rules — they only draw a label.  Zero cycles pass
through derive.  The only code that exercises the knob is the
zoo's `cycle` model, which under the default has no world: a
companion demo to `liar`, showing self-support earns nothing.

## What this is not

Not a three-valued logic.  `open` never appears in a model file
and never survives into an answer: every derive closes to t or
f before returning, so all sampled worlds are strictly
two-valued and paint never sees a third color.  `open` is the
grey node of white/grey/black cycle detection — the "call in
progress" mark of tabled Prologs — internal machinery, not a
truth value.  In Fitting's Kripke-Kleene semantics (1985) and
the well-founded semantics (Van Gelder, Ross & Schlipf 1988)
the third value is a citizen of the final model; here it is
scaffolding, torn down before anyone looks.

Not negation as failure.  There is no `not` operator to loop
through: denial is an explicit f label — a failed derivation, a
demand, a contribution rolled against — and every walk pushes
through to a conclusion, t or f, never "could not prove".
That makes the program positive, and on positive programs the
well-founded and stable semantics agree and are two-valued:
unfounded loops are simply false.  So `*loops*` nil matches ASP
exactly on this fragment, with none of the machinery negation
would demand.

Not a TMS.  Doyle's JTMS (1979) records justifications and
retracts, on contradiction, only the guilty assumption —
dependency-directed backtracking.  Our trail is chronological,
the Prolog/WAM kind: undo pops everything back to the mark,
guilty or innocent, and we accept redoing innocent work in
exchange for storing no justification network.  What survives
of the TMS idea is the labels themselves: in/out became t/f,
and the world is the network.

Not an ATMS either.  de Kleer's ATMS (1986) maintains every
consistent environment at once; sample draws worlds one at a
time and throws the trail away.  ATMS results by Monte Carlo:
the unanimity filter over sampled worlds approximates cautious
consequences — and when the generator is a solver, the solver
computes that filter natively (see REPORT_rivals.md).

The coinductive option has a name too.  `*loops*` t is the
greatest-fixpoint reading of co-LP (Gupta et al. 2007), where a
cycle of positive calls succeeds.  Keeping it behind the knob
records that the choice is semantic, not accidental — and that
on this corpus it is free either way.

Two small corollaries of the open mark.  A demand `(= g v)` on
a goal still being argued fails — loops through demands are
unfounded like any other.  And eager sorts known atoms first,
`open` among them, so a walk that has wandered into a loop
fails fast rather than after spending its dice.

{% endraw %}