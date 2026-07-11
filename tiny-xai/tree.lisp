; vim: set lispwords+=loop,aif :
;;;; Trees. `tree` recurses on the best bin while `grow-p`
;;;; allows; leaves keep their rows and a `mid` prediction.
;;;; `leaf` routes a new row down; `show` prints branch
;;;; conditions as text. Passing a different accum
;;;; (make-sym) turns the same code from regression into
;;;; classification.

; Recursively split rows on the min-cost bin
(defun tree (tbl rows y &optional (accum #'make-num) (lvl 0))
  (let ((i (make-node :n (length rows) :rows rows
                      :mid (mid (adds (mapcar y rows)
                                      (funcall accum))))))
    (when (grow-p rows lvl) (branch tbl i rows y accum lvl))
    i))

; Enough rows and shallow enough to split again?
(defun grow-p (rows lvl)
  (and (>= (length rows) (* 2 (? *my* --leaf)))
       (< lvl (? *my* --depth))))

; If best bin divides rows, grow yes/no subtrees
(defun branch (tbl i rows y accum lvl &aux yes no)
  (aif (split tbl rows y accum)
    (let ((at (second it)) (v (third it)))
      (dolist (r rows)
        (if (has-p (col-at tbl at) (elt r at) v)
            (push r yes)
            (push r no)))
      (when (and yes no)
        (setf $at  at
              $v   v
              $yes (tree tbl yes y accum (1+ lvl))
              $no  (tree tbl no  y accum (1+ lvl)))))))

; The column summary at index `at`
(defun col-at (tbl at)
  (elt (? tbl cols all) at))

; Walk row down the tree; return its leaf's mid
(defun leaf (tbl i row)
  (if $at
      (leaf tbl
            (if (has-p (col-at tbl $at) (elt row $at) $v)
                $yes
                $no)
            row)
      $mid))

; List of every leaf node
(defun leaves (i)
  (if $at
      (append (leaves $yes) (leaves $no))
      (list i)))

; One branch test as text, e.g. |Volume <= 183|
(defun cond-txt (tbl i yes)
  (let ((col (col-at tbl $at)))
    (format nil "~a ~a ~a" (? col txt)
            (if (sym-p col)
                (if yes "==" "!=")
                (if yes "<=" ">"))
            $v)))

; Print tree: n, mid, indented branch conditions
(defun show (tbl i &optional (pad "") (edge ""))
  (format t "~&~5d ~8,2f  ~a~a~%" $n $mid pad edge)
  (when $at
    (let ((pad2 (if (equal edge "") pad (cat pad "|  "))))
      (show tbl $yes pad2 (cond-txt tbl i t))
      (show tbl $no  pad2 (cond-txt tbl i nil)))))

; X col indexes tested anywhere in the tree
(defun used (i)
  (when $at
    (remove-duplicates
      (cons $at (append (used $yes) (used $no))))))

; One line per tree: leaves, x cols used
(defun about (tbl i)
  (format t "~&leaves= ~a, x= ~a of ~a~%"
          (length (leaves i))
          (length (used i))
          (length (? tbl cols x))))
