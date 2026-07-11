; vim: set lispwords+=loop,aif,set-macro-character :
;;;; One accessor, three spellings. The function `ats` reads
;;;; hash keys and struct slots alike; the macro `?` nests
;;;; it, as in (? tbl cols x); inside methods the `$slot`
;;;; reader macro abbreviates (ats i 'slot). `(setf ats)`
;;;; writes either; `ats!` fills a missing key on first
;;;; touch. Two conveniences: `aif` binds `it` to its test
;;;; value; `o` makes a fresh equal hash, optionally primed.
;;;; Loaded before all other files so `$` is live when
;;;; their code is read.

; Nested slot/hash access: (? tbl cols x)
(defmacro ? (x k &rest ks)
  (if ks `(? (ats ,x ',k) ,@ks) `(ats ,x ',k)))

; $slot reads as (ats i 'slot); users of $ must bind `i`
(eval-when (:compile-toplevel :load-toplevel :execute)
  (set-macro-character #\$
    (lambda (stream ch)
      (declare (ignore ch)) `(ats i ',(read stream t nil t)))))

; Get k from a hash (default d) or a struct slot
(defun ats (x k &optional d)
  (if (hash-table-p x) (gethash k x d) (slot-value x k)))

; Set k in a hash or a struct slot
(defun (setf ats) (v x k &optional d)
  (declare (ignore d))
  (if (hash-table-p x)
      (setf (gethash k x) v)
      (setf (slot-value x k) v)))

; Get x's k, else stash and return a fresh (new)
(defun ats! (x k new)
  (or (ats x k) (setf (ats x k) (funcall new))))

; Anaphoric if: `it` holds the test value
(defmacro aif (test then &optional else)
  `(let ((it ,test))
     (if it ,then ,else)))

; Fresh equal hash-table, optionally primed with k v pairs
(defun o (&rest kvs)
  (let ((h (make-hash-table :test #'equal)))
    (loop for (k v) on kvs by #'cddr do (setf (gethash k h) v))
    h))
