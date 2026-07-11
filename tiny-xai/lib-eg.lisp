; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for lib.lisp: the running example
;;;; csv, and coercing its cells.

#|
## The running example

First, look at the data (this sample, like every trace in
this file, is pasted from a real run):

    Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+
         8     304  193     70       1  4732  18.5    10
         8     360  215     70       1  4615    14    10
         8     307  200     70       1  4376    15    10
         8     318  210     70       1  4382  13.5    10
         ... plus 394 more rows

The header names the columns; each later row is one car.
Notice the header spellings -- they matter soon.

| call | returns | what |
|------|---------|------|
| `(mapcsv fun file)` | nil | fun applied to each row |
|#

(defun eg--rows (&aux (n 0))
  "The running example: header, then the first rows"
  (mapcsv (lambda (row)
            (when (< (incf n) 6) (print row))
            (when (search "auto93" (? *my* --file))
              (assert (= (length row) 8))))
          (? *my* --file))
  (format t "~&... plus ~a more rows~%" (- n 5))
  (when (search "auto93" (? *my* --file))
    (assert (= n 399))))


#|
## Reading cells

Those cells arrived as strings. `thing` coerces each one:
" 23 " becomes the number 23, "?" marks a missing value,
anything else stays text. Notice "-1e2" becoming -100.0 --
csv cells can hide exponents.

| call | returns | what |
|------|---------|------|
| `(thing s)` | num, `?`, t, nil, text | coerce one csv cell |
|#

(defun eg--thing ()
  "String coercion round-trip"
  (let ((got (mapcar #'thing '(" 23 " "3.14" "-1e2"
                               "?" "True" "False" "abc"))))
    (print got)
    (assert (equal got '(23 3.14 -100.0 ? t nil "abc")))))
