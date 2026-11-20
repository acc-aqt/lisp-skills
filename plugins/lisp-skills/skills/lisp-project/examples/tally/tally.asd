;;;; System definition for the tally example project.
;;;; :serial t loads the components in the order listed: the package first.

(asdf:defsystem "tally"
  :description "Count how often each word occurs in a text."
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:file "tally"))
  :in-order-to ((test-op (load-op "tally/tests"))))

;;; Loading the tests system runs its top-level tester assertions.
(asdf:defsystem "tally/tests"
  :depends-on ("tally" (:require "tester"))
  :components ((:file "tally-tests")))
