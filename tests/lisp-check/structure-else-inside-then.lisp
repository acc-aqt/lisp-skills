;;; expect: FAIL
;;; expect-output: structure-else-inside-then.lisp:13: structure:
;;; expect-output: (progn form starting at line 11
;;; expect-output: (if form starting at line 10
;;; The else-branch is indented as the IF's third argument, but the PROGN's
;;; closing paren comes after it, so the IF has no else-branch and the string
;;; is the PROGN's value. The file reads and compiles clean.

(defun sign-word (n)
  (if (minusp n)
      (progn (print n)
             "negative"
      "not negative")))
