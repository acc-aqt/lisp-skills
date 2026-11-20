;;; expect: FAIL
;;; expect-output: read-unterminated-string.lisp:5: read:
;;; The docstring is missing its closing double quote.

(defun add1 (x)
  "Return X plus one.
  (+ x 1))
