# rig.lisp

{% raw %}
```text
rig.lisp : the keys pipeline over nfr5.lisp; port of run.py.
  sbcl --script rig.lisp MODEL.lisp NAME
MODEL.lisp holds (<- h body) clauses plus *hard* and *soft*.
Sample n1 worlds with hard goals gated, take the best by
distance-to-heaven, shrink its settable labels by unanimity
filter then Zeller ddmin, assess with n2 replays.
Constants match run.py: n1 1000, n2 30, eps .05, z0 2.
Per-run state lives in specials so every function stays small.
```

```lisp
(load (merge-pathnames "nfr5.lisp" *load-truename*))

(defvar *n1* 1000)   (defvar *n2* 30)     (defvar *eps* .05)
(defvar *hard* nil)  (defvar *soft* nil)  ; set by the model file
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
  (loop for w in ws
        for (b f) = (multiple-value-list (bf w))
        minimize b into b0 maximize b into b1
        minimize f into f0 maximize f into f1
        finally (setf *mm* (list b0 b1 f0 f1))))

(defun d2h (w)
  (multiple-value-bind (b f) (bf w)
    (sqrt (/ (+ (expt (- 1 (nrm (first *mm*) (second *mm*) b)) 2)
                (expt (nrm (third *mm*) (fourth *mm*) f) 2))
             2))))

;;; ---- reduce and assess a seed -------------------------------
(defun replays (seed)
  (mapcar #'d2h (sample *query* :beliefs seed :replay t :n *n2*)))

(defun passes (seed &aux (ds (replays seed)))
  (incf *tests*)
  (and ds (<= (mu ds) (+ *dbest* *eps*))))

(defun pool (wbest)
  "settable labels of the best world"
  (loop for x being the hash-keys of wbest using (hash-value v)
        when (member x *settable*) collect (cons x v)))

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
(defun gated () (loop for h in *hard* append (list h `(= ,h t))))

(defun rig (name)
  (statics)
  (setf *query* (append (gated) (list (cons 'and *soft*)))
        *tests* 0)
  (let* ((ws    (sample *query* :n *n1*))
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
    (format t "~a,~a,~a,~a,~d,~d,~d,~d,~d~%"
            name (lomu ds) (lomu rb) (lomu (replays seed))
            (length pool) (length same) (length seed) *tests*
            (pc (/ (length seed) (length *mention*))))))

(let ((args sb-ext:*posix-argv*))
  (load (first (last args 2)))
  (setf *seed* 1)
  (rig (car (last args))))
```

{% endraw %}