;;;; Source in src/, tests in tests/, and the load order given per file
;;;; with :depends-on instead of :serial t.

(asdf:defsystem "shapes"
  :depends-on ((:require "osi"))
  :components ((:module "src"
                :components ((:file "package")
                             (:file "macros" :depends-on ("package"))
                             (:file "area" :depends-on ("package" "macros"))
                             (:file "report" :depends-on ("area")))))
  :in-order-to ((test-op (load-op "shapes/tests"))))

(asdf:defsystem "shapes/tests"
  :depends-on ("shapes" (:require "tester"))
  :components ((:module "tests"
                :components ((:file "shapes-tests")))))
