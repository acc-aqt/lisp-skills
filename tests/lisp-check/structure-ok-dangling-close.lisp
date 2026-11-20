;;; expect: OK
;;; Closing parens on a line of their own are not idiomatic Lisp, but they
;;; don't change the nesting: a line that starts with ) is not checked.

(defun count-evens (numbers)
  (let ((count 0))
    (dolist (n numbers)
      (when (evenp n)
        (incf count))
    )
    count
  )
)
