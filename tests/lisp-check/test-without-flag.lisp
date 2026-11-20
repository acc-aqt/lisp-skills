;;; expect: OK
;;; expect-no-output: TEST FAILURE
;;; Without --test the file is only read and compiled: the failing assertion
;;; is never run.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :test-without-flag
  (:use :cl :util.test))

(in-package :test-without-flag)

(test 5 (+ 1 1))
