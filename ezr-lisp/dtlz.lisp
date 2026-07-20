; vim: set lispwords+=loop,aif :
;;;; Drive xai with an EXTERNAL MODEL instead of a CSV.
;;;; The DTLZ1-7 benchmarks are live models: a row's x-values
;;;; are decision variables; its goals are computed on demand
;;;; via the *label* hook. This is how an outside user plugs
;;;; their own (expensive) model into xai.
;;;;
;;;;   sbcl --script dtlz.lisp              # dtlz2
;;;;   sbcl --script dtlz.lisp --model dtlz7
;;;;   sbcl --script dtlz.lisp --model all --M 3 --N 8
;;;; Under ASDF, load the "xai/dtlz" system instead;
;;;; the guard below skips the load; eval-when never fires.

(unless (find-package :xai)
  (load (merge-pathnames "xai.lisp" *load-truename*)))
(in-package :xai)


;;; ## Models

;;;; Each maps x in [0,1]^N to M objectives to MINIMIZE.
;;;; The last N-M+1 x's form the "distance" group xm; the
;;;; rest shape the front.

(defun g1 (xm)
  "Multi-modal distance: many local optima"
  (* 100 (+ (length xm)
            (loop for v in xm
                  sum (- (expt (- v .5) 2)
                         (cos (* 20 pi (- v .5))))))))

(defun g2 (xm)
  "Unimodal distance: sum of squares off 0.5"
  (loop for v in xm sum (expt (- v .5) 2)))

(defun g6 (xm)
  "Biased distance: tenth roots"
  (loop for v in xm sum (expt v 0.1)))

(defun sphere (m g th)
  "Cos/sin product front shared by dtlz2-6"
  (loop for i below m
        collect (let ((v (+ 1 g)))
                  (dotimes (j (- m 1 i))
                    (setf v (* v (cos (elt th j)))))
                  (when (plusp i)
                    (setf v (* v (sin (elt th (- m 1 i))))))
                  v)))

(defun dtlz1 (x m)
  "Linear front (sum fi = 0.5)"
  (let ((g (g1 (nthcdr (1- m) x))))
    (loop for i below m
          collect (let ((v (* 0.5 (+ 1 g))))
                    (dotimes (j (- m 1 i))
                      (setf v (* v (elt x j))))
                    (when (plusp i)
                      (setf v (* v (- 1 (elt x (- m 1 i))))))
                    v))))

(defun half-pi-thetas (x m &optional (p 1))
  "First m-1 x's scaled onto [0,pi/2], optionally biased"
  (loop for v in (subseq x 0 (1- m))
        collect (* (expt v p) (/ pi 2))))

(defun dtlz2 (x m)
  "Spherical front"
  (sphere m (g2 (nthcdr (1- m) x)) (half-pi-thetas x m)))

(defun dtlz3 (x m)
  "Spherical front, multi-modal distance"
  (sphere m (g1 (nthcdr (1- m) x)) (half-pi-thetas x m)))

(defun dtlz4 (x m)
  "Spherical front, biased density"
  (sphere m (g2 (nthcdr (1- m) x)) (half-pi-thetas x m 100)))

(defun degen (x m g)
  "Dtlz5/6 theta remap onto a degenerate curve"
  (sphere m g
          (cons (* (first x) (/ pi 2))
                (loop for i from 1 below (1- m)
                      collect (* (/ pi (* 4 (+ 1 g)))
                                 (+ 1 (* 2 g (elt x i))))))))

(defun dtlz5 (x m)
  "Degenerate curve front"
  (degen x m (g2 (nthcdr (1- m) x))))

(defun dtlz6 (x m)
  "Degenerate curve front, biased distance"
  (degen x m (g6 (nthcdr (1- m) x))))

(defun dtlz7 (x m)
  "Disconnected front"
  (let* ((k (- (length x) m -1))
         (g (+ 1 (* (/ 9 k) (loop for v in (nthcdr (1- m) x)
                                  sum v))))
         (f (subseq x 0 (1- m)))
         (h (- m (loop for fi in f
                       sum (* (/ fi (+ 1 g))
                              (+ 1 (sin (* 3 pi fi))))))))
    (append f (list (* (+ 1 g) h)))))

(defvar *models* '(dtlz1 dtlz2 dtlz3 dtlz4 dtlz5 dtlz6 dtlz7))


;;; ## Seam
;;; The pool and the label seam.

(defun opt (flag default)
  "Value after `flag` on the command line, else default"
  (aif (member flag (args) :test #'equal)
    (thing (second it))
    default))

(defun fresh-pool (n nn mm)
  "N rows: random decision vars, goals unknown"
  (loop repeat n
        collect (coerce (append (loop repeat nn collect (rand))
                                (make-list mm :initial-element
                                              '?))
                        'vector)))

(defun labeller (tbl model nn mm)
  "Closure for *label*: run the model, fold goals into cols"
  (lambda (row)
    (when (find '? row)
      (let ((x (coerce (subseq row 0 nn) 'list)))
        (loop for v in (funcall model x mm)
              for at from nn do
          (setf (elt row at) v)
          (add (col-at tbl at) v))))
    row))

(defun instance (tbl row nn win)
  "Print one row: decision vars, objectives, disty, win"
  (format t "  x ~{ ~5,2f~}~%" (coerce (subseq row 0 nn)
                                       'list))
  (format t "  f ~{ ~6,3f~}   (disty ~,3f, win ~a; ~a)~%"
          (coerce (subseq row nn) 'list)
          (disty tbl row)
          (round (funcall win row))
          "100=best 0=median"))


;;; ## Driver
;;; Drive one model.

(defun names (nn mm)
  "Header: X1..Xn decision vars, F1-..Fm- minimize goals"
  (coerce (append (loop for i from 1 to nn
                        collect (format nil "X~a" i))
                  (loop for i from 1 to mm
                        collect (format nil "F~a-" i)))
          'vector))

(defun oracle (model nn mm)
  "Wins grader from a fresh, fully labelled pool"
  (setf *seed* (? *my* --seed))
  (let* ((tbl (make-tbl (cons (names nn mm)
                              (fresh-pool 1000 nn mm))))
         (*label* (labeller tbl model nn mm)))
    (mapc *label* (? tbl rows))
    (wins tbl)))

(defun run-model (name nn mm &aux (model (symbol-function
                                           name)))
  "Landscape + tree + holdout, goals computed on demand"
  (format t "~&~%model ~(~a~)   N=~a x-vars   M=~a goals~%"
          name nn mm)
  (let ((win (oracle model nn mm)))
    (setf *seed* (? *my* --seed))
    (let* ((tbl (make-tbl (cons (names nn mm)
                                (fresh-pool 1000 nn mm))))
           (*label* (labeller tbl model nn mm))
           (got (acquire tbl)))
      (format t "~&best option found (one instance):~%")
      (instance tbl (first got) nn win)
      (format t "~&why? which x-ranges reach good goals:~%")
      (show tbl (tree tbl got
                      (lambda (r) (disty tbl r))))
      (setf *seed* (? *my* --seed))
      (let* ((tbl (make-tbl (cons (names nn mm)
                                  (fresh-pool 1000 nn mm))))
             (*label* (labeller tbl model nn mm)))
        (format t "~&does it generalize? best on unseen data:~%")
        (instance tbl (holdout tbl) nn win)))))

(eval-when (:execute)
  (let ((name (opt "--model" "dtlz2"))
        (nn   (opt "--N" 6))
        (mm   (opt "--M" 2)))
    (setf (? *my* --budget) 100)
    (dolist (m (if (equal name "all")
                   *models*
                   (list (intern (string-upcase name)
                                 :xai))))
      (run-model m nn mm))))
