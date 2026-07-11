; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for stats.lisp: when do two results
;;;; differ?

#|
## When do two results differ?

One tool before any experiment: `same` calls two lists of
numbers equal only if `cohen` AND `cliffs` AND `ks` all
agree. Take 20 disty scores from our table: they equal
themselves, survive a 0.02 nudge, and differ after a +1
shift. Notice how conservative this is -- tiny changes are
treated as noise, so later "X beats Y" claims mean
something.

| call | returns | what |
|------|---------|------|
| `(same xs ys)` | t or nil | t iff cohen+cliffs+ks agree |
|#

(defun eg--same (&aux (i (make-tbl (? *my* --file))) xs)
  "Same: true for a nudge, false for a shift"
  (setf xs (mapcar (lambda (r) (disty i r))
                   (few (? i rows) 20)))
  (let ((ys (mapcar (lambda (x) (+ x 0.02)) xs))
        (zs (mapcar (lambda (x) (+ x 1)) xs)))
    (format t
      "~&same: self ~a nudged(+.02) ~a shifted(+1) ~a~%"
      (same xs xs) (same xs ys) (same xs zs))
    (assert (same xs xs))
    (assert (same xs ys))
    (assert (not (same xs zs)))))
