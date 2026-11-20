;;; expect: FAIL
;;; expect-output: structure-let-closed-early.lisp:14: structure:
;;; expect-output: (let form starting at line 11, but that form was closed on line 13
;;; expect-output: (defun form starting at line 10
;;; The LET closes one line too early, so the last FORMAT escapes it and
;;; prints the global *SCALE*. The file reads and compiles clean.

(defvar *scale* 1)

(defun show-scaled (x)
  (let ((*scale* 2))
    (print (* x *scale*))
    (format t "scaled~%"))
    (format t "scale ~a~%" *scale*))
