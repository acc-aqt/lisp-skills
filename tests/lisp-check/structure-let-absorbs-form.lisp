;;; expect: FAIL
;;; expect-output: structure-let-absorbs-form.lisp:11: structure:
;;; expect-output: line 9
;;; The FORMAT call is indented as the next form of the DEFUN body, after the
;;; LET, but the LET's closing paren is at the end of the function, so the
;;; call is inside the LET. The file reads and compiles clean.

(defun show-double (x)
  (let ((y (* x 2)))
    (print y)
  (format t "done~%")))
