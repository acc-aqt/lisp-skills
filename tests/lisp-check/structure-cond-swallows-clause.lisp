;;; expect: FAIL
;;; expect-output: structure-cond-swallows-clause.lisp:11: structure:
;;; expect-output: (cond form starting at line 10
;;; expect-no-output: structure-cond-swallows-clause.lisp:12: structure:
;;; The first clause's ) moved past the second clause, which became part of
;;; the first clause's body. The second clause is still indented as a sibling
;;; clause of the COND, so its line sits at the first clause's column.

(defun sign-word (n)
  (cond ((minusp n) "negative"
        ((zerop n) "zero"))
        (t "positive")))
