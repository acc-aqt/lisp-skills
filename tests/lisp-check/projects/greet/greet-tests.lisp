;;; expect: OK
;;; flags: --test
;;; expect-no-output: Fast loading
;;; expect-no-output: ompiling
;;; A tests file that uses its project's package: lisp-check loads greet.asd first.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :greet-tests
  (:use :cl :util.test :greet))

(in-package :greet-tests)

(test "Hello, Ada!" (greeting "Ada") :test #'string=)
