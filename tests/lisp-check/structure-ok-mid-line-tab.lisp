;;; expect: OK
;;; A tab after the indentation advances to the next multiple of 8 columns,
;;; as in most editors. Below, (* x 2) starts at column 8 and closes on its
;;; line; the next argument is aligned under it, so it is a sibling. Counting
;;; the tab as one column would put (* x 2) at column 7 and misjudge x as
;;; inside it.

(defun double-plus (x)
  (+ 1	(* x 2)
        x))
