;;; expect: FAIL
;;; expect-output: read-missing-paren.lisp:9: read:
;;; The second defun is never closed; the error points at the line where it starts.

(defun add1 (x)
  "Return X plus one."
  (+ x 1))

(defun add2 (x)
  (+ x 2)

(defun add3 (x)
  (+ x 3))
