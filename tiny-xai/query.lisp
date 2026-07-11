; vim: set lispwords+=loop,aif :
;;;; Query. Questions for summaries. `mid` = central
;;;; tendency (mean or mode); `spread` = dispersion (sd or
;;;; entropy); `norm` maps a num onto 0..1 by a logistic
;;;; z-score; `minus` = summary of i's data without j's --
;;;; bin scoring depends on it.

; Central tendency of a num
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
