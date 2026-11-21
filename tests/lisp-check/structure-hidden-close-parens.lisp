;;; expect: FAIL
;;; expect-output: structure-hidden-close-parens.lisp:14: structure:
;;; expect-output: (let form starting at line 11
;;; The ) inside the character literal, string, comment and |symbol| do not
;;; close the LET. If they did, the misplaced line would go unreported.

(defun close-parens ()
  (list #\) ")" '|)|)) ; )

(defun show-close-parens ()
  (let ((parens (close-parens)))
    (print #\)) (print ")") ; )
    (print '|)|)
  (format t "done~%")))
