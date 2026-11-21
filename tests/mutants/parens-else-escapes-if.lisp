;;; expect: FAIL
;;; flags: --test
;;; mutant-kind: original-indentation
;;; expect-structure: caught
;;; expect-output: parens-else-escapes-if.lisp:62: structure:
;;; Mutant of plugins/lisp-skills/skills/lisp-writing/examples/parens-tests.lisp: moved the ) at line 62, column 23 to line 61, column 23 (lines of this file).
;;;; Misplaced parens: each WRONG version compiles, but does something else.
;;;; The indentation of a WRONG version shows what was meant; the parens
;;;; decide what runs.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-parens
  (:use :cl :util.test))

(in-package :lisp-writing-parens)

;;; 1. A form escapes WHEN: its ) closes before the body.
;;;    (INCF COUNT) then runs for every word. The wrong version is kept in a
;;;    string because lisp-check reports its indentation as a structure
;;;    problem.

(defparameter *count-long-wrong*
  "(lambda (words)
     (let ((count 0))
       (dolist (word words)
         (when (> (length word) 3))
           (incf count))
       count))")

(defun count-long-wrong (words)
  (funcall (compile nil (read-from-string *count-long-wrong*)) words))

(defun count-long (words)
  (let ((count 0))
    (dolist (word words)
      (when (> (length word) 3)
        (incf count)))
    count))

(test 3 (count-long-wrong (list "a" "bb" "cccc")))
(test 1 (count-long (list "a" "bb" "cccc")))

;;; 2. The else-branch is nested inside the then-branch.
;;;    The IF has no else-branch, so it returns NIL. The wrong version is
;;;    kept in a string because lisp-check reports its indentation as a
;;;    structure problem.

(defparameter *classify-wrong*
  "(lambda (n)
     (if (minusp n)
         (list :negative n
         (list :positive n))))")

(defun classify-wrong (n)
  (funcall (compile nil (read-from-string *classify-wrong*)) n))

(defun classify (n)
  (if (minusp n)
      (list :negative n))
      (list :positive n))

(test nil (classify-wrong 5))
(test '(:positive 5) (classify 5) :test #'equal)
(test '(:negative -1 (:positive -1)) (classify-wrong -1) :test #'equal)
(test '(:negative -1) (classify -1) :test #'equal)

;;; 3. Two COND clauses merge into one. The second test becomes a body
;;;    form of the first clause, and the clause returns its last form.

(defun parity-wrong (n)
  (cond ((zerop n) :zero
         (evenp n) :even)
        (t :odd)))

(defun parity (n)
  (cond ((zerop n) :zero)
        ((evenp n) :even)
        (t :odd)))

(test :even (parity-wrong 0))
(test :zero (parity 0))
(test :odd (parity-wrong 2))
(test :even (parity 2))

;;; 4. The DEFUN body ends early. The next form is no longer part of the
;;;    function: it runs once, when the file loads. The last ) is extra.

(defparameter *defun-ends-early*
  "(defun next-label (n)
     (incf n))
     (format nil \"item-~d\" n))")

(defparameter *defun-complete*
  "(defun next-label (n)
     (incf n)
     (format nil \"item-~d\" n))")

(defun second-form (string)
  "Read the form after the first one in STRING."
  (values (read-from-string string t nil
                            :start (nth-value 1 (read-from-string string)))))

(test '(defun next-label (n) (incf n))
      (values (read-from-string *defun-ends-early*))
      :test #'equal)
(test '(format nil "item-~d" n)
      (second-form *defun-ends-early*)
      :test #'equal)
(test '(defun next-label (n) (incf n) (format nil "item-~d" n))
      (values (read-from-string *defun-complete*))
      :test #'equal)
