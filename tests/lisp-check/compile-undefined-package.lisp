;;; expect: FAIL
;;; expect-output: compile-undefined-package.lisp:7: compile: Package "NO-SUCH-PACKAGE" not found.
;;; A symbol in a package that does not exist reads fine with syntax checking
;;; only, so the compile stage is what catches it.

(defun greet ()
  (no-such-package:say "hello"))
