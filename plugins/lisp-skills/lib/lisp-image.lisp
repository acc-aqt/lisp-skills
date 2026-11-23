;;;; Server for bin/lisp-image. Loaded by alisp after lisp-check.lisp, whose
;;;; stages --load reuses; entry point SERVE. Not in -batch mode, which exits
;;;; on entering the debugger before *DEBUGGER-HOOK* can abort the request.
;;;;
;;;; It listens on a localhost port. bin/lisp-eval connects, sends a header
;;;; line "eval SECONDS TOKEN" or "load SECONDS TOKEN" and then the forms or
;;;; the file's path, and closes its side. The answer is the output, then OK or
;;;; FAIL. TOKEN must match the image's token file, which only its user can
;;;; read, so other users on the machine cannot run code in the image.

(require :sock)

(defpackage :lisp-image (:use :cl))
(in-package :lisp-image)

(defvar *image-package* (find-package :cl-user)
  "The package forms are read and evaluated in. An IN-PACKAGE carries over to
the next request, as at a REPL.")

(defun problem (message)
  (format t "~&eval: ~a~%" (lisp-check::one-line message)))

(defun print-values (values)
  "Print VALUES, cutting long lists short so they do not flood the answer."
  (let ((*print-length* 50)
        (*print-level* 10))
    (if values
        (dolist (value values)
          (format t "~&=> ~s~%" value))
        (format t "~&=> ; no values~%"))))

(defun eval-forms (text)
  "Read and evaluate each form in TEXT, printing its values. Stop at the
first error and return NIL; return true if every form ran."
  (let ((*package* *image-package*))
    (unwind-protect
         (with-input-from-string (in text)
           (loop
             (let ((form (handler-case (read in nil in)
                           (error (condition)
                             (problem (format nil "read: ~a" condition))
                             (return nil)))))
               (when (eq form in)
                 (return t))
               (handler-case (print-values (multiple-value-list (eval form)))
                 (serious-condition (condition)
                   (problem (format nil "error: ~a" condition))
                   (return nil))))))
      (setf *image-package* *package*))))

(defun load-stage (file fasl)
  "Load FASL into the image. Unlike lisp-check's test stage, a file without
tester assertions is fine."
  (multiple-value-bind (failed passed)
      (lisp-check::load-assertions file fasl "load" "error while loading")
    (cond ((null failed) nil)
          ((plusp failed)
           (lisp-check::report-failed-assertions file failed passed)
           nil)
          (t t))))

(defun run-request (command seconds body)
  (mp:with-timeout (seconds
                    (problem (format nil "timed out after ~d seconds (set LISP_EVAL_TIMEOUT for a longer limit)"
                                     seconds))
                    nil)
    (cond ((string= command "eval") (eval-forms body))
          ((string= command "load") (lisp-check::check-file body #'load-stage))
          (t (problem (format nil "unknown request ~s" command))
             nil))))

(defvar *token* nil
  "The secret a request must carry, read from the image's token file.")

(defun words (line)
  (loop for start = 0 then (1+ end)
        for end = (position #\Space line :start start)
        collect (subseq line start end)
        while end))

(defun read-request (connection)
  "Return the command, the time limit in seconds, the token and the body of
the request."
  (destructuring-bind (&optional command seconds token &rest more)
      (words (read-line connection nil ""))
    (declare (ignore more))
    (values command
            (or (and seconds (parse-integer seconds :junk-allowed t)) 60)
            token
            (with-output-to-string (out)
              (loop for char = (read-char connection nil)
                    while char
                    do (write-char char out))))))

(defun answer (connection)
  "Run the request on CONNECTION and send back everything it printed, then OK
or FAIL."
  (setf (stream-external-format connection) :utf-8)
  (multiple-value-bind (command seconds token body) (read-request connection)
    (unless (equal token *token*)
      (format connection "lisp-eval: the image refused the request: wrong token~%")
      (finish-output connection)
      (return-from answer))
    (let* ((ok nil)
           (output
             (with-output-to-string (out)
               (let* ((terminal (make-two-way-stream (make-string-input-stream "") out))
                      (*standard-output* out)
                      (*error-output* out)
                      (*trace-output* out)
                      (*standard-input* terminal)
                      (*terminal-io* terminal)
                      (*query-io* terminal)
                      (*debug-io* terminal))
                 (setf ok (catch 'abort-request
                            (let ((*debugger-hook*
                                    (lambda (condition hook)
                                      (declare (ignore hook))
                                      (problem (format nil "error: ~a" condition))
                                      (throw 'abort-request nil))))
                              (run-request command seconds body))))
                 (fresh-line)))))
      (format connection "~a~:[FAIL~;OK~]~%" output ok)
      (finish-output connection))))

(defun write-port-file (state port)
  "Write PORT to STATE/port in one step, so a reader never sees half of it."
  (let ((temporary (format nil "~a/new-port" state)))
    (with-open-file (out temporary :direction :output :if-exists :supersede)
      (format out "~d~%" port))
    (rename-file temporary (format nil "~a/port" state))))

(defun serve ()
  (let ((state (second (sys:command-line-arguments :application t)))
        (listener (socket:make-socket :connect :passive :local-host "127.0.0.1"
                                      :local-port 0 :reuse-address t)))
    (setf *token* (with-open-file (in (format nil "~a/token" state))
                    (read-line in)))
    (let ((*load-verbose* nil))
      (require :streama)
      (require :tester))
    (write-port-file state (socket:local-port listener))
    (format t "lisp-image: listening on port ~d~%" (socket:local-port listener))
    (finish-output)
    (loop
      (let ((connection (socket:accept-connection listener)))
        (unwind-protect (ignore-errors (answer connection))
          (ignore-errors (close connection)))))))
