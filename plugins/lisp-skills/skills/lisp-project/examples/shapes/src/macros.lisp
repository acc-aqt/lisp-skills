;;;; Macros load before the files that use them: area.lisp depends on this file.

(in-package :shapes)

(defmacro squared (form)
  "Multiply FORM by itself, evaluating it once."
  (let ((value (gensym "VALUE")))
    `(let ((,value ,form))
       (* ,value ,value))))
