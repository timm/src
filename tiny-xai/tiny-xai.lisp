; vim: set lispwords+=loop,aif :
;;;; Landscape analysis for XAI and optimization CSVs:
;;;; summarize columns, learn distances, sample landscapes,
;;;; grow trees, and grade how few labels buy a good row.
;;;;
;;;; This file owns the package, constants, help text,
;;;; settings and structs, then loads everything else --
;;;; macros first, so the `$` reader macro is live before
;;;; any other file is read. All state lives in six
;;;; structs: `settings` holds the knobs (slot names double
;;;; as CLI flags); `sym` and `num` summarize one column
;;;; each; `cols` and `tbl` hold tables; `node` is one tree
;;;; node.

(defpackage :tiny-xai (:use :common-lisp))
(in-package :tiny-xai)

#+sbcl (declaim (sb-ext:muffle-conditions
                  warning style-warning))

(defconstant +tiny+ 1e-32)
(defconstant +big+  1e32)

(defvar *help* "
tiny-xai: explainable multi-objective optimization, tiny-ly.
(c) 2026 Tim Menzies <timm@ieee.org> (see LICENSE.md).

Samples a data landscape under a small labelling budget,
grows a regression tree over the labels, picks good rows,
and shows which x-ranges explain them.

USAGE: sbcl --script tiny-xai-eg.lisp [--key val ..] [--run ..]

CSVs name their column roles in the header: leading
uppercase = numeric; trailing +/- = goal to maximize or
minimize; trailing X = ignore; ? cells = missing.

Every OPTION below is a flag (e.g. --seed 1 --file x.csv).
Every TEST and STUDY runs by its flag (e.g. --all --tree).")

; Settings slots ARE the CLI flags (see cli, help)
(defstruct (settings (:conc-name))
  (--seed 1234567891) (--p 2) (--depth 4)
  (--leaf 3) (--budget 50) (--cap 1024) (--check 5) (--more 4)
  (--keepf 0.66) (--acquire "active")
  (--file  "$MOOT/optimize/misc/auto93.csv"))

(defvar *my* (make-settings))

(defstruct sym (at 0) (txt " ") (n 0) (w 1) (has (o)))

(defstruct num (at 0) (txt " ") (n 0) (w 1) (mu 0.0) (m2 0.0))

(defstruct (cols (:constructor %make-cols)) names all x y)

(defstruct (tbl (:constructor %make-tbl)) cols rows)

(defstruct node at v n mid rows yes no)

; One load point for the whole engine: macros first, then
; each file in dependency order, each loaded exactly once.
(dolist (f '("macros" "lib" "rand" "cols" "query" "tbl"
             "dist" "acquire" "bins" "tree" "stats"
             "main"))
  (load (merge-pathnames
          (concatenate 'string f ".lisp")
          #.(or *compile-file-truename* *load-truename*))))
