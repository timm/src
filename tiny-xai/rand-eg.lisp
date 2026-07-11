; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for rand.lisp: reproducible
;;;; randomness.

#|
## Reproducible randomness

Later demos shuffle and sample, so first: `rand`, a seeded
16807 Lehmer generator that repeats exactly on sbcl and
clisp (Common Lisp's own `random` does not). The second
check sums three uniforms 10,000 times (Irwin-Hall): mean
lands on 0, sd on 1 -- testing `rand`, `add`, and Welford
in one shot.

| call | returns | what |
|------|---------|------|
| `(rand n)` | float 0..n | next seeded random |
| `(rint n)` | int 0..n-1 | random integer |
| `(add i v)` | v | Welford-update num i |
|#

(defun eg--rand (&aux a b (i (make-num)))
  "Seeded rand repeats; 10k Irwin-Hall -> mean 0, sd 1"
  (setf *seed* 1 a (rand)
        *seed* 1 b (rand))
  (format t "~&rand ~,3f ~,3f rint ~a~%" a b (rint 10))
  (assert (= a b))
  (assert (< 0 a 1))
  (dotimes (k 10000)
    (add i (/ (- (+ (rand) (rand) (rand)) 1.5) 0.5)))
  (format t "~&irwin-hall mu ~,3f sd ~,3f~%"
          (mid i) (spread i))
  (assert (< (abs (mid i)) 0.05))
  (assert (< (abs (- (spread i) 1)) 0.05)))
