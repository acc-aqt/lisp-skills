;;; expect: FAIL
;;; expect-output: compile-undefined-variable.lisp:5: compile: style-warning: Free reference to undeclared variable *LIMIT* assumed special.
;;; A variable that is never defined with defvar or defparameter.

(defun over-limit-p (x)
  (> x *limit*))
