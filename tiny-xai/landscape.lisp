; vim: set lispwords+=loop,aif :
;;;; Landscape sampling. The active learner. `active`
;;;; labels a few rows, sorts the pool by `project`-ion
;;;; onto the line joining two distant labelled poles,
;;;; culls the third nearest the bad pole, repeats.
;;;; `landscape` caps it at budget-check labels and returns
;;;; them best-first.

; Row -> position on the east-west line (x=dist, y=goal)
(defun project (rows x y)
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

; Label <= budget-check rows, best first
(defun landscape (tbl)
  (labels ((y (r)   (disty tbl r))
           (x (a b) (distx tbl a b)))
    (let ((cap  (- (? *my* --budget) (? *my* --check)))
          (rows (shuffle (? tbl rows))))
      (sort (if (equal (? *my* --landscape) "random")
                (subseq rows 0 (min cap (length rows)))
                (active rows cap #'x #'y))
            #'< :key #'y))))

; Label pool heads; cull pool's bad third; repeat
(defun active (pool cap x y &aux lab)
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
