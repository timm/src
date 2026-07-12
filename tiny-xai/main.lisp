; vim: set lispwords+=loop,aif :
;;;; Main. `wins` grades any row: 100 = equals the best,
;;;; 0 = no better than median. `holdout` is the evaluation
;;;; rig: budgeted train, tree-ranked test. `slot-names`
;;;; and `egs` are the introspection: demos are found by
;;;; name, so the eg files register nothing here. `cli`
;;;; maps --flags onto `settings` slots then runs the named
;;;; eg--/study-- functions; `help` prints everything.

; Grader: row -> % of gap to best closed, [-100,100]
(defun wins (tbl)
  (let* ((ys (sort (mapcar (lambda (r) (disty tbl r))
                           (? tbl rows))
                   #'<))
         (lo (first ys))
         (b4 (elt ys (floor (length ys) 2))))
    (lambda (r)
      (max -100 (min 100 (* 100
        (- 1 (/ (- (disty tbl r) lo)
                (+ (- b4 lo) +tiny+)))))))))

; Budget rig: acquire train -> tree -> best test row
(defun holdout (tbl)
  (labels ((y (r) (disty tbl r)))
    (let* ((rows  (shuffle (? tbl rows)))
           (half  (floor (length rows) 2))
           (train (subseq rows 0 half))
           (test  (nthcdr half rows))
           (got   (acquire (clone tbl train)))
           (tr    (tree tbl got #'y)))
      (argmin #'y
              (subseq (sort test #'<
                            :key (lambda (r) (leaf tbl tr r)))
                      0 (? *my* --check))))))

; Slot names of a struct instance or type
(defun slot-names (x)
  (mapcar #+sbcl  #'sb-mop:slot-definition-name
          #+clisp #'clos:slot-definition-name
          (#+sbcl  sb-mop:class-slots
           #+clisp clos:class-slots
           (find-class (if (symbolp x) x (type-of x))))))

; Sorted fbound tiny-xai symbols starting with prefix
(defun egs (prefix)
  (sort (loop for s being the present-symbols
              of (find-package :tiny-xai)
              when (and (fboundp s)
                        (eql 0 (search prefix (string s)))
                        (not (member s '(eg--all eg--study))))
              collect s)
        #'string< :key #'string))

; Command-line args after the script name
(defun args ()
  #+sbcl  (cdr sb-ext:*posix-argv*)
  #+clisp ext:*args*)

; Print options (with defaults), tests, studies
(defun help ()
  (format t "~a~%~%OPTIONS:~%" *help*)
  (dolist (s (slot-names *my*))
    (format t "  ~(~a~) ~a~%" s (ats *my* s)))
  (format t "~%TESTS: (run by flag, e.g. --tree)~%")
  (dolist (s (egs "EG--"))
    (format t "  ~(~a~)~26t~a~%" (subseq (string s) 2)
            (documentation s 'function)))
  (format t "~%STUDIES:~%")
  (dolist (s (egs "STUDY--"))
    (format t "  ~(~a~)~26t~a~%" (subseq (string s) 5)
            (documentation s 'function))))

; Set settings slots from flags, then run named tests
(defun cli (*my*)
  (let ((args (args)))
    (loop for (f v) on args do
      (dolist (slot (slot-names *my*))
        (when (equalp f (string slot))
          (setf (slot-value *my* slot) (thing v)))))
    (loop for s in args do
      (dolist (pre '("EG" "STUDY"))
        (let ((fun (intern (format nil "~a~:@(~a~)" pre s)
                           :tiny-xai)))
          (when (fboundp fun)
            (setf *seed* (? *my* --seed))
            (funcall fun)))))))
