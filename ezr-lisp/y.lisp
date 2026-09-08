;;;; ezr.lisp: multi-objective active learning. MIT.
;;;; usage: sbcl --script ezr.lisp [:flag val ..] csv
#+sbcl (declaim (sb-ext:muffle-conditions style-warning))
(defvar *the*
  (list :p 2 :start 4 :stop 24 :few 128 :m 1 :k 2 :leaf 8
        :repeats 20
        :file
        (namestring (merge-pathnames
                     "gits/moot/optimize/misc/auto93.csv"
                     (user-homedir-pathname)))
        :kfile
        (namestring (merge-pathnames
                     "gits/moot/classify/diabetes.csv"
                     (user-homedir-pathname)))))
(defun the? (x) (getf *the* x))

(defstruct (col (:conc-name nil))
  txt (at 0) (n 0) (mu 0) (m2 0) (lo 1d30) (hi -1d30)
  (w 1) (has (make-hash-table :test #'equal)) num)

(defstruct (data (:conc-name nil)) cols x y klass rows (nr 0))

(defun add (c v &optional (inc 1) &aux (d 0))
  (unless (equal v "?")
    (incf (n c) inc)
    (cond
      ((not (num c)) (incf (gethash v (has c) 0) inc))
      (t (setf d (- v (mu c)))
         (incf (mu c) (* inc (/ d (max 1 (n c)))))
         (incf (m2 c) (* inc d (- v (mu c))))
         (setf (lo c) (min v (lo c))
               (hi c) (max v (hi c)))))))

(defun adds (d row &optional (inc 1))
  (incf (nr d) inc)
  (if (plusp inc)
      (push row (rows d))
      (setf (rows d)
            (remove row (rows d) :count 1 :test #'eq)))
  (mapc (lambda (c v) (add c v inc)) (cols d) row)
  row)

(defun sd (c)
  (if (< (n c) 2) 0
      (sqrt (/ (max 0 (m2 c)) (- (n c) 1)))))

(defun mid (c &aux (bn -1) bk)
  "Num: mean. Sym: mode"
  (if (num c) (mu c)
      (progn (maphash (lambda (k v)
                        (when (> v bn) (setf bk k bn v)))
                      (has c))
             bk)))

(defun col-of (xs &optional (fy #'identity) nump
               &aux (c (make-col :num nump)))
  "One col summarizing (fy x) over xs"
  (dolist (x xs c) (add c (funcall fy x))))

(defun norm (c v
             &aux (z (/ (- v (mu c)) (+ 1d-32 (sd c)))))
  (/ 1 (+ 1 (exp (* -1.7 (max -3 (min 3 z)))))))


; -------------------------------------------------------
;;;; data: tables, distances

(defun new-cols (d names &aux (at -1))
  (loop for s in names collect
    (let* ((z (char s (1- (length s))))
           (c (make-col :txt s :at (incf at)
                        :w (if (eql z #\-) -1 1)
                        :num (upper-case-p (char s 0)))))
      (cond ((eql z #\X))
            ((eql z #\!) (setf (klass d) c))
            ((find z "+-") (push c (y d)))
            (t (push c (x d))))
      c)))

(defun new-data (src &aux (d (make-data)))
  (dolist (row src d)
    (if (cols d)
        (adds d row)
        (setf (cols d) (new-cols d row)))))

(defun clone (d &optional rows)
  (new-data (cons (mapcar #'txt (cols d)) rows)))

(defun ydist (d row &aux (p (the? :p)))
  (expt (/ (loop for c in (y d) sum
             (expt (abs (- (norm c (nth (at c) row))
                           (if (< (w c) 0) 0 1)))
                   p))
           (length (y d)))
        (/ 1.0 p)))

(defun ysort (d rows &optional flip)
  (sort (copy-list rows) (if flip #'> #'<)
        :key (lambda (r) (ydist d r))))

(defun ymu (d rows)
  (/ (loop for r in rows sum (ydist d r)) (length rows)))

(defun ymids (d rows)
  "Mean raw value of each y col over rows"
  (loop for c in (y d) collect
    (/ (loop for r in rows
             for v = (nth (at c) r)
             unless (equal v "?") sum v)
       (length rows))))

; -------------------------------------------------------
;;;; bayes: pdf, likelihoods, active learning

(defun pdf (c v &aux (s (+ 1d-32 (sd c))))
  (/ (exp (- (/ (expt (- v (mu c)) 2) (* 2 s s))))
     (* 2.5066 s)))

(defun like (c v &optional (prior 0))
  "Likelihood of value v in one col"
  (if (num c)
      (pdf c v)
      (/ (+ (gethash v (has c) 0) (* (the? :m) prior))
         (+ (n c) (the? :m)))))

(defun likes (d row nall nh
              &aux (prior (/ (+ (nr d) (the? :k))
                             (+ nall (* (the? :k) nh)))))
  "Log-likelihood of row in one table"
  (+ (log prior)
     (loop for c in (x d) for v = (nth (at c) row)
           unless (equal v "?")
           sum (log (max 1d-32 (like c v prior))))))

(defun liked (row datas)
  "Table that most likes row"
  (let ((nall (loop for d in datas sum (nr d))))
    (first (sort (copy-list datas) #'> :key
                 (lambda (d)
                   (likes d row nall (length datas)))))))

(defun guess (d best rest todo
              &aux (all (nr d))
                   (few (min (length todo) (the? :few))))
  "Reorder todo: first few sorted most-promising-first"
  (append (sort (subseq todo 0 few) #'> :key
                (lambda (r) (- (likes best r all 2)
                               (likes rest r all 2))))
          (nthcdr few todo)))

(defun label (d best rest row
              &aux (k (isqrt (+ 1 (nr best) (nr rest)))))
  "Row joins best (sorted worst-first); spill to rest"
  (adds best row)
  (setf (rows best) (ysort d (rows best) t))
  (when (> (nr best) k)
    (adds rest (adds best (first (rows best)) -1))))

(defun acquire (d &aux (best (clone d)) (rest (clone d))
                     (all (shuffle (rows d))) todo)
  (setf todo (subseq all (the? :start)))
  (dolist (row (subseq all 0 (the? :start)))
    (label d best rest row))
  (loop while
        (and todo
             (< (+ (nr best) (nr rest)) (the? :stop)))
        do (setf todo (guess d best rest todo))
           (label d best rest (pop todo)))
  (append (reverse (rows best)) (rows rest)))

; -------------------------------------------------------
;;;; tree: min-variance splits over labeled rows

(defun div (c)
  "Num: sd. Sym: entropy"
  (if (num c)
      (sd c)
      (loop for k being the hash-values of (has c)
            for p = (/ k (n c))
            when (plusp p)
            sum (* p (log (/ 1 p) 2)))))

(defun xpect (a b &aux (n2 (+ (n a) (n b) 1d-32)))
  (/ (+ (* (div a) (n a)) (* (div b) (n b))) n2))

(defun best-cut (&aux best)
  "Closure: feed it (score col v); no args = winner"
  (lambda (&optional s c v)
    (when (and s (or (null best) (< s (first best))))
      (setf best (list s c v)))
    best))

(defun cuts-num (c xy keep nump
                 &aux (lhs (make-col :num nump))
                      (tot (make-col :num nump)))
  "One sweep, rhs = shrinking tot; offer cuts to keep"
  (setf xy (sort xy #'< :key #'car))
  (dolist (p xy) (add tot (cdr p)))
  (loop for (a b) on xy do
    (add lhs (cdr a))
    (add tot (cdr a) -1)
    (when (and b (/= (car a) (car b)))
      (funcall keep (xpect lhs tot) c (car a)))))

(defun cuts-sym (c xy keep nump)
  "Yes side = one symbol; offer each split to keep"
  (dolist (v (remove-duplicates (mapcar #'car xy)
                                :test #'equal))
    (let ((lhs (make-col :num nump))
          (rhs (make-col :num nump)))
      (dolist (p xy)
        (add (if (equal (car p) v) lhs rhs) (cdr p)))
      (funcall keep (xpect lhs rhs) c v))))

(defun cut (d rows fy nump &aux (keep (best-cut)) xy)
  "Lowest-diversity (score col v) over all x cols"
  (dolist (c (x d) (funcall keep))
    (setf xy (loop for r in rows
                   unless (equal (nth (at c) r) "?")
                   collect (cons (nth (at c) r)
                                 (funcall fy r))))
    (if (num c)
        (cuts-num c xy keep nump)
        (cuts-sym c xy keep nump))))

(defun selects? (c v row &aux (xv (nth (at c) row)))
  (or (equal xv "?")
      (if (num c) (<= xv v) (equal xv v))))

(defun grow (d rows &optional (edge "")
                    (fy (lambda (r) (ydist d r))) (nump t)
             &aux yes no
             (z (and (> (length rows) (the? :leaf))
                     (cut d rows fy nump)))
             (c (second z)) (v (third z))
             (my (mid (col-of rows fy nump)))
             (ys (and nump (ymids d rows))))
  "Min-diversity splits; nested (edge n mid ys c v . kids)"
  (when z
    (dolist (r rows)
      (if (selects? c v r) (push r yes) (push r no)))
    (when (and yes no)
      (return-from grow
        (list edge (length rows) my ys c v
              (grow d yes (format nil "~a ~a ~a" (txt c)
                            (if (num c) "<=" "==") v)
                    fy nump)
              (grow d no  (format nil "~a ~a ~a" (txt c)
                            (if (num c) ">" "!=") v)
                    fy nump)))))
  (list edge (length rows) my ys nil nil))

(defun leaf (node row &aux (kids (nthcdr 6 node)))
  "Walk row to its leaf; (third leaf) is its prediction"
  (if kids
      (leaf (if (selects? (fifth node) (sixth node) row)
                (first kids)
                (second kids))
            row)
      node))

; -------------------------------------------------------
;;;; klass: tree and bayes classifiers, paired trials

(defun ktree (d rows &aux (kat (at (klass d))) tr)
  "Learner: klass tree; returns row -> predicted klass"
  (setf tr (grow d rows ""
                 (lambda (r) (nth kat r)) nil))
  (lambda (row) (third (leaf tr row))))

(defun klassed (d rows &aux out)
  "Alist of (klass-value . clone holding its rows)"
  (dolist (r rows out)
    (let* ((k (nth (at (klass d)) r))
           (p (or (assoc k out :test #'equal)
                  (car (push (cons k (clone d)) out)))))
      (adds (cdr p) r))))

(defun kbayes (d rows &aux (models (klassed d rows))
                           (nall (length rows))
                           (nh (length models)))
  "Learner: naive bayes; returns row -> predicted klass"
  (lambda (row)
    (car (first
          (sort (copy-list models) #'> :key
                (lambda (p)
                  (likes (cdr p) row nall nh)))))))

(defun klassify (d makers
                 &optional (repeats (the? :repeats))
                 &aux (kat (at (klass d)))
                      (accs (mapcar (constantly nil)
                                    makers)))
  "Shared shuffles/splits; per maker, list of accuracies"
  (dotimes (i repeats accs)
    (let* ((rows (shuffle (rows d)))
           (n2 (floor (* 2 (length rows)) 3))
           (train (subseq rows 0 n2))
           (test (nthcdr n2 rows)))
      (loop for m in makers for j from 0
            for f = (funcall m d train) do
        (push (/ (loop for r in test count
                   (equal (funcall f r) (nth kat r)))
                 (length test) 1.0)
              (nth j accs))))))

; -------------------------------------------------------
;;;; stats: are two samples of numbers the same?

(defun cohen? (xs ys &optional (dd 0.35)
               &aux (a (col-of xs #'identity t))
                    (b (col-of ys #'identity t)) s)
  "Mean gap small, in pooled sd units"
  (setf s (sqrt (/ (+ (* (1- (n a)) (expt (sd a) 2))
                      (* (1- (n b)) (expt (sd b) 2)))
                   (max 1 (+ (n a) (n b) -2)))))
  (<= (abs (- (mu a) (mu b))) (* dd s)))

(defun cliffs? (xs ys &optional (dd 0.197)
                &aux (gt 0) (lt 0) (j 0) (k 0)
                     (v (coerce ys 'vector))
                     (m (length ys)))
  "Sorted xs ys: rank imbalance below threshold?"
  (dolist (x xs)
    (loop while (and (< j m) (< (aref v j) x))
          do (incf j) (setf k j))
    (loop while (and (< k m) (<= (aref v k) x))
          do (incf k))
    (incf gt j) (incf lt (- m k)))
  (<= (/ (abs (- gt lt)) (* (length xs) m)) dd))

(defun ks? (xs ys &optional (aa 1.36)
            &aux (n1 (length xs)) (m (length ys))
                 (vx (coerce xs 'vector))
                 (vy (coerce ys 'vector))
                 (i 0) (j 0) (dd 0))
  "Sorted xs ys: 95% kolmogorov-smirnov"
  (loop while (and (< i n1) (< j m)) do
    (let ((v (min (aref vx i) (aref vy j))))
      (loop while (and (< i n1) (<= (aref vx i) v))
            do (incf i))
      (loop while (and (< j m) (<= (aref vy j) v))
            do (incf j))
      (setf dd (max dd (abs (- (/ i n1) (/ j m)))))))
  (<= dd (* aa (sqrt (/ (+ n1 m) (* n1 m))))))

(defun same? (xs ys
              &aux (sx (sort (copy-list xs) #'<))
                   (sy (sort (copy-list ys) #'<)))
  "Same by all three tests"
  (and (cliffs? sx sy) (ks? sx sy) (cohen? sx sy)))

(defun main (f &aux (d (new-data (csv f)))
                    (lab (acquire d)))
  (format t "~a n=~a mid=~,3f ezr=~,3f~%" f (nr d)
          (ymu d (rows d)) (ydist d (first lab)))
  (show d (grow d lab)))

; -------------------------------------------------------
;;;; lib: portability, argv, csv parsing, misc

#+clisp
(ext:without-package-lock ("SYSTEM")
  (setf system::*inhibit-floating-point-underflow* t
        custom:*floating-point-contagion-ansi* t))

; Tiny errors: one line, no debugger dump
#+sbcl
(setf sb-ext:*invoke-debugger-hook*
      (lambda (c old)
        (declare (ignore old))
        (format *error-output* "!! ~a~%" c)
        (sb-ext:exit :code 1)))

; Command-line args, no runtime junk
(defun args ()
  #+sbcl (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*)

; String --> number, else string; full parse only
(defun thing (s)
  (multiple-value-bind (x i)
      (ignore-errors (read-from-string s nil s))
    (if (and (numberp x) (eql i (length s))) x s)))

; Comma-separated line --> list of things
(defun cells (s &aux (j (position #\, s)))
  (if j
      (cons (thing (subseq s 0 j))
            (cells (subseq s (1+ j))))
      (list (thing s))))

; Csv file --> list of rows
(defun csv (f)
  (with-open-file (s f)
    (loop for r = (read-line s nil)
          while r collect (cells r))))

; Non-mutating Fisher-Yates
(defun shuffle (l &aux (v (coerce l 'vector)))
  (loop for i from (1- (length v)) downto 1
        do (rotatef (aref v i) (aref v (random (1+ i)))))
  (coerce v 'list))

; Indented print of nested (edge n mu . kids) lists
(defun leafs (node &aux (kids (nthcdr 6 node)))
  (if kids (mapcan #'leafs kids) (list node)))

(defun show (d tree
             &aux (ls (sort (leafs tree) #'<
                            :key #'third))
                  (top (first ls))
                  (bot (first (last ls))))
  "Tree with y-col mids per node; +/- = best/worst leaf"
  (format t "~a" "  d2h   n")
  (dolist (c (y d)) (format t " ~5@a" (txt c)))
  (terpri)
  (labels
    ((walk (node pre)
       (destructuring-bind
             (edge sz mu ys c v &rest kids) node
         (declare (ignore c v))
         (format t "~a ~3d ~3d"
                 (cond ((eq node top) "+")
                       ((eq node bot) "-")
                       (t " "))
                 (round (* 100 mu)) sz)
         (dolist (v ys) (format t " ~5d" (round v)))
         (format t "   ~a~a~%" (or pre "") edge)
         (dolist (k kids)
           (walk k (if pre
                       (concatenate 'string pre "|  ")
                       ""))))))
    (walk tree nil)))

; -------------------------------------------------------
;;;; start-up

(defun --help (&aux fns)
  "Show usage, settings, demos"
  (format t "usage: y.lisp [:k v | --demo | csv]..~%")
  (loop for (k v) on *the* by #'cddr
        do (format t "  ~(~s~) = ~a~%" k v))
  (do-symbols (s)
    (when (and (eql 0 (search "--" (string s)))
               (fboundp s))
      (pushnew s fns)))
  (dolist (s (sort fns #'string<))
    (format t "  ~(~a~)  ~a~%" s
            (or (documentation s 'function) ""))))

(defun --the () "Show settings" (print *the*))

(defun --csv (&aux (rows (csv (the? :file))))
  "Row count and first data row"
  (format t "rows ~a~%~a~%" (length rows) (second rows)))

(defun --data (&aux (d (new-data (csv (the? :file)))))
  "Per-goal mu and sd"
  (dolist (c (y d))
    (format t "~a n ~a mu ~,2f sd ~,2f~%"
            (txt c) (n c) (mu c) (sd c))))

(defun --acquire (&aux (d (new-data (csv (the? :file)))))
  "Best labeled row's ydist, spending :stop labels"
  (format t "ezr ~,3f~%" (ydist d (first (acquire d)))))

(defun --tree () "Acquire, grow, show tree"
  (main (the? :file)))

(defun musd (xs &aux (c (col-of xs #'identity t)))
  (values (mu c) (sd c)))

(defun --klass (&aux (d (new-data (csv (the? :kfile))))
                     (accs (first (klassify d (list #'ktree)))))
  "Klass-tree acc over :repeats splits; returns the accs"
  (multiple-value-bind (m s) (musd accs)
    (format t "tree acc mu ~,2f sd ~,2f~%" m s))
  accs)

(defun --klass2 (&aux (d (new-data (csv (the? :kfile)))))
  "Tree vs bayes accs, same splits: same or different?"
  (destructuring-bind (ta ba)
      (klassify d (list #'ktree #'kbayes))
    (multiple-value-bind (m1 s1) (musd ta)
      (multiple-value-bind (m2 s2) (musd ba)
        (format t "tree ~,2f (~,2f) bayes ~,2f (~,2f) : ~a~%"
                m1 s1 m2 s2
                (if (same? ta ba) "same" "different"))))))

(defun cli (&aux (args (args)) (*read-eval* nil))
  "':k v' sets *the*; '--fn' calls that defun; else csv"
  (loop while args do
    (let* ((f (pop args))
           (fn (find-symbol (string-upcase f))))
      (cond ((eql 0 (search "--" f))
             (when (and fn (fboundp fn)) (funcall fn)))
            ((eql (char f 0) #\:)
             (setf (getf *the* (read-from-string f))
                   (thing (pop args))))
            (t (main f))))))

(cli)

;`(shuffle)` uses `random` off the global state, so runs
; repeat unless you (setf *random-state*
; (make-random-state t)) — that is why my three test
; runs gave identical numbers.
