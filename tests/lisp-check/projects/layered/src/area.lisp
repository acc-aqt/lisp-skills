;;; expect: OK
;;; expect-no-output: defined
;;; A file of the system itself: loading the system first causes no
;;; redefinition warnings when the file is compiled again.
(in-package :layered)

(defun square-area (side)
  (* side side))
