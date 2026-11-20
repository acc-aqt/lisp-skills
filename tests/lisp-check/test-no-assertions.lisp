;;; expect: FAIL
;;; flags: --test
;;; expect-output: test-no-assertions.lisp:?: test: no tester assertions ran
;;; Checking a file with --test when it has no tester assertions is a mistake:
;;; nothing was tested, so it must not pass.

(defun add1 (x)
  (+ x 1))
