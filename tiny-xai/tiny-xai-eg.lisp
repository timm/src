; vim: set lispwords+=loop,aif :
;;;; Tutorial and tests for tiny-xai (library: tiny-xai.lisp).
;;;; Prose lives in #| markdown |# blocks; each demo is one
;;;; eg-- function; a postprocessor appends each demo's real
;;;; output. One -eg file per engine file, loaded below in
;;;; tutorial order. Run any demo by flag:
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

One table runs through this whole tutorial: auto93, 398 cars
from the 1970s-80s. Every idea below acts on these same
rows, so each new concept is just a new thing happening to
data you already know. Every demo prints what it sees and
asserts what must hold; outputs are machine-made, never
hand-copied.
|#


#|
## Knobs

One `settings` struct holds every knob; slot names double
as CLI flags, so --file swaps the table and --seed the
randomness. Notice --budget 50: the whole game is spending
it well.

| call | returns | what |
|------|---------|------|
| `*my*` | `settings` struct | knobs; slots = CLI flags |
|#

(defun eg--my ()
  "Print the settings"
  (format t "~&~s~%" *my*)
  (assert (settings-p *my*)))

; The tutorial, one -eg file per engine file, in reading
; order (see each file's #| markdown |# prose).
(dolist (f '("lib-eg" "macros-eg" "cols-eg" "query-eg"
             "rand-eg" "tbl-eg" "dist-eg" "stats-eg"
             "acquire-eg" "bins-eg" "tree-eg" "main-eg"))
  (load (merge-pathnames
          (concatenate 'string f ".lisp")
          #.(or *compile-file-truename* *load-truename*))))


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
