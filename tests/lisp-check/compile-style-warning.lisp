;;; expect: FAIL
;;; expect-output: compile-style-warning.lisp:5: compile: style-warning: Variable B is never used.
;;; A style warning, here an unused variable, also fails the check.

(defun add (a b)
  (+ a 1))
