;;; expect: FAIL
;;; expect-output: read-extra-paren.lisp:7: read:
;;; One closing parenthesis too many at the end of the defun.

(defun add1 (x)
  "Return X plus one."
  (+ x 1)))

(defun add2 (x)
  (+ x 2))
