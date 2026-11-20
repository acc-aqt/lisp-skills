;;; expect: FAIL
;;; expect-output: unbalanced.lisp:8: read:
;;; expect-no-output: system:
;;; The read stage runs before the system is loaded, so a broken file in the
;;; system is reported with its own line.
(in-package :broken)

(defun half (x)
  (/ x 2)
