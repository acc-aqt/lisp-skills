;;; expect: FAIL
;;; expect-output: read-comma-outside-backquote.lisp:6: read:
;;; A comma outside a backquote is a reader error.

(defmacro twice (form)
  (list 'progn ,form ,form))
