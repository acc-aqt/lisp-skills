;;; expect: FAIL
;;; expect-output: read-stops-before-compile.lisp:9: read:
;;; expect-no-output: : compile:
;;; The file has a compile problem (unused B) and a read problem (extra paren).
;;; Only the read problem is reported: a file that does not read is not compiled.

(defun add (a b)
  (+ a 1))
(defun sub1 (x) (- x 1)))
