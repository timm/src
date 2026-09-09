{% raw %}
need to explan makes breaks helps hurts and internally, must

Abductive logic programming frames inference as explanation: given a
program P of clauses, a set A of abducible atoms that P leaves
undefined, and integrity constraints IC, an explanation is a set of
assumptions over A that, together with P, entails the goals without
violating IC (Kakas, Kowalski & Toni 1992).  Our engine is this
framework run forwards, many times: P is the goal model, A is its
headless atoms, IC is the demands, and each world is one candidate
explanation.  One generalization: our assumptions are two-valued, so
an explanation is not a set of atoms assumed true but a labelling — a
partial function from atoms to {t, f}, with unlabelled atoms unseen.

A model is a set of clauses h ← body.  An atom that heads at least one
clause is defined; its truth must be argued through some clause body.
An atom that heads no clause is abducible: the model places no
constraint on it, so the engine may assume whichever label is useful,
subject only to consistency; i.e. each world holds only one label per
atom.  Goals may be of either kind: a defined goal demands its proof,
an abducible goal is satisfied by assumption alone.  Hard goals are
gated — the walk must derive them and a demand insists the result is
t — so any world that cannot earn all its hard goals dies.  Soft goals
are engaged, not gated: the query ends by mentioning every one, and a
bare mention never fails.  Slogan: hards filter, softs score, the
loop breeds worlds against the score.

Each world is one ISAMP probe [Crawford & Baker 1994]: guess, commit,
never backtrack across worlds.  One walk builds one world; a walk that
hits a failed demand leaves a dead world, and we start another.
Patience counts consecutive dead worlds; when it runs out, sampling
stops.  When the walk reaches an atom it applies three rules in
priority order: an existing label stands, whatever it says; else, an
atom with clauses is derived, and a failed derivation labels it f;
else, with no evidence and no rules, we assume t.  Assumption is thus
a last resort that fills silence but never overrules.

As a walk proceeds, labels (x/t, x/f) accumulate in the world.  On
recursing into a defined subgoal g, we note the current trail position
— the mark — then record the assumed outcome g=t; if the walk revisits
g, the stored label answers at once.  If g's body fails, we forget
every binding made after the mark and write g=f instead: a denial, not
a contradiction.  Leaf atoms and link targets are single writes with
nothing to roll back, so they get labels but no mark.  Afterwards the
scorer counts benefit (soft goals labelled t), footprint (task leaves
bought), and distance-to-heaven combines the two.  Search is
selection, not repair: cast many worlds, score each, keep the best,
then shrink its labels to the few keys that recreate it on replay.

Replaying an explanation is not just rerunning the query: a model with
many disjunctions offers many pathways, and fresh dice may wander down
a branch the original walk never took, committing assumptions that
collide with the supplied labels.  Replay must guide inference back
along the pathways already paid for, and gamble only where the
explanation is silent.  So replay runs the same engine with a
candidate labelling supplied up front, sorted at intake by kind.
Adopt: labels on abducible atoms preload as assumptions, and an f
label on any atom preloads as a denial no assumption may override.
Re-earn: a t label on a defined atom is a claim, not an assumption;
the engine rewrites it as an internal must goal — derive, then insist
on t — and a world that cannot re-earn the claim is dead.  The walk
then adds three mechanisms to the core sampler.  Steer: at each
disjunction, take a branch that has already run and paid off, without
rolling the dice.  Cite: a subgoal whose atoms are all already true is
cited, not rederived.  Yield: contribution links defer to existing
labels, whatever their value; demands never yield.  Everything else is
still sampled, so replaying many times measures how much of the
outcome the explanation pins down: a good set of keys shows small
variance around a good score.  Play gambles; replay holds you to your
story.

Two departures from classical ALP.  First, we do not search for a
minimal explanation; we sample explanations and select by score, and
minimality returns at the end, when ddmin shrinks the best world's
assumptions to the few keys that recreate it.  Second, clause bodies
are negation-free, so the classic hazards of negation-as-failure —
nonmonotonic loops such as a ← ¬a, and the three-valued semantics
needed to tame them — cannot arise: falsity is never a premise, only a
recorded outcome, consumed solely by the integrity constraints.  False
labels enter a world three ways: a contribution link rolls f, a demand
requires f, or a sampled derivation fails and the engine records the
goal false.  That last move — denial — is weaker than NAF: NAF
concludes falsity only after every derivation fails, while denial
commits after one randomly chosen attempt.  Within a world denial is a
bet; across worlds, sampling repairs it, since goals deniable on some
clause choices and derivable on others appear both ways in the sample.

{% endraw %}