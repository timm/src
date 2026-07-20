; vim: set lispwords+=loop,aif :
;;;; Landscape analysis for XAI and optimization CSVs:
;;;; summarize columns, learn distances, sample landscapes,
;;;; grow trees, and grade how few labels buy a good row.
;;;;
;;;; This file owns the package, constants, help text,
;;;; settings and structs, then loads everything else --
;;;; macros first, so the `$` reader macro is live before
;;;; any other file is read. All state lives in six
;;;; structs: `settings` holds the knobs (slot names double
;;;; as CLI flags); `sym` and `num` summarize one column
;;;; each; `cols` and `tbl` hold tables; `node` is one tree
;;;; node.

(defpackage :xai (:use :common-lisp))
(in-package :xai)

(setf *read-default-float-format* 'double-float)

#+sbcl (declaim (sb-ext:muffle-conditions
                  warning style-warning))

(defconstant +tiny+ 1e-32)
(defconstant +big+  1e32)

(defvar *help* "
xai: explainable multi-objective optimization, tiny-ly.
(c) 2026 Tim Menzies <timm@ieee.org> (see LICENSE.md).

Samples a data landscape under a small labelling budget,
grows a regression tree over the labels, picks good rows,
and shows which x-ranges explain them.

USAGE: sbcl --script xai-eg.lisp [--key val ..] [--run ..]

CSVs name their column roles in the header: leading
uppercase = numeric; trailing +/- = goal to maximize or
minimize; trailing X = ignore; ? cells = missing.

Every OPTION below is a flag (e.g. --seed 1 --file x.csv).
Every TEST and STUDY runs by its flag (e.g. --all --tree).
Also: --join --transcript --check (course upkeep).")

; Settings slots ARE the CLI flags (see cli, help)
(defstruct (settings (:conc-name))
  (--seed 1234567891) (--p 2) (--depth 4)
  (--leaf 3) (--budget 50) (--cap 1024) (--check 5) (--more 4)
  (--keepf 0.66) (--acquire "active")
  (--file  "$MOOT/optimize/misc/auto93.csv"))

(defvar *my* (make-settings))

(defstruct sym (at 0) (txt " ") (n 0) (w 1) (has (o)))

(defstruct num (at 0) (txt " ") (n 0) (w 1) (mu 0.0) (m2 0.0))

(defstruct (cols (:constructor %make-cols)) names all x y klass)

(defstruct (tbl (:constructor %make-tbl)) cols rows)

(defstruct node at v n mid rows yes no)


;;; ## Macros
;;; One accessor, three spellings. The function `ats` reads
;;; hash keys and struct slots alike; the macro `?` nests
;;; it, as in (? tbl cols x); inside methods the `$slot`
;;; reader macro abbreviates (ats i 'slot). `(setf ats)`
;;; writes either; `ats!` fills a missing key on first
;;; touch. Two conveniences: `aif` binds `it` to its test
;;; value; `o` makes a fresh equal hash, optionally primed.
;;; Loaded before all other files so `$` is live when
;;; their code is read.

(defmacro ? (x k &rest ks)
  (if ks `(? (ats ,x ',k) ,@ks) `(ats ,x ',k)))

; $slot reads as (ats i 'slot); users of $ must bind `i`
(eval-when (:compile-toplevel :load-toplevel :execute)
  (set-macro-character #\$
    (lambda (stream ch)
      (declare (ignore ch)) `(ats i ',(read stream t nil t)))))

(defun ats (x k &optional d)
  "Get k from a hash (default d) or a struct slot"
  (if (hash-table-p x) (gethash k x d) (slot-value x k)))

(defun (setf ats) (v x k &optional d)
  "Set k in a hash or a struct slot"
  (declare (ignore d))
  (if (hash-table-p x)
      (setf (gethash k x) v)
      (setf (slot-value x k) v)))

(defun ats! (x k new)
  "Get x's k, else stash and return a fresh (new)"
  (or (ats x k) (setf (ats x k) (funcall new))))

(defmacro aif (test then &optional else)
  "Anaphoric if: `it` holds the test value"
  `(let ((it ,test))
     (if it ,then ,else)))

(defun o (&rest kvs)
  "Fresh equal hash-table, optionally primed with k v pairs"
  (let ((h (make-hash-table :test #'equal)))
    (loop for (k v) on kvs by #'cddr do (setf (gethash k h) v))
    h))


;;; ## Lib
;;; Strings and files. `thing` and `things` coerce csv
;;; cells; `trim` strips whitespace; `mapcsv` streams a
;;; file, with `path` expanding a leading $MOOT (env via
;;; `getenv`, else HOME/gits/moot). `cat` glues printed
;;; forms.

(defun trim (s)
  (string-trim '(#\space #\tab #\return) s))

(defun thing (s &aux (opt '(("?" . ?) ("True" . t) ("False"))))
  "String -> number | ? | t | nil | trimmed string"
  (let ((s (trim s))
        (*read-eval*))
    (aif (assoc s opt :test #'equal)
      (cdr it)
      (let ((x (ignore-errors (read-from-string s nil))))
        (if (numberp x) x s)))))

(defun things (s &optional (ch #\,) (start 0))
  "Split s on ch; coerce each cell with thing"
  (aif (position ch s :start start)
    (cons (thing (subseq s start it)) (things s ch (1+ it)))
    (list (thing (subseq s start)))))

(defun getenv (s)
  "Environment variable, or nil"
  #+sbcl  (sb-ext:posix-getenv s)
  #+clisp (ext:getenv s))

(defun path (s)
  "Expand a leading $MOOT (env, else HOME/gits/moot)"
  (if (and (> (length s) 5) (string= "$MOOT" s :end2 5))
      (concatenate 'string
        (or (getenv "MOOT")
            (concatenate 'string
              (namestring (user-homedir-pathname)) "gits/moot"))
        (subseq s 5))
      s))

(defun mapcsv (fun file)
  "Call fun on each csv row (skipping blanks, # comments)"
  (labels ((line (s &aux (s1 (trim s)))
             (unless (or (equal s1 "") (eql (char s1 0) #\#))
               (funcall fun (coerce (things s1) 'vector)))))
    (with-open-file (s (path file))
      (loop (line (or (read-line s nil) (return)))))))

(defun cat (&rest xs)
  "Concatenate the printed forms of xs"
  (format nil "~{~a~}" xs))


;;; ## Rand
;;; Random and picking. Ways to pick from a list: `shuffle`
;;; (Fisher-Yates) and `few` pick at random, driven by
;;; `rand` -- a seeded 16807 Lehmer generator so runs
;;; reproduce across sbcl and clisp; `argmin`/`argmax`
;;; pick by score.

(defvar *seed* 1234567891)

(defun rand (&optional (n 1))
  "Next 0..n from a 16807 Lehmer generator"
  (setf *seed* (mod (* 16807 *seed*) 2147483647))
  (* n (/ *seed* 2147483647.0)))

(defun rint (&optional (n 2))
  "Random integer 0 <= i < n"
  (floor (rand n)))

(defun shuffle (lst &aux (v (coerce lst 'vector)))
  "Fisher-Yates, driven by the seeded rand"
  (loop for i from (1- (length v)) downto 1 do
    (rotatef (elt v i) (elt v (rint (1+ i)))))
  (coerce v 'list))

(defun few (lst k)
  "K items picked at random"
  (subseq (shuffle lst) 0 (min k (length lst))))

(defun argmin (fun lst &aux best (lo +big+))
  "Element of lst minimizing (fun x)"
  (dolist (x lst best)
    (let ((v (funcall fun x)))
      (when (< v lo) (setf lo v best x)))))

(defun argmax (fun lst &aux best (hi (- +big+)))
  "Element of lst maximizing (fun x)"
  (dolist (x lst best)
    (let ((v (funcall fun x)))
      (when (> v hi) (setf hi v best x)))))


;;; ## Cols
;;; Update. `add` grows a column summary by one value:
;;; `sym`s count, `num`s fold mu and m2 by Welford (w<0
;;; removes). `adds` folds a whole list. (Tables route
;;; rows to their columns in tbl.lisp.)

(defmethod add ((i sym) v &optional (w 1))
  (incf $n  w)
  (incf (ats $has v 0) w)
  v)

(defmethod add ((i num) v &optional (w 1))
  "Fold v into mu,m2 by Welford (w<0 removes); return v"
  (incf $n w)
  (when (>= $n 1)
    (let ((d (- v $mu)))
      (incf $mu (/ (* w d) $n))
      (incf $m2 (* w d (- v $mu)))))
  v)

(defun adds (lst &optional (i (make-num)))
  "Fold a list into a summary; return the summary"
  (dolist (v lst i) (add i v)))


;;; ## Query
;;; Query. Questions for summaries. `mid` = central
;;; tendency (mean or mode); `spread` = dispersion (sd or
;;; entropy); `norm` maps a num onto 0..1 by a logistic
;;; z-score; `minus` = summary of i's data without j's --
;;; bin scoring depends on it.

(defmethod mid ((i num))
  $mu)

(defmethod mid ((i sym) &aux best (most (- +big+)))
  "Most common symbol"
  (labels ((most (k v) (when (> v most) (setf most v best k))))
    (maphash #'most $has)
    best))

(defmethod spread ((i sym))
  "Entropy of a sym's counts"
  (loop for v being the hash-values of $has
    sum (* (/ v $n) (log (/ $n v) 2))))

(defmethod spread ((i num))
  "Standard deviation of a num"
  (if (< $n 2)
      0
      (sqrt (/ (max 0 $m2) (1- $n)))))

(defmethod norm ((i num) v)
  "Map v to 0..1 via a logistic over its z-score"
  (let ((z (/ (- v $mu) (+ (spread i) +tiny+))))
    (/ 1 (+ 1 (exp (* -1.7 (max -3 (min 3 z))))))))

(defmethod minus ((i num) (j num) &aux (k (make-num)))
  "Num summarizing i's data without j's"
  (let ((n (- $n (? j n)))
        (d (- (? j mu) $mu)))
    (when (plusp n)
      (setf (? k n)  n
            (? k mu) (/ (- (* $n $mu) (* (? j n) (? j mu))) n)
            (? k m2) (max 0 (- $m2 (? j m2)
                               (/ (* d d $n (? j n)) n)))))
    k))

(defmethod minus ((i sym) (j sym) &aux (k (make-sym)))
  "Sym summarizing i's data without j's"
  (setf (? k n) (- $n (? j n)))
  (maphash (lambda (x c &aux (c1 (- c (ats (? j has) x 0))))
             (when (plusp c1) (setf (ats (? k has) x) c1)))
           $has)
  k)


;;; ## Tbl
;;; Construction. Tables are born here. `make-cols` reads
;;; roles from the header (uppercase = num; -,+,! = goals;
;;; X = skip); `make-tbl` streams rows from a csv file or
;;; a list, its `add` routing each cell to its column;
;;; `clone` reuses one table's header over other rows.

(defun make-cols (names &optional (i (%make-cols :names names)))
  (loop for s across names for at from 0 do
    (let* ((a (char s 0))
           (z (char s (1- (length s))))
           (col (if (upper-case-p a)
                    (make-num :at at :txt s)
                    (make-sym :at at :txt s))))
      (push col $all)
      (cond ((find z "-+!")
             (when (eql z #\!) (setf $klass col))
             (when (eql z #\-) (setf (? col w) 0))
             (push col $y))
            ((not (eql z #\X)) (push col $x)))))
  (setf $all (nreverse $all) $x (nreverse $x) $y (nreverse $y))
  i)

(defun make-tbl (&optional src &aux (i (%make-tbl)))
  "Table from a csv file name or a list of rows"
  (labels ((inc (row) (add i row)))
    (if (stringp src)
        (mapcsv #'inc src)
        (mapc #'inc src))
    i))

(defun clone (tbl rows)
  "Fresh tbl over a subset of rows"
  (make-tbl (cons (? tbl cols names) rows)))

(defmethod add ((i tbl) row &optional (w 1))
  "First row makes cols; later rows update them"
  (if $cols
      (dolist (col (? $cols all) (push row $rows))
        (let ((v (elt row (? col at))))
          (unless (eq v '?) (add col v w))))
      (setf $cols (make-cols row)))
  row)


;;; ## Dist
;;; Distances. `minkowski` is the p-norm skeleton; missing
;;; cells are skipped. `disty` reads only y columns:
;;; distance to the ideal goals (0 = heaven); `*label*` is
;;; the hook where live models compute y on demand (see
;;; dtlz.lisp). `gap` scores one x value pair and serves
;;; only `distx`, the distance over x columns.

(defun minkowski (row cols fun &aux (n +tiny+) (d 0))
  (dolist (col cols (expt (/ d n) (/ 1 (? *my* --p))))
    (let ((v (elt row (? col at))))
      (unless (eq v '?)
        (setf n (1+ n)
              d (+ d (expt (funcall fun col v)
                           (? *my* --p))))))))

(defvar *label* #'identity
  "hook: label a row on demand (see dtlz.lisp)")

(defun disty (tbl row)
  "Row's distance to the best goals (0 = ideal)"
  (let ((row (funcall *label* row)))
    (minkowski row (? tbl cols y)
      (lambda (col v) (abs (- (norm col v) (? col w)))))))

(defmethod gap ((i sym) u v)
  "Distance between two sym values"
  (if (equal u v) 0 1))

(defmethod gap ((i num) u v)
  "Distance between two num values; missing v = far pole"
  (let* ((u (norm i u))
         (v (if (eq v '?)
                (if (< u .5) 1 0)
                (norm i v))))
    (abs (- u v))))

(defun distx (tbl r1 r2)
  "Distance between two rows over the x cols"
  (minkowski r1 (? tbl cols x)
    (lambda (col u) (gap col u (elt r2 (? col at))))))


;;; ## Acquire
;;; Acquire labels. `sway3` is the active learner: label a
;;; few rows off the good end, project the pool onto the
;;; line joining two poles (far rows at first; on later
;;; passes the best and worst labels so far), keep the
;;; keepf slice nearest the good pole, repeat; when the
;;; pool runs dry with budget unspent, redo on a fresh
;;; shuffle, labels accumulating across passes.

(defun project (rows x y &optional east west)
  (labels ((far (r) (argmax (lambda (z) (funcall x z r)) rows)))
    (let* ((east (or east (far (first rows))))
           (west (or west (far east)))
           (c    (+ (funcall x east west) +tiny+)))
      (when (> (funcall y east) (funcall y west))
        (rotatef east west))
      (lambda (r)
        (/ (+ (expt (funcall x east r) 2) (* c c)
              (- (expt (funcall x west r) 2)))
           (* 2 c))))))

(defun labs (lab &aux out)
  "All labelled rows, as a list"
  (maphash (lambda (k v) (declare (ignore k)) (push v out))
           lab)
  out)

(defun acquire (tbl)
  "Label <= budget-check rows, best first; --acquire picks how"
  (labels ((y (r)   (disty tbl r))
           (x (a b) (distx tbl a b)))
    (let ((cap (- (? *my* --budget) (? *my* --check))))
      (sort (if (equal (? *my* --acquire) "random")
                (few (? tbl rows) cap)
                (sway3 (shuffle (? tbl rows)) #'y #'x cap))
            #'< :key #'y))))

; pole; redo on a fresh shuffle when the pool runs dry
(defun sway3 (rows y x cap &optional lab east west
              &aux (b4 (copy-list rows)))
  "Grow a few labels; keep the keepf slice nearest the good"
  (setf lab (or lab (make-hash-table :test #'eq)))
  (loop while (>= (length rows) (* 2 (? *my* --leaf))) do
    (let ((more (min (? *my* --more)
                     (- cap (hash-table-count lab))))
          new)
      (dolist (r rows)
        (cond ((gethash r lab) (push r new))
              ((>= (decf more) 0)
               (push r new)
               (setf (gethash r lab) r))))
      (when (>= (hash-table-count lab) cap)
        (return-from sway3 (labs lab)))       ; budget spent
      (setf rows
            (subseq (sort rows #'< :key
                          (project (nreverse new) x y
                                   east west))
                    0 (floor (max 1 (* (? *my* --keepf)
                                       (length rows))))))))
  (if (< (hash-table-count lab) (length b4))
      (let ((seen (sort (labs lab) #'< :key y)))
        (sway3 (shuffle b4) y x cap lab       ; redo, anchored
               (first seen) (car (last seen))))
      (labs lab)))


;;; ## Bins
;;; Bins. `split` finds the single cheapest bin over all x
;;; cols; cost is the size-weighted `spread` of the two
;;; halves (the far half computed by `minus`, not a second
;;; pass). Numeric bins come from exact sorted split
;;; points, never fixed-width approximations.
;;; `keep-best-bin` is a closure holding the running best;
;;; `has-p` says which side a row falls on (? = yes).

(defmethod has-p ((i sym) w v)
  (or (eq w '?) (equal w v)))

(defmethod has-p ((i num) w v)
  "Row value w on the yes-side of bin v? (? = yes)"
  (or (eq w '?) (<= w v)))

(defun split (tbl rows y &optional (accum #'make-num)
                  (keeper (keep-best-bin)))
  "Best (cost at v) bin over all x cols"
  (dolist (col (? tbl cols x) (funcall keeper))
    (let ((at  (? col at))
          (ys  (funcall accum))
          (xs  (if (sym-p col) (make-sym) (make-num)))
          xy)
      (loop for r in rows for x = (elt r at) do
        (unless (eq x '?)
          (if (sym-p col)
              (add (ats! (? xs has) x accum)
                   (add ys (funcall y r)))
              (push (cons x (add ys (funcall y r))) xy))))
      (bins xs xy ys at accum keeper))))

(defun keep-best-bin (&aux (lo +big+) kept)
  "Closure: offer (this ys at v); () returns cheapest bin"
  (labels
    ((big-p (m n)
       (<= (? *my* --leaf) m (- n (? *my* --leaf))))
     (score (a b)
       (/ (+ (* (spread a) (? a n)) (* (spread b) (? b n)))
          (+ (? a n) (? b n) +tiny+))))
    (lambda (&optional this ys at v)
      (when (and this (big-p (? this n) (? ys n)))
        (let ((c (score this (minus ys this))))
          (when (< c lo) (setf lo c kept (list c at v)))))
      kept)))

(defmethod bins ((i sym) xy ys at accum keeper)
  "Offer each key's y-summary as a candidate bin"
  (loop for k being the hash-keys of $has
        using (hash-value this) do
    (funcall keeper this ys at k)))

(defmethod bins ((i num) xy ys at accum keeper
                 &aux (this (funcall accum)))
  "Offer a candidate bin at each change in sorted x"
  (loop for ((x . y) . rest) on (sort xy #'< :key #'car) do
    (add this y)
    (when (and rest (not (eql x (caar rest))))
      (funcall keeper this ys at x))))


;;; ## Tree
;;; Trees. `tree` recurses on the best bin while `grow-p`
;;; allows; leaves keep their rows and a `mid` prediction.
;;; `leaf` routes a new row down; `show` prints branch
;;; conditions as text. Passing a different accum
;;; (make-sym) turns the same code from regression into
;;; classification.

(defun tree (tbl rows y &optional (accum #'make-num) (lvl 0))
  (let ((i (make-node :n (length rows) :rows rows
                      :mid (mid (adds (mapcar y rows)
                                      (funcall accum))))))
    (when (grow-p rows lvl) (branch tbl i rows y accum lvl))
    i))

(defun grow-p (rows lvl)
  "Enough rows and shallow enough to split again?"
  (and (>= (length rows) (* 2 (? *my* --leaf)))
       (< lvl (? *my* --depth))))

(defun branch (tbl i rows y accum lvl &aux yes no)
  "If best bin divides rows, grow yes/no subtrees"
  (aif (split tbl rows y accum)
    (let ((at (second it)) (v (third it)))
      (dolist (r rows)
        (if (has-p (col-at tbl at) (elt r at) v)
            (push r yes)
            (push r no)))
      (when (and yes no)
        (setf $at  at
              $v   v
              $yes (tree tbl yes y accum (1+ lvl))
              $no  (tree tbl no  y accum (1+ lvl)))))))

(defun col-at (tbl at)
  "The column summary at index `at`"
  (elt (? tbl cols all) at))

(defun leaf (tbl i row)
  "Walk row down the tree; return its leaf's mid"
  (if $at
      (leaf tbl
            (if (has-p (col-at tbl $at) (elt row $at) $v)
                $yes
                $no)
            row)
      $mid))

(defun leaves (i)
  "List of every leaf node"
  (if $at
      (append (leaves $yes) (leaves $no))
      (list i)))

(defun cond-txt (tbl i yes)
  "One branch test as text, e.g. |Volume <= 183|"
  (let ((col (col-at tbl $at)))
    (format nil "~a ~a ~a" (? col txt)
            (if (sym-p col)
                (if yes "==" "!=")
                (if yes "<=" ">"))
            $v)))

(defun show (tbl i &optional (pad "") (edge ""))
  "Print tree: n, mid, indented branch conditions"
  (format t "~&~5d ~8,2f  ~a~a~%" $n $mid pad edge)
  (when $at
    (let ((pad2 (if (equal edge "") pad (cat pad "|  "))))
      (show tbl $yes pad2 (cond-txt tbl i t))
      (show tbl $no  pad2 (cond-txt tbl i nil)))))

(defun used (i)
  "X col indexes tested anywhere in the tree"
  (when $at
    (remove-duplicates
      (cons $at (append (used $yes) (used $no))))))

(defun about (tbl i)
  "One line per tree: leaves, x cols used"
  (format t "~&leaves= ~a, x= ~a of ~a~%"
          (length (leaves i))
          (length (used i))
          (length (? tbl cols x))))


;;; ## Stats
;;; Stats. `same` is a conservative equality: `cohen` AND
;;; `cliffs` AND `ks` must all agree before two result
;;; sets are called equal, so later "X beats Y" claims
;;; mean something.

(defun cliffs (xs ys &aux (gt 0) (lt 0))
  (dolist (x xs)
    (dolist (y ys)
      (cond ((> x y) (incf gt))
            ((< x y) (incf lt)))))
  (/ (abs (- gt lt))
     (+ (* (length xs) (length ys)) +tiny+)))

(defun ks (xs ys)
  "Kolmogorov-Smirnov: max gap between the two CDFs"
  (labels ((cdf (v lst)
             (/ (count-if (lambda (z) (<= z v)) lst)
                (length lst))))
    (loop for v in (append xs ys)
          maximize (abs (- (cdf v xs) (cdf v ys))))))

(defun cohen (xs ys &optional (eps 0.35))
  "Small effect: |mean gap| <= eps * pooled sd"
  (let* ((x (adds xs)) (y (adds ys))
         (n (? x n))   (m (? y n))
         (sd (sqrt (/ (+ (* (1- n) (expt (spread x) 2))
                         (* (1- m) (expt (spread y) 2)))
                      (+ n m -2)))))
    (<= (abs (- (mid x) (mid y))) (* eps (+ sd +tiny+)))))

(defun same (xs ys &optional (cliff 0.195) (conf 1.36))
  "True if xs,ys are statistically indistinguishable"
  (and (cohen xs ys)
       (<= (cliffs xs ys) cliff)
       (let ((n (length xs)) (m (length ys)))
         (<= (ks xs ys)
             (* conf (sqrt (/ (+ n m) (* n m))))))))


;;; ## Main
;;; Main. `wins` grades any row: 100 = equals the best,
;;; 0 = no better than median. `holdout` is the evaluation
;;; rig: budgeted train, tree-ranked test. `slot-names`
;;; and `egs` are the introspection: demos are found by
;;; name, so the eg files register nothing here. `cli`
;;; maps --flags onto `settings` slots then runs the named
;;; eg--/study-- functions; `help` prints everything.

(defun wins (tbl)
  (let* ((ys (sort (mapcar (lambda (r) (disty tbl r))
                           (? tbl rows))
                   #'<))
         (lo (first ys))
         (b4 (elt ys (floor (length ys) 2))))
    (lambda (r)
      (max -100 (min 100 (* 100
        (- 1 (/ (- (disty tbl r) lo)
                (+ (- b4 lo) +tiny+)))))))))

(defun holdout (tbl)
  "Budget rig: acquire train -> tree -> best test row"
  (labels ((y (r) (disty tbl r)))
    (let* ((rows  (shuffle (? tbl rows)))
           (half  (floor (length rows) 2))
           (train (subseq rows 0 half))
           (test  (nthcdr half rows))
           (got   (acquire (clone tbl train)))
           (tr    (tree tbl got #'y)))
      (argmin #'y
              (subseq (sort test #'<
                            :key (lambda (r) (leaf tbl tr r)))
                      0 (? *my* --check))))))

(defun slot-names (x)
  "Slot names of a struct instance or type"
  (mapcar #+sbcl  #'sb-mop:slot-definition-name
          #+clisp #'clos:slot-definition-name
          (#+sbcl  sb-mop:class-slots
           #+clisp clos:class-slots
           (find-class (if (symbolp x) x (type-of x))))))

(defun egs (prefix)
  "Sorted fbound xai symbols starting with prefix"
  (sort (loop for s being the present-symbols
              of (find-package :xai)
              when (and (fboundp s)
                        (eql 0 (search prefix (string s)))
                        (not (member s '(eg--all eg--study eg--join
                                          eg--transcript eg--check))))
              collect s)
        #'string< :key #'string))

(defun args ()
  "Command-line args after the script name"
  #+sbcl  (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*)

(defun sh (cmd)
  "Run a shell command; return its exit code"
  #+sbcl (sb-ext:process-exit-code
           (sb-ext:run-program "/bin/sh" (list "-c" cmd)
                               :output *standard-output*
                               :error *error-output*))
  #-sbcl 1)

(defun slurp (file)
  "Whole file as one string"
  (with-open-file (s file)
    (let ((str (make-string (file-length s))))
      (subseq str 0 (read-sequence str s)))))

(defun gkeys (&aux (keys (o)))
  "Glossary headings '## key' as a set"
  (with-open-file (s "../glossary.md")
    (loop for line = (read-line s nil) while line do
      (when (and (> (length line) 3)
                 (string= "## " line :end2 3)
                 (every #'lower-case-p (subseq line 3)))
        (setf (gethash (subseq line 3) keys) t))))
  keys)

(defun freeze (script out)
  "Capture script's --all to out (a real run, never edited)"
  (assert (zerop (sh (cat "sbcl --script " script
                          " --all > " out))))
  (format t "~&~a frozen~%" out))

(defun check-transcript (script out &aux ok)
  "A fresh --all must reproduce the frozen transcript"
  (setf ok (zerop (sh (cat "sbcl --script " script
                           " --all | diff - " out))))
  (format t "~&~a~%" (if ok "transcript ok"
                            "TRANSCRIPT DRIFT"))
  (assert ok))

(defun join-check (srcfile &aux (src (slurp srcfile))
                                (keys (gkeys)) (ok t)
                                (taught (o)))
  "Doc claims, executable: glossary links, table signatures"
  (let ((tag "glossary.md#") (start 0))
    (loop for pos = (search tag src :start2 start)
          while pos
          do (let* ((k0 (+ pos (length tag)))
                    (k1 (position-if-not #'alpha-char-p src
                                         :start k0))
                    (key (subseq src k0 k1)))
               (unless (or (string= key "")  ; the tag itself
                           (gethash key keys))
                 (setf ok nil)
                 (format t "~&no heading: ~a~%" key))
               (setf start k1))))
  (with-input-from-string (s src)
    (loop for line = (read-line s nil) while line do
      (when (eql 0 (search "| `(" line))
        (let* ((k0 4)
               (k1 (position-if
                     (lambda (c) (member c '(#\Space #\))))
                     line :start k0))
               (name (subseq line k0 k1))
               (sym (find-symbol (string-upcase name) :xai)))
          (if (and sym (fboundp sym))
              (setf (gethash name taught) t)
              (progn (setf ok nil)
                     (format t "~&table names missing fn: ~a~%"
                             name)))))))
  (format t "~&coverage: ~a taught verbs; ~a demos~%"
          (hash-table-count taught) (length (egs "EG--")))
  (assert ok))

(defun help ()
  "Print options (with defaults), tests, studies"
  (format t "~a~%~%OPTIONS:~%" *help*)
  (dolist (s (slot-names *my*))
    (format t "  ~(~a~) ~a~%" s (ats *my* s)))
  (format t "~%TESTS: (run by flag, e.g. --tree)~%")
  (dolist (s (egs "EG--"))
    (format t "  ~(~a~)~26t~a~%" (subseq (string s) 2)
            (documentation s 'function)))
  (format t "~%STUDIES:~%")
  (dolist (s (egs "STUDY--"))
    (format t "  ~(~a~)~26t~a~%" (subseq (string s) 5)
            (documentation s 'function))))

(defun cli (*my*)
  "Set settings slots from flags, then run named tests"
  (let ((args (args)))
    (loop for (f v) on args do
      (dolist (slot (slot-names *my*))
        (when (equalp f (string slot))
          (setf (slot-value *my* slot) (thing v)))))
    (loop for s in args do
      (dolist (pre '("EG" "STUDY"))
        (let ((fun (intern (format nil "~a~:@(~a~)" pre s)
                           :xai)))
          (when (fboundp fun)
            (setf *seed* (? *my* --seed))
            (funcall fun)))))))
