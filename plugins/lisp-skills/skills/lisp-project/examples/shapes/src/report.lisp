;;;; Uses the built-in osi module, which shapes.asd loads with (:require "osi").

(in-package :shapes)

(defun area-report (side)
  "Return a line describing the area of a square with sides of length SIDE."
  (format nil "A square with side ~a has area ~a." side (square-area side)))

(defun machine-name ()
  "Return the name of this machine, as printed by uname -n."
  (first (excl.osi:command-output "uname -n")))
