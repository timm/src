; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for landscape.lisp: the active
;;;; learner.

#|
## The active learner

The payoff. `landscape` labels a handful of rows, projects
the rest onto a line between two distant labelled poles
(good end, bad end), culls the third nearest the bad pole,
and repeats -- spending at most --budget labels. Notice the
best labelled row: found after ~45 labels, it is the kind
of car that floated to the top back when we (expensively)
scored all 398.

| call | returns | what |
|------|---------|------|
| `(landscape tbl)` | rows | labelled few, best first |
|#

(defun eg--land (&aux (i (make-tbl (? *my* --file))))
  "Landscape labels few rows, sorted best first"
  (let* ((lab (landscape i))
         (ys  (mapcar (lambda (r) (disty i r)) lab)))
    (format t "~&labelled ~a best ~,3f worst ~,3f~%"
            (length lab) (first ys) (car (last ys)))
    (format t "~&best labelled row:")
    (print (first lab))
    (assert (<= (length lab)
                (- (? *my* --budget) (? *my* --check))))
    (assert (equal ys (sort (copy-list ys) #'<)))
    (assert (< (first ys) 0.4))))
