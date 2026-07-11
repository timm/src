; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for cols.lisp: symbolic columns.

#|
## Symbolic columns

Lowercase header names (like origin) make `sym` columns:
things we can only count and compare. First a case tiny
enough to check by eye, then the table's own origin column.
Notice entropy: high when counts are even, low when one
value dominates.

| call | returns | what |
|------|---------|------|
| `(add i v)` | v | count v into sym i |
| `(mid i)` | symbol | the mode |
| `(spread i)` | float | entropy of the counts |
|#

(defun eg--sym (&aux (i (make-sym)))
  "Sym mode and entropy: tiny case, then a real column"
  (dolist (v '(a a a a b b c)) (add i v))
  (format t "~&(a a a a b b c): mid ~a ent ~,3f~%"
          (mid i) (spread i))
  (assert (eq (mid i) 'a))
  (assert (< (abs (- (spread i) 1.379)) 0.01))
  (let* ((d (make-tbl (? *my* --file)))
         (origin (find "origin" (? d cols all)
                       :key (lambda (c) (? c txt))
                       :test #'equal)))
    (when origin
      (format t "origin: mid ~a ent ~,3f~%"
              (mid origin) (spread origin)))))
