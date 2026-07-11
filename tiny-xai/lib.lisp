; vim: set lispwords+=loop,aif :
;;;; Strings and files. `thing` and `things` coerce csv
;;;; cells; `trim` strips whitespace; `mapcsv` streams a
;;;; file, with `path` expanding a leading $MOOT (env via
;;;; `getenv`, else HOME/gits/moot). `cat` glues printed
;;;; forms.

; Strip spaces, tabs, returns
(defun trim (s)
  (string-trim '(#\space #\tab #\return) s))

; String -> number | ? | t | nil | trimmed string
(defun thing (s &aux (opt '(("?" . ?) ("True" . t) ("False"))))
  (let ((s (trim s))
        (*read-eval*))
    (aif (assoc s opt :test #'equal)
      (cdr it)
      (let ((x (ignore-errors (read-from-string s nil))))
        (if (numberp x) x s)))))

; Split s on ch; coerce each cell with thing
(defun things (s &optional (ch #\,) (start 0))
  (aif (position ch s :start start)
    (cons (thing (subseq s start it)) (things s ch (1+ it)))
    (list (thing (subseq s start)))))

; Environment variable, or nil
(defun getenv (s)
  #+sbcl  (sb-ext:posix-getenv s)
  #+clisp (ext:getenv s))

; Expand a leading $MOOT (env, else HOME/gits/moot)
(defun path (s)
  (if (and (> (length s) 5) (string= "$MOOT" s :end2 5))
      (concatenate 'string
        (or (getenv "MOOT")
            (concatenate 'string
              (namestring (user-homedir-pathname)) "gits/moot"))
        (subseq s 5))
      s))

; Call fun on each csv row (skipping blanks, # comments)
(defun mapcsv (fun file)
  (labels ((line (s &aux (s1 (trim s)))
             (unless (or (equal s1 "") (eql (char s1 0) #\#))
               (funcall fun (coerce (things s1) 'vector)))))
    (with-open-file (s (path file))
      (loop (line (or (read-line s nil) (return)))))))

; Concatenate the printed forms of xs
(defun cat (&rest xs)
  (format nil "~{~a~}" xs))
