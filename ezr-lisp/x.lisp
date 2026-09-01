; vim: set lispwords+=loop,aif :

(defvar *help+* "
xaiplus: learners and optimizers layered on xai
(c) 2026 Tim Menzies <timm@ieee.org>, MIT license

USAGE: sbcl --script xaiplus-eg.lisp [--key val ..] [--run ..]

OPTIONS (added to xai's; never shadowing its flags):")
; Extra knobs; slots are flags, as in xai's settings
(defstruct (settings (:conc-name))
  (--knn 3)      ; neighbors for the knn classifier
  (--kluster 8)  ; clusters for kmeans / kmeans++
  (--iter 10)    ; kmeans passes
  (--few 128)    ; sample pool for kmeans++ seeding
  (--k 1)        ; naive-bayes laplace smoothing
  (--m 2)        ; naive-bayes m-estimate prior weight
  (--wait 10)    ; rows seen before naive bayes scores
  (--f 0.5)      ; DE extrapolation factor
  (--cr 0.3)     ; DE crossover rate
  (--np 20)      ; DE/GA population size
  (--gens 20)    ; DE/GA generations
  (--tour 5)     ; GA tournament size
  (--budget1 300); SA/LS eval budget
  (--restart 40) ; LS restart-on-stagnation gap
  (--start 20))  ; acquire warm-start labels

(defvar *my* (make-settings))

#+sbcl (setf *debugger-hook*
	     (lambda (c old) (declare (ignore old))
	       (format *error-output* "!! ~a~%" c)
	       (sb-ext:exit :code 1)))

#+sbcl (defun args () (cdr sb-ext:*posix-argv*))
#+sbcl (defun slot-names (x)
	 (mapcar #'sb-mop:slot-definition-name
		 (sb-mop:class-slots (class-of x))))

#+clisp (defun args () ext:*args*)
#+clisp (defun slot-names (x)
	  (mapcar #'clos:slot-definition-name
		  (clos:class-slots (class-of x))))

(defun thing (s &aux (*read-eval* nil))
  (let ((x (ignore-errors (read-from-string s nil nil))))
    (cond ((numberp x)         x)
          ((member x '(t nil)) x)
          (t                   s))))

(defvar *eg* nil)

(defmacro defdemo (name args &body body)
  `(progn (defun ,name ,args (setf *seed* (-seed *my*)) ,@body)
	  (push (cons ,(string-downcase name) #',name) *eg*)))

(defmacro aif (test then &optional else)
  `(let ((it ,test)) (if it ,then ,else)))

(defun cli (&aux (args (argv)))
  "Call eg functions; set *my* slots from matching --flags"
  (loop for (f v) on args do
	(aif (assoc f *eg* :test #'string=)
	     (funcall (cdr it))
	     (dolist (slot (slot-names *my*))
	       (when (equalp f (string slot))
		 (setf (slot-value *my* slot) (thing v)))))))

(defdemo -h ()
  "Print xai's help, then the extra options"
  (help)
  (format t "~a~%" *help*)
  (dolist (s (slot-names *my*))
    (format t "  ~(~a~) ~a~%" s (ats *my* s))))

(cli)
(print *my*)
