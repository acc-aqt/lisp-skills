;;;; Tests for the tally system. `lisp-check --test` loads tally.asd first,
;;;; so this file can use the :tally package.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :tally-tests
  (:use :cl :util.test :tally))

(in-package :tally-tests)

(test '("the" "cat" "sat") (split-words "The cat, sat.") :test #'equal)
(test '() (split-words "  ... ") :test #'equal)

(defparameter *counts* (tally-words "the cat and the hat and the bat"))

(test 3 (word-count *counts* "the"))
(test 3 (word-count *counts* "THE"))
(test 0 (word-count *counts* "dog"))
(test 5 (hash-table-count *counts*))
;; gethash returns two values; test wants one, so keep the first with values.
(test 2 (values (gethash "and" *counts*)))
(test '(("the" . 3) ("and" . 2) ("bat" . 1))
      (top-words *counts* 3)
      :test #'equal)
