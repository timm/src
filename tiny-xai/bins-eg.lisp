; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for bins.lisp: explaining, one bin.

#|
## Explaining: one bin

Why are the good cars good? `split` tries one bin per x
column and keeps the cheapest, where cost is the
size-weighted spread of the two halves. The assert: the
best bin beats the unsplit spread, else explanation would
be hopeless. Notice the winner reads like something a
mechanic would say: small engines differ from big ones.

| call | returns | what |
|------|---------|------|
| `(split tbl rows y)` | (cost at v) | cheapest single bin |
|#

(defun eg--bins (&aux (i (make-tbl (? *my* --file))))
  "Best single bin beats the unsplit spread"
  (let* ((rows (? i rows))
         (goal (car (last (? i cols y))))
         (best (split i rows
                      (lambda (r) (elt r (? goal at))))))
    (format t "~&best ~,2f at ~a v ~a (sd ~,2f)~%"
            (first best)
            (? (elt (? i cols all) (second best)) txt)
            (third best) (spread goal))
    (assert (< (first best) (spread goal)))
    (when (search "auto93" (? *my* --file))
      (assert (eql (third best) 183)))))
