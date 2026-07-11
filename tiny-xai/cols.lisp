; vim: set lispwords+=loop,aif :
;;;; Update. `add` grows a column summary by one value:
;;;; `sym`s count, `num`s fold mu and m2 by Welford (w<0
;;;; removes). `adds` folds a whole list. (Tables route
;;;; rows to their columns in tbl.lisp.)

; Count v (weight w); return v
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
