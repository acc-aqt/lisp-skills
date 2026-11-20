;;;; A small file that passes lisp-check.

(defpackage :clean-example
  (:use :cl)
  (:export #:count-words))

(in-package :clean-example)

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
