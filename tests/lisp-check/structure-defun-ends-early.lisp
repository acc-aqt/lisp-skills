;;; expect: FAIL
;;; expect-output: structure-defun-ends-early.lisp:10: structure:
;;; expect-output: (defun form starting at line 8, but that form was closed on line 9
;;; expect-output: by the parens it is at top level
;;; The DEFUN body ends one form early: the last FORMAT runs once, when the
;;; file loads, and not when GREET is called. The file reads and compiles clean.

(defun greet (name)
  (format t "Hello, ~a~%" name))
  (format t "Goodbye~%")
