; vim: set lispwords+=loop,aif :
;;;; Rebuild REPORT.md's stats over $MOOT/optimize.
;;;; Worker (one line of csv per dataset):
;;;;   sbcl --script report.lisp FILE.csv
;;;; Merge (histograms from the workers' lines):
;;;;   sbcl --script report.lisp --hist report.csv
;;;; Full sweep, 10-way parallel:
;;;;   ls $MOOT/optimize/*/*.csv | xargs -P 10 -I{} \
;;;;     sbcl --script report.lisp {} > report.csv
;;;;   sbcl --script report.lisp --hist report.csv

(unless (find-package :tiny-xai)
  (load (merge-pathnames "tiny-xai.lisp" *load-truename*)))
(in-package :tiny-xai)

(defun arm (tbl budget mode &aux out (w (wins tbl)))
  "One arm: 20 paired holdouts at one budget and mode"
  (setf (? *my* --budget) budget
        (? *my* --acquire) mode)
  (dotimes (k 20 out)
    (setf *seed* (+ (? *my* --seed) k))
    (push (funcall w (holdout tbl)) out)))

(defun report1 (file &aux (n (make-num)))
  "Five arms on one csv -> one comma-separated line"
  (setf (? *my* --file) file
        *seed* (? *my* --seed))
  (let ((tbl (make-tbl file)))
    (setf (? tbl rows) (few (? tbl rows) (? *my* --cap)))
    (let* ((a50  (arm tbl 50  "active"))
           (a20  (arm tbl 20  "active"))
           (a200 (arm tbl 200 "active"))
           (r50  (arm tbl 50  "random"))
           (r200 (arm tbl 200 "random")))
      (labels ((mu (l) (mid (adds l (make-num))))
               (d (a b) (if (same a b) 0
                            (- (mu a) (mu b)))))
        (format t "~a,~,2f,~,2f,~,2f,~,2f,~,2f~%"
                file (mu a50)
                (d a50 a20) (d a200 a50)
                (d a50 r50) (d a50 r200))))))

(defun hist (vals lo hi width &optional ties)
  "Percent + stars histogram (one * = 3 datasets)"
  (let ((n (length vals)))
    (labels ((row (label c)
               (format t "~a ~3d%~a~%" label
                       (round (* 100 c) n)
                       (if (zerop c) ""
                           (format nil " ~v@{*~}"
                                   (round c 3) t)))))
      (loop for b from lo below hi by width do
        (let* ((last (>= (+ b width) hi))
               (c (count-if
                    (lambda (v)
                      (and (<= b v)
                           (or (< v (+ b width))
                               (and last (= v hi)))
                           (not (and ties (zerop v)))))
                    vals)))
          (row (format nil "[~3d,~3d~a" b (+ b width)
                       (if last "]" ")")) c)
          (when (and ties (< b 0) (<= 0 (+ b width)))
            (row "   ties=0 "
                 (count-if #'zerop vals))))))))

(defun verdict (vals)
  "Wins/losses/ties line for one delta column"
  (format t "wins ~a  losses ~a  ties ~a  max ~,1f  min ~,1f~%"
          (count-if #'plusp vals) (count-if #'minusp vals)
          (count-if #'zerop vals)
          (reduce #'max vals) (reduce #'min vals)))

(defun hists (file &aux rows)
  "Read the workers' csv; print every histogram"
  (with-open-file (s file)
    (loop (aif (read-line s nil)
            (push (things it) rows)
            (return))))
  (labels ((col (k) (mapcar (lambda (r) (elt r k)) rows)))
    (format t "~a datasets~%" (length rows))
    (format t "~%RQ0: mu(win), active, budget 50~%")
    (hist (col 1) 0 100 10)
    (let ((v (sort (col 1) #'<)) (n (length rows)))
      (format t "quartiles: min ~a, q1 ~a, median ~a, ~
                 q3 ~a, max ~a~%"
              (round (elt v 0)) (round (elt v (floor n 4)))
              (round (elt v (floor n 2)))
              (round (elt v (floor (* 3 n) 4)))
              (round (elt v (1- n)))))
    (format t "~%RQ1: mu(win@50) - mu(win@20), active~%")
    (hist (col 2) -15 30 5 t) (verdict (col 2))
    (format t "~%RQ1b: mu(win@200) - mu(win@50), active~%")
    (hist (col 3) -30 30 5 t) (verdict (col 3))
    (format t "~%RQ2: mu(win(active)) - mu(win(random)), ~
               budget 50~%")
    (hist (col 4) -15 30 5 t) (verdict (col 4))
    (format t "~%RQ2b: mu(win(active@50)) - ~
               mu(win(random@200))~%")
    (hist (col 5) -30 30 5 t) (verdict (col 5))))

(eval-when (:execute)
  (let ((a (args)))
    (if (equal (first a) "--hist")
        (hists (second a))
        (report1 (first a)))))
