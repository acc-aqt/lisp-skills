;;; expect: FAIL
;;; expect-output: compile-warning.lisp:6: compile: warning: CAR should be given exactly 1 argument
;;; Calling a standard function with the wrong number of arguments is a
;;; compiler warning.

(defun first-of (list)
  (car list list))
