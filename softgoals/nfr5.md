need to explan makes breaks helps hurts and internally, must

Abductive logic programming frames inference as explanation: given a program
P of clauses, abducible atoms A that P leaves undefined, and integrity
constraints IC, an explanation is a set of assumptions over A that, with P,
entails the goals without violating IC (Kakas, Kowalski & Toni 1992).  Our
engine runs this framework forwards, many times: P is the goal model, A its
headless atoms, IC the demands, each world one candidate explanation.  One
generalization: assumptions are two-valued, so an explanation is a labelling
— a partial function from atoms to {t, f} — not a set of atoms assumed true.

A model is a set of clauses h ← body.  An atom heading a clause is defined:
its truth must be argued through some body.  One heading no clause is
abducible: assume whichever label is useful, subject only to consistency;
i.e. each world holds only one label per atom.  Hard goals are gated —
derive, then a demand insists on t — so a world that cannot earn every hard
goal dies.  Soft goals are engaged, not gated: the query ends by mentioning
every one, and a bare mention never fails.  Slogan: hards filter, softs
score, the loop breeds worlds against the score.

Each world is one ISAMP probe [Crawford & Baker 1994]: guess, commit, never
backtrack across worlds.  A failed demand leaves a dead world and we start
another; patience counts consecutive dead worlds and, exhausted, stops the
sampling.  At each atom, three rules in priority order: an existing label
stands, whatever it says; else clauses are derived, failure labelling the
atom f; else assume t.

As the walk proceeds, labels (x/t, x/f) accumulate.  Entering a defined
subgoal g, we note the trail position — the mark — and record the optimistic
g=t, so revisits answer at once; if g's body fails we forget every binding
past the mark and write g=f: a denial, not a contradiction.  Leaves and link
targets are single writes, no mark.  The scorer counts benefit (soft goals
t), footprint (task leaves bought), and distance-to-heaven combining both;
search is selection, not repair — cast many worlds, keep the best, shrink
its labels to the keys that recreate it on replay.

Replaying is not just rerunning the query: a model with many disjunctions
offers many pathways, and fresh dice may wander down a branch the original
walk never took, committing assumptions that collide with the supplied
labels.  So replay guides inference back along pathways already paid for,
gambling only where the explanation is silent: the same engine runs with a
candidate labelling supplied up front, plus six mechanisms (named as such in
the source code) — two at intake, one keyword, three on the walk:

- ADOPT: labels on abducible atoms preload as assumptions, and an f
  label on any atom preloads as a denial no assumption may override.
- RE-EARN: a t label on a defined atom is a claim, not an assumption;
  the engine rewrites it as a must goal, and a world that cannot
  re-earn the claim is dead.
- MUST: internal keyword (users never write it) backing re-earn:
  derive the atom, then demand the result is t.
- STEER: at each disjunction, take a branch that already ran and paid
  off, without rolling the dice.
- CITE: a subgoal whose atoms are all already true is not rederived.
- YIELD: contribution links defer to existing labels, whatever their
  value; demands never yield.

All else is still sampled, so replaying many times measures how much the
explanation pins down: good keys show small variance around a good score.
Play gambles; replay holds you to your story.

Each mechanism earns its keep by ablation — remove it and watch what
breaks.

- Without ADOPT, replay becomes empty: the supplied labels never enter
  the world, so replay is just play again and nothing about the
  explanation is ever tested.
- Without RE-EARN, replay becomes gullible: a t label on a defined
  atom is swallowed as an assumption instead of being rewritten as a
  goal, so the claim's subtree is never walked and nothing checks that
  the claim can actually be derived.  Assert diy/t with no coders in
  sight, and replay nods along.
- Without MUST, replay becomes inaccurate: conclusions contradicting
  the base assumptions can be reached.  The claim's subtree is still
  walked, but when its derivation fails the engine just records the
  claim f and carries on.  For example, a
  replay of diy/t can return, as a "success", a world holding diy/f.
  MUST turns that mismatch into a dead world.
- Without STEER, replay becomes slow: instead of taking the disjunct
  used before, the engine explores the disjuncts in any order.  Wrong
  disjuncts commit assumptions that contradict the adopted labels, so
  worlds keep dying and the sampler keeps retrying; many dead worlds
  are burned before a live one appears, and good keys look unstable
  for reasons that have nothing to do with the keys.
- Without CITE, replay becomes slow another way: subtrees already
  proven t are rewalked instead of accepted.  The answers do not
  change — memo, STEER and YIELD resolve every revisit the same way —
  so this costs time, not truth.  (CITE becomes load-bearing only if
  STEER is also gone: then a rewalked or re-rolls its bet, and a
  paid-off win can be lost.)
- Without YIELD, replay becomes needlessly fatal: contribution links
  roll dice against labels already in the world.  A link firing onto
  a labelled quality can roll the other value; the contradiction fails
  the clause, the failed clause denies its head, and worlds die over
  side-effect edges whose outcome the explanation had already fixed.
  (Demands are the deliberate exception: a demand that contradicts a
  label should kill the world, which is why demands never yield.)

Two departures from classical ALP.  First, no search for a minimal
explanation: we sample and select by score; minimality returns at the end
when ddmin shrinks the best world's assumptions to the keys that recreate
it.  Second, clause bodies are negation-free, so the hazards of
negation-as-failure — loops like a ← ¬a, and the three-valued semantics that
tame them — cannot arise: falsity is never a premise, only a recorded
outcome, consumed solely by the integrity constraints.  False labels enter
three ways: a link rolls f, a demand requires f, or a sampled derivation
fails and the goal is recorded false — denial, weaker than NAF since it
commits after one random attempt, not all.  Within a world denial is a bet;
across worlds sampling repairs it: goals deniable on some clause choices and
derivable on others appear both ways in the sample.

-----------------------------

Slogan stands: hards filter, softs score, loop breeds worlds against
the score.

Hard goals and soft goals enter the query differently.  Each hard goal
is gated — the walk must derive it and then a demand insists the
result is t — so any world that cannot earn all its hard goals dies.
Soft goals are engaged, not gated: the query ends by mentioning every
one, and a bare mention never fails.

When the walk reaches an atom it applies three rules in priority
order.  If the atom is already labelled — say a contribution link
fired earlier — that evidence stands, whatever it says.  Else, if the
atom has clauses, we derive it: its criteria are checked, and a failed
derivation labels it f.  Else, with no evidence and no rules, we
assume t.

Assumption is thus a last resort that fills silence but never
overrules: a soft goal whose clauses fail, or that a link has already
denied, stays f in that world.  Coverage is counted only afterwards,
by the scorer: benefit is the number of soft goals labelled t,
footprint the number of task leaves bought, and distance-to-heaven
combines the two.  Search is selection, not repair: we cast many
worlds, score each, keep the best, then shrink its labels to the few
keys that recreate it on replay.

----------

Each world is one ISAMP probe [Crawford & Baker 1994]: guess, commit,
never backtrack across worlds.  One walk builds one world; a walk that
hits a failed demand leaves a dead world, and we start another.
Patience counts consecutive dead worlds; when it runs out, sampling
stops.

As a walk proceeds, labels (x/t, x/f) accumulate in the world.  On
recursing into a subgoal g, we note the current trail position — the
mark — then record the assumed outcome g=t.  That optimistic record
does double duty: if the walk revisits g, by loop or by shared
subgoal, the stored label answers at once, so no work repeats and the
growing label set stays consistent.  If g's body fails, we forget
every binding made after the mark and write g=f instead: a denial, not
a contradiction.  Marks are laid once per derivation attempt, on entry
to each head with clauses, before its body is walked; leaf atoms and
link targets are single writes with nothing to roll back, so they get
labels but no mark.

--------- so play is lneient and replay is demaning

Almost — flip it partway. Both enforce = demands equally. The real
split:

- play = explore. Every choice diced fresh; links can clash mid-walk
and deny heads. Nothing privileged.  - replay = defend. Your beliefs
are privileged: won goals skip, labelled qualities settle links, ors
steer to won branches. Lenient about edges, demanding about your
claims — a believed-t head must re-derive its whole subtree, and a
belief that gates against a demand kills the world.

Slogan: play gambles, replay holds you to your story.
