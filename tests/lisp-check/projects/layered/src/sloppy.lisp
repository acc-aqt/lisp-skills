;;; expect: FAIL
;;; expect-output: sloppy.lisp:8: compile: style-warning: Variable UNUSED is never used.
;;; expect-no-output: system:
;;; Warnings are not reported while the system loads, but the compile stage
;;; still reports them for the file being checked.
(in-package :layered)

(defun sloppy-double (x unused)
  (* 2 x))
