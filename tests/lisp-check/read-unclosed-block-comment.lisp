;;; expect: FAIL
;;; expect-output: read-unclosed-block-comment.lisp:8: read:
;;; A #| block comment without its closing |#.

(defun add1 (x)
  (+ x 1))

#| Old version:
(defun add1 (x)
  (1+ x))
