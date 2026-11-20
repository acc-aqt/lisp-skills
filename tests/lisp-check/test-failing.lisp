;;; expect: FAIL
;;; flags: --test
;;; expect-output: test-failing.lisp:?: test: 1 of 2 assertions failed
;;; expect-output: (ADD1 1)
;;; expect-no-output: (ADD1 2)
;;; One assertion fails: the output names it, and not the one that passes.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :test-failing
  (:use :cl :util.test))

(in-package :test-failing)

(defun add1 (x)
  (+ x 1))

(test 5 (add1 1))
(test 3 (add1 2))
