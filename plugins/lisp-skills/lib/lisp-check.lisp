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

(defun fasl-path ()
  (format nil "/tmp/lisp-check-~d.fasl" (excl::getpid)))

(defun compile-stage ()
  "Compile *FILE* into a temporary fasl. Every warning is a problem."
  (let ((ok t)
        (fasl (fasl-path))
        (error-position nil))
    (unwind-protect
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
               (let ((*package* (find-package :cl-user)))
                 (compile-file *file* :output-file fasl :verbose nil :print nil
                                      :external-format :utf-8)))
           (error (condition)
             (setf ok nil)
             (report (and error-position (line-at (1- error-position)))
                     "compile" condition)))
      (ignore-errors (delete-file fasl)))
    ok))

(defun main ()
  (let* ((*file* (second (sys:command-line-arguments :application t)))
         (*text* (file-text *file*))
         (ok (and (read-stage) (compile-stage))))
    (format t "~:[FAIL~;OK~]~%" ok)
    (finish-output)
    (excl:exit (if ok 0 1) :quiet t)))
