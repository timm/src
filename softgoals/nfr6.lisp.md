# nfr6.lisp

{% raw %}
```text
nfr6.lisp : nfr5 with ONE walk: play == replay.
The replay flag is gone. Knowledge drives every step, in
both modes; replay is just play that starts with labels
already in the world:
  atom known        -> stop, never descend (memo==cite)
  and               -> knowns first (free checks), then
                       the unknowns, shuffled
  or                -> any true, eager order: knowns
                       first, then shuffled unknowns;
                       a failed try rolls back
  link, target known-> evidence stands, whatever it says
  (= x v)           -> binding, always, the only killer
One asymmetry survives, at intake not in the walk: a
supplied t on a defined atom is a claim, rewritten as
(seq x (= x t)) so it must re-earn (RE-EARN), else
diy/t-with-no-coders sails through.
```

```lisp
		     #+sbcl
(progn
  (declaim (sb-ext:muffle-conditions style-warning))
  (setf sb-ext:*invoke-debugger-hook*
        (lambda (condition hook)
          (declare (ignore hook))
          (format *error-output* "~&Error: ~A~%" condition)
          (sb-ext:exit :code 1))))

(defvar *links* '((makes t) (breaks f) (helps t t f) (hurts f f t)))
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
        ((member (car g) '(and or seq)) (mapcan #'syms (copy-list (cdr g))))
        (t                              (list (second g)))))

(defun known (x w) (nth-value 1 (gethash x w)))

(defun delivered (g w)   ; no denied task inside: an or-try paid off
  (cond ((symbolp g) (eq (gethash g w) 't))
        ((member (car g) '(and seq))
         (every (lambda (x) (delivered x w)) (cdr g)))
        (t t)))          ; =, links, inner or: isamp already ruled

(let (trail)   ; the undo trail, reachable ONLY via these verbs
  (defun add (x v w)
    "record x=v on the world and the trail; always true"
    (setf (gethash x w) v) (push x trail) t)
  (defun mark ()      trail)
  (defun undo (mark w)
    "roll back to mark; reports nil: undoing is never success"
    (loop until (eq trail mark) do (remhash (pop trail) w)))
  (defun wipe ()      (setf trail nil)))

(defun believe (x v w)
  (if (known x w) (eq (gethash x w) v) (add x v w)))

(defun won (g w)
  "walked, and no denied task inside"
  (and (isamp g w) (delivered g w)))

(defun many (goals patience try w &optional (mark (mark)))
  "walk goals via TRY; PATIENCE failures tolerated (each rolled
   back alone), one more undoes the lot; win early once no
   losing streak can sink us"
  (cond ((< patience 0)               (undo mark w))
        ((<= (length goals) patience) t)
        (t (let ((try-mark (mark)))
             (many (cdr goals)
                   (if (funcall try (car goals) w) patience
                       (progn (undo try-mark w) (1- patience)))
                   try w mark)))))

(defun derive (g w)
  "try one body under g=t; on failure undo and deny: g=f"
  (let ((mark (mark)))
    (add g 't w)
    (unless (isamp (pick (get g 'rules)) w)
      (undo mark w)
      (add g 'f w))
    t))

(defun eager (xs w &optional yes no)
  "knowns to the front (free checks); dice only for the rest"
  (if (null xs)
      (append yes (shuffled (reverse no)))   ; known order: no dice, no labels
      (if (every (lambda (a) (known a w)) (syms (car xs)))
          (eager (cdr xs) w (cons (car xs) yes) no)
          (eager (cdr xs) w yes (cons (car xs) no)))))

(defun isamp (g w)
  "t = walk FINISHED, not g true; wanting victory, read labels after: (= g t) dies, won shops"
  (cond
    ((symbolp g)
     (cond ((known g w)     t)                   ; known: never descend
           ((get g 'rules)  (derive g w))
           (t               (add g 't w))))      ; fiat: abduce to t
    ((eq (car g) '=)   (believe (second g) (third g) w))
    ((eq (car g) 'seq) (many (cdr g) 0 #'isamp w))
    ((eq (car g) 'and) (many (eager (cdr g) w) 0 #'isamp w))
    ((eq (car g) 'or)  (many (eager (cdr g) w) (1- (length (cdr g))) #'won w))
    ((assoc (car g) *links*)
     (or (known (second g) w)                    ; evidence stands
         (believe (second g) (pick (cdr (assoc (car g) *links*))) w)))
    (t nil)))

(defun sample (query &key beliefs (n 20) (patience 1000))
  (let (pre goals worlds (got 0) (miss 0))
    (loop for (x . v) in beliefs
          do (if (and (eq v 't) (get x 'rules))
                 (push `(seq ,x (= ,x t)) goals)   ; RE-EARN: claims re-prove
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
        ((member (car g) '(and or seq))
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
  "load a model, sample one world (with any beliefs), paint it"
  (clear)
  (load model)
  (setf *model* (pathname-name model))
  (reseed seed)
  (paint (car (sample (query) :beliefs beliefs :n 1))))

(defvar *egs*   ; the example suite: every model beside this file
  (let ((here (or *load-truename* *default-pathname-defaults*)))
    (cons (merge-pathnames "small.lisp" here)
          (directory (merge-pathnames "models/*.lisp" here)))))

(defun eg (&optional (seed 1))
  "paint one sampled world for every model in *egs*"
  (dolist (m *egs*) (terpri) (painted m seed)))
;---------------------------------------------------------------
;;; zoo: tiny in-file models plus the play/replay verbs.
;;; From a repl:
;;;   (play 'shop)                => how: ((coders . t) ...)
;;;   (replay 'shop (play 'shop)) => paint what that how reaches
;;;   (parade)                    => play the whole zoo
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
  "believe HOW, walk again, paint what gets reached"
  (use name)
  (let ((w (car (sample (query) :beliefs how :n 1))))
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

(defmodel gate :doc "or tries branches, eager order, till one delivers"
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

(defmodel linkbet :doc "or over links: no task inside, first try delivers"
  :hard (spin)
  :rules ((<- spin (or (helps mood) (hurts mood)))))
```

{% endraw %}