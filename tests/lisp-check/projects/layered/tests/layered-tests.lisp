;;; expect: OK
;;; flags: --test
;;; A tests file in a subdirectory: lisp-check walks up to layered.asd.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :layered-tests
  (:use :cl :util.test :layered))

(in-package :layered-tests)

(test 9 (square-area 3))
