# rig7.lisp

{% raw %}
```text
rig7.lisp : the keys pipeline over nfr7.lisp (truth walk:
isamp = achieved?). Otherwise rig6.lisp verbatim.
  sbcl --script rig7.lisp MODEL.lisp NAME
```

```lisp
(load (merge-pathnames "nfr7.lisp" *load-truename*))

(defvar *n1* 1000)   (defvar *n2* 30)     (defvar *eps* .05)
(defvar *mention* nil) (defvar *quals* nil) (defvar *leaves* nil)
(defvar *settable* nil)                   ; set by statics
(defvar *query* nil) (defvar *mm* nil)    ; set by rig
(defvar *dbest* 0)   (defvar *tests* 0)

;;; ---- statics: what the clause shapes give away --------------
(defun subforms (g)
  (if (and (consp g) (member (car g) '(and or seq)))
      (cons g (mapcan #'subforms (copy-list (cdr g))))
      (list g)))

(defun bodies () (loop for h in *heads* append (get h 'rules)))

(defun linkp (g) (and (consp g) (assoc (car g) *links*)))
(defun orp (g)   (and (consp g) (eq (car g) 'or)))

(defun statics (&aux (gs (mapcan #'subforms (bodies))))
  (setf *mention*  (remove-duplicates
                    (append (mapcan #'syms (bodies)) *heads* *hard*
                            (mapcan #'syms (copy-list *soft*))))
        *quals*    (set-difference
                    (remove-duplicates
                     (mapcar #'second (remove-if-not #'linkp gs)))
                    *heads*)
        *leaves*   (set-difference
                    (set-difference *mention* *heads*) *quals*)
        *settable* (union (set-difference *mention* *heads*)
                          (loop for g in gs when (orp g)
                                append (loop for x in (cdr g) collect (if (atom x) x (car (syms x))))))))

;;; ---- scoring ------------------------------------------------
(defun tp (x w)  (eq (gethash x w) 't))
(defun mu (ds)   (/ (reduce #'+ ds) (length ds)))
(defun sd (ds &aux (m (mu ds)))
  (sqrt (/ (loop for d in ds sum (expt (- d m) 2)) (length ds))))
(defun nrm (lo hi x) (if (<= hi lo) .5 (/ (- x lo) (- hi lo))))
(defun pc (x)    (round (* 100 x)))

(defun lomu (ds)   ; one group of the report: lo, mu (sd)
  (if ds
      (format nil "~d,~d (~d)"
              (pc (reduce #'min ds)) (pc (mu ds)) (pc (sd ds)))
      "-,-"))

(defun bf (w)
  "benefit = qualities won; footprint = leaves bought"
  (values (count-if (lambda (q) (tp q w)) *quals*)
          (count-if (lambda (l) (tp l w)) *leaves*)))

(defun yardstick (ws)
  "absolute scale 0..|quals|, 0..|leaves|: fiat play compresses
   the sampled spread to ~1 leaf, so sampled min/max explodes
   the norm of any out-of-distribution replay"
  (declare (ignore ws))
  (setf *mm* (list 0 (length *quals*) 0 (length *leaves*))))

(defun d2h (w)
  (multiple-value-bind (b f) (bf w)
    (sqrt (/ (+ (expt (- 1 (nrm (first *mm*) (second *mm*) b)) 2)
                (expt (nrm (third *mm*) (fourth *mm*) f) 2))
             2))))

;;; ---- reduce and assess a seed -------------------------------
(defun replays (seed)
  (mapcar #'d2h (sample *query* :beliefs seed :try *soft* :n *n2*)))

(defun passes (seed &aux (ds (replays seed)))
  (incf *tests*)
  (and ds (<= (mu ds) (+ *dbest* *eps*))))

(defun pool (wbest)
  "settable labels of the best world; denial of a defined atom
   is a conclusion, not a choice: skip it"
  (loop for x being the hash-keys of wbest using (hash-value v)
        when (and (member x *settable*)
                  (not (and (eq v 'f) (get x 'rules))))
        collect (cons x v)))

(defun shared (pool ws)
  "the unanimous subset: every world agrees, so forced not chosen"
  (loop for (x . v) in pool
        when (every (lambda (w) (eq (gethash x w) v)) ws)
        collect (cons x v)))

(defun ddmin (test c n)   ; Zeller; z0 2, zup x2, zdn -1
  (if (= (length c) 1) c
    (let* ((sz (max 1 (ceiling (length c) n)))
           (chunks (loop for i from 0 below (length c) by sz
                         collect (subseq c i (min (length c) (+ i sz))))))
      (or (loop for ch in chunks
                when (funcall test ch) return (ddmin test ch 2))
          (loop for ch in chunks
                for rest = (set-difference c ch :test #'equal)
                when (and rest (funcall test rest))
                return (ddmin test rest (max (- n 1) 2)))
          (if (< n (length c))
              (ddmin test c (min (length c) (* 2 n)))
              c)))))

;;; ---- the pipeline -------------------------------------------
(defun ourkeys ()
  "b4 sample, pool/shared/cands, rebaseline, ddmin: the rig core"
  (statics)
  (setf *query* (copy-list *hard*)
        *tests* 0)
  (let* ((ws    (sample *query* :try *soft* :n *n1*))
         (ds    (progn (yardstick ws) (mapcar #'d2h ws)))
         (wbest (nth (position (setf *dbest* (reduce #'min ds)) ds) ws))
         (pool  (pool wbest))
         (same  (shared pool ws))
         (cands (set-difference pool same :test #'equal))
         (rb    (replays cands))   ; rebaseline: ddmin's target is what
         (seed  (cond (cands       ; the FULL set scores under replay
                       (when rb (setf *dbest* (mu rb)))
                       (ddmin #'passes cands 2))
                      (t '()))))
    (values seed ds rb pool same)))

(defun rig (name &aux (t0 (get-internal-real-time)))
  (multiple-value-bind (seed ds rb pool same) (ourkeys)
    (format t "~a,~a,~a,~a,~d,~d,~d,~d,~d,~d~%"
            name (lomu ds) (lomu rb) (lomu (replays seed))
            (length pool) (length same) (length seed) *tests*
            (pc (/ (length seed) (length *mention*)))
            (round (- (get-internal-real-time) t0)
                   (/ internal-time-units-per-second 1000)))))

;;; ---- stats: are two d2h samples the same? -------------------
(defun cliffs (xs ys &optional (d 0.197)) ; sorted: rank imbalance
  (let ((gt 0) (lt 0) (j 0) (k 0)
        (m (length ys)) (v (coerce ys 'vector)))
    (dolist (x xs)
      (loop while (and (< j m) (< (aref v j) x)) do (incf j) (setf k j))
      (loop while (and (< k m) (<= (aref v k) x)) do (incf k))
      (incf gt j) (incf lt (- m k)))
    (<= (/ (abs (- gt lt)) (* (length xs) m)) d)))

(defun ks (xs ys &optional (a 1.36)) ; sorted: 95% kolmogorov-smirnov
  (let ((n (length xs)) (m (length ys)) (i 0) (j 0) (d 0)
        (vx (coerce xs 'vector)) (vy (coerce ys 'vector)))
    (loop while (and (< i n) (< j m)) do
      (let ((v (min (aref vx i) (aref vy j))))
        (loop while (and (< i n) (<= (aref vx i) v)) do (incf i))
        (loop while (and (< j m) (<= (aref vy j) v)) do (incf j))
        (setf d (max d (abs (- (/ i n) (/ j m)))))))
    (<= d (* a (sqrt (/ (+ n m) (* n m)))))))

;;; ---- rivals: our keys vs asp-min keys, one replay engine ----
(defun rivals (name asp &aux (t0 (get-internal-real-time)))
  "battery on 30x replays of both key sets; cohen eps = .35 sd(b4);
   win by lo (keys chase the best world), mu printed beside it"
  (multiple-value-bind (seed ds) (ourkeys)
    (let* ((msours (round (- (get-internal-real-time) t0)
                          (/ internal-time-units-per-second 1000)))
           (xs  (replays seed))
           (ys  (replays asp)))
      (when (or (null xs) (null ys))  ; a seed can kill every world
        (format t "~a,~a,~a,~d,~d,-,-,-,DEAD,~a,~d~%"
                name (lomu xs) (lomu ys) (length seed) (length asp)
                (if ys "asp" "ours") msours)
        (return-from rivals))
      (let* ((sx  (sort (copy-list xs) #'<))
           (sy  (sort (copy-list ys) #'<))
           (co  (<= (abs (- (mu xs) (mu ys))) (* 0.35 (sd ds))))
           (cl  (cliffs sx sy))
           (kk  (ks sx sy))
           (tie (and co cl kk)))
      (format t "~a,~a,~a,~d,~d,~a,~a,~a,~a,~a,~d~%"
              name (lomu xs) (lomu ys) (length seed) (length asp)
              (if cl "y" "n") (if kk "y" "n") (if co "y" "n")
              (if tie "SAME" "DIFF")
              (cond (tie "tie")
                    ((< (car sx) (car sy)) "ours")
                    ((> (car sx) (car sy)) "asp")
                    (t "tie"))
              msours)))))

(let ((args (cdr sb-ext:*posix-argv*)))   ; --script strips itself
  (destructuring-bind (model name &optional keys seed) args
    (load model)
    (reseed (if seed (parse-integer seed) 1))
    (if keys
        (rivals name (with-open-file (s keys) (read s)))
        (rig name))))
```

{% endraw %}