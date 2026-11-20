;;;; CLOS: classes, generic functions, methods.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-clos
  (:use :cl :util.test))

(in-package :lisp-writing-clos)

;;; A slot has :initarg (for make-instance), :initform (default),
;;; and :reader or :accessor (generated functions).
(defclass shape ()
  ((name :initarg :name :initform "shape" :reader shape-name)))

(defclass rectangle (shape)
  ((width :initarg :width :accessor rectangle-width)
   (height :initarg :height :accessor rectangle-height))
  (:default-initargs :name "rectangle"))

(defclass circle (shape)
  ((radius :initarg :radius :reader circle-radius))
  (:default-initargs :name "circle"))

;;; DEFGENERIC once, then one DEFMETHOD per class.
(defgeneric area (shape)
  (:documentation "Return the area of SHAPE."))

(defmethod area ((shape rectangle))
  (* (rectangle-width shape) (rectangle-height shape)))

(defmethod area ((shape circle))
  (* pi (expt (circle-radius shape) 2)))

(test 12 (area (make-instance 'rectangle :width 3 :height 4)))
(test "circle" (shape-name (make-instance 'circle :radius 1)) :test #'string=)
(test t (typep (make-instance 'circle :radius 1) 'shape))

;;; An :accessor can be used with SETF.
(test 10 (let ((r (make-instance 'rectangle :width 3 :height 4)))
           (setf (rectangle-width r) 10)
           (rectangle-width r)))

;;; A method on the parent class works for every subclass.
(defgeneric describe-shape (shape))

(defmethod describe-shape ((shape shape))
  (format nil "a ~a with area ~,2f" (shape-name shape) (area shape)))

(test "a circle with area 3.14" (describe-shape (make-instance 'circle :radius 1))
      :test #'string=)

;;; CALL-NEXT-METHOD runs the parent's method.
(defclass square (rectangle) ()
  (:default-initargs :name "square"))

(defmethod describe-shape ((shape square))
  (concatenate 'string (call-next-method) " (square)"))

(test "a square with area 4.00 (square)"
      (describe-shape (make-instance 'square :width 2 :height 2))
      :test #'string=)

;;; Validate slots in an :AFTER method on INITIALIZE-INSTANCE.
(defmethod initialize-instance :after ((shape circle) &key)
  (unless (plusp (circle-radius shape))
    (error "Radius must be positive, got ~a." (circle-radius shape))))

(test-error (make-instance 'circle :radius -1))

;;; PRINT-OBJECT controls how an object prints.
(defmethod print-object ((shape rectangle) stream)
  (print-unreadable-object (shape stream :type t)
    (format stream "~ax~a" (rectangle-width shape) (rectangle-height shape))))

(test "#<RECTANGLE 3x4>" (princ-to-string (make-instance 'rectangle :width 3 :height 4))
      :test #'string=)
