; vim: set lispwords+=loop,aif :
;;;; Construction. Tables are born here. `make-cols` reads
;;;; roles from the header (uppercase = num; -,+,! = goals;
;;;; X = skip); `make-tbl` streams rows from a csv file or
;;;; a list, its `add` routing each cell to its column;
;;;; `clone` reuses one table's header over other rows.

; Columns from header names; fill all, x, y
(defun make-cols (names &optional (i (%make-cols :names names)))
  (loop for s across names for at from 0 do
    (let* ((a (char s 0))
           (z (char s (1- (length s))))
           (col (if (upper-case-p a)
                    (make-num :at at :txt s)
                    (make-sym :at at :txt s))))
      (push col $all)
      (cond ((find z "-+!")
             (when (eql z #\-) (setf (? col w) 0))
             (push col $y))
            ((not (eql z #\X)) (push col $x)))))
  (setf $all (nreverse $all) $x (nreverse $x) $y (nreverse $y))
  i)

; Table from a csv file name or a list of rows
(defun make-tbl (&optional src &aux (i (%make-tbl)))
  (labels ((inc (row) (add i row)))
    (if (stringp src)
        (mapcsv #'inc src)
        (mapc #'inc src))
    i))

; Fresh tbl over a subset of rows
(defun clone (tbl rows)
  (make-tbl (cons (? tbl cols names) rows)))

; First row makes cols; later rows update them
(defmethod add ((i tbl) row &optional (w 1))
  (if $cols
      (dolist (col (? $cols all) (push row $rows))
        (let ((v (elt row (? col at))))
          (unless (eq v '?) (add col v w))))
      (setf $cols (make-cols row)))
  row)
