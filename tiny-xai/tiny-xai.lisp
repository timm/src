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

(defpackage :tiny-xai (:use :common-lisp))
(in-package :tiny-xai)

#+sbcl (declaim (sb-ext:muffle-conditions
                  warning style-warning))

(defconstant +tiny+ 1e-32)
(defconstant +big+  1e32)

(defvar *help* "
tiny-xai: explainable multi-objective optimization, tiny-ly.
(c) 2026 Tim Menzies <timm@ieee.org> (see LICENSE.md).

Samples a data landscape under a small labelling budget,
grows a regression tree over the labels, picks good rows,
and shows which x-ranges explain them.

USAGE: sbcl --script tiny-xai-eg.lisp [--key val ..] [--run ..]

CSVs name their column roles in the header: leading
uppercase = numeric; trailing +/- = goal to maximize or
minimize; trailing X = ignore; ? cells = missing.

Every OPTION below is a flag (e.g. --seed 1 --file x.csv).
Every TEST and STUDY runs by its flag (e.g. --all --tree).")

; Settings slots ARE the CLI flags (see cli, help)
(defstruct (settings (:conc-name))
  (--seed 1234567891) (--p 2) (--depth 4)
  (--leaf 3) (--budget 50) (--cap 1024) (--check 5) (--more 4)
  (--keepf 0.66) (--acquire "active")
  (--file  "$MOOT/optimize/misc/auto93.csv"))

(defvar *my* (make-settings))

(defstruct sym (at 0) (txt " ") (n 0) (w 1) (has (o)))

(defstruct num (at 0) (txt " ") (n 0) (w 1) (mu 0.0) (m2 0.0))

(defstruct (cols (:constructor %make-cols)) names all x y)

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

; Get k from a hash (default d) or a struct slot
(defun ats (x k &optional d)
  (if (hash-table-p x) (gethash k x d) (slot-value x k)))

; Set k in a hash or a struct slot
(defun (setf ats) (v x k &optional d)
  (declare (ignore d))
  (if (hash-table-p x)
      (setf (gethash k x) v)
      (setf (slot-value x k) v)))

; Get x's k, else stash and return a fresh (new)
(defun ats! (x k new)
  (or (ats x k) (setf (ats x k) (funcall new))))

; Anaphoric if: `it` holds the test value
(defmacro aif (test then &optional else)
  `(let ((it ,test))
     (if it ,then ,else)))

; Fresh equal hash-table, optionally primed with k v pairs
(defun o (&rest kvs)
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

; String -> number | ? | t | nil | trimmed string
(defun thing (s &aux (opt '(("?" . ?) ("True" . t) ("False"))))
  (let ((s (trim s))
        (*read-eval*))
    (aif (assoc s opt :test #'equal)
      (cdr it)
      (let ((x (ignore-errors (read-from-string s nil))))
        (if (numberp x) x s)))))

; Split s on ch; coerce each cell with thing
(defun things (s &optional (ch #\,) (start 0))
  (aif (position ch s :start start)
    (cons (thing (subseq s start it)) (things s ch (1+ it)))
    (list (thing (subseq s start)))))

; Environment variable, or nil
(defun getenv (s)
  #+sbcl  (sb-ext:posix-getenv s)
  #+clisp (ext:getenv s))

; Expand a leading $MOOT (env, else HOME/gits/moot)
(defun path (s)
  (if (and (> (length s) 5) (string= "$MOOT" s :end2 5))
      (concatenate 'string
        (or (getenv "MOOT")
            (concatenate 'string
              (namestring (user-homedir-pathname)) "gits/moot"))
        (subseq s 5))
      s))

; Call fun on each csv row (skipping blanks, # comments)
(defun mapcsv (fun file)
  (labels ((line (s &aux (s1 (trim s)))
             (unless (or (equal s1 "") (eql (char s1 0) #\#))
               (funcall fun (coerce (things s1) 'vector)))))
    (with-open-file (s (path file))
      (loop (line (or (read-line s nil) (return)))))))

; Concatenate the printed forms of xs
(defun cat (&rest xs)
  (format nil "~{~a~}" xs))

;;; ## Rand
;;; Random and picking. Ways to pick from a list: `shuffle`
;;; (Fisher-Yates) and `few` pick at random, driven by
;;; `rand` -- a seeded 16807 Lehmer generator so runs
;;; reproduce across sbcl and clisp; `argmin`/`argmax`
;;; pick by score.

(defvar *seed* 1234567891)

; Next 0..n from a 16807 Lehmer generator
(defun rand (&optional (n 1))
  (setf *seed* (mod (* 16807 *seed*) 2147483647))
  (* n (/ *seed* 2147483647.0)))

; Random integer 0 <= i < n
(defun rint (&optional (n 2))
  (floor (rand n)))

; Fisher-Yates, driven by the seeded rand
(defun shuffle (lst &aux (v (coerce lst 'vector)))
  (loop for i from (1- (length v)) downto 1 do
    (rotatef (elt v i) (elt v (rint (1+ i)))))
  (coerce v 'list))

; K items picked at random
(defun few (lst k)
  (subseq (shuffle lst) 0 (min k (length lst))))

; Element of lst minimizing (fun x)
(defun argmin (fun lst &aux best (lo +big+))
  (dolist (x lst best)
    (let ((v (funcall fun x)))
      (when (< v lo) (setf lo v best x)))))

; Element of lst maximizing (fun x)
(defun argmax (fun lst &aux best (hi (- +big+)))
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

; Fold v into mu,m2 by Welford (w<0 removes); return v
(defmethod add ((i num) v &optional (w 1))
  (incf $n w)
  (when (>= $n 1)
    (let ((d (- v $mu)))
      (incf $mu (/ (* w d) $n))
      (incf $m2 (* w d (- v $mu)))))
  v)

; Fold a list into a summary; return the summary
(defun adds (lst &optional (i (make-num)))
  (dolist (v lst i) (add i v)))

;;; ## Query
;;; Query. Questions for summaries. `mid` = central
;;; tendency (mean or mode); `spread` = dispersion (sd or
;;; entropy); `norm` maps a num onto 0..1 by a logistic
;;; z-score; `minus` = summary of i's data without j's --
;;; bin scoring depends on it.

(defmethod mid ((i num))
  $mu)

; Most common symbol
(defmethod mid ((i sym) &aux best (most (- +big+)))
  (labels ((most (k v) (when (> v most) (setf most v best k))))
    (maphash #'most $has)
    best))

; Entropy of a sym's counts
(defmethod spread ((i sym))
  (loop for v being the hash-values of $has
    sum (* (/ v $n) (log (/ $n v) 2))))

; Standard deviation of a num
(defmethod spread ((i num))
  (if (< $n 2)
      0
      (sqrt (/ (max 0 $m2) (1- $n)))))

; Map v to 0..1 via a logistic over its z-score
(defmethod norm ((i num) v)
  (let ((z (/ (- v $mu) (+ (spread i) +tiny+))))
    (/ 1 (+ 1 (exp (* -1.7 (max -3 (min 3 z))))))))

; Num summarizing i's data without j's
(defmethod minus ((i num) (j num) &aux (k (make-num)))
  (let ((n (- $n (? j n)))
        (d (- (? j mu) $mu)))
    (when (plusp n)
      (setf (? k n)  n
            (? k mu) (/ (- (* $n $mu) (* (? j n) (? j mu))) n)
            (? k m2) (max 0 (- $m2 (? j m2)
                               (/ (* d d $n (? j n)) n)))))
    k))

; Sym summarizing i's data without j's
(defmethod minus ((i sym) (j sym) &aux (k (make-sym)))
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
             (when (eql z #\-) (setf (? col w) 0))
             (push col $y))
            ((not (eql z #\X)) (push col $x)))))
  (setf $all (nreverse $all) $x (nreverse $x) $y (nreverse $y))
  i)

; Table from a csv file name or a list of rows
(defun make-tbl (&optional src &aux (i (%make-tbl)))
  (labels ((inc (row) (add i row)))
    (if (stringp src)
        (mapcsv #'inc src)
        (mapc #'inc src))
    i))

; Fresh tbl over a subset of rows
(defun clone (tbl rows)
  (make-tbl (cons (? tbl cols names) rows)))

; First row makes cols; later rows update them
(defmethod add ((i tbl) row &optional (w 1))
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

; Row's distance to the best goals (0 = ideal)
(defun disty (tbl row)
  (let ((row (funcall *label* row)))
    (minkowski row (? tbl cols y)
      (lambda (col v) (abs (- (norm col v) (? col w)))))))

; Distance between two sym values
(defmethod gap ((i sym) u v)
  (if (equal u v) 0 1))

; Distance between two num values; missing v = far pole
(defmethod gap ((i num) u v)
  (let* ((u (norm i u))
         (v (if (eq v '?)
                (if (< u .5) 1 0)
                (norm i v))))
    (abs (- u v))))

; Distance between two rows over the x cols
(defun distx (tbl r1 r2)
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

; All labelled rows, as a list
(defun labs (lab &aux out)
  (maphash (lambda (k v) (declare (ignore k)) (push v out))
           lab)
  out)

; Label <= budget-check rows, best first; --acquire picks how
(defun acquire (tbl)
  (labels ((y (r)   (disty tbl r))
           (x (a b) (distx tbl a b)))
    (let ((cap (- (? *my* --budget) (? *my* --check))))
      (sort (if (equal (? *my* --acquire) "random")
                (few (? tbl rows) cap)
                (sway3 (shuffle (? tbl rows)) #'y #'x cap))
            #'< :key #'y))))

; Grow a few labels; keep the keepf slice nearest the good
; pole; redo on a fresh shuffle when the pool runs dry
(defun sway3 (rows y x cap &optional lab east west
              &aux (b4 (copy-list rows)))
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

; Row value w on the yes-side of bin v? (? = yes)
(defmethod has-p ((i num) w v)
  (or (eq w '?) (<= w v)))

; Best (cost at v) bin over all x cols
(defun split (tbl rows y &optional (accum #'make-num)
                  (keeper (keep-best-bin)))
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

; Closure: offer (this ys at v); () returns cheapest bin
(defun keep-best-bin (&aux (lo +big+) kept)
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

; Offer each key's y-summary as a candidate bin
(defmethod bins ((i sym) xy ys at accum keeper)
  (loop for k being the hash-keys of $has
        using (hash-value this) do
    (funcall keeper this ys at k)))

; Offer a candidate bin at each change in sorted x
(defmethod bins ((i num) xy ys at accum keeper
                 &aux (this (funcall accum)))
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

; Enough rows and shallow enough to split again?
(defun grow-p (rows lvl)
  (and (>= (length rows) (* 2 (? *my* --leaf)))
       (< lvl (? *my* --depth))))

; If best bin divides rows, grow yes/no subtrees
(defun branch (tbl i rows y accum lvl &aux yes no)
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

; The column summary at index `at`
(defun col-at (tbl at)
  (elt (? tbl cols all) at))

; Walk row down the tree; return its leaf's mid
(defun leaf (tbl i row)
  (if $at
      (leaf tbl
            (if (has-p (col-at tbl $at) (elt row $at) $v)
                $yes
                $no)
            row)
      $mid))

; List of every leaf node
(defun leaves (i)
  (if $at
      (append (leaves $yes) (leaves $no))
      (list i)))

; One branch test as text, e.g. |Volume <= 183|
(defun cond-txt (tbl i yes)
  (let ((col (col-at tbl $at)))
    (format nil "~a ~a ~a" (? col txt)
            (if (sym-p col)
                (if yes "==" "!=")
                (if yes "<=" ">"))
            $v)))

; Print tree: n, mid, indented branch conditions
(defun show (tbl i &optional (pad "") (edge ""))
  (format t "~&~5d ~8,2f  ~a~a~%" $n $mid pad edge)
  (when $at
    (let ((pad2 (if (equal edge "") pad (cat pad "|  "))))
      (show tbl $yes pad2 (cond-txt tbl i t))
      (show tbl $no  pad2 (cond-txt tbl i nil)))))

; X col indexes tested anywhere in the tree
(defun used (i)
  (when $at
    (remove-duplicates
      (cons $at (append (used $yes) (used $no))))))

; One line per tree: leaves, x cols used
(defun about (tbl i)
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

; Kolmogorov-Smirnov: max gap between the two CDFs
(defun ks (xs ys)
  (labels ((cdf (v lst)
             (/ (count-if (lambda (z) (<= z v)) lst)
                (length lst))))
    (loop for v in (append xs ys)
          maximize (abs (- (cdf v xs) (cdf v ys))))))

; Small effect: |mean gap| <= eps * pooled sd
(defun cohen (xs ys &optional (eps 0.35))
  (let* ((x (adds xs)) (y (adds ys))
         (n (? x n))   (m (? y n))
         (sd (sqrt (/ (+ (* (1- n) (expt (spread x) 2))
                         (* (1- m) (expt (spread y) 2)))
                      (+ n m -2)))))
    (<= (abs (- (mid x) (mid y))) (* eps (+ sd +tiny+)))))

; True if xs,ys are statistically indistinguishable
(defun same (xs ys &optional (cliff 0.195) (conf 1.36))
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

; Budget rig: acquire train -> tree -> best test row
(defun holdout (tbl)
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

; Slot names of a struct instance or type
(defun slot-names (x)
  (mapcar #+sbcl  #'sb-mop:slot-definition-name
          #+clisp #'clos:slot-definition-name
          (#+sbcl  sb-mop:class-slots
           #+clisp clos:class-slots
           (find-class (if (symbolp x) x (type-of x))))))

; Sorted fbound tiny-xai symbols starting with prefix
(defun egs (prefix)
  (sort (loop for s being the present-symbols
              of (find-package :tiny-xai)
              when (and (fboundp s)
                        (eql 0 (search prefix (string s)))
                        (not (member s '(eg--all eg--study))))
              collect s)
        #'string< :key #'string))

; Command-line args after the script name
(defun args ()
  #+sbcl  (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*)

; Print options (with defaults), tests, studies
(defun help ()
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

; Set settings slots from flags, then run named tests
(defun cli (*my*)
  (let ((args (args)))
    (loop for (f v) on args do
      (dolist (slot (slot-names *my*))
        (when (equalp f (string slot))
          (setf (slot-value *my* slot) (thing v)))))
    (loop for s in args do
      (dolist (pre '("EG" "STUDY"))
        (let ((fun (intern (format nil "~a~:@(~a~)" pre s)
                           :tiny-xai)))
          (when (fboundp fun)
            (setf *seed* (? *my* --seed))
            (funcall fun)))))))
