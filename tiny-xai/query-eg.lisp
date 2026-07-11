; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for query.lisp: numeric columns.

#|
## Numeric columns

Uppercase names (like Mpg+) make `num` columns: things we
can average. Folding all 398 Mpg cells one at a time
(Welford's trick: no list kept, just n, mu, m2) gives the
column's mean and standard deviation. Notice: the average
1970s car did about 24 mpg.

| call | returns | what |
|------|---------|------|
| `(make-tbl file)` | tbl | rows + column summaries |
| `(mid i)` | float | mean of num i |
| `(spread i)` | float | standard deviation |
|#

(defun eg--num (&aux (i (make-tbl (? *my* --file))))
  "Fold one num column; watch mu and sd emerge"
  (let ((mpg (car (last (? i cols y)))))
    (format t "~&~a: n ~a mu ~,2f sd ~,2f~%"
            (? mpg txt) (? mpg n) (mid mpg) (spread mpg))
    (when (search "auto93" (? *my* --file))
      (assert (< (abs (- (mid mpg) 23.84)) 0.1))
      (assert (< (abs (- (spread mpg) 8.34)) 0.1)))))
