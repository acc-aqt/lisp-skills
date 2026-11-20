;;;; FORMAT directives, shown as tester assertions: (test EXPECTED FORM).
;;;; (format nil ...) returns a string. (format t ...) prints to standard output.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :lisp-writing-format
  (:use :cl :util.test))

(in-package :lisp-writing-format)

(test "Hello, Ada!" (format nil "Hello, ~a!" "Ada") :test #'string=)
(test "\"Ada\"" (format nil "~s" "Ada") :test #'string=)
(test "42" (format nil "~d" 42) :test #'string=)
(test "  42" (format nil "~4d" 42) :test #'string=)
(test "0042" (format nil "~4,'0d" 42) :test #'string=)
(test "1,234,567" (format nil "~:d" 1234567) :test #'string=)
(test "3.14" (format nil "~,2f" 3.14159) :test #'string=)
(test "ff" (format nil "~(~x~)" 255) :test #'string=)
(test "101" (format nil "~b" 5) :test #'string=)
(test "a   |" (format nil "~4a|" "a") :test #'string=)
(test "   a|" (format nil "~4@a|" "a") :test #'string=)
(test "1 file" (format nil "~d file~:p" 1) :test #'string=)
(test "2 files" (format nil "~d file~:p" 2) :test #'string=)
(test "a, b, c" (format nil "~{~a~^, ~}" '("a" "b" "c")) :test #'string=)
(test "yes" (format nil "~:[no~;yes~]" t) :test #'string=)
(test "line 1
line 2" (format nil "line 1~%line 2") :test #'string=)
(test "100%" (format nil "~d%" 100) :test #'string=)
(test "~" (format nil "~~") :test #'string=)

;;; Lisp strings have no \n escape: "\n" is just "n". Use ~% for a newline.
(test "n" "\n" :test #'string=)

;;; Pass a stream to write to it. ~& starts a fresh line only if needed.
(defun write-report (stream name count)
  (format stream "~&~a: ~d item~:p~%" name count))

(test "disk: 3 items
" (with-output-to-string (s) (write-report s "disk" 3)) :test #'string=)
