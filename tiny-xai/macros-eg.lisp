; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for macros.lisp: one accessor,
;;;; three spellings.

#|
## Little accessors

Everything else leans on one idea: `ats` reads hash keys
and struct slots alike, `?` nests it, `ats!` fills a
missing key on first touch, and `aif` remembers its test
as `it`. Notice `?` walking two levels in one call.

| call | returns | what |
|------|---------|------|
| `(ats x k)` | value | hash key or struct slot |
| `(? x k1 k2 ..)` | value | nested ats |
| `(ats! x k new)` | value | get, else stash fresh (new) |
| `(aif test then else)` | -- | `it` = the test value |
|#

(defun eg--macros (&aux (h (o "a" 1 "b" (o "c" 2))))
  "Hash/slot access: o, ats, ats!, ?, aif"
  (setf (ats h "d") 3)
  (format t "~&a ~a b.c ~a d ~a seed ~a~%"
          (ats h "a") (? h "b" "c") (ats h "d")
          (? *my* --seed))
  (assert (= 1 (ats h "a")))
  (assert (= 2 (? h "b" "c")))
  (assert (= 3 (ats h "d")))
  (assert (= 4 (ats! h "e" (lambda () 4))))
  (assert (= 4 (ats h "e")))
  (assert (numberp (? *my* --seed)))
  (assert (eq 'yes (aif (+ 1 2) (and (= it 3) 'yes)))))
