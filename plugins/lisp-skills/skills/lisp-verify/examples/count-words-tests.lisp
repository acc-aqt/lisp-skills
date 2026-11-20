;;;; A test file that passes `lisp-check --test`.
;;;; Assertions are top-level tester forms, so loading the file runs them.
;;;; The function under test is defined here to keep the example to one file.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :count-words-tests
  (:use :cl :util.test))

(in-package :count-words-tests)

(defun count-words (text)
  "Return the number of space-separated words in TEXT."
  (let ((count 0)
        (in-word nil))
    (loop for char across text
          do (if (char= char #\Space)
                 (setf in-word nil)
                 (unless in-word
                   (setf in-word t)
                   (incf count))))
    count))

(test 0 (count-words ""))
(test 1 (count-words "lisp"))
(test 3 (count-words "  read  compile test "))
