; vim: set lispwords+=loop,aif :
;;;; An applications layer over xai.lisp (which it never
;;;; edits, bar one hook). Each learner and optimizer --
;;;; knn, kmeans, naive bayes, DE, GA, SA, local search,
;;;; racing, synthesis, anomaly -- is a plain function over
;;;; a xai tbl. Load xai.lisp for the engine; this file for
;;;; the apps. After ezr-lua/xaiplus.lua, the reference.

(unless (find-package :xai)
  (load (merge-pathnames "xai.lisp" *load-truename*)))

(in-package :xai)

(defvar *help+* "
xaiplus: learners and optimizers layered on xai
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

USAGE: sbcl --script xaiplus-eg.lisp [--key val ..] [--run ..]

OPTIONS (added to xai's; never shadowing its flags):")

; Extra knobs; slots are flags, as in xai's settings
(defstruct (settings+ (:conc-name))
  (--knn 3)      ; neighbors for the knn classifier
  (--kluster 8)  ; clusters for kmeans / kmeans++
  (--iter 10)    ; kmeans passes
  (--few 128)    ; sample pool for kmeans++ seeding
  (--k 1)        ; naive-bayes laplace smoothing
  (--m 2)        ; naive-bayes m-estimate prior weight
  (--wait 10)    ; rows seen before naive bayes scores
  (--f 0.5)      ; DE extrapolation factor
  (--cr 0.3)     ; DE crossover rate
  (--np 20)      ; DE/GA population size
  (--gens 20)    ; DE/GA generations
  (--tour 5)     ; GA tournament size
  (--budget1 300); SA/LS eval budget
  (--restart 40) ; LS restart-on-stagnation gap
  (--start 20))  ; acquire warm-start labels

(defvar *my+* (make-settings+))

; adding new flags, never shadowing old ones
(assert (null (intersection (slot-names *my+*)
                            (slot-names *my*))))



;;; ## Lib
;;; The few verbs xai does not already export.

(defun at-min (fun lst &aux (lo +big+) (out 0))
  "Index of lst minimizing (fun x)"
  (loop for x in lst for j from 0 do
    (let ((v (funcall fun x)))
      (when (< v lo) (setf lo v out j))))
  out)

(defun wpick (ws &aux (r (rand (reduce #'+ ws))))
  "Index into ws, chance proportional to its weight"
  (loop for w in ws for j from 0 do
    (decf r w)
    (when (<= r 0) (return-from wpick j)))
  (1- (length ws)))

(defun wpick-key (h &aux ks ws)
  "Weighted pick of a hash key (sorted walk: repeatable)"
  (setf ks (sort (loop for k being the hash-keys of h
                       collect k)
                 #'string< :key (lambda (x) (cat x)))
        ws (mapcar (lambda (k) (gethash k h)) ks))
  (elt ks (wpick ws)))

(defun gauss (&optional (mu 0) (sd 1))
  "Box-Muller bell: mean mu, sd sd (real tails)"
  (+ mu (* sd (sqrt (* -2 (log (rand))))
             (cos (* 2 pi (rand))))))

(defun mids (tbl)
  "Centroid row: the mid of every column"
  (coerce (mapcar #'mid (? tbl cols all)) 'vector))

(defun del (tbl row)
  "Fold a row back out of a tbl (summaries stay honest)"
  (dolist (col (? tbl cols all))
    (let ((v (elt row (? col at))))
      (unless (eq v '?) (add col v -1))))
  (setf (? tbl rows) (remove row (? tbl rows)
                             :count 1 :test #'eq))
  row)



;;; ## Knn
;;; k-nearest-neighbor classifier: a row's klass is the
;;; mode of its k closest rows' klasses (distx from xai).
;;; No fit step -- the data IS the model. Needs a "!"
;;; klass column.

(defun near (tbl r0 &optional (k (? *my+* --knn)))
  "The k rows of tbl nearest r0, by distx"
  (subseq (sort (copy-list (? tbl rows)) #'<
                :key (lambda (r) (distx tbl r0 r)))
          0 (min k (length (? tbl rows)))))

(defun nearest (tbl r0 &optional (rows (? tbl rows)))
  "The one row nearest r0: no sort, one pass"
  (argmin (lambda (r) (distx tbl r0 r)) rows))

(defun knn (tbl r0 &optional k
            &aux (at (? (? tbl cols klass) at)))
  "Predict r0's klass = mode of its k neighbors' klasses"
  (mid (adds (mapcar (lambda (r) (elt r at))
                     (near tbl r0 (or k (? *my+* --knn))))
             (make-sym))))



;;; ## Kmeans
;;; k clusters: drop each row into its nearest centroid,
;;; move the centroids to their members' middle, repeat. A
;;; centroid is just a `mids` row; a cluster is a clone.

(defun assign (tbl cents &aux out)
  "One pass: each row into its nearest centroid's clone"
  (setf out (mapcar (lambda (c) (declare (ignore c))
                      (clone tbl nil))
                    cents))
  (dolist (r (? tbl rows) out)
    (add (elt out (at-min (lambda (c) (distx tbl c r))
                          cents))
         r)))

(defun recentre (clusters &aux cents)
  "Centroids = the middle of each non-empty cluster"
  (dolist (c clusters (nreverse cents))
    (when (? c rows) (push (mids c) cents))))

(defun kmeans (tbl &optional k iter &aux cents)
  "K clusters: iter rounds of assign then recentre"
  (setf cents (few (? tbl rows)
                   (or k (? *my+* --kluster))))
  (dotimes (j (or iter (? *my+* --iter))
              (assign tbl cents))
    (setf cents (recentre (assign tbl cents)))))



;;; ## Kmeanspp
;;; kmeans++ seeding: centroids far apart. Each new
;;; centroid is drawn from a small random pool, with chance
;;; proportional to its squared distance to the nearest
;;; centroid so far (the d^2 trick). Returns seed rows.

(defun d2 (tbl cents r &aux (lo +big+))
  "Squared distance from r to its nearest centroid"
  (dolist (c cents lo)
    (let ((d (distx tbl r c)))
      (setf lo (min lo (* d d))))))

(defun farther (tbl cents &optional few2 &aux pool ws)
  "One more centroid: d^2-weighted pick from a random pool"
  (setf pool (few (? tbl rows)
                  (min (or few2 (? *my+* --few))
                       (length (? tbl rows))))
        ws   (mapcar (lambda (r) (d2 tbl cents r)) pool))
  (elt pool (wpick ws)))

(defun kpp (tbl &optional k few2 &aux cents)
  "K centroids by kmeans++ seeding"
  (setf cents (few (? tbl rows) 1))
  (loop while (< (length cents) (or k (? *my+* --kluster)))
        do (setf cents
                 (nconc cents
                        (list (farther tbl cents few2)))))
  cents)



;;; ## Bayes
;;; naive Bayes likelihoods. `like` = P(v | col): a sym
;;; m-estimate, or a num gaussian pdf. `likes` = the
;;; log-sum likelihood of a whole row under one klass's
;;; model (a xai tbl holding just that klass's rows).

(defun like (col v prior)
  "P(v|col): sym m-estimate, else num gaussian pdf"
  (if (sym-p col)
      (/ (+ (ats (? col has) v 0) (* (? *my+* --k) prior))
         (+ (? col n) (? *my+* --k)))
      (let ((z (* 2 (expt (+ (spread col) +tiny+) 2))))
        (/ (exp (- (/ (expt (- v (? col mu)) 2) z)))
           (sqrt (* pi z))))))

(defun likes (h row nrows nh &aux prior (out 0))
  "Log-likelihood of a row under klass model h (a tbl)"
  (setf prior (/ (+ (length (? h rows)) (? *my+* --m))
                 (+ nrows (* (? *my+* --m) nh)))
        out   (log prior))
  (dolist (col (? h cols x) out)
    (let ((v (elt row (? col at))))
      (unless (eq v '?)
        (let ((l (like col v prior)))
          (when (> l 0) (incf out (log l))))))))

(defun mostlikes (h row nrows nh &aux (bs (- +big+)) best)
  "Klass in h (hash klass -> tbl) most liking the row"
  (dolist (k (sort (loop for k being the hash-keys of h
                         collect k)
                   #'string< :key (lambda (x) (cat x)))
             best)
    (let ((s (likes (gethash k h) row nrows nh)))
      (when (> s bs) (setf bs s best k)))))



;;; ## Classify
;;; Incremental naive Bayes, test-then-train: for each row,
;;; predict its klass from the models seen so far, push the
;;; (got want) pair, then train the true klass's model. One
;;; pass, no held-out split.

(defun acc (seen &aux (n 0))
  "Fraction of seen (got want) pairs that agree"
  (dolist (p seen (/ n (+ (length seen) +tiny+)))
    (when (equal (first p) (second p)) (incf n))))

(defun classify (tbl &optional wait
                 &aux (at (? (? tbl cols klass) at))
                      (h (o)) (nh 0) (i 0) seen)
  "Test-then-train naive Bayes; returns the (got want)s"
  (setf wait (or wait (? *my+* --wait)))
  (dolist (row (reverse (? tbl rows)) (nreverse seen))
    (let ((want (elt row at)))
      (when (and (>= (incf i) wait) (> nh 0))
        (push (list (mostlikes h row
                               (length (? tbl rows)) nh)
                    want)
              seen))
      (unless (gethash want h)
        (setf (gethash want h) (clone tbl nil))
        (incf nh))
      (add (gethash want h) row))))



;;; ## Mutate
;;; Mutators for the optimizers. `pick` samples one fresh
;;; value for a column (sym by frequency, num a gaussian
;;; nudge clamped to mu +-3sd); `picks` mutates n random x
;;; cells; `extrapolate` is DE's a + F*(b - c), with one
;;; column always kept from a.

(defun lohi (col k &aux (s (spread col)))
  "lo,hi = mu -+ k spreads of a num column"
  (values (- (? col mu) (* k s)) (+ (? col mu) (* k s))))

(defun pick (col v)
  "Fresh value for col: sym by frequency, num by nudge"
  (if (sym-p col)
      (wpick-key (? col has))
      (multiple-value-bind (lo hi) (lohi col 3)
        (let ((v (if (eq v '?) (? col mu) v)))
          (max lo (min hi (+ v (* (spread col)
                                  (gauss 0 1)))))))))

(defun picks (tbl row &optional (n 1)
              &aux (out (copy-seq row))
                   (xs (shuffle (? tbl cols x))))
  "Copy row; mutate n of its x columns via pick"
  (dotimes (j (min n (length xs)) out)
    (let ((c (elt xs j)))
      (setf (elt out (? c at))
            (pick c (elt out (? c at)))))))

(defun extrapolate (cols a b c &optional f cr
                    &aux (out (copy-seq a)) keep)
  "DE blend a + F*(b - c) per x col; one col kept from a"
  (setf f    (or f (? *my+* --f))
        cr   (or cr (? *my+* --cr))
        keep (elt cols (rint (length cols))))
  (dolist (col cols out)
    (when (and (not (eq col keep)) (< (rand) cr))
      (let ((va (elt a (? col at)))
            (vb (elt b (? col at)))
            (vc (elt c (? col at))))
        (setf (elt out (? col at))
          (cond ((eq va '?) '?)
                ((sym-p col) (if (< (rand) f) vb va))
                ((or (eq vb '?) (eq vc '?)) va)
                (t (multiple-value-bind (lo hi)
                       (lohi col 4)
                     (let ((v    (+ va (* f (- vb vc))))
                           (span (+ (- hi lo) +tiny+)))
                       (+ lo (mod (- v lo) span)))))))))))



;;; ## Optimize
;;; Shared gear. `with-surrogate` binds xai's *label* hook
;;; so disty can score any row -- even a synthetic one --
;;; by snapping it to its nearest real row (a cheap
;;; surrogate for the true, expensive objective; identity
;;; on real rows). Every optimizer MINIMIZES the hooked
;;; disty and returns its best row.

(defmacro with-surrogate ((tbl) &body body)
  "Bind *label* to nearest-real-row for the body's extent"
  `(let ((*label* (lambda (r) (nearest ,tbl r))))
     ,@body))



;;; ## De
;;; Differential evolution. Each generation every parent
;;; spawns a DE kid (blend three random pop rows via
;;; extrapolate) that replaces the parent when the hooked
;;; disty scores the kid better.

(defun de (tbl &aux pop)
  "Differential evolution; returns the best row found"
  (with-surrogate (tbl)
    (labels ((y (r) (disty tbl r)))
      (setf pop (coerce (few (? tbl rows) (? *my+* --np))
                        'vector))
      (dotimes (g (? *my+* --gens))
        (dotimes (i (length pop))
          (let* ((trio (few (coerce pop 'list) 3))
                 (kid (extrapolate (? tbl cols x)
                                   (first trio)
                                   (second trio)
                                   (third trio))))
            (when (< (y kid) (y (elt pop i)))
              (setf (elt pop i) kid)))))
      (argmin #'y (coerce pop 'list)))))



;;; ## Ga
;;; Genetic algorithm. Each generation: mutate the whole
;;; pop (one cell each), then refill by one-point crossover
;;; of two tournament-picked parents.

(defun tourney (pop y &aux (x (elt pop (rint (length pop)))))
  "Lowest-scoring row among --tour random pop rows"
  (dotimes (j (1- (? *my+* --tour)) x)
    (let ((z (elt pop (rint (length pop)))))
      (when (< (funcall y z) (funcall y x)) (setf x z)))))

(defun cross (tbl mum dad
              &aux (kid (copy-seq mum))
                   (cut (rint (length (? tbl cols x)))))
  "One-point crossover of two rows over the x columns"
  (loop for c in (? tbl cols x) for j from 0 do
    (when (> j cut) (setf (elt kid (? c at))
                          (elt dad (? c at)))))
  kid)

(defun ga (tbl &aux pop kids)
  "Genetic algorithm; returns the best row found"
  (with-surrogate (tbl)
    (labels ((y (r) (disty tbl r)))
      (setf pop (few (? tbl rows) (? *my+* --np)))
      (dotimes (g (? *my+* --gens))
        (setf pop (mapcar (lambda (r) (picks tbl r 1)) pop)
              kids nil)
        (dotimes (j (? *my+* --np))
          (push (cross tbl (tourney pop #'y)
                           (tourney pop #'y))
                kids))
        (setf pop kids))
      (argmin #'y pop))))



;;; ## Sa
;;; Simulated annealing, (1+1). From one row, repeatedly
;;; mutate one cell; always keep a better kid, sometimes a
;;; worse one (metropolis, cooling as the budget spends).

(defun sa (tbl &aux s es best eb)
  "Simulated annealing; returns the best row seen"
  (with-surrogate (tbl)
    (labels ((y (r) (disty tbl r)))
      (setf s  (elt (? tbl rows)
                    (rint (length (? tbl rows))))
            es (y s) best s eb es)
      (loop for h from 1 to (? *my+* --budget1) do
        (let* ((kid (picks tbl s 1))
               (e   (y kid)))
          (when (or (< e es)
                    (< (rand)
                       (exp (/ (- es e)
                               (+ (- 1 (/ h (? *my+*
                                             --budget1)))
                                  +tiny+)))))
            (setf s kid es e))
          (when (< e eb) (setf best kid eb e))))
      best)))



;;; ## Ls
;;; Greedy local search, (1+1) with restarts. Keep only
;;; strict improvements; after --restart steps with no new
;;; best, jump to a fresh random row.

(defun ls (tbl &aux s es best eb (imp 0))
  "Greedy local search; returns the best row found"
  (with-surrogate (tbl)
    (labels ((y (r) (disty tbl r)))
      (setf s  (elt (? tbl rows)
                    (rint (length (? tbl rows))))
            es (y s) best s eb es)
      (loop for h from 1 to (? *my+* --budget1) do
        (let* ((kid (picks tbl s 1))
               (e   (y kid)))
          (when (< e es) (setf s kid es e))
          (when (< e eb) (setf best kid eb e imp h))
          (when (> (- h imp) (? *my+* --restart))
            (setf s   (elt (? tbl rows)
                           (rint (length (? tbl rows))))
                  es  (y s)
                  imp h))))
      best)))



;;; ## Race
;;; Race the optimizers head to head: run each, score its
;;; best row by the hooked disty, return (name score)
;;; pairs ranked best first.

(defun race (tbl &aux out)
  "Which search wins here? (name score), best first"
  (with-surrogate (tbl)
    (dolist (pair (list (cons "de" #'de) (cons "ga" #'ga)
                        (cons "ls" #'ls) (cons "sa" #'sa)))
      (push (list (car pair)
                  (disty tbl (funcall (cdr pair) tbl)))
            out))
    (sort (nreverse out) #'< :key #'second)))



;;; ## Sample
;;; Synthesize new rows. Grow a tree, then for each new row
;;; pick a leaf and DE-blend three of its rows -- so
;;; synthetic rows land inside real, coherent regions, not
;;; in the voids between them.

(defun sample (tbl &optional (n 100) &aux tr big out)
  "N synthetic rows, each a DE-blend inside one leaf"
  (setf tr  (tree tbl (? tbl rows)
                  (lambda (r) (disty tbl r)))
        big (remove-if (lambda (l) (< (length (? l rows)) 3))
                       (leaves tr)))
  (loop while (and big (< (length out) n)) do
    (let ((rs (few (? (elt big (rint (length big))) rows)
                   3)))
      (push (extrapolate (? tbl cols x)
                         (first rs) (second rs) (third rs))
            out)))
  out)



;;; ## Acquire
;;; The HISTORIC active learner, kept for comparison (xai's
;;; own acquire uses poles; this one does not). Label a
;;; warm-start, split it best/rest by sqrt(N), then
;;; repeatedly label the top-scored unlabeled row and
;;; re-cap best. Two scorers: Bayes likelihood, or centroid
;;; distance.

(defun acquire-bayes (tbl best rest row &aux n)
  "Score: like(best) - like(rest); higher = likelier good"
  (declare (ignore tbl))
  (setf n (+ (length (? best rows)) (length (? rest rows))))
  (- (likes best row n 2) (likes rest row n 2)))

(defun acquire-centroid (tbl best rest row)
  "Score: dist to rest mid - dist to best mid"
  (- (distx tbl row (mids rest))
     (distx tbl row (mids best))))

(defun by-disty (tbl rs)
  "Rows sorted best-first by disty"
  (sort (copy-list rs) #'<
        :key (lambda (r) (disty tbl r))))

(defun acquire-top (tbl &optional (score #'acquire-bayes)
                                  budget start
                    &aux rows lab sorted cap best rest unlab)
  "Warm-start, then label the top-scored row per round"
  (setf budget (or budget (? *my* --budget))
        start  (or start (? *my+* --start))
        rows   (shuffle (? tbl rows))
        lab    (clone tbl (subseq rows 0 start))
        sorted (by-disty tbl (? lab rows))
        cap    (floor (sqrt (length sorted)))
        best   (clone tbl (subseq sorted 0 cap))
        rest   (clone tbl (nthcdr cap sorted))
        unlab  (nthcdr start rows))
  (dotimes (b budget lab)
    (when (null unlab) (return lab))
    (setf unlab (sort unlab #'>
                      :key (lambda (r)
                             (funcall score tbl best rest
                                      r))))
    (add lab (first unlab))
    (add best (first unlab))
    (setf unlab (rest unlab))
    (when (> (length (? best rows))
             (floor (sqrt (length (? lab rows)))))
      (let ((worst (car (last (by-disty tbl
                                        (? best rows))))))
        (del best worst)
        (add rest worst)))))



;;; ## Anomaly
;;; Calibrate a 1-nearest-neighbor distance on the training
;;; rows (a num of every row's gap to its nearest OTHER
;;; row), then score any row's gap against that spread: a
;;; high normalized score = a lonely row = an anomaly.

(defun anomaly (tbl &aux (dn (make-num)))
  "Detector row -> 0..1; high = far from all neighbors"
  (labels ((gap1 (r &aux (nn (argmin
                               (lambda (z)
                                 (if (eq r z)
                                     +big+
                                     (distx tbl r z)))
                               (? tbl rows))))
             (distx tbl r nn)))
    (dolist (r (? tbl rows))
      (add dn (gap1 r)))
    (lambda (r) (norm dn (gap1 r)))))



;;; ## Start
;;; `cli+` sets the extra knobs from flags; `help+` prints
;;; both option sets. (The eg file calls both, then xai's
;;; own cli to run the named demos.)

(defun cli+ (&aux (args (args)))
  "Set *my+* slots from any matching --flags"
  (loop for (f v) on args do
    (dolist (slot (slot-names *my+*))
      (when (equalp f (string slot))
        (setf (slot-value *my+* slot) (thing v))))))

(defun help+ ()
  "Print xai's help, then the extra options"
  (help)
  (format t "~a~%" *help+*)
  (dolist (s (slot-names *my+*))
    (format t "  ~(~a~) ~a~%" s (ats *my+* s))))
