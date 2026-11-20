;;; expect: FAIL
;;; flags: --test
;;; expect-output: test-signals-error.lisp:?: test: error while running the tests:
;;; An assertion whose form signals an error stops the tests and fails the check.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :test-signals-error
  (:use :cl :util.test))

(in-package :test-signals-error)

(defun first-word (text)
  (error "first-word: ~s has no words" text))

(test "a" (first-word "a b") :test #'equal)
