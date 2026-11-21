;;; expect: FAIL
;;; flags: --test
;;; mutant-kind: re-indented
;;; expect-structure: missed
;;; expect-no-output: structure:
;;; Mutant of plugins/lisp-skills/skills/lisp-writing/examples/conditions-tests.lisp: moved the ) at line 35, column 32 to line 36, column 5 (lines of this file), then re-indented to match.
;;;; Conditions: signalling, handling, restarts, cleanup.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-conditions
  (:use :cl :util.test))

(in-package :lisp-writing-conditions)

;;; HANDLER-CASE catches an error and returns the clause's value.
;;; Catch the most specific condition type you expect.
;;; PARSE-INTEGER returns two values; VALUES keeps only the first.
(defun parse-number-or-default (string default)
  (handler-case (values (parse-integer string))
    (parse-error () default)))

(test 42 (parse-number-or-default "42" 0))
(test 0 (parse-number-or-default "abc" 0))

;;; DEFINE-CONDITION makes your own condition type. :REPORT gives its message.
(define-condition invalid-age (error)
  ((age :initarg :age :reader invalid-age-value))
  (:report (lambda (condition stream)
             (format stream "Age ~a is not valid." (invalid-age-value condition)))))

(defun check-age (age)
  (unless (<= 0 age 150)
    (error 'invalid-age :age age)
    age))

(test 30 (check-age 30))
(test-error (check-age -1) :condition-type 'invalid-age)

;;; Bind the condition to a variable to read it. PRINC-TO-STRING gives the report.
(defun age-error-message (age)
  (handler-case (check-age age)
    (invalid-age (condition) (princ-to-string condition))))

(test "Age -1 is not valid." (age-error-message -1) :test #'string=)

;;; RESTART-CASE offers ways to recover. HANDLER-BIND picks one with
;;; INVOKE-RESTART, without unwinding the code that signalled.
(defun parse-entry (string)
  (restart-case (parse-integer string)
    (use-value (value)
      :report "Use a different value."
      value)))

(defun parse-all (strings)
  (handler-bind ((parse-error (lambda (condition)
                                (declare (ignore condition))
                                (invoke-restart 'use-value 0))))
    (mapcar #'parse-entry strings)))

(test '(1 0 3) (parse-all '("1" "x" "3")) :test #'equal)

;;; UNWIND-PROTECT runs its cleanup forms even when an error leaves the body.
(defun with-cleanup-status ()
  (let ((status :open))
    (ignore-errors
     (unwind-protect (error "Something failed.")
       (setf status :closed)))
    status))

(test :closed (with-cleanup-status))

;;; WARN signals a warning and continues. ERROR stops unless handled.
(defun checked-ratio (a b)
  (when (zerop b)
    (warn "Dividing by zero; returning 0.")
    (return-from checked-ratio 0))
  (/ a b))

(test-warning (checked-ratio 1 0))
(test 1/2 (checked-ratio 1 2))
