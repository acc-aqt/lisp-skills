;;; expect: FAIL
;;; flags: --test
;;; expect-output: structure-and-test.lisp:20: structure:
;;; expect-output: test: 1 of 2 assertions failed
;;; A structure problem does not stop the test stage. The failing assertion
;;; shows what the misplaced paren did: N is inside the WHEN, so a positive
;;; number gives NIL.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :structure-and-test
  (:use :cl :util.test))

(in-package :structure-and-test)

(defun clamp-negative (n)
  (when (minusp n)
    (setf n 0)
  n))

(test 0 (clamp-negative -5))
(test 3 (clamp-negative 3))
