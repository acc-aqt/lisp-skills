;;; expect: OK
;;; flags: --test
;;; expect-no-output: Fast loading
;;; expect-no-output: tester patch
;;; A test file whose tester assertions all pass.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :test-passing
  (:use :cl :util.test))

(in-package :test-passing)

(defun add1 (x)
  (+ x 1))

(test 2 (add1 1))
(test "ab" (concatenate 'string "a" "b") :test #'string=)
(test-error (car 1) :condition-type 'type-error)
