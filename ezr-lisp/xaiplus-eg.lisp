; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for xaiplus (library:
;;;; xaiplus.lisp). Prose lives in #| markdown |# blocks;
;;;; each demo is one eg-- function. Run any demo by flag:
;;;;   sbcl --script xaiplus-eg.lisp --all --race
;;;; Under ASDF, load system "xai/plus-eg" instead.

(unless (find-package :xai)
  (load (merge-pathnames "xaiplus.lisp" *load-truename*)))

(in-package :xai)


#|
# xaiplus: standing on xai's shoulders

xai (the engine) knows columns, distance, labels and
trees. This layer spends that vocabulary: classifiers
(knn, naive bayes), clusterers (kmeans, kmeans++),
optimizers (DE, GA, SA, local search), and the odd jobs
around them (racing, synthesis, anomaly detection). Every
app is a plain function over a xai tbl; none is more than
a screenful.

Two tables run through the demos: breast.w (699 biopsies,
a "!" klass column) for the classifiers, and auto93 (398
cars, three goals) for the optimizers.

## How to run this course

(Easier read: this file, rendered --
[xaiplus-eg.html](https://timm.github.io/src/ezr-lisp/docs/xaiplus-eg.html);
its library
[xaiplus.html](https://timm.github.io/src/ezr-lisp/docs/xaiplus.html);
the engine course
[xai-eg.html](https://timm.github.io/src/ezr-lisp/docs/xai-eg.html);
the shared dictionary
[glossary](https://timm.github.io/src/glossary.html).)

Install and fetch as per xai-eg.lisp, then:

    sbcl --script xaiplus-eg.lisp --all   # seconds

Four levels of read, per lesson: (skim) beside
[xaiplus-eg.out](xaiplus-eg.out); (run) one demo, e.g.
`--race`, change a knob, rerun; (dive) retype a demo at
the REPL (`sbcl --load xaiplus.lisp`); (deep dive) port a
lesson and reproduce its slice of xaiplus-eg.out.

## Contents

| lesson | section | core ideas |
|--------|---------|------------|
|  1 | Knn      | [knn](../glossary.md#knn) [mode](../glossary.md#mode) |
|  2 | Kmeans   | [kmeans](../glossary.md#kmeans) [centroid](../glossary.md#centroid) |
|  3 | Kmeanspp | [kmeanspp](../glossary.md#kmeanspp) [centroid](../glossary.md#centroid) |
|  4 | Bayes    | [bayes](../glossary.md#bayes) [gauss](../glossary.md#gauss) |
|  5 | Classify | [bayes](../glossary.md#bayes) [confusion](../glossary.md#confusion) [mode](../glossary.md#mode) |
|  6 | Mutate   | [mutate](../glossary.md#mutate) [gauss](../glossary.md#gauss) |
|  7 | De       | [de](../glossary.md#de) [mutate](../glossary.md#mutate) |
|  8 | Ga       | [ga](../glossary.md#ga) [mutate](../glossary.md#mutate) |
|  9 | Sa       | [sa](../glossary.md#sa) [mutate](../glossary.md#mutate) |
| 10 | Ls       | [ls](../glossary.md#ls) |
| 11 | Race     | [race](../glossary.md#race) [bets](../glossary.md#bets) |
| 12 | Sample   | [synthesis](../glossary.md#synthesis) [tree](../glossary.md#tree) |
| 13 | Acquire  | [active](../glossary.md#active) [budget](../glossary.md#budget) [bayes](../glossary.md#bayes) |
| 14 | Anomaly  | [anomaly](../glossary.md#anomaly) |
|#

(defvar +data+ "$MOOT/classify/breast.w.csv")
(defvar +dopt+ "$MOOT/optimize/misc/auto93.csv")

(defun med (tbl &aux ys)
  "Median disty of a tbl's rows"
  (setf ys (sort (mapcar (lambda (r) (disty tbl r))
                         (? tbl rows))
                 #'<))
  (elt ys (floor (length ys) 2)))

(defun nny (tbl r)
  "Disty of r's nearest real row (the surrogate score)"
  (disty tbl (nearest tbl r)))



;;; ## Knn egs

#|
## Lesson 1: k nearest neighbors

No fit step: to classify a row, find its --knn nearest
labelled rows (distx, from xai) and vote. Train on 490
random biopsies, test on the rest. Notice the accuracy --
strong, from a classifier with no model at all.

**Core ideas:** [knn](../glossary.md#knn),
[mode](../glossary.md#mode)

| call | returns | what |
|------|---------|------|
| `(knn tbl r0)` | klass | mode of the k nearest klasses |
| `(near tbl r0 k)` | rows | the k rows nearest r0 |
| `(nearest tbl r0)` | row | one nearest row, no sort |
|#

(defun eg--knn (&aux (d (make-tbl +data+))
                     rows tr te at (ok 0))
  "3-NN accuracy on a 70:30 split of breast.w"
  (setf rows (shuffle (? d rows))
        tr   (clone d (subseq rows 0 490))
        te   (nthcdr 490 rows)
        at   (? (? d cols klass) at))
  (dolist (r te)
    (when (equal (knn tr r) (elt r at)) (incf ok)))
  (format t "~&3-NN accuracy on breast.w: ~,3f~%"
          (/ ok (length te)))
  (assert (> (/ ok (length te)) 0.9))
  (assert (knn tr (first (? tr rows)))))

#|
**Exercises (lesson 1).**

0. In your own favorite language (not lisp), write knn
   and reproduce the accuracy line.
1. (simple) Rerun with `--knn 1`, then 7, then 15. Where
   does accuracy peak, and why not at 1?
2. knn is O(N) per query. Speed it: only compare against
   `(few rows 100)`. How much accuracy buys how much time?
|#



;;; ## Kmeans egs

#|
## Lesson 2: kmeans

Unsupervised now: no klass, just geometry. Drop each row
into its nearest centroid, move each centroid to its
cluster's middle (`mids`), repeat --iter times. Notice
every row lands in exactly one cluster.

**Core ideas:** [kmeans](../glossary.md#kmeans),
[centroid](../glossary.md#centroid)

| call | returns | what |
|------|---------|------|
| `(kmeans tbl k iter)` | clones | k clusters of the rows |
| `(mids tbl)` | row | the centroid: mid of every column |
|#

(defun eg--kmeans (&aux (d (make-tbl +data+))
                        cl ns (tot 0))
  "5 kmeans clusters; every row placed exactly once"
  (setf cl (kmeans d 5))
  (dolist (c cl)
    (incf tot (length (? c rows)))
    (push (length (? c rows)) ns))
  (format t "~&5 clusters, sizes: ~a~%" (sort ns #'<))
  (assert (<= 1 (length cl) 5))
  (assert (= tot (length (? d rows)))))

#|
**Exercises (lesson 2).**

0. Port assign/recentre; reproduce the sizes line.
1. (simple) Rerun with `--iter 1` then 20. Do the sizes
   settle? How would you detect convergence?
2. Score a clustering: mean distx of each row to its
   centroid. Compare k=2,5,10. Why does more k always
   score better -- and why is that a trap?
|#



;;; ## Kmeanspp egs

#|
## Lesson 3: kmeans++ seeding

Random seeds can land in one clump. The ++ trick: pick
each new seed with chance proportional to its SQUARED
distance from the seeds so far -- far rows likely, clumps
unlikely. Notice the mean pairwise gap between seeds.

**Core ideas:** [kmeanspp](../glossary.md#kmeanspp),
[centroid](../glossary.md#centroid)

| call | returns | what |
|------|---------|------|
| `(kpp tbl k)` | rows | k seed rows, spread far apart |
|#

(defun eg--kpp (&aux (d (make-tbl +data+))
                     cs (spread 0) (gap 0))
  "5 kmeans++ seeds; distinct, spread apart"
  (setf cs (kpp d 5))
  (loop for (a . more) on cs do
    (dolist (b more)
      (incf gap)
      (incf spread (distx d a b))))
  (format t "~&5 kmeans++ seeds, mean pair distance: ~,3f~%"
          (/ spread gap))
  (assert (= (length cs) 5))
  (assert (> (/ spread gap) 0)))

#|
**Exercises (lesson 3).**

0. Port the d^2-weighted pick; reproduce the mean pair
   distance line.
1. (simple) Replace kpp seeds with `(few rows 5)` and
   recompute the mean pair distance. Which is bigger?
2. Feed kpp's seeds to kmeans as its start centroids. Does
   seeding change where kmeans converges?
|#



;;; ## Bayes egs

#|
## Lesson 4: likelihoods

`like` asks: how likely is value v under this column's
summary? Sym columns use an m-estimate over their counts;
num columns a gaussian pdf. Notice the value at the mean
beats one three sds out.

**Core ideas:** [bayes](../glossary.md#bayes),
[gauss](../glossary.md#gauss)

| call | returns | what |
|------|---------|------|
| `(like col v prior)` | float | P(v given col) |
| `(likes h row n nh)` | float | log-likelihood of a row |
|#

(defun eg--like (&aux (d (make-tbl +data+)) c v1 v2)
  "Gaussian likelihood: the mean beats 3 sds out"
  (setf c  (first (? d cols x))
        v1 (like c (? c mu) 0.5)
        v2 (like c (+ (? c mu) (* 3 (spread c))) 0.5))
  (format t "~&like at mean vs 3sd out: ~,3f ~,3f~%" v1 v2)
  (assert (> v1 v2))
  (assert (> v1 0)))

#|
**Exercises (lesson 4).**

0. Port like; reproduce the mean-vs-3sd line.
1. (simple) Predict: like at mu+1sd -- between the two
   printed numbers, or outside? Check.
2. Plot (print a star histogram of) like across mu-4sd ..
   mu+4sd in half-sd steps. What curve appears?
|#



;;; ## Classify egs

#|
## Lesson 5: incremental naive bayes

Test-then-train: for each row, guess its klass from the
models seen SO FAR, record (got want), then train the true
klass's model. One pass, no split, and the learner is
scored on rows it had not yet seen. Notice the accuracy on
this easy data.

**Core ideas:** [bayes](../glossary.md#bayes),
[confusion](../glossary.md#confusion),
[mode](../glossary.md#mode)

| call | returns | what |
|------|---------|------|
| `(classify tbl)` | pairs | (got want) per scored row |
| `(acc seen)` | 0..1 | fraction where got = want |
|#

(defun eg--classify (&aux (d (make-tbl +data+)) seen)
  "Test-then-train naive bayes on breast.w"
  (setf seen (classify d))
  (format t "~&naive Bayes accuracy on breast.w: ~,3f~%"
          (acc seen))
  (assert (> (acc seen) 0.9))
  (assert (> (length seen) 600)))

#|
**Exercises (lesson 5).**

0. Port classify; reproduce the accuracy line.
1. (simple) Rerun with `--wait 100`. Accuracy up or down?
   Why does waiting help the early guesses?
2. Build the confusion matrix from the (got want) pairs.
   Which klass is mistaken for which -- and is the
   mistake symmetric?
|#



;;; ## Mutate egs

#|
## Lesson 6: mutators

The optimizers below need to bend rows. `picks` copies a
row and resamples n of its x cells (sym by frequency, num
a gaussian nudge clamped to mu +-3sd); `extrapolate` is
DE's a + F*(b - c) blend, one column always kept from a.
Notice: at most n cells change, and at least one survives.

**Core ideas:** [mutate](../glossary.md#mutate),
[gauss](../glossary.md#gauss)

| call | returns | what |
|------|---------|------|
| `(picks tbl row n)` | row | copy with n cells resampled |
| `(extrapolate cols a b c)` | row | DE blend of three rows |
| `(pick col v)` | value | one fresh value for col |
|#

(defun eg--picks (&aux (d (make-tbl +data+))
                       r m (diff 0))
  "picks(n=3) changes at most 3 x cells"
  (setf r (first (? d rows))
        m (picks d r 3))
  (dolist (c (? d cols x))
    (unless (equal (elt m (? c at)) (elt r (? c at)))
      (incf diff)))
  (format t "~&cells changed by picks(n=3): ~a of ~a~%"
          diff (length (? d cols x)))
  (assert (= (length m) (length r)))
  (assert (<= diff 3)))

(defun eg--extrapolate (&aux (d (make-tbl +data+))
                             a b c kid (same 0))
  "extrapolate always keeps >= 1 col from its base"
  (setf a (first  (? d rows))
        b (second (? d rows))
        c (third  (? d rows))
        kid (extrapolate (? d cols x) a b c))
  (dolist (col (? d cols x))
    (when (equal (elt kid (? col at)) (elt a (? col at)))
      (incf same)))
  (format t "~&x cols kept from base a: ~a of ~a~%"
          same (length (? d cols x)))
  (assert (= (length kid) (length a)))
  (assert (>= same 1)))

#|
**Exercises (lesson 6).**

0. Port picks; reproduce the cells-changed line.
1. (simple) Predict: `(picks d r 999)` changes how many
   cells? Check, then explain the cap.
2. extrapolate wraps out-of-range nums back into mu+-4sd
   via mod. Replace wrap with clamp; do DE's results
   (lesson 7) get better or worse?
|#



;;; ## De egs

#|
## Lesson 7: differential evolution

From here on, optimization on auto93: find a row with good
goals, scoring candidates by the surrogate -- disty of the
nearest REAL row (synthetic rows never get their own
labels). DE: each parent fights a kid blended from three
random pop rows; better kid replaces parent. Notice DE
pulls disty from a median near 0.5 down toward 0.

**Core ideas:** [de](../glossary.md#de),
[mutate](../glossary.md#mutate)

| call | returns | what |
|------|---------|------|
| `(de tbl)` | row | best row found, hooked disty |
|#

(defun eg--de (&aux (d (make-tbl +dopt+)) best)
  "DE beats the median row"
  (setf best (de d))
  (format t "~&DE   best (nearest-real disty): ~,3f  ~
             median ~,3f~%" (nny d best) (med d))
  (assert (< (nny d best) (med d))))

#|
**Exercises (lesson 7).**

0. In your own favorite language (not lisp), write DE and
   reproduce the best-vs-median line.
1. (simple) Rerun with `--gens 5` then 50. Where do the
   gains flatten, and how much does `--np` matter?
2. The surrogate snaps kids to real rows. Remove the hook
   (score kids directly by disty): why is that cheating,
   and by how much does it flatter the score?
|#



;;; ## Ga egs

#|
## Lesson 8: genetic algorithm

Each generation: mutate everyone a little, then refill the
population by one-point crossover of tournament winners.
Same budget shape as DE, different search story: GA mixes
whole rows, DE blends arithmetic differences.

**Core ideas:** [ga](../glossary.md#ga),
[mutate](../glossary.md#mutate)

| call | returns | what |
|------|---------|------|
| `(ga tbl)` | row | best row found, hooked disty |
|#

(defun eg--ga (&aux (d (make-tbl +dopt+)) best)
  "GA beats the median row"
  (setf best (ga d))
  (format t "~&GA   best (nearest-real disty): ~,3f  ~
             median ~,3f~%" (nny d best) (med d))
  (assert (< (nny d best) (med d))))

#|
**Exercises (lesson 8).**

0. Port tourney and cross; reproduce the best-vs-median
   line.
1. (simple) Rerun with `--tour 2` then 10. Stronger
   selection: better answers or premature convergence?
2. Add elitism (best row survives unchanged). Does it
   help at --gens 5? At 50?
|#



;;; ## Sa egs

#|
## Lesson 9: simulated annealing

(1+1) search: one current row, one mutated kid at a time.
Better kids always replace; worse kids sometimes do, less
often as the budget cools -- so early exploration gives
way to late exploitation.

**Core ideas:** [sa](../glossary.md#sa),
[mutate](../glossary.md#mutate)

| call | returns | what |
|------|---------|------|
| `(sa tbl)` | row | best row seen, hooked disty |
|#

(defun eg--sa (&aux (d (make-tbl +dopt+)) best)
  "SA beats the median row"
  (setf best (sa d))
  (format t "~&SA   best (nearest-real disty): ~,3f  ~
             median ~,3f~%" (nny d best) (med d))
  (assert (< (nny d best) (med d))))

#|
**Exercises (lesson 9).**

0. Port sa; reproduce the best-vs-median line.
1. (simple) Print the accept-worse rate per 100 steps.
   Does it fall as the budget spends?
2. Remove the metropolis clause (keep only strict
   improvers). When does that hurt: smooth landscapes or
   rough ones?
|#



;;; ## Ls egs

#|
## Lesson 10: local search with restarts

Greedy (1+1): keep only strict improvements. The one
addition: after --restart steps without a new best, jump
to a fresh random row. Restarts are the poor searcher's
answer to local optima -- and often embarrassingly hard
to beat.

**Core ideas:** [ls](../glossary.md#ls)

| call | returns | what |
|------|---------|------|
| `(ls tbl)` | row | best row found, hooked disty |
|#

(defun eg--ls (&aux (d (make-tbl +dopt+)) best)
  "LS beats the median row"
  (setf best (ls d))
  (format t "~&LS   best (nearest-real disty): ~,3f  ~
             median ~,3f~%" (nny d best) (med d))
  (assert (< (nny d best) (med d))))

#|
**Exercises (lesson 10).**

0. Port ls; reproduce the best-vs-median line.
1. (simple) Rerun with `--restart 5` then 200. Too eager
   vs too patient: where is the sweet spot here?
2. Log the best-so-far curve for ls and sa on one run
   each. Which spends its budget better, early and late?
|#



;;; ## Race egs

#|
## Lesson 11: racing the optimizers

Which search wins HERE? Run all four on the same table,
same budget shape, and rank their best rows by the hooked
disty. Notice the answer is a ranking, not a winner: on
another table the order may flip -- which is the point.

**Core ideas:** [race](../glossary.md#race),
[bets](../glossary.md#bets)

| call | returns | what |
|------|---------|------|
| `(race tbl)` | pairs | (name score), best first |
|#

(defun eg--race (&aux (d (make-tbl +dopt+)) rank)
  "All four optimizers, ranked best first"
  (setf rank (race d))
  (format t "~&optimizer race (best first):~%")
  (dolist (o rank)
    (format t "    ~a ~,3f~%" (first o) (second o)))
  (assert (= (length rank) 4))
  (assert (<= (second (first rank))
              (second (car (last rank)))))
  (assert (< (second (first rank)) (med d))))

#|
**Exercises (lesson 11).**

0. Port race; reproduce the ranking (any order that
   satisfies the asserts).
1. (simple) Race again on breast.w (no goals -- what
   breaks, and why does auto93 work?).
2. Race with three different seeds. How stable is the
   ranking? What would it take to claim "X wins" honestly
   (hint: lesson 8 of the xai course)?
|#



;;; ## Sample egs

#|
## Lesson 12: synthesizing rows

New rows without new labels: grow a tree, pick a leaf,
DE-blend three of its rows. Kids land inside real,
coherent regions -- not in the voids between clusters
where no real row lives.

**Core ideas:** [synthesis](../glossary.md#synthesis),
[tree](../glossary.md#tree)

| call | returns | what |
|------|---------|------|
| `(sample tbl n)` | rows | n synthetic, leaf-coherent |
|#

(defun eg--sample (&aux (d (make-tbl +dopt+)) rows)
  "30 synthetic rows, full width"
  (setf rows (sample d 30))
  (format t "~&synthesized rows: ~a  width ~a of ~a~%"
          (length rows) (length (first rows))
          (length (? d cols all)))
  (assert (= (length rows) 30))
  (assert (= (length (first rows))
             (length (? d cols all)))))

#|
**Exercises (lesson 12).**

0. Port sample; reproduce the width line.
1. (simple) Feed the 30 kids to the anomaly detector of
   lesson 14. Are synthetic rows lonelier than real ones?
2. Blend across DIFFERENT leaves instead. Score both ways
   with the detector: why do cross-leaf kids score
   stranger?
|#



;;; ## Acquire egs

#|
## Lesson 13: the historic active learner

Kept for comparison with xai's pole-based acquire: warm-
start some labels, split them best/rest by sqrt(N), then
repeatedly label the unlabeled row that best separates
the two models. Two scorers: bayes likelihood or centroid
distance. Notice both find a good row under budget.

**Core ideas:** [active](../glossary.md#active),
[budget](../glossary.md#budget),
[bayes](../glossary.md#bayes)

| call | returns | what |
|------|---------|------|
| `(acquire-top tbl score)` | tbl | the labelled rows |
| `(acquire-bayes tbl b r row)` | float | like(b) - like(r) |
| `(acquire-centroid tbl b r row)` | float | dist gap |
|#

(defun eg--acquire (&aux (d (make-tbl +dopt+)) lab ys)
  "Both scorers find a good row under budget"
  (dolist (score (list #'acquire-bayes
                       #'acquire-centroid))
    (setf *seed* (? *my* --seed)
          lab    (acquire-top d score)
          ys     (sort (mapcar (lambda (r) (disty d r))
                               (? lab rows))
                       #'<))
    (format t "~&acquire best disty: ~,3f  labels ~a~%"
            (first ys) (length (? lab rows)))
    (assert (< (first ys) (med d)))
    (assert (> (length (? lab rows)) (? *my+* --start)))))

#|
**Exercises (lesson 13).**

0. Port acquire-centroid; reproduce its line.
1. (simple) Rerun with `--start 5` then 50. How does the
   warm-start size move the best label found?
2. Compare against xai's own pole-based `acquire` at the
   same budget: which labels fewer rows for the same
   best disty?
|#



;;; ## Anomaly egs

#|
## Lesson 14: anomaly detection

Calibrate on the training rows: a num summarizing each
row's gap to its nearest OTHER row. A new row far from
even its nearest neighbor gets a high normalized score.
Notice most rows score low; a lonely few score high.

**Core ideas:** [anomaly](../glossary.md#anomaly)

| call | returns | what |
|------|---------|------|
| `(anomaly tbl)` | function | detector: row -> 0..1 |
|#

(defun eg--anomaly (&aux (d (make-tbl +dopt+)) det ss)
  "Anomaly scores span 0..1; someone is lonely"
  (setf det (anomaly d)
        ss  (sort (mapcar det (? d rows)) #'<))
  (format t "~&anomaly scores lo/mid/hi: ~,3f ~,3f ~,3f~%"
          (first ss) (elt ss (floor (length ss) 2))
          (car (last ss)))
  (assert (>= (first ss) 0))
  (assert (<= (car (last ss)) 1))
  (assert (> (car (last ss)) 0.5)))

#|
**Exercises (lesson 14).**

0. Port anomaly; reproduce the lo/mid/hi line.
1. (simple) Score a plainly fake row (all mins, or all
   maxes). Does it beat the loneliest real row?
2. knn (lesson 1) misclassifies some biopsies. Are the
   mistakes lonelier than average? (Join lesson 1's
   errors to this lesson's scores.)
|#


#|
## Runners

`eg--all` finds its demos by name (`egs`, from xai),
reseeding before each. Course upkeep as per xai-eg.lisp:
`--transcript` freezes, `--check` diffs, `--join`
verifies doc claims.
|#

(defun eg--all ()
  "Run every unit test"
  (dolist (s (egs "EG--"))
    (format t "~&~%; ~(~a~)~%" s)
    (setf *seed* (? *my* --seed))
    (funcall s)))

(defun eg--transcript ()
  "Freeze --all output to xaiplus-eg.out (a real run)"
  (freeze "xaiplus-eg.lisp" "xaiplus-eg.out"))

(defun eg--check ()
  "A fresh --all must reproduce the frozen transcript"
  (check-transcript "xaiplus-eg.lisp" "xaiplus-eg.out"))

(defun eg--join ()
  "Doc claims, executable: glossary links, table signatures"
  (join-check "xaiplus-eg.lisp"))

(eval-when (:execute)
  (if (member "-h" (args) :test #'equal)
      (help+)
      (progn (cli+) (cli *my*))))
