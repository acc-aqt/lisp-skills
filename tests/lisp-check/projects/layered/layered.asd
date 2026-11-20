;;;; Source in src/ and tests in tests/: lisp-check finds this .asd from either.

(asdf:defsystem "layered"
  :components ((:module "src"
                :serial t
                :components ((:file "package")
                             (:file "area")
                             (:file "sloppy")))))
