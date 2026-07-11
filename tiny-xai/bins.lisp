; vim: set lispwords+=loop,aif :
;;;; Bins. `split` finds the single cheapest bin over all x
;;;; cols; cost is the size-weighted `spread` of the two
;;;; halves (the far half computed by `minus`, not a second
;;;; pass). Numeric bins come from exact sorted split
;;;; points, never fixed-width approximations.
;;;; `keep-best-bin` is a closure holding the running best;
;;;; `has-p` says which side a row falls on (? = yes).

; Row value w on the yes-side of bin v? (? = yes)
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
