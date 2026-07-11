; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for tiny-xai (library: tiny-xai.lisp).
;;;; Prose lives in #| markdown |# blocks; each demo is one
;;;; eg-- function; a postprocessor appends each demo's real
;;;; output. Run any demo by flag:
;;;;   sbcl --script tiny-xai-eg.lisp --all --study --tree
;;;; Under ASDF, load system "tiny-xai/eg" instead; the guard
;;;; below skips the load; the eval-when never fires.

(unless (find-package :tiny-xai)
  (load (merge-pathnames "tiny-xai.lisp" *load-truename*)))

(in-package :tiny-xai)

#|
# tiny-xai: from zero to someplace cool

Here is the problem. Tables of data are cheap to collect
but *labels* are dear: running a benchmark, compiling a
config, polling a focus group. So the real question is not
"how good is the model?" but "how few labels buy a good
answer?"

This file walks tiny-xai from its atoms (summarizing one
column) to a working active learner that finds near-best
rows after labelling only a few dozen, then *explains* its
choices with a small tree. Every demo below runs; every
output is machine-generated, never hand-copied.
|#

#|
## Settings

Every tool needs knobs. All of tiny-xai's live in one
`settings` struct whose slot names double as CLI flags,
so `--budget 20` just overwrites a slot. One struct, one
help string, no config files.
|#

(defun eg--my ()
  "Print the settings"
  (format t "~&~s~%" *my*)
  (assert (settings-p *my*)))

#|
## Reading strings

CSV cells arrive as strings. `thing` coerces each to a
number, `?` (missing), `t`, `nil`, or a trimmed string --
guessing types so column code never has to.
|#

(defun eg--thing ()
  "String coercion round-trip"
  (let ((got (mapcar #'thing '(" 23 " "3.14" "-1e2"
                               "?" "True" "False" "abc"))))
    (print got)
    (assert (equal got '(23 3.14 -100.0 ? t nil "abc")))))

#|
## Reproducible randomness

Common Lisp's `random` differs across implementations, so
same-seed runs would diverge between sbcl and clisp. A
16807 Lehmer generator (`rand`, `rint`) makes every trace
in this tutorial reproducible everywhere.
|#

(defun eg--rand (&aux a b)
  "Seeded rand is deterministic and in (0,1)"
  (setf *seed* 1 a (rand)
        *seed* 1 b (rand))
  (format t "~&rand ~,3f rint ~a~%" a (rint 10))
  (assert (= a b))
  (assert (< 0 a 1)))

#|
## Columns: the atoms

What are we processing here? In any table of data there
are columns of `num`bers and columns of `sym`bols. Numbers
are things we can add, subtract, average; symbols we can
only count and compare. So tiny-xai has exactly two column
summaries: `num` (incremental mean and standard deviation,
via Welford) and `sym` (counts, mode, entropy). Everything
else in the system is built by folding rows into these.

The `num` demo is a sneaky double-check: summing three
uniform randoms (Irwin-Hall) approximates a normal, so
after 10,000 samples `mid` must be near 0 and `spread`
near 1 -- testing `rand`, `add`, and Welford in one go.
|#

(defun eg--num (&aux (i (make-num)))
  "Irwin-Hall: 10k samples -> mean 0, sd 1"
  (dotimes (k 10000)
    (add i (/ (- (+ (rand) (rand) (rand)) 1.5) 0.5)))
  (format t "~&num mu ~,3f sd ~,3f~%" (mid i) (spread i))
  (assert (< (abs (mid i)) 0.05))
  (assert (< (abs (- (spread i) 1)) 0.05)))

(defun eg--sym (&aux (i (make-sym)))
  "Sym mode and entropy on a known distribution"
  (dolist (v '(a a a a b b c)) (add i v))
  (format t "~&sym mid ~a ent ~,3f~%" (mid i) (spread i))
  (assert (eq (mid i) 'a))
  (assert (< (abs (- (spread i) 1.379)) 0.01)))

#|
## Tables

Column roles hide in the CSV header: leading uppercase
means numeric; a trailing `+` or `-` marks a goal to
maximize or minimize; trailing `X` means ignore. So
`make-data` needs no schema file: the first row builds
`cols`, later rows update every column summary as they
stream past. The demo data is auto93: 398 cars, 4 inputs,
3 goals (minimize `Lbs-`, maximize `Acc+` and `Mpg+`).
|#

(defun eg--csv (&aux (n 0))
  "Csv reader: row shapes and count"
  (mapcsv (lambda (row)
            (when (< (incf n) 4) (print row))
            (when (search "auto93" (? *my* --file))
              (assert (= (length row) 8))))
          (? *my* --file))
  (format t "~&rows ~a~%" n)
  (when (search "auto93" (? *my* --file))
    (assert (= n 399))))

(defun eg--data (&aux (i (make-data (? *my* --file))))
  "Data build: col roles and goal stats"
  (format t "~&rows ~a |x| ~a |y| ~a~%"
          (length (? i rows))
          (length (? i cols x))
          (length (? i cols y)))
  (dolist (col (? i cols y))
    (format t "~a mid ~,2f div ~,2f~%"
            (? col txt) (mid col) (spread col)))
  (when (search "auto93" (? *my* --file))
    (assert (= (length (? i rows)) 398))
    (assert (= (length (? i cols all)) 8))
    (assert (= (length (? i cols x)) 4))
    (assert (= (length (? i cols y)) 3))
    (let ((mpg (elt (? i cols y) 2)))
      (assert (< (abs (- (mid mpg) 23.84)) 0.1))
      (assert (< (abs (- (spread mpg) 8.34)) 0.1)))))

#|
## Distance

Two distances, two jobs. `disty` reads only the goal
columns: each row's distance to "heaven" (all goals at
their best), 0 = ideal. `distx` reads only the inputs:
how far apart two rows are before we know their goals.
Optimization *scores* with y but *navigates* with x --
that split is what lets us label so few rows.
|#

(defun eg--dists (&aux (i (make-data (? *my* --file))))
  "Disty in [0,1]; distx zero-self, symmetric, bounded"
  (let* ((rows (? i rows))
         (ys   (sort (mapcar (lambda (r) (disty i r)) rows)
                     #'<))
         (r1   (first rows))
         (r2   (second rows)))
    (format t "~&disty lo ~,3f hi ~,3f~%"
            (first ys) (car (last ys)))
    (assert (<= 0 (first ys) (car (last ys)) 1))
    (assert (= 0 (distx i r1 r1)))
    (assert (< (abs (- (distx i r1 r2) (distx i r2 r1)))
               1e-6))
    (assert (<= 0 (distx i r1 r2) 1))))

#|
## Landscape sampling: the active learner

Now the payoff. `landscape` labels a handful of rows,
projects the rest onto a line between two distant labelled
poles (good end, bad end), culls the third nearest the bad
pole, and repeats -- spending at most `budget` labels.
Note the demo's asserts: the labels come back sorted, and
the best of ~45 labels already lands under 0.4 disty.
|#

(defun eg--land (&aux (i (make-data (? *my* --file))))
  "Landscape labels few rows, sorted best first"
  (let* ((lab (landscape i))
         (ys  (mapcar (lambda (r) (disty i r)) lab)))
    (format t "~&labelled ~a best ~,3f worst ~,3f~%"
            (length lab) (first ys) (car (last ys)))
    (assert (<= (length lab)
                (- (? *my* --budget) (? *my* --check))))
    (assert (equal ys (sort (copy-list ys) #'<)))
    (assert (< (first ys) 0.4))))

#|
## Cuts

To explain "what makes a row good" we need splits. `split`
tries one cut per x column and keeps the cheapest, where
cost is the size-weighted spread of the two halves. The
assert: the best single cut always beats the unsplit
spread -- otherwise explanation would be hopeless.
|#

(defun eg--cuts (&aux (i (make-data (? *my* --file))))
  "Best single cut beats the unsplit spread"
  (let* ((rows (? i rows))
         (goal (car (last (? i cols y))))
         (best (split i rows
                      (lambda (r) (elt r (? goal at))))))
    (format t "~&best ~,2f at ~a v ~a (sd ~,2f)~%"
            (first best)
            (? (elt (? i cols all) (second best)) txt)
            (third best) (spread goal))
    (assert (< (first best) (spread goal)))
    (when (search "auto93" (? *my* --file))
      (assert (eql (third best) 183)))))

#|
## Trees

Recurse the cuts and a tree falls out: each branch is a
readable condition (`Volume <= 183`), each leaf holds the
rows that satisfy the path to it. `leaf` walks a new row
down to a prediction; `about` reports a happy fact -- the
tree usually needs only a few of the x columns.
|#

(defun eg--tree (&aux (i (make-data (? *my* --file))))
  "Tree build: show, partition, walk"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (let* ((rows (? i rows))
         (goal (car (last (? i cols y))))
         (tr   (tree i rows
                     (lambda (r) (elt r (? goal at))))))
    (show i tr)
    (about i tr)
    (let ((lvs (leaves tr)))
      (assert (? tr at))
      (assert (> (length lvs) 3))
      (assert (= (length rows)
                 (loop for l in lvs sum (? l n))))
      (assert (<= 1 (length (used tr))
                  (length (? i cols x))))
      (assert (numberp (leaf i tr (first rows)))))))

#|
## Grading

How good is a picked row? `wins` calibrates per dataset:
100 = the pick equals the best row, 0 = no better than the
median, negative = worse than median. All later studies
report on this scale so results compare across datasets.
|#

(defun eg--wins (&aux (i (make-data (? *my* --file))))
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
## When are two results "the same"?

Comparing methods needs a conservative equality: `same` is
true only if a cohen check (small mean gap), cliff's delta
(small effect), AND kolmogorov-smirnov (close CDFs) all
agree. The demo: a distribution equals itself, survives a
tiny nudge, and differs after a real shift.
|#

(defun eg--same (&aux xs)
  "Same: true for a nudge, false for a shift"
  (dotimes (k 20) (push (rand) xs))
  (let ((ys (mapcar (lambda (x) (+ x 0.02)) xs))
        (zs (mapcar (lambda (x) (+ x 1)) xs)))
    (format t "~&same: self ~a nudged ~a shifted ~a~%"
            (same xs xs) (same xs ys) (same xs zs))
    (assert (same xs xs))
    (assert (same xs ys))
    (assert (not (same xs zs)))))

#|
## Someplace cool: the whole rig

`holdout` puts it all together. Split the data 50:50;
run `landscape` on the train half under the label budget;
grow a tree from those few labels; use the tree to rank
the *unseen* test half; label only the top `check` rows
and return the best. A good win here means a few dozen
labels found a near-best row among rows never labelled
during training. That is the whole point of the toolkit,
in one function you can now read.
|#

(defun eg--holdout (&aux (i (make-data (? *my* --file))))
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
beat random labelling (rq2). `deltas` prints 0 when
`same` says two treatments tie, else the mean gap.
|#

(defun study--holdouts (&aux (i (make-data (? *my* --file)))
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

(defun study--delta (&aux (i (make-data (? *my* --file))))
  "Rq2: active vs random labelling, budget 50"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--landscape "active" "random"))

(defun study--budgets (&aux (i (make-data (? *my* --file))))
  "Rq1: budget 50 vs 20, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 50 20))

(defun study--saturate (&aux (i (make-data (? *my* --file))))
  "Rq1 caveat: budget 200 vs 50 (sampler stops near 40)"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 200 50))

#|
## Runners

`eg--all` and `eg--study` find their functions by name
(see `egs` in the library), reseeding before each so any
demo can be reproduced in isolation.
|#

(defun run-egs (lst)
  "Run each test, reseeding before each"
  (dolist (s lst)
    (format t "~&~%; ~(~a~)~%" s)
    (setf *seed* (? *my* --seed))
    (funcall s)))

(defun eg--all ()
  "Run every unit test"
  (run-egs (egs "EG--")))

(defun eg--study ()
  "Run every study"
  (run-egs (egs "STUDY--")))

(eval-when (:execute)
  (if (member "-h" (args) :test #'equal)
      (help)
      (cli *my*)))
