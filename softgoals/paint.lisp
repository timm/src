; vim: set lispwords+=loop :
;;;; paint.lisp : print a model annotated with one sampled world:
;;;; atom/t (won), atom/f (denied), bare atom (unseen). Plain
;;;; ascii; pipe through sed for color (see Makefile `paint`).
;;;;   sbcl --script paint.lisp MODEL.lisp [SEED]

(load (merge-pathnames "nfr5.lisp" *load-truename*))
(defvar *hard* nil) (defvar *soft* nil)

(defun tag (x w)
  (case (gethash x w)
    ((t)       (format nil "~c[32m~(~a~)/t~c[0m" #\Esc x #\Esc))
    ((f)       (format nil "~c[31m~(~a~)/f~c[0m" #\Esc x #\Esc))
    (otherwise (format nil "~(~a~)" x))))

(defun pp (g w)
  (cond ((symbolp g) (tag g w))
        ((member (car g) '(and or seq))
         (format nil "(~(~a~)~{ ~a~})" (car g)
                 (mapcar (lambda (x) (pp x w)) (cdr g))))
        ((eq (car g) '=)
         (format nil "(= ~a ~(~a~))" (tag (second g) w) (third g)))
        (t (format nil "(~(~a~) ~a)" (car g) (tag (second g) w)))))

(defun paint (w)
  (format t ";; hard:~{ ~a~}~%" (mapcar (lambda (h) (tag h w)) *hard*))
  (format t ";; soft:~{ ~a~}~%~%" (mapcar (lambda (s) (pp s w)) *soft*))
  (dolist (h (reverse *heads*))
    (dolist (b (get h 'rules))
      (format t "(<- ~a ~a)~%" (tag h w) (pp b w)))))

(let* ((args  sb-ext:*posix-argv*)
       (model (car (last (remove-if-not
                          (lambda (s) (search "lisp" s)) args))))
       (n     (parse-integer (car (last args)) :junk-allowed t)))
  (load model)
  (setf *seed* (or n 1))
  (paint (car (sample (append (loop for h in *hard*
                                    append (list h `(= ,h t)))
                              (list (cons 'and *soft*)))
                      :n 1))))
