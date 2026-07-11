; vim: set lispwords+=loop,aif :
;;;; Unit tests (eg--*) and experiment sweeps (study--*) for
;;;; tiny-xai (library lives in tiny-xai.lisp). Run by flag:
;;;;   sbcl --script tiny-xai-eg.lisp --all --study --tree
;;;; Under ASDF, load system "tiny-xai/eg" instead; the guard
;;;; below skips the load and the eval-when never fires.

(unless (find-package :tiny-xai)
  (load (merge-pathnames "tiny-xai.lisp" *load-truename*)))

(in-package :tiny-xai)

;;; ## Unit tests
;;;   _    _    _
;;;  (/_  (_|  _>
;;;        _|

(defun eg--my ()
  "Print the settings"
  (format t "~&~s~%" *my*)
  (assert (settings-p *my*)))

(defun eg--thing ()
  "String coercion round-trip"
  (let ((got (mapcar #'thing '(" 23 " "3.14" "-1e2"
                               "?" "True" "False" "abc"))))
    (print got)
    (assert (equal got '(23 3.14 -100.0 ? t nil "abc")))))

(defun eg--rand (&aux a b)
  "Seeded rand is deterministic and in (0,1)"
  (setf *seed* 1 a (rand)
        *seed* 1 b (rand))
  (format t "~&rand ~,3f rint ~a~%" a (rint 10))
  (assert (= a b))
  (assert (< 0 a 1)))

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

;;; ## Studies
;;;   _  _|_        _|  o   _    _
;;;  _>   |_  |_|  (_|  |  (/_  _>

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

;;; ## Runners
;;;  ._        ._   ._    _  ._
;;;  |   |_|   | |  | |  (/_  |

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
