;;;; Tests for the shapes system. lisp-check finds shapes.asd in the parent
;;;; directory and loads it, so this file can use the :shapes package.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :shapes-tests
  (:use :cl :util.test :shapes))

(in-package :shapes-tests)

(test 9 (square-area 3))
(test 4 (square-area (+ 1 1)))
(test t (< 3.14 (circle-area 1) 3.15))
(test "A square with side 2 has area 4." (area-report 2) :test #'string=)
(test t (stringp (machine-name)))
