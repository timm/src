; vim: set lispwords+=loop,aif :
;;;; Acquire labels. `sway3` is the active learner: label a
;;;; few rows off the good end, project the pool onto the
;;;; line joining two poles (far rows at first; on later
;;;; passes the best and worst labels so far), keep the
;;;; keepf slice nearest the good pole, repeat; when the
;;;; pool runs dry with budget unspent, redo on a fresh
;;;; shuffle, labels accumulating across passes.

; Row -> position on the east-west line (x=dist, y=goal);
; poles default to two far rows, else the given anchors
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
