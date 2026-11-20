;;;; Common traps, shown as tester assertions: (test EXPECTED FORM).

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-traps
  (:use :cl :util.test))

(in-package :lisp-writing-traps)

;;; Scheme/Clojure habits: DEFUN, not define or defn. NIL and T, not #f and #t.

(defun has-items-p (list)
  (not (null list)))

(test nil (has-items-p '()))
(test t (has-items-p (list 'a)))
(test t (eq nil '()))
(test nil (first '()))
(test 3 (funcall (lambda (x) (+ x 1)) 2))

;;; Hash tables, not Clojure maps. String keys need :TEST #'EQUAL.

(defun make-counts (words)
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (word words counts)
      (incf (gethash word counts 0)))))

(test 2 (values (gethash "b" (make-counts (list "a" "b" "b")))))
(test nil (nth-value 1 (gethash "z" (make-counts (list "a")))))

;;; Equality.

(test t (eq 'red 'red))
(test t (eql 3 3))
(test nil (eql 1 1.0))
(test t (= 1 1.0))
(test nil (eql "abc" (copy-seq "abc")))
(test t (equal "abc" (copy-seq "abc")))
(test t (equal (list 1 (list 2)) (list 1 (list 2))))
(test t (string= "abc" (copy-seq "abc")))
(test t (string-equal "ABC" "abc"))
(test t (equalp "ABC" "abc"))
(test nil (member (copy-seq "b") (list "a" "b")))
(test '("b") (member (copy-seq "b") (list "a" "b") :test #'string=) :test #'equal)

;;; DEFVAR keeps an existing value. DEFPARAMETER always sets it.
;;; Reloading a file re-runs both. Here the variables already have the value 5,
;;; as after an earlier load.

(setf (symbol-value '*counter*) 5)
(setf (symbol-value '*limit*) 5)

(defvar *counter* 0)
(defparameter *limit* 10)

(test 5 *counter*)
(test 10 *limit*)

;;; LET binds in parallel. LET* binds in order.

(test 3 (let* ((a 1) (b (+ a 2))) b))

;;; SORT is destructive. Sort a copy of data you want to keep.

(defun sorted (numbers)
  (sort (copy-list numbers) #'<))

(test '(1 2 3) (sorted (list 3 1 2)) :test #'equal)

;;; Case mode. alisp reads FOO and foo as the same symbol, named "FOO".
;;; Compare symbol names with STRING or SYMBOL-NAME, so the code also works in mlisp.

(test t (eq :red (find-symbol (string '#:red) :keyword)))
(test t (eq 'Foo 'foo))
(test nil (values (find-symbol "red" :keyword)))
