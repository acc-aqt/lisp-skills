;;;; LOOP patterns, shown as tester assertions: (test EXPECTED FORM).

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-loop
  (:use :cl :util.test))

(in-package :lisp-writing-loop)

;;; FOR x IN walks a list. COLLECT builds a new list.
(defun squares (numbers)
  (loop for n in numbers
        collect (* n n)))

(test '(1 4 9) (squares '(1 2 3)) :test #'equal)

;;; FOR i FROM a TO b counts, including b. SUM adds.
(defun sum-to (limit)
  (loop for i from 1 to limit
        sum i))

(test 6 (sum-to 3))

;;; WHEN filters.
(defun evens (numbers)
  (loop for n in numbers
        when (evenp n) collect n))

(test '(2 4) (evens '(1 2 3 4)) :test #'equal)

;;; FOR x ACROSS walks a vector or string. COUNT counts true results.
(defun count-matches (char string)
  (loop for c across string
        count (char= c char)))

(test 3 (count-matches #\a "banana"))

;;; MAXIMIZE and MINIMIZE.
(defun largest (numbers)
  (loop for n in numbers
        maximize n))

(test 5 (largest '(3 5 1)))

;;; Two FOR clauses step together. The loop ends when the shorter list ends.
(defun pair-up (keys values)
  (loop for k in keys
        for v in values
        collect (cons k v)))

(test '((a . 1) (b . 2)) (pair-up '(a b) '(1 2)) :test #'equal)

;;; FOR i FROM 0 BELOW n counts up to n - 1.
(defun indexes (sequence)
  (loop for i from 0 below (length sequence)
        collect i))

(test '(0 1 2) (indexes "abc") :test #'equal)

;;; Hash tables: FOR k BEING THE HASH-KEYS OF table (also HASH-VALUES).
(defun make-table (keys)
  (let ((table (make-hash-table :test #'equal)))
    (dolist (k keys table)
      (setf (gethash k table) t))))

(defun hash-keys-sorted (table)
  (sort (loop for k being the hash-keys of table
              collect k)
        #'string<))

(test '("x" "y") (hash-keys-sorted (make-table '("y" "x"))) :test #'equal)

;;; RETURN leaves the loop with a value. Without it, this loop returns NIL.
(defun position-of-first-negative (numbers)
  (loop for n in numbers
        for i from 0
        when (minusp n) do (return i)))

(test 2 (position-of-first-negative '(4 0 -1 -5)))
(test nil (position-of-first-negative '(1 2)))

;;; UNTIL and WHILE stop the loop. FINALLY runs at the end.
(defun count-until-blank (lines)
  (let ((count 0))
    (loop for line in lines
          until (string= line "")
          do (incf count)
          finally (return count))))

(test 3 (count-until-blank '("a" "b" "c" "" "d")))
