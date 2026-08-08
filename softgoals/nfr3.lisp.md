# nfr3.lisp

{% raw %}
```text
nfr3.lisp : nfr3.pl said in lisp. Same bet -- the model
is data, a tiny compiler turns each head into something
callable -- but lisp already owns the two tricks prolog
sweated for. The compiler is one SETF of SYMBOL-FUNCTION
per node (so a model IS a set of functions; typos are
undefined-function errors, the world is closed). ISAMP
replaces backtracking outright: a contradiction THROWs,
the world restarts fresh -- nfr3's greedy flag is the
only mode here. Beliefs live in one special var, no DCG
threading. Labels 2 1 0 -1 -2; pending loop values are
boxes guessed at combine time (restart = retry guess).
```

```lisp
(defvar *m* (make-hash-table))  ; head -> list of bodies
(defvar *b* ())                 ; beliefs: (node . val|box)

(defmacro <-- (head &rest bodies)
  `(setf (gethash ',head *m*)
         (append (gethash ',head *m*) ',bodies)))

(defun fail! () (throw 'fail nil))
(defun pick (xs) (elt xs (random (length xs))))
(defun shuffled (xs &aux (v (coerce xs 'vector)))
  (loop for i downfrom (1- (length v)) to 1
        do (rotatef (aref v i) (aref v (random (1+ i)))))
  (coerce v 'list))

;; ---- beliefs; a box is a pending (looping) value ---------
(defun recall (k)  (cdr (assoc k *b*)))
(defun learn (k v) (push (cons k v) *b*) v)
(defun box ()      (list :?))
(defun boxp (e)    (and (consp e) (eq (car e) :?)))
(defun unbox (v)   (if (boxp v) (cadr v) v))

;; demand: agree with what is known, else fill it, else die.
(defun demand (v want)
  (cond ((null want) v)
        ((boxp v) (if (cdr v)
                      (if (= (cadr v) want) want (fail!))
                      (progn (setf (cdr v) (list want))
                             want)))
        ((= v want) v)
        (t (fail!))))

;; recall k, else assume: leaves get random +-2 (the stagger)
(defun maybe (k want)
  (let ((v (recall k)))
    (if v (demand v want)
        (learn k (or want (pick '(2 -2)))))))

;; ---- the three node species, as closures -----------------
(defun stub-fn (k)                       ; leaf
  (lambda (&optional want) (maybe k want)))

(defun rule-fn (k bodies)                ; choice-or: pick one
  (lambda (&optional want)               ; body, walk it; only
    (let ((v (recall k)))                ; ever proves 2
      (cond (v (demand v want))
            ((eql want -2) (fail!))      ; falsity is assumed,
            (t (learn k 2)               ; never derived
               (mapc #'lit (shuffled (pick bodies)))
               2)))))

(defun edge-fn (k contribs)              ; label ALL contribs,
  (lambda (&optional want)               ; combine; a demand is
    (let ((v (recall k)))                ; assumed, not derived
      (cond (v (demand v want))          ; (nfr2 guess parity)
            (want (learn k want))
            (t (combine (learn k (box))
                        (mapcar #'contrib
                                (shuffled contribs))))))))

(defun lit (l)                           ; hard body literal
  (if (consp l) (maybe (cadr l) -2) (funcall l 2)))

(defun contrib (e)                       ; soft contribution ->
  (if (atom e) (funcall e)               ; symbolic value tree
      (destructuring-bind (op x . xs) e
        (ecase op
          (no     (maybe x -2))
          (makes  (funcall x))
          (breaks `(neg  ,(funcall x)))
          (helps  `(damp ,(funcall x)))
          (hurts  `(neg (damp ,(funcall x))))
          (and `(amin ,@(mapcar #'contrib (cons x xs))))
          (or  `(amax ,@(mapcar #'contrib (cons x xs))))))))

;; ---- ground the pending boxes, then fold the algebra -----
(defun pends (e)
  (cond ((boxp e) (unless (cdr e) (list e)))
        ((consp e) (mapcan #'pends e))))

(defun evalx (e)
  (cond ((numberp e) e)
        ((boxp e) (cadr e))
        (t (let ((w (mapcar #'evalx (cdr e))))
             (ecase (car e)
               (neg  (- (first w)))
               (damp (max -1 (min 1 (first w))))
               (amin (reduce #'min w))
               (amax (reduce #'max w)))))))

(defun combine (b vs)
  (let ((ps (delete-duplicates (pends vs) :test #'eq)))
    (dolist (p ps)                       ; big cyclic cluster:
      (setf (cdr p)                      ; punt to undecided
            (list (if (> (length ps) 3) 0
                      (pick '(2 1 0 -1 -2))))))
    (let* ((ws (mapcar #'evalx vs))
           (hi (reduce #'max ws :initial-value 0))
           (lo (reduce #'min ws :initial-value 0)))
      (when (and (= hi 2) (= lo -2)) (fail!))
      (demand b (+ hi lo)))))            ; closes self-loops:
                                         ; guess must equal it
;; ---- compiler: functions all the way down ----------------
(defun hardp (b)
  (every (lambda (l) (or (atom l) (eq (car l) 'no))) b))

(defun refs (e)
  (cond ((atom e) (list e))
        ((member (car e) '(and or)) (mapcan #'refs (cdr e)))
        (t (list (cadr e)))))

(defun compile-model ()
  (let ((ks (loop for k being the hash-keys of *m*
                  collect k)))
    (dolist (k ks)
      (let* ((bs (gethash k *m*))
             (hs (remove-if-not #'hardp bs)))
        (setf (symbol-function k)
              (if hs (rule-fn k hs)      ; any all-hard body:
                  (edge-fn k             ; rules win, edges die
                           (reduce #'append bs))))))
    (dolist (x (set-difference
                (remove-duplicates
                 (loop for bs being the hash-values of *m*
                       nconc (loop for b in bs
                                   nconc (mapcan #'refs b))))
                ks))
      (setf (symbol-function x) (stub-fn x)))))

;; ---- top: a world is one catch, 100 restarts max ---------
(defmacro world (&body form)
  `(loop repeat 100
         do (catch 'fail
              (return (let ((*b* ())) ,@form)))))

(defun picks ()
  (sort (loop for (k . v) in *b*
              unless (gethash k *m*)
                collect (case (unbox v)
                          ( 2 k)
                          (-2 `(no ,k))
                          (t `(lab ,k ,(unbox v)))))
        #'string< :key #'princ-to-string))

(defun abduce (g) (world (funcall g 2) (picks)))
(defun soften (g)
  (world (let ((v (funcall g))) (list (unbox v) (picks)))))

(defun worlds (n f)                      ; sample n, distinct
  (sort (delete-duplicates
         (delete nil (loop repeat n collect (funcall f)))
         :test #'equal)
        #'string< :key #'princ-to-string))

;; ---- eg: the nfr3-eg.pl graphs, one arrow, body shapes ---
(<-- happy (rich))
(<-- happy (loved (no lonely)))
(<-- rich  (works lucky))
(<-- loved (friends))
(<-- friends (happy))          ; loop
(<-- g (p q))
(<-- p (x))
(<-- q ((no x)))               ; needs x and (no x): no worlds
(<-- performance ((helps indexing) (hurts logging)))
(<-- security    ((makes encryption) (hurts indexing)))
(<-- usability   ((breaks encryption) (helps gui)))
(<-- good  ((and performance security usability)))
(<-- trust ((helps good) (makes trust)))  ; self loop
(<-- hard-goals (happy))
(<-- soft-goals ((or performance security usability)))

(defun eg ()
  (setf *random-state* (make-random-state t))
  (compile-model)
  (flet ((w (n g) (worlds n (lambda () (abduce g)))))
    (format t "happy ~a~%" (w 300 'happy))
    (format t "g     ~a~%" (w 100 'g))
    (format t "hard  ~a~%" (w 300 'hard-goals)))
  (let ((ws (worlds 600 (lambda () (soften 'good)))))
    (format t "good  ~a worlds, best ~a~%" (length ws)
            (first (sort (copy-list ws) #'> :key #'first))))
  (format t "trust ~a~%"
          (sort (delete-duplicates
                 (loop repeat 300
                       collect (first (soften 'trust))))
                #'<)))
(eg)
```

{% endraw %}