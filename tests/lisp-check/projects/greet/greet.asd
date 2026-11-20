;;;; A minimal system: lisp-check loads it before checking files in this directory.

(asdf:defsystem "greet"
  :serial t
  :components ((:file "package")
               (:file "greet")))
