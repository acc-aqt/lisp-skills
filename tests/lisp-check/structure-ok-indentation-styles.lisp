;;; expect: OK
;;; Common indentation styles pass: 2-space bodies, arguments aligned under
;;; the first argument, LOOP keywords aligned, COND and CASE clauses,
;;; IF branches, aligned LET bindings, keyword arguments and backquote.

(defpackage :structure-ok-indentation-styles
  (:use :cl)
  (:export #:classify
           #:summarize))

(in-package :structure-ok-indentation-styles)

(defun classify (n)
  "Return a keyword naming the kind of N.
Multi-line docstrings are fine."
  (cond ((not (integerp n)) :other)
        ((minusp n)
         :negative)
        ((zerop n) :zero)
        (t
         (case (mod n 3)
           (0 :fizz)
           ((1 2)
            :plain)))))

(defun summarize (numbers &key (key #'identity)
                               (test #'plusp))
  (let ((total 0)
        (kept (remove-if-not test numbers
                             :key key)))
    (loop for n in kept
          for i from 0
          when (evenp i)
            do (incf total n)
          finally (return (values total
                                  (length kept))))))

(defun pick (flag a b)
  (if flag
      (list :then a)
      (list :else
            b)))

(defmacro with-label ((var label) &body body)
  `(let ((,var ,label))
     (format nil "~a: ~a"
             ,var
             (progn ,@body))))

(defun use-label ()
  (with-label (name "count")
    (mapcar (lambda (x)
              (* x 2))
            '(1 2
              3))))
