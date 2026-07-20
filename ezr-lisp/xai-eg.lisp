; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for xai (library: xai.lisp).
;;;; Prose lives in #| markdown |# blocks; each demo is one
;;;; eg-- function; a postprocessor appends each demo's real
;;;; output. One -eg file per engine file, loaded below in
;;;; tutorial order. Run any demo by flag:
;;;;   sbcl --script xai-eg.lisp --all --study --tree
;;;; Under ASDF, load system "xai/eg" instead; the guard
;;;; below skips the load; the eval-when never fires.

(unless (find-package :xai)
  (load (merge-pathnames "xai.lisp" *load-truename*)))

(in-package :xai)


#|
# xai: from zero to someplace cool

Tables of data are cheap; *labels* are dear: running a
benchmark, compiling a config, polling a focus group. So the
question is not "how good is the model?" but "how few labels
buy a good answer?"

One table runs through this whole tutorial: auto93, 398 cars
from the 1970s-80s. Every idea below acts on these same
rows, so each new concept is just a new thing happening to
data you already know. Every demo prints what it sees and
asserts what must hold; outputs are machine-made, never
hand-copied.
|#


#|
## How to run this course

(Easier read: this file, rendered --
[xai-eg.html](https://timm.github.io/src/ezr-lisp/docs/xai-eg.html);
its library
[xai.html](https://timm.github.io/src/ezr-lisp/docs/xai.html);
the shared dictionary
[glossary](https://timm.github.io/src/glossary.html).)

Install [sbcl](https://www.sbcl.org) (mac:
`brew install sbcl`), then fetch the code and its data:

    git clone https://github.com/timm/src
    git clone https://github.com/timm/moot ~/gits/moot
    cd src/ezr-lisp
    sbcl --script xai-eg.lisp --all   # seconds; all assert

Then four levels of read, per lesson:

1. (skim) Read a lesson here beside its printed output in
   [xai-eg.out](xai-eg.out). Can you tell what is going
   on?
2. (run) Run one demo from the command line, e.g.
   `sbcl --script xai-eg.lisp --dists`. Change an input;
   rerun.
3. (dive) Fire up the REPL: `sbcl --load xai.lisp`, then
   `(in-package :xai)`, then retype any demo, line by
   line, printing as you go.
4. (deep dive) Port a lesson to your own favorite
   language (not lisp) and reproduce its slice of
   xai-eg.out. Best to start with the shorter functions.

## Contents

The lessons in order, and the ideas each lands in the
[glossary](../glossary.md). `sbcl --script xai-eg.lisp -h`
lists the matching flags.

| lesson | section | core ideas |
|--------|---------|------------|
|  0 | Lisp    | [lisp](../glossary.md#lisp) [truthy](../glossary.md#truthy) [bob](../glossary.md#bob) |
|  1 | Lib     | [csv](../glossary.md#csv) [coerce](../glossary.md#coerce) |
|  2 | Macros  | [macros](../glossary.md#macros) [ssot](../glossary.md#ssot) |
|  3 | Cols    | [entropy](../glossary.md#entropy) [mode](../glossary.md#mode) |
|  4 | Query   | [welford](../glossary.md#welford) [stream](../glossary.md#stream) |
|  5 | Rand    | [seed](../glossary.md#seed) |
|  6 | Tbl     | [tables](../glossary.md#tables) [schema](../glossary.md#schema) [goals](../glossary.md#goals) |
|  7 | Dist    | [norm](../glossary.md#norm) [minkowski](../glossary.md#minkowski) [missing](../glossary.md#missing) [heaven](../glossary.md#heaven) |
|  8 | Stats   | [effect](../glossary.md#effect) [ks](../glossary.md#ks) [same](../glossary.md#same) |
|  9 | Acquire | [budget](../glossary.md#budget) [active](../glossary.md#active) [poles](../glossary.md#poles) |
| 10 | Bins    | [bins](../glossary.md#bins) [cost](../glossary.md#cost) |
| 11 | Tree    | [tree](../glossary.md#tree) [predict](../glossary.md#predict) [explain](../glossary.md#explain) |
| 12 | Main    | [holdout](../glossary.md#holdout) [win](../glossary.md#win) [baseline](../glossary.md#baseline) [variability](../glossary.md#variability) |
|#


;;; ## Lisp egs
;;; Lesson 0: enough Common Lisp to read everything else.

#|
## Lesson 0: lisp for the impatient pythonista

You know python (or lua); Common Lisp needs a few
adjustments before the rest of this file reads easily.
The demos below are the traps that bite hardest: what
counts as false, five spellings of "equal", functions
living in their own namespace, numbers that stay exact --
then a first SE rule, checked against our own source code.

**Core ideas:** [lisp](../glossary.md#lisp),
[truthy](../glossary.md#truthy), [bob](../glossary.md#bob)

| call | returns | what |
|------|---------|------|
| `(member x lst)` | tail or nil | nil = false = () |
| `(equal a b)` | t or nil | structural equality |
| `(funcall f x)` | value | call a function value |
| `(floor 7 2)` | 3, 1 | multiple return values |
|#

(defun eg--truthy ()
  "Only nil is false; nil IS the empty list"
  (format t "~&nil is (): ~a; 0 is true: ~a~%"
          (eq nil '()) (if 0 'yes 'no))
  (assert (eq nil '()))
  (assert (if 0 t))                    ; 0 and "" are true
  (assert (if "" t))
  (assert (equal '(2 3) (member 2 '(1 2 3)))))

(defun eg--equality ()
  "The equality zoo: eq eql equal equalp ="
  (format t "~&eq ~a eql ~a equal ~a equalp ~a = ~a~%"
          (eq (list 1) (list 1))       ; not the same object
          (eql 1 1.0)                  ; types differ
          (equal (list 1 2) (list 1 2)) ; same structure
          (equalp "AB" "ab")           ; case-blind
          (= 1 1.0))                   ; same numeric value
  (assert (not (eq (list 1) (list 1))))
  (assert (not (eql 1 1.0)))
  (assert (equal (list 1 2) (list 1 2)))
  (assert (equalp "AB" "ab"))
  (assert (= 1 1.0)))

(defun eg--funs (&aux (f #'sqrt))
  "Functions live in their own namespace: #' and funcall"
  (format t "~&(funcall f 16) ~a; mapcar 1+ ~a~%"
          (funcall f 16) (mapcar #'1+ '(1 2 3)))
  (assert (= 4 (funcall f 16)))
  (assert (equal '(2 3 4) (mapcar #'1+ '(1 2 3))))
  (assert (= 6 (reduce #'+ '(1 2 3)))))

(defun eg--numbers ()
  "Exact rationals; floor returns two values"
  (format t "~&1/3 stays ~a; (float 1/3) is ~a~%"
          (/ 1 3) (float 1/3))
  (assert (eql 1/3 (/ 1 3)))           ; no silent rounding
  (multiple-value-bind (q r) (floor 7 2)
    (format t "~&(floor 7 2) = ~a remainder ~a~%" q r)
    (assert (and (= q 3) (= r 1)))))

(defun eg--bob (&aux (n 0) (sizes (make-hash-table))
                     (small 0) (big 0))
  "Uncle Bob's rule, checked: code paragraphs of xai.lisp"
  (with-open-file (s "xai.lisp")
    (loop for line = (read-line s nil) while line do
      (let ((l (string-left-trim '(#\Space #\Tab) line)))
        (if (and (> (length l) 0) (char/= (char l 0) #\;))
            (incf n)
            (unless (zerop n)
              (incf (gethash n sizes 0)) (setf n 0))))))
  (unless (zerop n) (incf (gethash n sizes 0)))
  (loop for size from 1 to 99
        for k = (gethash size sizes)
        when k do
          (format t "~&~2d ~a~%" size
                  (make-string k :initial-element #\*))
          (if (<= size 6) (incf small k) (incf big k)))
  (format t "~&small (<=6 lines): ~a bigger: ~a~%" small big)
  (assert (> small big)))              ; Bob would approve

#|
**Exercises (lesson 0).**

0. In your own favorite language (not lisp), write the
   `--bob` analyzer for that language's comment syntax,
   then run it on its own source. Is your code
   Bob-friendly?
1. (simple) Predict, then check at the REPL: `(eq 'a 'a)`,
   `(eql 1/2 0.5)`, `(equalp '(1 "A") '(1 "a"))`,
   `(/ 10 4)`.
2. Extend `--bob` to report the largest paragraph and its
   first line. Which part of xai.lisp most needs Uncle
   Bob's attention -- and would splitting it actually help
   a reader?
|#


#|
## Knobs

One `settings` struct holds every knob; slot names double
as CLI flags, so --file swaps the table and --seed the
randomness. Notice --budget 50: the whole game is spending
it well.

**Core ideas:** [ssot](../glossary.md#ssot)

| call | returns | what |
|------|---------|------|
| `*my*` | `settings` struct | knobs; slots = CLI flags |
|#

(defun eg--my ()
  "Print the settings"
  (format t "~&~s~%" *my*)
  (assert (settings-p *my*)))


;;; ## Lib egs
;;; Tutorial and tests for lib.lisp: the running example
;;; csv, and coercing its cells.

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

**Core ideas:** [csv](../glossary.md#csv),
[coerce](../glossary.md#coerce)

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

#|
**Exercises (lesson 1).**

0. Port `thing` to another language: same seven inputs,
   same seven outputs.
1. (simple) Predict, then check: `(thing "  -0.5 ")`,
   `(thing "1e-2")`, `(thing "nan?")`.
2. Write `(rowcount file)` using `mapcsv`, then use it to
   report the row count of every csv in
   `$MOOT/optimize/misc`.
|#


;;; ## Macros egs
;;; Tutorial and tests for macros.lisp: one accessor,
;;; three spellings.

#|
## Little accessors

Everything else leans on one idea: `ats` reads hash keys
and struct slots alike, `?` nests it, `ats!` fills a
missing key on first touch, and `aif` remembers its test
as `it`. Notice `?` walking two levels in one call.

**Core ideas:** [macros](../glossary.md#macros),
[ssot](../glossary.md#ssot)

| call | returns | what |
|------|---------|------|
| `(ats x k)` | value | hash key or struct slot |
| `(? x k1 k2 ..)` | value | nested ats |
| `(ats! x k new)` | value | get, else stash fresh (new) |
| `(aif test then else)` | -- | `it` = the test value |
|#

(defun eg--macros (&aux (h (o "a" 1 "b" (o "c" 2))))
  "Hash/slot access: o, ats, ats!, ?, aif"
  (setf (ats h "d") 3)
  (format t "~&a ~a b.c ~a d ~a seed ~a~%"
          (ats h "a") (? h "b" "c") (ats h "d")
          (? *my* --seed))
  (assert (= 1 (ats h "a")))
  (assert (= 2 (? h "b" "c")))
  (assert (= 3 (ats h "d")))
  (assert (= 4 (ats! h "e" (lambda () 4))))
  (assert (= 4 (ats h "e")))
  (assert (numberp (? *my* --seed)))
  (assert (eq 'yes (aif (+ 1 2) (and (= it 3) 'yes)))))

#|
**Exercises (lesson 2).**

0. In a language without macros, write `?` as a function.
   What did you lose? (Hint: try `(? x k1 k2 k3)`.)
1. (simple) Predict, then check: `(? *my* --file)`, and
   `(ats! h "e" (lambda () 99))` on a hash where "e"
   already holds 4.
2. Use `macroexpand-1` on `(? h "b" "c")` at the REPL.
   Rewrite the expansion by hand, then check yours behaves
   the same.
|#


;;; ## Cols egs
;;; Tutorial and tests for cols.lisp: symbolic columns.

#|
## Symbolic columns

Lowercase header names (like origin) make `sym` columns:
things we can only count and compare. First a case tiny
enough to check by eye, then the table's own origin column.
Notice entropy: high when counts are even, low when one
value dominates.

**Core ideas:** [entropy](../glossary.md#entropy),
[mode](../glossary.md#mode)

| call | returns | what |
|------|---------|------|
| `(add i v)` | v | count v into sym i |
| `(mid i)` | symbol | the mode |
| `(spread i)` | float | entropy of the counts |
|#

(defun eg--sym (&aux (i (make-sym)))
  "Sym mode and entropy: tiny case, then a real column"
  (dolist (v '(a a a a b b c)) (add i v))
  (format t "~&(a a a a b b c): mid ~a ent ~,3f~%"
          (mid i) (spread i))
  (assert (eq (mid i) 'a))
  (assert (< (abs (- (spread i) 1.379)) 0.01))
  (let* ((d (make-tbl (? *my* --file)))
         (origin (find "origin" (? d cols all)
                       :key (lambda (c) (? c txt))
                       :test #'equal)))
    (when origin
      (format t "origin: mid ~a ent ~,3f~%"
              (mid origin) (spread origin)))))

#|
**Exercises (lesson 3).**

0. Port sym add/mid/spread to another language; reproduce
   mid a, ent 1.379 for (a a a a b b c).
1. (simple) Predict entropy for (a b), (a a b b), (a a a
   a): which is highest? Check with `add` and `spread`.
2. Add a `merge` that folds one sym's counts into another,
   then show entropy never drops when merging two columns
   that disagree.
|#


;;; ## Query egs
;;; Tutorial and tests for query.lisp: numeric columns.

#|
## Numeric columns

Uppercase names (like Mpg+) make `num` columns: things we
can average. Folding all 398 Mpg cells one at a time
(Welford's trick: no list kept, just n, mu, m2) gives the
column's mean and standard deviation. Notice: the average
1970s car did about 24 mpg.

**Core ideas:** [welford](../glossary.md#welford),
[stream](../glossary.md#stream)

| call | returns | what |
|------|---------|------|
| `(make-tbl file)` | tbl | rows + column summaries |
| `(mid i)` | float | mean of num i |
| `(spread i)` | float | standard deviation |
|#

(defun eg--num (&aux (i (make-tbl (? *my* --file))))
  "Fold one num column; watch mu and sd emerge"
  (let ((mpg (car (last (? i cols y)))))
    (format t "~&~a: n ~a mu ~,2f sd ~,2f~%"
            (? mpg txt) (? mpg n) (mid mpg) (spread mpg))
    (when (search "auto93" (? *my* --file))
      (assert (< (abs (- (mid mpg) 23.84)) 0.1))
      (assert (< (abs (- (spread mpg) 8.34)) 0.1)))))

#|
**Exercises (lesson 4).**

0. Port Welford (n, mu, m2) to another language; match
   mu 23.84, sd 8.34 on auto93's Mpg+.
1. (simple) Feed `add` the numbers 1..10 by hand at the
   REPL. Predict mu and sd before printing them.
2. Welford's claim is one pass, no stored list. Compute sd
   the naive two-pass way and time both on a million
   random numbers.
|#


;;; ## Rand egs
;;; Tutorial and tests for rand.lisp: reproducible
;;; randomness.

#|
## Reproducible randomness

Later demos shuffle and sample, so first: `rand`, a seeded
16807 Lehmer generator that repeats exactly on sbcl and
clisp (Common Lisp's own `random` does not). The second
check sums three uniforms 10,000 times (Irwin-Hall): mean
lands on 0, sd on 1 -- testing `rand`, `add`, and Welford
in one shot.

**Core ideas:** [seed](../glossary.md#seed)

| call | returns | what |
|------|---------|------|
| `(rand n)` | float 0..n | next seeded random |
| `(rint n)` | int 0..n-1 | random integer |
| `(add i v)` | v | Welford-update num i |
|#

(defun eg--rand (&aux a b (i (make-num)))
  "Seeded rand repeats; 10k Irwin-Hall -> mean 0, sd 1"
  (setf *seed* 1 a (rand)
        *seed* 1 b (rand))
  (format t "~&rand ~,3f ~,3f rint ~a~%" a b (rint 10))
  (assert (= a b))
  (assert (< 0 a 1))
  (dotimes (k 10000)
    (add i (/ (- (+ (rand) (rand) (rand)) 1.5) 0.5)))
  (format t "~&irwin-hall mu ~,3f sd ~,3f~%"
          (mid i) (spread i))
  (assert (< (abs (mid i)) 0.05))
  (assert (< (abs (- (spread i) 1)) 0.05)))

#|
**Exercises (lesson 5).**

0. Port the 16807 generator; from seed 1 your first three
   floats must match this rig's (print them here first).
1. (simple) Rerun `--rand` with `--seed 2`. Which printed
   numbers change? Which asserts still hold, and why?
2. Sum five uniforms instead of three (rescale by the
   right sd). Does the Irwin-Hall bell tighten?
|#


;;; ## Tbl egs
;;; Tutorial and tests for tbl.lisp: the whole table.

#|
## The whole table

`make-tbl` streams the csv once: the first row builds one
column summary per header name (trailing `-` or `+` = goal
to minimize or maximize; trailing `X` = ignore), and later
rows update them. Notice the goals: minimize Lbs-, maximize
Acc+ and Mpg+ -- light, quick, thrifty cars win.

**Core ideas:** [tables](../glossary.md#tables),
[schema](../glossary.md#schema),
[goals](../glossary.md#goals)

| call | returns | what |
|------|---------|------|
| `(make-tbl src)` | tbl | src = file name or rows |
| `(mid col)` | value | mean or mode |
| `(spread col)` | float | sd or entropy |
|#

(defun eg--tbl (&aux (i (make-tbl (? *my* --file))))
  "Tbl build: col roles and goal stats"
  (format t "~&rows ~a |x| ~a |y| ~a~%"
          (length (? i rows))
          (length (? i cols x))
          (length (? i cols y)))
  (dolist (col (? i cols y))
    (format t "~a mid ~,2f div ~,2f~%"
            (? col txt) (mid col) (spread col)))
  (when (search "auto93" (? *my* --file))
    (assert (= (length (? i rows)) 398))
    (assert (= (length (? i cols all)) 8))
    (assert (= (length (? i cols x)) 4))
    (assert (= (length (? i cols y)) 3))
    (let ((mpg (elt (? i cols y) 2)))
      (assert (< (abs (- (mid mpg) 23.84)) 0.1))
      (assert (< (abs (- (spread mpg) 8.34)) 0.1)))))

#|
**Exercises (lesson 6).**

0. Port the header rules (case, trailing -,+,X) and
   reproduce this demo's |x| and |y| on auto93.
1. (simple) Edit one header name (say Volume -> VolumeX)
   in a copy of the csv. Predict |x| and |y|, rerun.
2. Point --file at any other csv under $MOOT. What breaks
   first: your assumptions or the code's?
|#


;;; ## Dist egs
;;; Tutorial and tests for dist.lisp: distance to heaven.

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

**Core ideas:** [norm](../glossary.md#norm),
[minkowski](../glossary.md#minkowski),
[missing](../glossary.md#missing),
[heaven](../glossary.md#heaven)

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

#|
**Exercises (lesson 7).**

0. Port disty; reproduce this demo's best and worst rows
   on auto93.
1. (simple) Change --p from 2 to 1 (city-block). Rerun
   --dists: do best and worst rows change?
2. Write knn: predict a row's Mpg+ as the mean of its k
   nearest rows by distx. Score it leave-one-out for
   k in {1, 3, 7}.
|#


;;; ## Stats egs
;;; Tutorial and tests for stats.lisp: when do two results
;;; differ?

#|
## When do two results differ?

One tool before any experiment: `same` calls two lists of
numbers equal only if `cohen` AND `cliffs` AND `ks` all
agree. Take 20 disty scores from our table: they equal
themselves, survive a 0.02 nudge, and differ after a +1
shift. Notice how conservative this is -- tiny changes are
treated as noise, so later "X beats Y" claims mean
something.

**Core ideas:** [effect](../glossary.md#effect),
[ks](../glossary.md#ks), [same](../glossary.md#same)

| call | returns | what |
|------|---------|------|
| `(same xs ys)` | t or nil | t iff cohen+cliffs+ks agree |
|#

(defun eg--same (&aux (i (make-tbl (? *my* --file))) xs)
  "Same: true for a nudge, false for a shift"
  (setf xs (mapcar (lambda (r) (disty i r))
                   (few (? i rows) 20)))
  (let ((ys (mapcar (lambda (x) (+ x 0.02)) xs))
        (zs (mapcar (lambda (x) (+ x 1)) xs)))
    (format t
      "~&same: self ~a nudged(+.02) ~a shifted(+1) ~a~%"
      (same xs xs) (same xs ys) (same xs zs))
    (assert (same xs xs))
    (assert (same xs ys))
    (assert (not (same xs zs)))))

#|
**Exercises (lesson 8).**

0. Port cliffs delta; check a list is 0.0 from itself and
   large from itself + 1.
1. (simple) Find the smallest shift (0.02? 0.1? 0.5?)
   where `same` first says nil for these disty scores.
2. `same` is three tests ANDed. Disable one at a time:
   which is the strictest gate on this data?
|#


;;; ## Acquire egs
;;; Tutorial and tests for acquire.lisp: the active
;;; learner.

#|
## The active learner

The payoff. `acquire` labels a handful of rows, projects
the rest onto a line between two distant labelled poles
(good end, bad end), culls the third nearest the bad pole,
and repeats -- spending at most --budget labels. Notice the
best labelled row: found after ~45 labels, it is the kind
of car that floated to the top back when we (expensively)
scored all 398.

**Core ideas:** [budget](../glossary.md#budget),
[active](../glossary.md#active),
[poles](../glossary.md#poles)

| call | returns | what |
|------|---------|------|
| `(acquire tbl)` | rows | labelled few, best first |
|#

(defun eg--land (&aux (i (make-tbl (? *my* --file))))
  "Landscape labels few rows, sorted best first"
  (let* ((lab (acquire i))
         (ys  (mapcar (lambda (r) (disty i r)) lab)))
    (format t "~&labelled ~a best ~,3f worst ~,3f~%"
            (length lab) (first ys) (car (last ys)))
    (format t "~&best labelled row:")
    (print (first lab))
    (assert (<= (length lab)
                (- (? *my* --budget) (? *my* --check))))
    (assert (equal ys (sort (copy-list ys) #'<)))
    (assert (< (first ys) 0.4))))

#|
**Exercises (lesson 9).**

0. Port acquire's project step: given two labelled poles,
   place any row on their line.
1. (simple) Rerun --land with --budget 20, then 100. How
   does the best labelled disty move?
2. Replace the pole pick (farthest pair) with a random
   pair. How many extra labels buy back the loss?
|#


;;; ## Bins egs
;;; Tutorial and tests for bins.lisp: explaining, one bin.

#|
## Explaining: one bin

Why are the good cars good? `split` tries one bin per x
column and keeps the cheapest, where cost is the
size-weighted spread of the two halves. The assert: the
best bin beats the unsplit spread, else explanation would
be hopeless. Notice the winner reads like something a
mechanic would say: small engines differ from big ones.

**Core ideas:** [bins](../glossary.md#bins),
[cost](../glossary.md#cost)

| call | returns | what |
|------|---------|------|
| `(split tbl rows y)` | (cost at v) | cheapest single bin |
|#

(defun eg--bins (&aux (i (make-tbl (? *my* --file))))
  "Best single bin beats the unsplit spread"
  (let* ((rows (? i rows))
         (goal (car (last (? i cols y))))
         (best (split i rows
                      (lambda (r) (elt r (? goal at))))))
    (format t "~&best ~,2f at ~a v ~a (sd ~,2f)~%"
            (first best)
            (? (elt (? i cols all) (second best)) txt)
            (third best) (spread goal))
    (assert (< (first best) (spread goal)))
    (when (search "auto93" (? *my* --file))
      (assert (eql (third best) 183)))))

#|
**Exercises (lesson 10).**

0. Port split for numeric columns only; reproduce the
   winning column and cut on auto93.
1. (simple) Predict: if the y function were a coin flip,
   could any bin beat the unsplit spread? Try it.
2. split scans each numeric column sorted. Break the sort
   (shuffle first) and measure how often the winner
   changes: why is order load-bearing?
|#


;;; ## Tree egs
;;; Tutorial and tests for tree.lisp: explaining, a whole
;;; tree.

#|
## Explaining: a whole tree

Recurse the bins and a tree falls out. Each printed line is
n, the mean Mpg of those rows, then the branch condition;
read any root-to-leaf path as a rule about our cars. Notice
how few x columns the tree needs -- most columns never
mattered.

**Core ideas:** [tree](../glossary.md#tree),
[predict](../glossary.md#predict),
[explain](../glossary.md#explain)

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

#|
**Exercises (lesson 11).**

0. Port leaf (the row-walker); route auto93's first five
   rows through this tree by hand and compare.
1. (simple) Rerun --tree with --depth 2, then 6. When do
   extra levels stop changing the printed story?
2. Trees explain; do they predict? Compare leaf's guess
   against the true Mpg+ over 50 held-out rows.
|#


;;; ## Main egs
;;; Tutorial and tests for main.lisp: grading, the whole
;;; rig, and the Rq0-Rq2 studies.

#|
## Grading

How good is a picked row? `wins` calibrates per table:
100 = the pick equals the best row, 0 = no better than the
median, negative = worse than median. All studies report on
this scale, so results compare across datasets. Notice the
worst row grades far below zero: picking badly is worse
than not picking at all.

**Core ideas:** [win](../glossary.md#win),
[baseline](../glossary.md#baseline)

| call | returns | what |
|------|---------|------|
| `(wins tbl)` | function | grader: row -> [-100,100] |
|#

(defun eg--wins (&aux (i (make-tbl (? *my* --file))))
  "Wins grader: best row = 100, all in [-100,100]"
  (let* ((w    (wins i))
         (rows (? i rows))
         (best (argmin (lambda (r) (disty i r)) rows)))
    (format t "~&win(best)= ~a win(worst)= ~a~%"
            (round (funcall w best))
            (round (funcall w (argmax
                                (lambda (r) (disty i r))
                                rows))))
    (assert (= 100 (round (funcall w best))))
    (dolist (r (few rows 30))
      (assert (<= -100 (funcall w r) 100)))))


#|
## Someplace cool: the whole rig

Split the table 50:50. Landscape-label the train half under
the budget; grow a tree from those few labels; let the tree
rank the *unseen* test half; label only the top --check
rows and keep the best. Notice the win: a few dozen labels
found a near-best car among cars never seen in training.
That is the whole toolkit, in one function you can now
read.

**Core ideas:** [holdout](../glossary.md#holdout)

| call | returns | what |
|------|---------|------|
| `(holdout tbl)` | row | best check from unseen half |
|#

(defun eg--holdout (&aux (i (make-tbl (? *my* --file))))
  "One holdout run: pick a good test row"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (let* ((got (holdout i))
         (w   (round (funcall (wins i) got))))
    (format t "~&picked ~s~%win= ~a disty= ~,3f~%"
            got w (disty i got))
    (assert (vectorp got))
    (assert (<= -100 w 100))
    (when (search "auto93" (? *my* --file))
      (assert (> w 0)))))


#|
## Studies

Demos convince; studies measure. Each study-- function
repeats the holdout rig 20 times and reports on the wins
scale, answering the research questions: how good is the
rig (rq0), does more budget help (rq1), and does active
beat random labelling (rq2). `deltas` prints 0 when `same`
says two treatments tie, else the mean gap.

**Core ideas:** [variability](../glossary.md#variability)

| call | returns | what |
|------|---------|------|
| `(deltas tbl knob v1 v2)` | -- | print 0 (tie) or gap |
|#

(defun study--holdouts (&aux (i (make-tbl (? *my* --file)))
                          w (n (make-num)))
  "Rq0: mean win over 20 holdouts"
  (setf (? i rows) (few (? i rows) (? *my* --cap))
        w (wins i))
  (dotimes (k 20)
    (add n (funcall w (holdout i))))
  (format t "~&mu ~5,1f sd ~5,1f ~a~%"
          (mid n) (spread n) (? *my* --file))
  (assert (<= -100 (mid n) 100))
  (when (search "auto93" (? *my* --file))
    (assert (> (mid n) 50))))

(defun deltas (i knob v1 v2
               &aux (w (wins i)) (v0 (ats *my* knob)))
  "20 paired holdouts per knob value; 0 if same, else gap"
  (labels ((runs (v &aux out)
             (setf (ats *my* knob) v)
             (dotimes (k 20 out)
               (setf *seed* (+ (? *my* --seed) k))
               (push (funcall w (holdout i)) out))))
    (let* ((a (runs v1))
           (b (runs v2))
           (d (if (same a b)
                  0
                  (- (mid (adds a)) (mid (adds b))))))
      (setf (ats *my* knob) v0)
      (format t "~&~6,1f ~a~%" d (? *my* --file)))))

(defun study--delta (&aux (i (make-tbl (? *my* --file))))
  "Rq2: active vs random labelling, budget 50"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--acquire "active" "random"))

(defun study--budgets (&aux (i (make-tbl (? *my* --file))))
  "Rq1: budget 50 vs 20, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 50 20))

(defun study--saturate (&aux (i (make-tbl (? *my* --file))))
  "Rq1: budget 200 vs 50, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 200 50))

#|
**Exercises (lesson 12).**

0. Port wins; verify the best row grades 100 and the
   median row grades near 0 on auto93.
1. (simple) Run --holdouts three times with three seeds.
   How much does mu move? That spread IS variability.
2. Add a study: --check 1 vs --check 10. Is checking more
   test rows worth ten times the labels?
|#


#|
## Course upkeep

Three checks keep this file honest (all in `make check` or
CI, none run by --all): `--transcript` freezes the printed
--all output to xai-eg.out from a real run (never
hand-edited); `--check` diffs a fresh run against it, so
any refactor that moves a graded number fails fast;
`--join` re-verifies the doc claims -- every glossary link
lands on a real heading, every `| (fn ..) |` table row
names a function that exists.
|#

(defun sh (cmd)
  "Run a shell command; return its exit code"
  #+sbcl (sb-ext:process-exit-code
           (sb-ext:run-program "/bin/sh" (list "-c" cmd)
                               :output *standard-output*
                               :error *error-output*))
  #-sbcl 1)

(defun eg--transcript ()
  "Freeze --all output to xai-eg.out (from a real run)"
  (assert (zerop (sh (concatenate 'string
    "sbcl --script xai-eg.lisp --all > xai-eg.out"))))
  (format t "~&xai-eg.out frozen~%"))

(defun eg--check (&aux ok)
  "A fresh --all must reproduce the frozen transcript"
  (setf ok (zerop (sh (concatenate 'string
    "sbcl --script xai-eg.lisp --all | diff - xai-eg.out"))))
  (format t "~&~a~%" (if ok "transcript ok"
                            "TRANSCRIPT DRIFT"))
  (assert ok))

(defun slurp (file &aux)
  "Whole file as one string"
  (with-open-file (s file)
    (let ((str (make-string (file-length s))))
      (subseq str 0 (read-sequence str s)))))

(defun gkeys (&aux (keys (make-hash-table :test #'equal)))
  "Glossary headings '## key' as a set"
  (with-open-file (s "../glossary.md")
    (loop for line = (read-line s nil) while line do
      (when (and (> (length line) 3)
                 (string= "## " line :end2 3)
                 (every #'lower-case-p (subseq line 3)))
        (setf (gethash (subseq line 3) keys) t))))
  keys)

(defun eg--join (&aux (src (slurp "xai-eg.lisp"))
                      (keys (gkeys)) (ok t)
                      (taught (make-hash-table :test #'equal)))
  "Doc claims, executable: glossary links, table signatures"
  (let ((tag "glossary.md#") (start 0))
    (loop for pos = (search tag src :start2 start)
          while pos
          do (let* ((k0 (+ pos (length tag)))
                    (k1 (position-if-not #'alpha-char-p src
                                         :start k0))
                    (key (subseq src k0 k1)))
               (unless (or (string= key "")  ; the tag itself
                           (gethash key keys))
                 (setf ok nil)
                 (format t "~&no heading: ~a~%" key))
               (setf start k1))))
  (with-input-from-string (s src)
    (loop for line = (read-line s nil) while line do
      (when (eql 0 (search "| `(" line))
        (let* ((k0 4)
               (k1 (position-if
                     (lambda (c) (member c '(#\Space #\))))
                     line :start k0))
               (name (subseq line k0 k1))
               (sym (find-symbol (string-upcase name) :xai)))
          (if (and sym (fboundp sym))
              (setf (gethash name taught) t)
              (progn (setf ok nil)
                     (format t "~&table names missing fn: ~a~%"
                             name)))))))
  (let ((total (length (egs "EG--"))))
    (format t "~&coverage: ~a taught verbs; ~a demos~%"
            (hash-table-count taught) total))
  (assert ok))


#|
## Runners

`eg--all` and `eg--study` find their functions by name (see
`egs` in the library), reseeding before each so any demo
reproduces in isolation.
|#

(defun run-egs (lst)
  "Run each test, reseeding before each"
  (dolist (s lst)
    (format t "~&~%; ~(~a~)~%" s)
    (setf *seed* (? *my* --seed))
    (funcall s)))

(defun eg--all ()
  "Run every unit test"
  (run-egs (egs "EG--")))

(defun eg--study ()
  "Run every study"
  (run-egs (egs "STUDY--")))

(eval-when (:execute)
  (if (member "-h" (args) :test #'equal)
      (help)
      (cli *my*)))
