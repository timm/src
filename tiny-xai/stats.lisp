; vim: set lispwords+=loop,aif :
;;;; Stats. `same` is a conservative equality: `cohen` AND
;;;; `cliffs` AND `ks` must all agree before two result
;;;; sets are called equal, so later "X beats Y" claims
;;;; mean something.

; Cliff's delta effect size, 0..1 (0 = identical)
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
