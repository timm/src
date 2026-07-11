; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for tbl.lisp: the whole table.

#|
## The whole table

`make-tbl` streams the csv once: the first row builds one
column summary per header name (trailing `-` or `+` = goal
to minimize or maximize; trailing `X` = ignore), and later
rows update them. Notice the goals: minimize Lbs-, maximize
Acc+ and Mpg+ -- light, quick, thrifty cars win.

| call | returns | what |
|------|---------|------|
| `(make-tbl src)` | tbl | src = file name or rows |
| `(mid col)` | value | mean or mode |
| `(spread col)` | float | sd or entropy |
|#

(defun eg--tbl (&aux (i (make-tbl (? *my* --file))))
  "Tbl build: col roles and goal stats"
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
