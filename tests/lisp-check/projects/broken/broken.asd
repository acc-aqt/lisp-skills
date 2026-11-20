;;;; A system that fails to load: unbalanced.lisp never closes a form.

(asdf:defsystem "broken"
  :serial t
  :components ((:file "package")
               (:file "unbalanced")))
