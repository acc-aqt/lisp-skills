;;;; Compiles cleanly but has a failing assertion, so it fails only when
;;;; checked with --test. tests/examples/test.sh uses it to prove that
;;;; *-tests.lisp examples are checked with --test.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :failing-tests
  (:use :cl :util.test))

(in-package :failing-tests)

(test 3 (+ 1 1))
