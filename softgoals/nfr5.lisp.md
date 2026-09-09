# nfr5.lisp

{% raw %}
```lisp
					; vim: set lispwords+=loop :
;;;; nfr5.lisp : world sampler for goal models; port of infer.py.
;;;; Bodies are plain sexprs -- the reader is the parser:
;;;;   (and ...) shuffled conjunction
;;;;   (or ...)  a bet: pick one branch, it must deliver
;;;;   (= x t)   demand (chk or add)    (helps x) weighted link
;;;;   (seq ...) ordered: (seq x (= x t)) derives then insists
;;;;   (must x)  sugar for the above: earn x, then insist on it
;;;;   bare atom label it, never a demand
;;;; (<- head body) records a clause on the head symbol plist.
;;;; Worlds are hash tables; undo is a trail. (An alist world
;;;; was tried and retired: free snapshots, but O(n) reads made
;;;; the replay-heavy keys pipeline 6x slower.) RNG is the
;;;; house park-miller 16807, seedable via *seed*.
		     #+sbcl
(progn
  (declaim (sb-ext:muffle-conditions style-warning))
  (setf sb-ext:*invoke-debugger-hook*
        (lambda (condition hook)
          (declare (ignore hook))
          (format *error-output* "~&Error: ~A~%" condition)
          (sb-ext:exit :code 1))))

(defvar *links* '((makes t) (breaks f) (helps t t f) (hurts f f t)))
(defvar *replay* nil)
(defvar *heads* nil)
(defvar *seed*  1)

(defmacro <- (head body)
  `(progn (pushnew ',head *heads*)
          (setf (get ',head 'rules)
                (append (get ',head 'rules) (list ',body)))))

(defun prand () (/ (setf *seed* (mod (* 16807 *seed*) 2147483647)) 2147483647d0))
(defun reseed (n)   ; park-miller warmup: small seeds' first
  (setf *seed* n)   ; draws are tiny, so burn a few
  (dotimes (i 3) (prand))
  n)
(defun rint (n) (floor (* n (prand))))
(defun pick (xs) (nth (rint (length xs)) xs))

(defun shuffled (xs &aux (v (coerce xs 'vector)))
  (loop for i from (1- (length v)) downto 1
        do (rotatef (aref v i) (aref v (rint (1+ i)))))
  (coerce v 'list))

(defun syms (g)
  (cond ((symbolp g)                    (list g))
        ((member (car g) '(and or seq must)) (mapcan #'syms (copy-list (cdr g))))
        (t                              (list (second g)))))

(defun known (x w) (nth-value 1 (gethash x w)))
(defun won (g w)   (every (lambda (a) (eq (gethash a w) 't)) (syms g)))

(defun delivered (g w)   ; no denied task inside: an or-bet paid off
  (cond ((symbolp g) (eq (gethash g w) 't))
        ((member (car g) '(and seq must))
         (every (lambda (x) (delivered x w)) (cdr g)))
        (t t)))          ; =, links, inner or: isamp already ruled

(defun settled (g w)     ; this branch already ran, and paid off
  (and (every (lambda (a) (known a w)) (syms g)) (delivered g w)))

(let (trail)   ; the undo trail, reachable ONLY via these verbs
  (defun add (x v w)
    "record x=v on the world and the trail; always true"
    (setf (gethash x w) v) (push x trail) t)
  (defun mark ()      trail)
  (defun undo (mark w)
    (loop until (eq trail mark) do (remhash (pop trail) w)))
  (defun wipe ()      (setf trail nil)))

(defun believe (x v w)
  (if (known x w) (eq (gethash x w) v) (add x v w)))

(defun derive (g w)
  "try one body under g=t; on failure undo and deny: g=f"
  (let ((mark (mark)))
    (add g 't w)
    (unless (isamp (pick (get g 'rules)) w)
      (undo mark w)
      (add g 'f w))
    t))

(defun isamp (g w)
  (cond
    ((and *replay* (or (symbolp g) (not (eq (car g) '=)))
          (won g w))
     t)                                          ; CITE: not rederived
    ((symbolp g)
     (cond ((known g w)     t)                   ; memo
           ((get g 'rules)  (derive g w))
           (t               (add g 't w))))      ; fiat: abduce to t
    ((eq (car g) '=)   (believe (second g) (third g) w))
    ((eq (car g) 'seq)  (every (lambda (x) (isamp x w)) (cdr g)))
    ((eq (car g) 'must) (every (lambda (x) (and (isamp x w)
                                                (believe x 't w)))
                               (cdr g)))
    ((eq (car g) 'and) (every (lambda (x) (isamp x w)) (shuffled (cdr g))))
    ((eq (car g) 'or)  (or (and *replay*         ; STEER: a paid-off
                                (some (lambda (x) (settled x w)) (cdr g)))
                           (let ((x (pick (cdr g))))   ; branch, else bet:
                             (and (isamp x w) (delivered x w)))))
    ((assoc (car g) *links*)
     (or (and *replay* (known (second g) w))     ; YIELD: label stands
         (believe (second g) (pick (cdr (assoc (car g) *links*))) w)))
    (t nil)))

(defun sample (query &key beliefs replay (n 20) (patience 1000))
  (let ((*replay* replay) pre goals worlds (got 0) (miss 0))
    (loop for (x . v) in beliefs
          do (if (and (eq v 't) (get x 'rules))
                 (push `(must ,x) goals)   ; RE-EARN: claims re-prove
                 (push (cons x v) pre)))   ; ADOPT: assumptions, denials
    (setf goals (append goals query))
    (loop while (and (< got n) (< miss patience))
          do (let ((w (make-hash-table :test 'eq)))
               (wipe)
               (loop for (x . v) in pre do (setf (gethash x w) v))
               (cond ((every (lambda (g) (isamp g w)) goals)
                      (setf miss 0) (incf got) (push w worlds))
                     (t (incf miss)))))
    (nreverse worlds)))

;---------------------------------------------------------------
;;; paint: print the model annotated with one sampled world:
;;; green atom/t (won), red atom/f (denied), bare atom (unseen).
(defvar *hard* nil) (defvar *soft* nil)   ; set by the model file
(defvar *model* nil) (defvar *doc* nil)   ; who is loaded, and why

(defun tag (x w)
  (case (gethash x w)
    ((t)       (format nil "~c[32m~(~a~)/t~c[0m" #\Esc x #\Esc))
    ((f)       (format nil "~c[31m~(~a~)/f~c[0m" #\Esc x #\Esc))
    (otherwise (format nil "~(~a~)" x))))

(defun pp (g w)
  (cond ((symbolp g) (tag g w))
        ((member (car g) '(and or seq must))
         (format nil "(~(~a~)~{ ~a~})" (car g)
                 (mapcar (lambda (x) (pp x w)) (cdr g))))
        ((eq (car g) '=)
         (format nil "(= ~a ~(~a~))" (tag (second g) w) (third g)))
        (t (format nil "(~(~a~) ~a)" (car g) (tag (second g) w)))))

(defun paint (w)
  (format t "~&;; ~(~a~)~@[ : ~a~]~%" *model* *doc*)
  (format t ";; hard:~{ ~a~}~%" (mapcar (lambda (h) (tag h w)) *hard*))
  (format t ";; soft:~{ ~a~}~%~%" (mapcar (lambda (s) (pp s w)) *soft*))
  (dolist (h (reverse *heads*))
    (dolist (b (get h 'rules))
      (format t "(<- ~a ~a)~%" (tag h w) (pp b w)))))

(defun clear ()   ; forget the last model: one theory per painted
  (dolist (h *heads*) (setf (get h 'rules) nil))
  (setf *heads* nil *hard* nil *soft* nil *model* nil *doc* nil))

(defun query ()   ; gate the hards, engage every soft
  (append (loop for h in *hard* append (list h `(= ,h t)))
          (when *soft* (list (cons 'and (copy-list *soft*))))
          (unless (or *hard* *soft*) (reverse *heads*))))

(defun painted (model &optional (seed 1) beliefs)
  "load a model, sample one world (replayed if beliefs), paint it"
  (clear)
  (load model)
  (setf *model* (pathname-name model))
  (reseed seed)
  (paint (car (sample (query)
                      :beliefs beliefs :replay (and beliefs t) :n 1))))

(defvar *egs*   ; the example suite: every model beside this file
  (let ((here (or *load-truename* *default-pathname-defaults*)))
    (cons (merge-pathnames "small.lisp" here)
          (directory (merge-pathnames "models/*.lisp" here)))))

(defun eg (&optional (seed 1))
  "paint one sampled world for every model in *egs*"
  (dolist (m *egs*) (terpri) (painted m seed)))

;---------------------------------------------------------------
;;; zoo: tiny in-file models plus the play/replay verbs.
;;; From a repl (make repl):
;;;   (play 'shop)                => how: ((coders . t) ...)
;;;   (replay 'shop (play 'shop)) => paint what that how reaches
;;;   (play 'shop 3)              => same, different dice
(defvar *models* nil)

(defmacro defmodel (name &key doc hard soft rules)
  `(push (list ',name ',hard ',soft ',rules ',doc) *models*))

(defun zoo ()   ; list the models: name, doc
  (loop for (name nil nil nil doc) in (reverse *models*)
        do (format t "~(~10a~) ~@[~a~]~%" name doc)))

(defun use (name)
  (clear)
  (destructuring-bind (hard soft rules &optional doc)
      (cdr (assoc name *models*))
    (setf *hard* hard *soft* soft *model* name *doc* doc)
    (dolist (r rules)   ; r = (<- head body)
      (pushnew (second r) *heads*)
      (setf (get (second r) 'rules)
            (append (get (second r) 'rules) (list (third r)))))))

(defun play (name &optional (seed 1))
  "satisfy the goals once, paint it; return how: ((atom . label) ...)"
  (use name)
  (reseed seed)
  (let ((w (car (sample (query) :n 1))))
    (when w
      (paint w)
      (loop for x being the hash-keys of w using (hash-value v)
            collect (cons x v)))))

(defun replay (name how)
  "believe HOW, walk prudently, paint what gets reached"
  (use name)
  (let ((w (car (sample (query) :beliefs how :replay t :n 1))))
    (if w (paint w) (format t ";; that how kills every world~%"))))

(defun parade (&optional (seed 1))
  "play every model in the zoo"
  (loop for (name) in (reverse *models*)
        do (terpri) (play name seed)))

;;; every model under five lines
(defmodel diy :doc "one clause, must assume a negation" :hard (diy)
  :rules ((<- diy (and coders (helps cheap) (hurts fast)))))

(defmodel shop :doc "or-choice with rival links" :hard (built)
  :soft (cheap fast)
  :rules ((<- built (or buy diy))
          (<- buy (and vendor (breaks cheap) (helps fast)))
          (<- diy (and coders (helps cheap) (hurts fast)))))

(defmodel gate :doc "or is a bet: seed=1--> lukc, seed=2-->hardwork"
  :hard (done)
  :rules ((<- done (or a b))
          (<- a (and hardwork))
          (<- b (and luck))))

(defmodel diamond :doc "memo: base decided once, shared"
  :hard (top)
  :rules ((<- top (and left right))
          (<- left (and base))
          (<- right (and base))))

(defmodel cycle :doc "memo also breaks loops" :hard (chicken)
  :rules ((<- chicken (and egg))
          (<- egg (and chicken))))

(defmodel deny :doc "a denied subgoal is a label, not a death" :hard (plan)
  :rules ((<- plan (and (= flood f) picnic))
          (<- picnic (and outdoors (= flood t)))))

(defmodel stubborn :doc "two hard goals; only worlds rolling the link f live"
  :hard (party cake)
  :rules ((<- party (seq (= diet f) cake))
          (<- cake (and bake (helps diet)))))

(defmodel twoface :doc "two clauses, one doomed: win flips across worlds"
  :rules ((<- win (and talent))
          (<- win (and (= jinx t) (= jinx f)))))

(defmodel liar :doc "(replay 'liar '((hero . t))) kills every world"
  :rules ((<- hero (and (= brave t) (= brave f)))))

(defmodel cheapdear :doc "same benefit, one branch buys 3 leaves, one buys 1"
  :hard (fed) :soft (happy)
  :rules ((<- fed (or feast snack))
          (<- feast (and shop cook wash (helps happy)))
          (<- snack (and grab (helps happy)))))

(defmodel small :doc "the paper's running example: build, deploy, use"
  :hard (built deployed) :soft (cheap fast private)
  :rules ((<- built (or buy diy))
          (<- buy (and vendor (breaks cheap) (helps fast)))
          (<- diy (and coders (helps cheap) (hurts fast)))
          (<- deployed (or cloud onprem))
          (<- cloud (and (helps fast) (hurts private)))
          (<- onprem (and (makes private) (hurts fast)))
          (<- usable (and tested (helps fast)))))

(defmodel linkbet :doc "or over links: no task inside, the bet always delivers"
  :hard (spin)
  :rules ((<- spin (or (helps mood) (hurts mood)))))
```

need to explan makes raks helps hurts and internally, nust

Abductive logic programming frames inference as explanation: given a program P of clauses, a set A of abducible atoms that P leaves undefined, and integrity constraints IC, an explanation is a set of assumptions over A that, together with P, entails the goals without violating IC (Kakas, Kowalski & Toni 1992).
Our engine is this framework run forwards, many times: P is the goal model, A is its headless atoms, IC is the demands, and each world is one candidate explanation.
One generalization: our assumptions are two-valued, so an explanation is not a set of atoms assumed true but a labelling — a partial function from atoms to {t, f}, with unlabelled atoms simply unseen.

A model is a set of clauses h ← body.
An atom that heads at least one clause is defined; its truth must be argued through some clause body.
An atom that heads no clause is abducible: the model places no constraint on it, so the engine may assume whichever label is useful, subject only to consistency; i.e. each world holds only one label per atom.
In (a ← b ∧ c), (b ← k): a and b are defined, k and c are abducible; b is internal — defined, but queried only in service of a.

Goals are what the query names, and they may be of either kind.
A defined goal demands its proof; an abducible goal is satisfied by assumption alone.
Hard goals are observations that every world must entail (an integrity constraint forces them true); soft goals are engaged but not enforced — worlds are scored, not killed, by them.

Replay runs the same engine with a candidate explanation supplied up front: a labelling of some atoms, found by play or proposed by a stakeholder.
Intake sorts the labels by kind.
Adopt: labels on abducible atoms preload as assumptions — that is what abducibles are for — and an f label on any atom preloads as a denial no assumption may override.
Re-earn: a t label on a defined atom is a claim, not an assumption; the engine rewrites it as an internal must goal — derive, then insist on t — and a world that cannot re-earn the claim is dead.
The walk then adds three mechanisms to the core sampler.
Steer: at each disjunction, take a branch that has already run and paid off, without rolling the dice.
Cite: a subgoal whose atoms are all already true is cited, not rederived.
Yield: contribution links defer to existing labels, whatever their value; demands never yield.
Everything the explanation leaves unlabelled is still sampled, so replaying many times measures how much of the outcome the explanation pins down: a good set of keys shows small variance around a good score.

One departure from classical ALP: we do not search for a minimal explanation, we sample explanations and select by score; minimality returns at the end, when ddmin shrinks the best world's assumptions to the few keys that recreate it.

A second departure concerns negation.
Clause bodies here are negation-free, so the classic hazards of negation-as-failure — nonmonotonic loops such as a ← ¬a, and the three-valued semantics needed to tame them — cannot arise: falsity is never a premise, only a recorded outcome, and it is consumed solely by the integrity constraints.
False labels enter a world three ways: a contribution link rolls f, a demand requires f, or a sampled derivation fails and the engine records the goal false.
That last move — we call it denial — is weaker than negation-as-failure: NAF concludes falsity only after every derivation fails, while denial commits after one randomly chosen attempt.
Within a world, denial is therefore just a bet; across worlds, sampling repairs it, since goals deniable on some clause choices and derivable on others appear both ways in the sample.

Replaying an explanation is not just rerunning the query: a model with many disjunctions offers many pathways, and fresh dice may wander down a branch the original walk never took, committing assumptions that collide with the supplied labels and killing worlds that the explanation, followed faithfully, would support.
Replay must therefore guide inference back along the pathways already paid for, and gamble only where the explanation is silent.

Replay runs the same engine with a candidate explanation supplied up front: a labelling of some atoms, found by play or proposed by a stakeholder.
How each label is honored depends on the atom's kind.
Labels on abducible atoms are adopted as assumptions — that is what abducibles are for.
A t label on a defined atom is a claim, not an assumption: the engine rewrites it internally as a must goal (derive, then insist on t), so the claim must re-earn its label, and a world where it cannot is dead.
An f label on any atom stands as a denial that no assumption may override.
Prudence supplies the guidance: proven subtrees are cited rather than rederived, a disjunction prefers a branch that has already run and paid off, and contribution links yield to existing labels — though demands never do.
Everything the explanation leaves unlabelled is still sampled, so replaying many times measures how much of the outcome the explanation actually pins down: a good set of keys shows small variance around a good score.

-----------------------------

Slogan stands: hards filter, softs score, loop breeds worlds against the score.

Hard goals and soft goals enter the query differently.
Each hard goal is gated — the walk must derive it and then a demand insists the result is t — so any world that cannot earn all its hard goals dies.
Soft goals are engaged, not gated: the query ends by mentioning every one, and a bare mention never fails.

When the walk reaches an atom it applies three rules in priority order.
If the atom is already labelled — say a contribution link fired earlier — that evidence stands, whatever it says.
Else, if the atom has clauses, we derive it: its criteria are checked, and a failed derivation labels it f.
Else, with no evidence and no rules, we assume t.

Assumption is thus a last resort that fills silence but never overrules: a soft goal whose clauses fail, or that a link has already denied, stays f in that world.
Coverage is counted only afterwards, by the scorer: benefit is the number of soft goals labelled t, footprint the number of task leaves bought, and distance-to-heaven combines the two.
Search is selection, not repair: we cast many worlds, score each, keep the best, then shrink its labels to the few keys that recreate it on replay.

----------

Each world is one ISAMP probe [Crawford & Baker 1994]: guess, commit, never backtrack across worlds.
One walk builds one world; a walk that hits a failed demand leaves a dead world, and we start another.
Patience counts consecutive dead worlds; when it runs out, sampling stops.

As a walk proceeds, labels (x/t, x/f) accumulate in the world.
On recursing into a subgoal g, we note the current trail position — the mark — then record the assumed outcome g=t.
That optimistic record does double duty: if the walk revisits g, by loop or by shared subgoal, the stored label answers at once, so no work repeats and the growing label set stays consistent.
If g's body fails, we forget every binding made after the mark and write g=f instead: a denial, not a contradiction.
Marks are laid once per derivation attempt, on entry to each head with clauses, before its body is walked; leaf atoms and link targets are single writes with nothing to roll back, so they get labels but no mark.

---------
so play is lneient and replay is demaning

Almost — flip it partway. Both enforce = demands equally. The real split:

- play = explore. Every choice diced fresh; links can clash mid-walk and deny heads. Nothing privileged.
- replay = defend. Your beliefs are privileged: won goals skip, labelled qualities settle links, ors steer to won branches. Lenient about edges, demanding about your claims — a believed-t head must re-derive its whole subtree, and a belief that gates against a demand kills the world.

Slogan: play gambles, replay holds you to your story.


(play 'shop)                    ; sample world, return how-alist
(play 'shop 3)                  ; other seed
(replay 'shop (play 'shop))     ; believe how, paint reached parts
(replay 'gate '((b . t)))       ; hand-made how: steer to branch b
(painted "small.lisp")          ; load model file, paint one world
(painted "models/Modernize.lisp" 7)             ; seed 7
(painted "small.lisp" 1 '((diy . t)))           ; replay-paint beliefs
(eg)                            ; paint every model in *egs*
(sample (query) :n 20)          ; raw worlds, current model
(use 'gate)                     ; install zoo model without running

From shell

make repl                       # zoo repl
make paint M=small.lisp S=1     # painted, one model
make eg S=3                     # painted, all models
make keys                       # python pipeline table
make keys-lisp                  # lisp pipeline table
sbcl --script rig.lisp small.lisp small    # one row of that table

Underneath (rarely called direct)

(sample query :beliefs how :replay t :n 30)  ; the engine verb
(paint w)                       ; color one world onto clauses
(clear)                         ; forget loaded model

```lisp
(defun main () (load "nfr5.lisp"))
```

{% endraw %}