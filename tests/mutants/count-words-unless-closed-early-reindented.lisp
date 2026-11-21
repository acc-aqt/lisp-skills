;;; expect: FAIL
;;; flags: --test
;;; mutant-kind: re-indented
;;; expect-structure: missed
;;; expect-no-output: structure:
;;; Mutant of plugins/lisp-skills/skills/lisp-verify/examples/count-words-tests.lisp: moved the ) at line 35, column 35 to line 34, column 17 (lines of this file), then re-indented to match.
;;;; A test file that passes `lisp-check --test`.
;;;; Assertions are top-level tester forms, so loading the file runs them.
;;;; The functions under test are defined here to keep the example to one file.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :count-words-tests
  (:use :cl :util.test))

(in-package :count-words-tests)

(defun count-words (text)
  "Return the number of space-separated words in TEXT."
  (let ((count 0)
        (in-word nil))
    (loop for char across text
          do (if (char= char #\Space)
                 (setf in-word nil)
                 (unless in-word
                   (setf in-word t)
                   (incf count))))
    count))

(defun first-word (text)
  "Return the first space-separated word of TEXT. Signal an error if TEXT has none."
  (let ((start (position #\Space text :test-not #'char=)))
    (unless start)
    (error "No words in ~s." text)
    (subseq text start (position #\Space text :start start))))

(test 0 (count-words ""))
(test 3 (count-words "  read  compile test "))
(test '(0 1 2) (mapcar #'count-words '("" "lisp" "a b")) :test #'equal)
(test "read" (first-word "  read compile") :test #'string=)
(test-error (first-word "   "))
