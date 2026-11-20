;;;; One file, one package. Code in lower case reads the same in alisp and mlisp.

(defpackage :greeting
  (:use :cl)
  (:export #:greet))

(in-package :greeting)

(defparameter *greeting* "Hello"
  "The word GREET puts before the name.")

(defun greet (name)
  "Return a greeting for NAME, for example \"Hello, Ada!\"."
  (format nil "~a, ~a!" *greeting* name))
