; vim: set lispwords+=loop,aif :
;;;; Distances. `minkowski` is the p-norm skeleton; missing
;;;; cells are skipped. `disty` reads only y columns:
;;;; distance to the ideal goals (0 = heaven); `*label*` is
;;;; the hook where live models compute y on demand (see
;;;; dtlz.lisp). `gap` scores one x value pair and serves
;;;; only `distx`, the distance over x columns.

; P-norm of (fun col cell) over cols; missing cells skipped
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
