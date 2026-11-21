;;; expect: OK
;;; A form closed before a line is only a problem when the line is indented
;;; right of that form's ( and the form was nested deeper than the one the
;;; line is in. Siblings closed before a new form opens at the same depth,
;;; arguments aligned under a closed first argument, and forms closed before
;;; a comment line all pass.

(defun print-and-list (a b)
  (progn (print a) (list a
                         b)))

(defun pair-up (a b)
  (list (car a) (car b)
        (cdr a)
        (cdr b)))

(defun sum-evens (numbers)
  (let ((sum 0))
    (dolist (n numbers)
      (when (evenp n)
        (incf sum)))
    ;; the comment line does not reset what closed above it
    sum))
