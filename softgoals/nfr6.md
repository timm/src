nfr6: one walk. play == replay. The replay machinery of nfr5
(STEER, CITE, YIELD as replay-only specials) is retired; what
survives of it is the default walk, for everyone.

Abductive logic programming frames inference as explanation: given a
program P of clauses, abducible atoms A that P leaves undefined, and
integrity constraints IC, an explanation is a set of assumptions over
A that, with P, entails the goals without violating IC (Kakas,
Kowalski & Toni 1992).  Our engine runs this framework forwards, many
times: P is the goal model, A its headless atoms, IC the demands,
each world one candidate explanation.  One generalization:
assumptions are two-valued, so an explanation is a labelling — a
partial function from atoms to {t, f} — not a set of atoms assumed
true.  A label t means supported: derived through some clause body,
or assumed because nothing constrained it.  A label f means denied:
a derivation that failed, a demand that required it, or a
contribution that rolled against it.  Unlabelled means unseen.

A model is a set of clauses h ← body.  An atom heading a clause is
defined: its truth must be argued through some body.  An atom heading
no clause is abducible: assume whichever label is useful, subject
only to consistency; i.e. each world holds only one label per atom.
Hard goals are gated — derive, then a demand insists on t — so a
world that cannot earn every hard goal dies.  Soft goals are engaged,
not gated: the query ends by mentioning every one, and a bare mention
never fails.  Slogan: hards filter, softs score, the loop breeds
worlds against the score.

The walk is one policy, in both modes, and knowledge drives every
step.  A known atom is never descended into: the memo that breaks
loops is the same rule that spares proven subtrees.  A conjunction
runs its already-known parts first (free checks), then shuffles only
the unknowns.  A disjunction wants any branch that delivers — no
denied task inside — and tries them in the same eager order, knowns
first, unknowns shuffled; a failed try rolls back its labels and the
next branch is tried, so a disjunction dies only when every branch
fails.  A contribution link onto a
labelled atom stands aside, whatever the label says: evidence does
not argue with evidence.  Only a demand (= x v) is binding; demands
are the one thing that can kill a world.  Entering a defined subgoal
we mark the trail and record the optimistic g=t; if the body fails
we roll back past the mark and write g=f: a denial, not a
contradiction, and the walk continues.  The scorer then counts
benefit (soft goals t) and footprint (task leaves bought);
distance-to-heaven combines them.  Search is selection, not repair:
cast many worlds, keep the best, shrink its labels to the keys that
recreate it on replay.

Replay is now the same walk, started with the explanation's labels
already in the world.  Whatever is preloaded is known, and the
knowledge-driven rules do the steering for free: settled branches
win their disjunctions, proven atoms are not rewalked, links defer.
One asymmetry survives, at intake, not in the walk.  Labels on
abducible atoms load as assumptions — that is what abducibles are
for — and an f label on any atom loads as a standing denial.  But a
t label on a DEFINED atom is a claim, not an assumption: the engine
rewrites it as an internal must goal (derive, then demand t), and a
world that cannot re-earn the claim is dead.  Without this, a
stakeholder could assert diy/t with no coders in sight and replay
would nod along.

That asymmetry is the boundary between two kinds of abduction.
Classic ALP abduces over leaves: explanations name only atoms the
program leaves undefined, and everything else must be re-derived.
Head abduction — letting an explanation label defined atoms —
buys determinism (the labelled heads pin the walk) but at a price:
every believed head must re-earn its whole subtree, and on or-heavy
models that derivation tax makes the full explanation replay worse
than a random world.  Measured on the SHORT corpus: leaf abduction
reaches the original world's score (lucky replays match the best
untreated run on every model) but wanders on average, because
leaves alone under-determine the disjunctions; head abduction is
tight where it is honest but pays the tax where or-nests are deep.
Stability came from leaves, determination from heads; the open
middle is to record the decisions themselves — which branch, not
which conclusion.

On negation: clause bodies are negation-free, so the classic hazards
of negation-as-failure — loops like a ← ¬a, and the three-valued
semantics that tame them — cannot arise.  Falsity is never a
premise: no body conditions on f, and f is consumed only by the
demands and by or-delivery.  A goal is recorded f when one sampled
derivation fails — denial, weaker than NAF, which concludes falsity
only after every derivation fails.  Within a world denial is a bet;
across worlds sampling repairs it, since goals deniable on some
clause choices and derivable on others appear both ways in the
sample.  Two departures from classical ALP remain: we sample and
select rather than search for minimal explanations (minimality
returns at the end, when ddmin shrinks the best world's labels to
keys), and our explanations are labellings, not sets of assumed
atoms — f is a first-class assumption precisely because it can only
forbid, never prove.
