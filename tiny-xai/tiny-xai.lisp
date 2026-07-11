; vim: set lispwords+=loop,aif,set-macro-character :
;;;; Landscape analysis for XAI and optimization CSVs:
;;;; summarize columns, learn distances, sample landscapes,
;;;; grow trees, and grade how few labels buy a good row.

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

USAGE: sbcl --script tiny-xai.lisp [--key val ...] [--run ..]

CSVs name their column roles in the header: leading
uppercase = numeric; trailing +/- = goal to maximize or
minimize; trailing X = ignore; ? cells = missing.

Every OPTION below is a flag (e.g. --seed 1 --file x.csv).
Every TEST and STUDY runs by its flag (e.g. --all --tree).")

;;; ## Settings and structs
;;;   _  _|_  ._        _  _|_   _
;;;  _>   |_  |   |_|  (_   |_  _>

(defstruct (settings (:conc-name))
  (--seed 1234567891) (--p 2) (--depth 4)
  (--leaf 3) (--budget 50) (--cap 1024) (--check 5) (--grow 4)
  (--keepf 0.66) (--landscape "active")
  (--file  "$MOOT/optimize/misc/auto93.csv"))

(defvar *my* (make-settings))

(defstruct sym (at 0) (txt " ") (n 0) (w 1) (has (o)))
(defstruct num (at 0) (txt " ") (n 0) (w 1) (mu 0.0) (m2 0.0))

(defstruct (cols (:constructor %make-cols)) names all x y)
(defstruct (data (:constructor %make-data)) cols rows)

(defstruct node at v n mid rows yes no)

;;; ## Macros and accessors
;;;  ._ _    _.   _  ._   _    _
;;;  | | |  (_|  (_  |   (_)  _>

(defmacro ? (x k &rest ks)
  "Nested slot/hash access: (? data cols x)"
  (if ks `(? (ats ,x ',k) ,@ks) `(ats ,x ',k)))

(defmacro aif (test then &optional else)
  "Anaphoric if: `it` holds the test value"
  `(let ((it ,test))
     (if it ,then ,else)))

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

(defun o (&rest kvs)
  "Fresh equal hash-table, optionally primed with k v pairs"
  (let ((h (make-hash-table :test #'equal)))
    (loop for (k v) on kvs by #'cddr do (setf (gethash k h) v))
    h))

;;; ## Update and summarize
;;;   _|   _.  _|_   _.
;;;  (_|  (_|   |_  (_|

(defmethod add ((i sym) v &optional (w 1))
  "Count v (weight w); return v"
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

(defmethod mid ((i num))
  "Central tendency of a num"
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

(defun make-cols (names &optional (i (%make-cols :names names)))
  "Columns from header names; fill all, x, y"
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

(defun make-data (&optional src &aux (i (%make-data)))
  "Table from a csv file name or a list of rows"
  (labels ((inc (row) (add i row)))
    (if (stringp src)
        (mapcsv #'inc src)
        (mapc #'inc src))
    i))

(defun clone (data rows)
  "Fresh data over a subset of rows"
  (make-data (cons (? data cols names) rows)))

(defmethod add ((i data) row &optional (w 1))
  "First row makes cols; later rows update them"
  (if $cols
      (dolist (col (? $cols all) (push row $rows))
        (let ((v (elt row (? col at))))
          (unless (eq v '?) (add col v w))))
      (setf $cols (make-cols row)))
  row)

;;; ## Distances
;;;   _|  o   _  _|_
;;;  (_|  |  _>   |_

(defun minkowski (row cols fun &aux (n +tiny+) (d 0))
  "P-norm of (fun col cell) over cols; missing cells skipped"
  (dolist (col cols (expt (/ d n) (/ 1 (? *my* --p))))
    (let ((v (elt row (? col at))))
      (unless (eq v '?)
        (setf n (1+ n)
              d (+ d (expt (funcall fun col v)
                           (? *my* --p))))))))

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

(defvar *label* #'identity
  "hook: label a row on demand (see dtlz.lisp)")

(defun disty (data row)
  "Row's distance to the best goals (0 = ideal)"
  (let ((row (funcall *label* row)))
    (minkowski row (? data cols y)
      (lambda (col v) (abs (- (norm col v) (? col w)))))))

(defun distx (data r1 r2)
  "Distance between two rows over the x cols"
  (minkowski r1 (? data cols x)
    (lambda (col u) (gap col u (elt r2 (? col at))))))

;;; ## Landscape sampling
;;;  |   _.  ._    _|   _   _   _.  ._    _
;;;  |  (_|  | |  (_|  _>  (_  (_|  |_)  (/_
;;;                                 |

(defun project (rows x y)
  "Row -> position on the east-west line (x=dist, y=goal)"
  (labels ((far (r) (argmax (lambda (z) (funcall x z r)) rows)))
    (let* ((east (far (first rows)))
           (west (far east))
           (c    (+ (funcall x east west) +tiny+)))
      (when (< (funcall y east) (funcall y west))
        (rotatef east west))
      (lambda (r)
        (/ (+ (expt (funcall x east r) 2) (* c c)
              (- (expt (funcall x west r) 2)))
           (* 2 c))))))

(defun landscape (data)
  "Label <= budget-check rows, best first"
  (labels ((y (r)   (disty data r))
           (x (a b) (distx data a b)))
    (let ((cap  (- (? *my* --budget) (? *my* --check)))
          (rows (shuffle (? data rows))))
      (sort (if (equal (? *my* --landscape) "random")
                (subseq rows 0 (min cap (length rows)))
                (active rows cap #'x #'y))
            #'< :key #'y))))

(defun active (pool cap x y &aux lab)
  "Label pool heads; cull pool's bad third; repeat"
  (labels ((known (r) (member r lab :test #'eq)))
    (loop while (and (< (length lab) cap)
                     (>= (length pool) (* 2 (? *my* --leaf))))
          do
      (let ((grown 0))
        (dolist (r pool)
          (when (and (< grown (? *my* --grow))
                     (< (length lab) cap)
                     (not (known r)))
            (push r lab)
            (incf grown))))
      (when (< (length lab) cap)
        (let ((here (remove-if-not #'known pool)))
          (setf pool
                (nthcdr (max 1 (floor (* (- 1 (? *my* --keepf))
                                         (length pool))))
                        (sort pool #'< :key
                              (project here x y)))))))
    lab))

;;; ## Cuts
;;;   _       _|_   _
;;;  (_  |_|   |_  _>

(defmethod has-p ((i sym) w v)
  "Row value w on the yes-side of cut v? (? = yes)"
  (or (eq w '?) (equal w v)))

(defmethod has-p ((i num) w v)
  "Row value w on the yes-side of cut v? (? = yes)"
  (or (eq w '?) (<= w v)))

(defun split (data rows y &optional (accum #'make-num)
                   (keeper (keep-best-cut)))
  "Best (cost at v) cut over all x cols"
  (dolist (col (? data cols x) (funcall keeper))
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
      (cuts xs xy ys at accum keeper))))

(defun keep-best-cut (&aux (lo +big+) kept)
  "Closure: offer (this ys at v); () returns cheapest cut"
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

(defmethod cuts ((i sym) xy ys at accum keeper)
  "Offer each key's y-summary as a candidate cut"
  (loop for k being the hash-keys of $has
        using (hash-value this) do
    (funcall keeper this ys at k)))

(defmethod cuts ((i num) xy ys at accum keeper
                 &aux (this (funcall accum)))
  "Offer a candidate cut at each change in sorted x"
  (loop for ((x . y) . rest) on (sort xy #'< :key #'car) do
    (add this y)
    (when (and rest (not (eql x (caar rest))))
      (funcall keeper this ys at x))))

;;; ## Trees
;;;  _|_  ._   _    _
;;;   |_  |   (/_  (/_

(defun tree (data rows y &optional (accum #'make-num) (lvl 0))
  "Recursively split rows on the min-cost cut"
  (let ((i (make-node :n (length rows) :rows rows
                      :mid (mid (adds (mapcar y rows)
                                      (funcall accum))))))
    (when (grow-p rows lvl) (branch data i rows y accum lvl))
    i))

(defun grow-p (rows lvl)
  "Enough rows and shallow enough to split again?"
  (and (>= (length rows) (* 2 (? *my* --leaf)))
       (< lvl (? *my* --depth))))

(defun branch (data i rows y accum lvl &aux yes no)
  "If best cut divides rows, grow yes/no subtrees"
  (aif (split data rows y accum)
    (let ((at (second it)) (v (third it)))
      (dolist (r rows)
        (if (has-p (col-at data at) (elt r at) v)
            (push r yes)
            (push r no)))
      (when (and yes no)
        (setf $at  at
              $v   v
              $yes (tree data yes y accum (1+ lvl))
              $no  (tree data no  y accum (1+ lvl)))))))

(defun col-at (data at)
  "The column summary at index `at`"
  (elt (? data cols all) at))

(defun leaf (data i row)
  "Walk row down the tree; return its leaf's mid"
  (if $at
      (leaf data
            (if (has-p (col-at data $at) (elt row $at) $v)
                $yes
                $no)
            row)
      $mid))

(defun leaves (i)
  "List of every leaf node"
  (if $at
      (append (leaves $yes) (leaves $no))
      (list i)))

(defun cond-txt (data i yes)
  "One branch test as text, e.g. |Volume <= 183|"
  (let ((col (col-at data $at)))
    (format nil "~a ~a ~a" (? col txt)
            (if (sym-p col)
                (if yes "==" "!=")
                (if yes "<=" ">"))
            $v)))

(defun show (data i &optional (pad "") (edge ""))
  "Print tree: n, mid, indented branch conditions"
  (format t "~&~5d ~8,2f  ~a~a~%" $n $mid pad edge)
  (when $at
    (let ((pad2 (if (equal edge "") pad (cat pad "|  "))))
      (show data $yes pad2 (cond-txt data i t))
      (show data $no  pad2 (cond-txt data i nil)))))

(defun used (i)
  "X col indexes tested anywhere in the tree"
  (when $at
    (remove-duplicates
      (cons $at (append (used $yes) (used $no))))))

(defun about (data i)
  "One line per tree: leaves, x cols used"
  (format t "~&leaves= ~a, x= ~a of ~a~%"
          (length (leaves i))
          (length (used i))
          (length (? data cols x))))

;;; ## Stats
;;;   _  _|_   _.  _|_   _
;;;  _>   |_  (_|   |_  _>

(defun wins (data)
  "Grader: row -> % of gap to best closed, [-100,100]"
  (let* ((ys (sort (mapcar (lambda (r) (disty data r))
                           (? data rows))
                   #'<))
         (lo (first ys))
         (b4 (elt ys (floor (length ys) 2))))
    (lambda (r)
      (max -100 (min 100 (* 100
        (- 1 (/ (- (disty data r) lo)
                (+ (- b4 lo) +tiny+)))))))))

(defun holdout (data)
  "Budget rig: landscape train -> tree -> best test row"
  (labels ((y (r) (disty data r)))
    (let* ((rows  (shuffle (? data rows)))
           (half  (floor (length rows) 2))
           (train (subseq rows 0 half))
           (test  (nthcdr half rows))
           (got   (landscape (clone data train)))
           (tr    (tree data got #'y)))
      (argmin #'y
              (subseq (sort test #'<
                            :key (lambda (r) (leaf data tr r)))
                      0 (? *my* --check))))))

(defun cliffs (xs ys &aux (gt 0) (lt 0))
  "Cliff's delta effect size, 0..1 (0 = identical)"
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

;;; ## Lib
;;;  |  o  |_
;;;  |  |  |_)

(defun slot-names (x)
  "Slot names of a struct instance or type"
  (mapcar #+sbcl  #'sb-mop:slot-definition-name
          #+clisp #'clos:slot-definition-name
          (#+sbcl  sb-mop:class-slots
           #+clisp clos:class-slots
           (find-class (if (symbolp x) x (type-of x))))))

(defun trim (s)
  "Strip spaces, tabs, returns"
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

(defvar *seed* 1234567891)

(defun rand (&optional (n 1))
  "Next 0..n from a 16807 Lehmer generator"
  (setf *seed* (mod (* 16807 *seed*) 2147483647))
  (* n (/ *seed* 2147483647.0)))

(defun rint (&optional (n 2))
  "Random integer 0 <= i < n"
  (floor (rand n)))

(defun cat (&rest xs)
  "Concatenate the printed forms of xs"
  (format nil "~{~a~}" xs))

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

(defun shuffle (lst &aux (v (coerce lst 'vector)))
  "Fisher-Yates, driven by the seeded rand"
  (loop for i from (1- (length v)) downto 1 do
    (rotatef (elt v i) (elt v (rint (1+ i)))))
  (coerce v 'list))

(defun few (lst k)
  "K items picked at random"
  (subseq (shuffle lst) 0 (min k (length lst))))

;;; ## Main
;;;  ._ _    _.  o  ._
;;;  | | |  (_|  |  | |

(defun egs (prefix)
  "Sorted fbound tiny-xai symbols starting with prefix"
  (sort (loop for s being the present-symbols
              of (find-package :tiny-xai)
              when (and (fboundp s)
                        (eql 0 (search prefix (string s)))
                        (not (member s '(eg--all eg--study))))
              collect s)
        #'string< :key #'string))

(defun args ()
  "Command-line args after the script name"
  #+sbcl  (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*)

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
                           :tiny-xai)))
          (when (fboundp fun)
            (setf *seed* (? *my* --seed))
            (funcall fun)))))))
