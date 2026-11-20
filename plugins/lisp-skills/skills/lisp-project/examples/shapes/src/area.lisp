(in-package :shapes)

(defun square-area (side)
  "Return the area of a square with sides of length SIDE."
  (squared side))

(defun circle-area (radius)
  "Return the area of a circle with radius RADIUS."
  (* pi (squared radius)))
