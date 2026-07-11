; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for tree.lisp: explaining, a whole
;;;; tree.

#|
## Explaining: a whole tree

Recurse the bins and a tree falls out. Each printed line is
n, the mean Mpg of those rows, then the branch condition;
read any root-to-leaf path as a rule about our cars. Notice
how few x columns the tree needs -- most columns never
mattered.

| call | returns | what |
|------|---------|------|
| `(tree tbl rows y)` | node | recurse bins into a tree |
| `(show tbl node)` | -- | print the tree |
| `(leaves node)` | list | all leaf nodes |
| `(leaf tbl node row)` | value | route row to its leaf mid |
|#

(defun eg--tree (&aux (i (make-tbl (? *my* --file))))
  "Tree build: show, partition, walk"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (let* ((rows (? i rows))
         (goal (car (last (? i cols y))))
         (tr   (tree i rows
                     (lambda (r) (elt r (? goal at))))))
    (show i tr)
    (about i tr)
    (let ((lvs (leaves tr)))
      (assert (? tr at))
      (assert (> (length lvs) 3))
      (assert (= (length rows)
                 (loop for l in lvs sum (? l n))))
      (assert (<= 1 (length (used tr))
                  (length (? i cols x))))
      (assert (numberp (leaf i tr (first rows)))))))
