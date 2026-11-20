;;; expect: FAIL
;;; expect-output: read-skips-structure.lisp:7: read:
;;; expect-no-output: structure:
;;; The first defun is never closed, so the second one, at column 0, is inside
;;; it. Only the read problem is reported: structure runs only after read.

(defun add2 (x)
  (+ x 2)

(defun add3 (x)
  (+ x 3))
