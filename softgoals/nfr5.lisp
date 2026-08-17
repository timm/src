; vim: set lispwords+=loop :
;;;; nfr5.lisp : world sampler for goal models; port of infer.py.
;;;; Bodies are plain sexprs -- the reader is the parser:
;;;;   (and ...) shuffled conjunction   (or ...)  commit to one
;;;;   (= x t)   demand (chk or add)    (helps x) weighted link
;;;;   (seq ...) ordered: (seq x (= x t)) derives then insists
;;;;   bare atom label it, never a demand
;;;; (<- head body) records a clause on the head symbol plist.
;;;; Worlds are hash tables; undo is a trail. (An alist world
;;;; was tried and retired: free snapshots, but O(n) reads made
;;;; the replay-heavy keys pipeline 6x slower.) RNG is the
;;;; house park-miller 16807, seedable via *seed*.
(defvar *links* '((makes t) (breaks f) (helps t t f) (hurts f f t)))
(defvar *replay* nil)
(defvar *heads* nil)
(defvar *seed*  1)
(defvar *trail* nil)

(defmacro <- (head body)
  `(progn (pushnew ',head *heads*)
          (setf (get ',head 'rules)
                (append (get ',head 'rules) (list ',body)))))

(defun prand ()
  (/ (setf *seed* (mod (* 16807 *seed*) 2147483647)) 2147483647d0))
(defun rint (n) (floor (* n (prand))))
(defun pick (xs) (nth (rint (length xs)) xs))

(defun shuffled (xs &aux (v (coerce xs 'vector)))
  (loop for i from (1- (length v)) downto 1
        do (rotatef (aref v i) (aref v (rint (1+ i)))))
  (coerce v 'list))

(defun syms (g)
  (cond ((symbolp g)                (list g))
        ((member (car g) '(and or seq)) (mapcan #'syms (copy-list (cdr g))))
        (t                          (list (second g)))))

(defun believed (g w) (every (lambda (a) (nth-value 1 (gethash a w))) (syms g)))

(defun believe (x v w)
  (multiple-value-bind (old got) (gethash x w)
    (if got (eq old v)
        (progn (setf (gethash x w) v) (push x *trail*) t))))

(defun derive (g w)
  (let ((mark *trail*))
    (setf (gethash g w) 't) (push g *trail*)
    (or (isamp (pick (get g 'rules)) w)
        (progn (loop until (eq *trail* mark)
                     do (remhash (pop *trail*) w))
               (setf (gethash g w) 'f) (push g *trail*)
               t))))

(defun isamp (g w)
  (cond
    ((and *replay* (or (symbolp g) (not (eq (car g) '=))) (believed g w)) t)
    ((symbolp g)
     (cond ((nth-value 1 (gethash g w)) t)
           ((get g 'rules) (derive g w))
           (t (setf (gethash g w) 't) (push g *trail*) t)))
    ((eq (car g) '=)   (believe (second g) (third g) w))
    ((eq (car g) 'seq) (every (lambda (x) (isamp x w)) (cdr g)))
    ((eq (car g) 'and) (every (lambda (x) (isamp x w)) (shuffled (cdr g))))
    ((eq (car g) 'or)  (if (and *replay*
                                (some (lambda (x) (believed x w)) (cdr g)))
                           t
                           (isamp (pick (cdr g)) w)))
    ((assoc (car g) *links*)
     (believe (second g) (pick (cdr (assoc (car g) *links*))) w))
    (t nil)))

(defun sample (query &key beliefs replay (n 20) (patience 1000))
  (let ((*replay* replay) worlds (got 0) (miss 0))
    (loop while (and (< got n) (< miss patience))
          do (let ((w (make-hash-table :test 'eq)) (*trail* nil))
               (loop for (x . v) in beliefs do (setf (gethash x w) v))
               (if (every (lambda (g) (isamp g w)) query)
                   (progn (setf miss 0) (incf got) (push w worlds))
                   (incf miss))))
    (nreverse worlds)))
