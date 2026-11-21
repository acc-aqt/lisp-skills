;;; expect: FAIL
;;; flags: --test
;;; mutant-kind: original-indentation
;;; expect-structure: missed
;;; expect-no-output: structure:
;;; Mutant of plugins/lisp-skills/skills/lisp-writing/examples/allegro-tests.lisp: moved the ) at line 41, column 49 to line 41, column 27 (lines of this file).
;;;; Allegro CL extensions. Not portable: use them only when ANSI CL has no equivalent.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester)
  (require :osi)
  (require :regexp2))

(defpackage :lisp-writing-allegro
  (:use :cl :util.test))

(in-package :lisp-writing-allegro)

;;; Shell commands.
;;; EXCL:RUN-SHELL-COMMAND with a string runs it through /bin/sh and
;;; returns the exit code. The command's output goes to Lisp's standard output.
(test 0 (excl:run-shell-command "true"))
(test 3 (excl:run-shell-command "exit 3"))

;;; EXCL.OSI:COMMAND-OUTPUT returns three values:
;;; stdout lines, stderr lines, exit code.
(test '("a" "b") (values (excl.osi:command-output "printf 'a\\nb\\n'")) :test #'equal)
(test 4 (nth-value 2 (excl.osi:command-output "exit 4")))

;;; A vector #(program argv0 arg ...) runs the program without a shell,
;;; so arguments need no quoting.
(test '("x y") (values (excl.osi:command-output #("/bin/echo" "/bin/echo" "x y")))
      :test #'equal)

;;; To read output as a stream: :OUTPUT :STREAM :WAIT NIL returns
;;; (values stream nil pid). Close the stream, then reap the process.
(defun read-line-from-command (command)
  (multiple-value-bind (stream error-stream pid)
      (excl:run-shell-command command :output :stream :wait nil)
    (declare (ignore error-stream))
    (unwind-protect (values) (read-line stream nil)
      (close stream)
      (sys:reap-os-subprocess :pid pid))))

(test "hello" (read-line-from-command "echo hello") :test #'string=)

;;; Environment variables. NIL when unset.
(test nil (sys:getenv "LISP_WRITING_UNSET_VARIABLE"))

;;; Splitting and joining strings.
(test '("a" "b" "" "c") (excl:delimited-string-to-list "a,b,,c" #\,) :test #'equal)
(test "a,b" (excl:list-to-delimited-string '("a" "b") #\,) :test #'string=)

;;; Regular expressions (module :regexp2). MATCH-RE returns
;;; (values matched-p whole-match group-1 ...).
(test '("a" "b" "c") (excl:split-re "," "a,b,c") :test #'equal)
(test "123" (nth-value 2 (excl:match-re "([0-9]+)" "id-123")) :test #'string=)

;;; Strings to bytes. Pass :NULL-TERMINATE NIL, or a 0 byte is added.
(test 4 (length (excl:string-to-octets "abc")))
(test 3 (length (excl:string-to-octets "abc" :null-terminate nil)))
(test "abc" (values (excl:octets-to-string (excl:string-to-octets "abc" :null-terminate nil)))
      :test #'string=)

;;; Case mode of the running image. alisp: :CASE-INSENSITIVE-UPPER (ANSI).
;;; mlisp: :CASE-SENSITIVE-LOWER (not verified here: Express ships only alisp).
(test :case-insensitive-upper excl:*current-case-mode*)
