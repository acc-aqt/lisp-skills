;;; expect: FAIL
;;; expect-output: structure-and-compile.lisp:10: structure:
;;; expect-output: structure-and-compile.lisp:7: compile: warning: CAR should be given exactly 1 argument
;;; A structure problem does not stop the compile stage: the compile problem
;;; caused by the same misplaced paren is reported too, after it.

(defun first-twice (list)
  (list (car list)
        (car list
        list)))
