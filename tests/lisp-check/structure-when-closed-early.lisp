;;; expect: FAIL
;;; expect-output: structure-when-closed-early.lisp:12: structure:
;;; expect-output: (when form starting at line 11, but that form was closed on line 11
;;; expect-output: (dolist form starting at line 10
;;; The WHEN closes on its own line, so (INCF COUNT), indented as its body,
;;; runs for every word. The file reads and compiles clean.

(defun count-long (words)
  (let ((count 0))
    (dolist (word words)
      (when (> (length word) 3))
        (incf count))
    count))
