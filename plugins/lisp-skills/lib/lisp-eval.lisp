;;;; Client for bin/lisp-eval. Loaded by alisp -batch; entry point MAIN.
;;;; Arguments: PORT SECONDS COMMAND BODY; the token comes in the environment
;;;; variable LISP_IMAGE_TOKEN. See lisp-image.lisp for the protocol.

(require :sock)

(defpackage :lisp-eval (:use :cl))
(in-package :lisp-eval)

(defun send-request (port seconds command body)
  "Send the request and copy the answer to standard output. Return its last line."
  (let ((socket (socket:make-socket :remote-host "127.0.0.1" :remote-port port))
        (last nil))
    (setf (stream-external-format socket) :utf-8)
    (unwind-protect
         (progn
           (format socket "~a ~d ~a~%~a" command seconds
                   (sys:getenv "LISP_IMAGE_TOKEN") body)
           (finish-output socket)
           (socket:shutdown socket :direction :output)
           (loop for line = (read-line socket nil)
                 while line
                 do (write-line line)
                    (setf last line)))
      (close socket))
    last))

(defun main ()
  (destructuring-bind (port seconds command body)
      (rest (sys:command-line-arguments :application t))
    (let* ((seconds (parse-integer seconds))
           (patience (+ seconds 30))
           (last (handler-case
                     (mp:with-timeout (patience
                                       (format t "~&lisp-eval: no answer within ~d seconds; the image may be stuck: lisp-image restart~%"
                                               patience)
                                       "lisp-eval:")
                       (send-request (parse-integer port) seconds command body))
                   (error (condition)
                     (format t "lisp-eval: could not reach the image on port ~a: ~a~%"
                             port condition)
                     "lisp-eval:"))))
      (finish-output)
      (excl:exit (cond ((equal last "OK") 0)
                       ((equal last "FAIL") 1)
                       (t (unless (and last (eql 0 (search "lisp-eval:" last)))
                            (format t "~&lisp-eval: the image closed the connection without answering; check it with: lisp-image status~%"))
                          (format t "FAIL~%")
                          (finish-output)
                          2))
                 :quiet t))))
