; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for dist.lisp: distance to heaven.

#|
## Distance to heaven

Now re-view the rows, twice. `disty` scores each row by
distance to the ideal goals (0 = heaven), reading only y
columns. Sorting our table by disty:

    Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
         4      90   48     78       2  1985  21.5    40  0.075
         4      90   48     80       2  2085  21.7    40  0.087
         4      85   65     81       3  1975  19.4    40  0.087
       ...     ...  ...    ...     ...   ...   ...   ...    ...
         8     454  220     70       1  4354     9    10  0.956
         8     455  225     73       1  4951    11    10  0.956

Light thrifty cars float up; guzzlers sink. Then `distx`,
difference over x columns only: sorting the same rows by
distx from that best car finds its near-clones:

    Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  distx
         4      90   48     78       2  1985  21.5    40  0.000
         4      89   71     78       2  1990  14.9    30  0.001
         4     121  115     78       2  2795  15.7    20  0.039
       ...     ...  ...    ...     ...   ...   ...   ...    ...
         8     455  225     70       1  4425    10    10  0.816

Notice: the rig *scores* with y but *navigates* with x, and
these tables are why that works -- rows close in x (top of
table two) are also close in y.

| call | returns | what |
|------|---------|------|
| `(disty tbl row)` | 0..1 | distance to ideal goals |
| `(distx tbl r1 r2)` | 0..1 | difference over x cols |
|#

(defun eg--dists (&aux (i (make-tbl (? *my* --file))))
  "Same rows, two sorts: by disty, by distx from the best"
  (let* ((rows (sort (copy-list (? i rows)) #'<
                     :key (lambda (r) (disty i r))))
         (lo (first rows))
         (hi (car (last rows))))
    (format t "~&best  (disty ~,3f):" (disty i lo))
    (print lo)
    (let ((near (argmin (lambda (r)
                          (if (eq r lo) 1 (distx i lo r)))
                        rows)))
      (format t "~&nearest in x (distx ~,3f):"
              (distx i lo near))
      (print near))
    (format t "~&worst (disty ~,3f):" (disty i hi))
    (print hi)
    (assert (<= 0 (disty i lo) (disty i hi) 1))
    (assert (= 0 (distx i lo lo)))
    (assert (< (abs (- (distx i lo hi) (distx i hi lo)))
               1e-6))
    (assert (<= 0 (distx i lo hi) 1))))
