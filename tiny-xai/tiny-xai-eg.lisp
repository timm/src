; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for tiny-xai (library: tiny-xai.lisp).
;;;; Prose lives in #| markdown |# blocks; each demo is one
;;;; eg-- function; a postprocessor appends each demo's real
;;;; output. Run any demo by flag:
;;;;   sbcl --script tiny-xai-eg.lisp --all --study --tree
;;;; Under ASDF, load system "tiny-xai/eg" instead; the guard
;;;; below skips the load; the eval-when never fires.

(unless (find-package :tiny-xai)
  (load (merge-pathnames "tiny-xai.lisp" *load-truename*)))

(in-package :tiny-xai)


#|
# tiny-xai: from zero to someplace cool

Tables of data are cheap; *labels* are dear: running a
benchmark, compiling a config, polling a focus group. So the
question is not "how good is the model?" but "how few labels
buy a good answer?"

One table runs through this whole file: auto93, 398 cars
from the 1970s-80s. Every idea below acts on these same
rows, so each new concept is just a new thing happening to
data you already know. Every demo prints what it sees and
asserts what must hold; outputs are machine-made, never
hand-copied.
|#


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

| calls    | takes     | returns                        |
|----------|-----------|--------------------------------|
| `mapcsv` | fun, file | calls fun on each row (vector) |
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

| calls   | takes  | returns                          |
|---------|--------|----------------------------------|
| `thing` | string | number, `?`, t, nil, or the text |
|#

(defun eg--thing ()
  "String coercion round-trip"
  (let ((got (mapcar #'thing '(" 23 " "3.14" "-1e2"
                               "?" "True" "False" "abc"))))
    (print got)
    (assert (equal got '(23 3.14 -100.0 ? t nil "abc")))))


#|
## Knobs

Where did the file name come from? One `settings` struct
holds every knob; slot names double as CLI flags, so --file
swaps the table and --seed the randomness. Notice
--budget 50: the whole game is spending it well.

| calls        | takes | returns                        |
|--------------|-------|--------------------------------|
| `*my*` (var) | --    | `settings`; slots = CLI flags  |
|#

(defun eg--my ()
  "Print the settings"
  (format t "~&~s~%" *my*)
  (assert (settings-p *my*)))


#|
## Symbolic columns

Lowercase header names (like origin) make `sym` columns:
things we can only count and compare. First a case tiny
enough to check by eye, then the table's own origin column.
Notice entropy: high when counts are even, low when one
value dominates.

| calls    | takes      | returns                  |
|----------|------------|--------------------------|
| `add`    | sym, value | the value (now counted)  |
| `mid`    | sym        | the mode                 |
| `spread` | sym        | entropy of the counts    |
|#

(defun eg--sym (&aux (i (make-sym)))
  "Sym mode and entropy: tiny case, then a real column"
  (dolist (v '(a a a a b b c)) (add i v))
  (format t "~&(a a a a b b c): mid ~a ent ~,3f~%"
          (mid i) (spread i))
  (assert (eq (mid i) 'a))
  (assert (< (abs (- (spread i) 1.379)) 0.01))
  (let* ((d (make-data (? *my* --file)))
         (origin (find "origin" (? d cols all)
                       :key (lambda (c) (? c txt))
                       :test #'equal)))
    (when origin
      (format t "origin: mid ~a ent ~,3f~%"
              (mid origin) (spread origin)))))


#|
## Numeric columns

Uppercase names (like Mpg+) make `num` columns: things we
can average. Folding all 398 Mpg cells one at a time
(Welford's trick: no list kept, just n, mu, m2) gives the
column's mean and standard deviation. Notice: the average
1970s car did about 24 mpg.

| calls       | takes     | returns                    |
|-------------|-----------|----------------------------|
| `make-data` | file name | data: rows + col summaries |
| `mid`       | num       | mean                       |
| `spread`    | num       | standard deviation         |
|#

(defun eg--num (&aux (i (make-data (? *my* --file))))
  "Fold one num column; watch mu and sd emerge"
  (let ((mpg (car (last (? i cols y)))))
    (format t "~&~a: n ~a mu ~,2f sd ~,2f~%"
            (? mpg txt) (? mpg n) (mid mpg) (spread mpg))
    (when (search "auto93" (? *my* --file))
      (assert (< (abs (- (mid mpg) 23.84)) 0.1))
      (assert (< (abs (- (spread mpg) 8.34)) 0.1)))))


#|
## Reproducible randomness

Later demos shuffle and sample, so first: `rand`, a seeded
16807 Lehmer generator that repeats exactly on sbcl and
clisp (Common Lisp's own `random` does not). The second
check sums three uniforms 10,000 times (Irwin-Hall): mean
lands on 0, sd on 1 -- testing `rand`, `add`, and Welford
in one shot.

| calls  | takes      | returns                     |
|--------|------------|-----------------------------|
| `rand` | n (opt)    | seeded float in 0..n        |
| `rint` | n          | integer 0 <= i < n          |
| `add`  | num, value | the value (Welford update)  |
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
  (format t "~&irwin-hall mu ~,3f sd ~,3f~%" (mid i) (spread i))
  (assert (< (abs (mid i)) 0.05))
  (assert (< (abs (- (spread i) 1)) 0.05)))


#|
## The whole table

`make-data` streams the csv once: the first row builds one
column summary per header name (trailing `-` or `+` = goal
to minimize or maximize; trailing `X` = ignore), and later
rows update them. Notice the goals: minimize Lbs-, maximize
Acc+ and Mpg+ -- light, quick, thrifty cars win.

| calls       | takes        | returns                  |
|-------------|--------------|--------------------------|
| `make-data` | file or rows | data                     |
| `mid`       | column       | mean or mode             |
| `spread`    | column       | sd or entropy            |
|#

(defun eg--data (&aux (i (make-data (? *my* --file))))
  "Data build: col roles and goal stats"
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

| calls   | takes          | returns                   |
|---------|----------------|---------------------------|
| `disty` | data, row      | 0..1; 0 = ideal goals     |
| `distx` | data, row, row | 0..1 over the x cols only |
|#

(defun eg--dists (&aux (i (make-data (? *my* --file))))
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
## When do two results differ?

One tool before any experiment: `same` calls two lists of
numbers equal only if `cohen` AND `cliffs` AND `ks` all
agree. Take 20 disty scores from our table: they equal
themselves, survive a 0.02 nudge, and differ after a +1
shift. Notice how conservative this is -- tiny changes are
treated as noise, so later "X beats Y" claims mean
something.

| calls  | takes  | returns                               |
|--------|--------|---------------------------------------|
| `same` | xs, ys | t iff `cohen`+`cliffs`+`ks` all agree |
|#

(defun eg--same (&aux (i (make-data (? *my* --file))) xs)
  "Same: true for a nudge, false for a shift"
  (setf xs (mapcar (lambda (r) (disty i r))
                   (few (? i rows) 20)))
  (let ((ys (mapcar (lambda (x) (+ x 0.02)) xs))
        (zs (mapcar (lambda (x) (+ x 1)) xs)))
    (format t "~&same: self ~a nudged(+.02) ~a shifted(+1) ~a~%"
            (same xs xs) (same xs ys) (same xs zs))
    (assert (same xs xs))
    (assert (same xs ys))
    (assert (not (same xs zs)))))


#|
## The active learner

The payoff. `landscape` labels a handful of rows, projects
the rest onto a line between two distant labelled poles
(good end, bad end), culls the third nearest the bad pole,
and repeats -- spending at most --budget labels. Notice the
best labelled row: found after ~45 labels, it is the kind
of car that floated to the top back when we (expensively)
scored all 398.

| calls       | takes | returns                        |
|-------------|-------|--------------------------------|
| `landscape` | data  | labelled rows, best first      |
|#

(defun eg--land (&aux (i (make-data (? *my* --file))))
  "Landscape labels few rows, sorted best first"
  (let* ((lab (landscape i))
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
## Explaining: one cut

Why are the good cars good? `split` tries one cut per x
column and keeps the cheapest, where cost is the
size-weighted spread of the two halves. The assert: the
best cut beats the unsplit spread, else explanation would
be hopeless. Notice the winner reads like something a
mechanic would say: small engines differ from big ones.

| calls   | takes         | returns                   |
|---------|---------------|---------------------------|
| `split` | data, rows, y | cheapest (cost at v) cut  |
|#

(defun eg--cuts (&aux (i (make-data (? *my* --file))))
  "Best single cut beats the unsplit spread"
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
## Explaining: a whole tree

Recurse the cuts and a tree falls out. Each printed line is
n, the mean Mpg of those rows, then the branch condition;
read any root-to-leaf path as a rule about our cars. Notice
how few x columns the tree needs -- most columns never
mattered.

| calls    | takes         | returns                 |
|----------|---------------|-------------------------|
| `tree`   | data, rows, y | the root node           |
| `show`   | data, node    | prints the tree         |
| `leaves` | node          | list of leaf nodes      |
| `leaf`   | data, node, row | that row's leaf `mid` |
|#

(defun eg--tree (&aux (i (make-data (? *my* --file))))
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
## Grading

How good is a picked row? `wins` calibrates per table:
100 = the pick equals the best row, 0 = no better than the
median, negative = worse than median. All studies report on
this scale, so results compare across datasets. Notice the
worst row grades far below zero: picking badly is worse
than not picking at all.

| calls  | takes | returns                          |
|--------|-------|----------------------------------|
| `wins` | data  | grader: row -> win in [-100,100] |
|#

(defun eg--wins (&aux (i (make-data (? *my* --file))))
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

| calls     | takes | returns                        |
|-----------|-------|--------------------------------|
| `holdout` | data  | best checked row, unseen half  |
|#

(defun eg--holdout (&aux (i (make-data (? *my* --file))))
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

| calls    | takes               | returns              |
|----------|---------------------|----------------------|
| `deltas` | data, knob, v1, v2  | prints 0 or mean gap |
|#

(defun study--holdouts (&aux (i (make-data (? *my* --file)))
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

(defun study--delta (&aux (i (make-data (? *my* --file))))
  "Rq2: active vs random labelling, budget 50"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--landscape "active" "random"))

(defun study--budgets (&aux (i (make-data (? *my* --file))))
  "Rq1: budget 50 vs 20, both active"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 50 20))

(defun study--saturate (&aux (i (make-data (? *my* --file))))
  "Rq1 caveat: budget 200 vs 50 (sampler stops near 40)"
  (setf (? i rows) (few (? i rows) (? *my* --cap)))
  (deltas i '--budget 200 50))


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
