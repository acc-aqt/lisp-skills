;;;; The package of the tally system. It is the first component in tally.asd,
;;;; so it exists before any other file says (in-package :tally).

(defpackage :tally
  (:use :cl)
  (:export #:split-words
           #:tally-words
           #:word-count
           #:top-words))
