; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for main.lisp: grading, the whole
;;;; rig, and the Rq0-Rq2 studies.

#|
## Grading

How good is a picked row? `wins` calibrates per table:
100 = the pick equals the best row, 0 = no better than the
median, negative = worse than median. All studies report on
this scale, so results compare across datasets. Notice the
worst row grades far below zero: picking badly is worse
than not picking at all.

| call | returns | what |
|------|---------|------|
| `(wins tbl)` | function | grader: row -> [-100,100] |
|#

(defun eg--wins (&aux (i (make-tbl (? *my* --file))))
  "Wins grader: best row = 100, all in [-100,100]"
  (let* ((w    (wins i))
         (rows (? i rows))
         (best (argmin (lambda (r) (disty i r)) rows)))
    (format t "~&win(best)= ~a win(worst)= ~a~%"
            (round (funcall w best))
            (round (funcall w (argmax
                                (lambda (r) (disty i r))
                                rows))))
    (assert (= 100 (round (funcall w best))))
    (dolist (r (few rows 30))
      (assert (<= -100 (funcall w r) 100)))))


#|
## Someplace cool: the whole rig

Split the table 50:50. Landscape-label the train half under
the budget; grow a tree from those few labels; let the tree
rank the *unseen* test half; label only the top --check
rows and keep the best. Notice the win: a few dozen labels
found a near-best car among cars never seen in training.
That is the whole toolkit, in one function you can now
read.

| call | returns | what |
|------|---------|------|
| `(holdout tbl)` | row | best check from unseen half |
|#

(defun eg--holdout (&aux (i (make-tbl (? *my* --file))))
  "One holdout run: pick a good test row"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (let* ((got (holdout i))
         (w   (round (funcall (wins i) got))))
    (format t "~&picked ~s~%win= ~a disty= ~,3f~%"
            got w (disty i got))
    (assert (vectorp got))
    (assert (<= -100 w 100))
    (when (search "auto93" (? *my* --file))
      (assert (> w 0)))))


#|
## Studies

Demos convince; studies measure. Each study-- function
repeats the holdout rig 20 times and reports on the wins
scale, answering the research questions: how good is the
rig (rq0), does more budget help (rq1), and does active
beat random labelling (rq2). `deltas` prints 0 when `same`
says two treatments tie, else the mean gap.

| call | returns | what |
|------|---------|------|
| `(deltas tbl knob v1 v2)` | -- | print 0 (tie) or gap |
|#

(defun study--holdouts (&aux (i (make-tbl (? *my* --file)))
                          w (n (make-num)))
  "Rq0: mean win over 20 holdouts"
  (setf (? i rows) (few (? i rows) (? *my* --cap))
        w (wins i))
  (dotimes (k 20)
    (add n (funcall w (holdout i))))
  (format t "~&mu ~5,1f sd ~5,1f ~a~%"
          (mid n) (spread n) (? *my* --file))
  (assert (<= -100 (mid n) 100))
  (when (search "auto93" (? *my* --file))
    (assert (> (mid n) 50))))

(defun deltas (i knob v1 v2
               &aux (w (wins i)) (v0 (ats *my* knob)))
  "20 paired holdouts per knob value; 0 if same, else gap"
  (labels ((runs (v &aux out)
             (setf (ats *my* knob) v)
             (dotimes (k 20 out)
               (setf *seed* (+ (? *my* --seed) k))
               (push (funcall w (holdout i)) out))))
    (let* ((a (runs v1))
           (b (runs v2))
           (d (if (same a b)
                  0
                  (- (mid (adds a)) (mid (adds b))))))
      (setf (ats *my* knob) v0)
      (format t "~&~6,1f ~a~%" d (? *my* --file)))))

(defun study--delta (&aux (i (make-tbl (? *my* --file))))
  "Rq2: active vs random labelling, budget 50"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--acquire "active" "random"))

(defun study--budgets (&aux (i (make-tbl (? *my* --file))))
  "Rq1: budget 50 vs 20, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 50 20))

(defun study--saturate (&aux (i (make-tbl (? *my* --file))))
  "Rq1: budget 200 vs 50, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 200 50))
