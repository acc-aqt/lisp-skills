;;;; Driver for bin/lisp-check. Loaded by alisp -batch; entry point MAIN.

(defpackage :lisp-check (:use :cl))
(in-package :lisp-check)

(defvar *file* nil "The file being checked, as given on the command line.")
(defvar *text* "" "The contents of *FILE*.")

(defun file-text (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((text (make-string (file-length in))))
      (subseq text 0 (read-sequence text in)))))

(defun line-at (position)
  (1+ (count #\Newline *text* :end (max 0 (min position (length *text*))))))

(defun one-line (thing)
  (let ((*print-readably* nil))
    (string-trim " " (substitute #\Space #\Newline (princ-to-string thing)))))

(defun report (line stage message)
  (format t "~a:~a: ~a: ~a~%" *file* (or line "?") stage (one-line message)))

(defun skip-blank (position)
  "Return the position of the next character in *TEXT* that is not whitespace
or inside a ; comment."
  (loop
    (loop while (and (< position (length *text*))
                     (member (char *text* position)
                             '(#\Space #\Tab #\Newline #\Return #\Page)))
          do (incf position))
    (if (and (< position (length *text*)) (char= (char *text* position) #\;))
        (setf position (or (position #\Newline *text* :start position)
                           (length *text*)))
        (return position))))

(defun read-stage ()
  "Read every form with *READ-SUPPRESS* so only syntax is checked."
  (let ((*read-suppress* t))
    (with-input-from-string (in *text*)
      (loop
        (let ((start (skip-blank (file-position in))))
          (handler-case (when (eq (read in nil in) in)
                          (return t))
            (end-of-file ()
              (report (line-at start) "read"
                      "form starting here is never closed (missing ')', '\"' or '|#')")
              (return nil))
            (error (condition)
              (report (line-at (1- (file-position in))) "read" condition)
              (return nil))))))))

(defun warning-line (condition)
  "Return the line of the top-level form CONDITION was signalled for, or NIL.
Uses Allegro internals, so any surprise yields NIL."
  (let* ((plist (ignore-errors (slot-value condition 'excl::plist)))
         (position (or (second (getf plist :loc))
                       (ignore-errors
                        (excl::source-context-start-char (getf plist :source-context))))))
    (when (integerp position)
      (line-at position))))

(defun parent-directory (directory)
  (let ((parts (pathname-directory directory)))
    (when (rest parts)
      (make-pathname :directory (butlast parts) :name nil :type nil :defaults directory))))

(defun project-asd-files ()
  "Return the *.asd files of the nearest directory, starting at *FILE*'s own and
going up, that has any. The search stops after a directory holding .git."
  (loop for directory = (make-pathname :name nil :type nil :defaults (truename *file*))
          then (parent-directory directory)
        while directory
        do (let ((asd-files (directory (merge-pathnames "*.asd" directory))))
             (when asd-files
               (return (sort asd-files #'string< :key #'namestring)))
             (when (probe-file (merge-pathnames ".git" directory))
               (return nil)))))

(defun asdf-call (name &rest arguments)
  (apply (find-symbol name :asdf) arguments))

(defun require-asdf ()
  "Load ASDF quietly and keep its compiled files under /tmp, out of the project."
  (let ((*load-verbose* nil))
    (require :streama)
    (require :asdf))
  (asdf-call "INITIALIZE-OUTPUT-TRANSLATIONS"
             '(:output-translations (t ("/tmp/lisp-check-asdf/" :implementation))
               :ignore-inherited-configuration)))

(defun call-quietly (function)
  (let* ((quiet (make-broadcast-stream))
         (*standard-output* quiet)
         (*error-output* quiet)
         (*package* (find-package :cl-user)))
    (handler-bind ((warning #'muffle-warning))
      (funcall function))))

(defun load-systems (asd-files)
  "Register every ASD-FILE, then load the system named like each one."
  (dolist (step '("LOAD-ASD" "LOAD-SYSTEM") t)
    (dolist (asd-file asd-files)
      (handler-case
          (call-quietly (lambda ()
                          (asdf-call step (if (string= step "LOAD-ASD")
                                              asd-file
                                              (pathname-name asd-file)))))
        (error (condition)
          (report nil "system"
                  (format nil "could not load system ~s from ~a: ~a"
                          (pathname-name asd-file) (namestring asd-file)
                          (one-line condition)))
          (return-from load-systems nil))))))

(defun system-stage ()
  "Load the systems of *FILE*'s project, if it has any, so the file can use the
project's packages. Warnings are left to the compile stage."
  (let ((asd-files (project-asd-files)))
    (or (null asd-files)
        (progn (require-asdf)
               (load-systems asd-files)))))

(defun fasl-path ()
  (format nil "/tmp/lisp-check-~d.fasl" (excl::getpid)))

(defun compile-stage (fasl)
  "Compile *FILE* into FASL. Every warning is a problem."
  (let ((ok t)
        (error-position nil))
    (handler-case
        (handler-bind ((warning
                         (lambda (condition)
                           (setf ok nil)
                           (report (warning-line condition) "compile"
                                   (format nil "~:[warning~;style-warning~]: ~a"
                                           (typep condition 'style-warning)
                                           (one-line condition)))
                           (muffle-warning condition)))
                       (stream-error
                         (lambda (condition)
                           (setf error-position
                                 (ignore-errors
                                  (file-position (stream-error-stream condition)))))))
          (let ((*package* (find-package :cl-user))
                (*load-verbose* nil))
            (compile-file *file* :output-file fasl :verbose nil :print nil
                                 :external-format :utf-8)))
      (error (condition)
        (setf ok nil)
        (report (and error-position (line-at (1- error-position)))
                "compile" condition)))
    ok))

(defun tester-variable (name)
  (find-symbol name :util.test))

(defun test-stage (fasl)
  "Load FASL, which runs the file's top-level tester assertions.
Tester prints each failing assertion itself; this adds one summary line."
  (let ((*load-verbose* nil))
    (require :tester))
  (let ((errors (tester-variable "*TEST-ERRORS*"))
        (successes (tester-variable "*TEST-SUCCESSES*")))
    (progv (list errors successes) (list 0 0)
      (handler-case (let ((*package* (find-package :cl-user)))
                      (load fasl :verbose nil :print nil))
        (error (condition)
          (report nil "test" (format nil "error while running the tests: ~a"
                                     (one-line condition)))
          (return-from test-stage nil)))
      (let ((failed (symbol-value errors))
            (passed (symbol-value successes)))
        (cond ((plusp failed)
               (report nil "test" (format nil "~d of ~d assertions failed"
                                          failed (+ failed passed)))
               nil)
              ((zerop passed)
               (report nil "test" "no tester assertions ran (write them as top-level (test ...) forms, not inside with-tests)")
               nil)
              (t t))))))

(defun main ()
  (let* ((arguments (rest (sys:command-line-arguments :application t)))
         (*file* (first arguments))
         (*text* (file-text *file*))
         (fasl (fasl-path))
         (ok (unwind-protect
                  (and (read-stage)
                       (system-stage)
                       (compile-stage fasl)
                       (or (not (member "--test" arguments :test #'string=))
                           (test-stage fasl)))
               (ignore-errors (delete-file fasl)))))
    (format t "~:[FAIL~;OK~]~%" ok)
    (finish-output)
    (excl:exit (if ok 0 1) :quiet t)))
