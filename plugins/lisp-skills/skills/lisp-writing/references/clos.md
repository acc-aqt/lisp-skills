### CLOS cheat-sheet

From `examples/clos-tests.lisp`, which passes `lisp-check --test`.

Define classes. A slot has `:initarg` (the keyword for `make-instance`),
`:initform` (the default) and `:reader` or `:accessor` (generated functions).

```lisp
(defclass shape ()
  ((name :initarg :name :initform "shape" :reader shape-name)))

(defclass rectangle (shape)
  ((width :initarg :width :accessor rectangle-width)
   (height :initarg :height :accessor rectangle-height))
  (:default-initargs :name "rectangle"))
```

Make an instance with keyword arguments, and quote the class name:
`(make-instance 'rectangle :width 3 :height 4)`.

Write `defgeneric` once, then one `defmethod` per class:

```lisp
(defgeneric area (shape)
  (:documentation "Return the area of SHAPE."))

(defmethod area ((shape rectangle))
  (* (rectangle-width shape) (rectangle-height shape)))

(defmethod area ((shape circle))
  (* pi (expt (circle-radius shape) 2)))
```

A method on a parent class works for every subclass. `call-next-method`
runs the parent's method:

```lisp
(defmethod describe-shape ((shape square))
  (concatenate 'string (call-next-method) " (square)"))
```

Validate in an `:after` method on `initialize-instance`:

```lisp
(defmethod initialize-instance :after ((shape circle) &key)
  (unless (plusp (circle-radius shape))
    (error "Radius must be positive, got ~a." (circle-radius shape))))
```

Control printing with `print-object`:

```lisp
(defmethod print-object ((shape rectangle) stream)
  (print-unreadable-object (shape stream :type t)
    (format stream "~ax~a" (rectangle-width shape) (rectangle-height shape))))

(test "#<RECTANGLE 3x4>" (princ-to-string (make-instance 'rectangle :width 3 :height 4))
      :test #'string=)
```

- Change a slot through its accessor: `(setf (rectangle-width r) 10)`.
  Use `slot-value` only inside methods that have no accessor.
- Check a type with `typep`: `(typep x 'shape)`.
- Give every `defmethod` the same required arguments as its `defgeneric`.
  A mismatch compiles without a warning but signals an error when the file
  loads, so check such files with `lisp-check --test`.
