; vim: set lispwords+=loop,aif :
;;;; Random and picking. Ways to pick from a list: `shuffle`
;;;; (Fisher-Yates) and `few` pick at random, driven by
;;;; `rand` -- a seeded 16807 Lehmer generator so runs
;;;; reproduce across sbcl and clisp; `argmin`/`argmax`
;;;; pick by score.

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
