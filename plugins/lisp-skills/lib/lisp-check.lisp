;;;; Driver for bin/lisp-check. Loaded by alisp -batch; entry point MAIN.

(defpackage :lisp-check (:use :cl))
(in-package :lisp-check)

(defparameter *scratch-directory* "/tmp/"
  "Where lisp-check writes compiled files, so none land in the checked project.")

(defun file-text (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((text (make-string (file-length in))))
      (subseq text 0 (read-sequence text in)))))

(defun line-at (text position)
  (1+ (count #\Newline text :end (max 0 (min position (length text))))))

(defun one-line (thing)
  (let ((*print-readably* nil))
    (string-trim " " (substitute #\Space #\Newline (princ-to-string thing)))))

(defun report (file line stage message)
  (format t "~a:~a: ~a: ~a~%" file (or line "?") stage (one-line message)))

(defun skip-blank (text position)
  "Return the position of the next character in TEXT that is not whitespace
or inside a ; comment."
  (loop
    (loop while (and (< position (length text))
                     (member (char text position)
                             '(#\Space #\Tab #\Newline #\Return #\Page)))
          do (incf position))
    (if (and (< position (length text)) (char= (char text position) #\;))
        (setf position (or (position #\Newline text :start position)
                           (length text)))
        (return position))))

(defun read-stage (file text)
  "Read every form of TEXT, the contents of FILE, with *READ-SUPPRESS* so only
syntax is checked."
  (let ((*read-suppress* t))
    (with-input-from-string (in text)
      (loop
        (let ((start (skip-blank text (file-position in))))
          (handler-case (when (eq (read in nil in) in)
                          (return t))
            (end-of-file ()
              (report file (line-at text start) "read"
                      "form starting here is never closed (missing ')', '\"' or '|#')")
              (return nil))
            (error (condition)
              (report file (line-at text (1- (file-position in))) "read" condition)
              (return nil))))))))

(defstruct (open-paren (:constructor make-open-paren (line column head)))
  line column head)

(defun form-head (text position)
  "Return the token starting at POSITION in TEXT, right after a (, such as
\"let\". It is empty when the ( is followed by another ( or a space."
  (let ((end (or (position-if (lambda (char)
                                (member char '(#\Space #\Tab #\Newline #\Return
                                               #\( #\) #\" #\;)))
                              text :start position)
                 (length text))))
    (subseq text position end)))

(defun describe-form (paren)
  (cond ((null paren) "top level")
        ((string= (open-paren-head paren) "")
         (format nil "the form starting at line ~d" (open-paren-line paren)))
        (t (format nil "the (~a form starting at line ~d"
                   (open-paren-head paren) (open-paren-line paren)))))

(defstruct (closed-paren (:constructor make-closed-paren (paren depth line)))
  paren depth line)

(defun outside-problem (open column)
  "Return a message if a line indented to COLUMN sits at or left of a paren in
OPEN, the parens still open at its start, innermost first; else NIL. The line
looks like it comes after that form, but the parens keep it inside."
  (let ((outside (find-if (lambda (paren) (>= (open-paren-column paren) column))
                          open :from-end t)))
    (when outside
      (format nil "line is indented as if it came after ~a, but the parens keep it inside that form; by its indentation it belongs in ~a"
              (describe-form outside)
              (describe-form (find-if (lambda (paren) (< (open-paren-column paren) column))
                                      open))))))

(defun inside-closed-problem (open closed column)
  "Return a message if a line indented to COLUMN sits right of a paren in
CLOSED that was nested deeper than the innermost paren in OPEN; else NIL.
The line looks like it is inside that form, but the form is already closed.
Of several such parens, the deepest is named."
  (let ((inside nil))
    (dolist (entry closed)
      (when (and (< (open-paren-column (closed-paren-paren entry)) column)
                 (> (closed-paren-depth entry) (length open))
                 (or (null inside)
                     (> (closed-paren-depth entry) (closed-paren-depth inside))))
        (setf inside entry)))
    (when inside
      (format nil "line is indented as if it were inside ~a, but that form was closed on line ~d; by the parens it is ~:[in ~a~;at top level~]"
              (describe-form (closed-paren-paren inside))
              (closed-paren-line inside)
              (null open)
              (describe-form (first open))))))

(defun indentation-problem (open closed column)
  "Return a message if a line indented to COLUMN contradicts the paren nesting
at its start, else NIL. OPEN holds the parens still open, innermost first;
CLOSED the parens closed since the previous code line, latest first."
  (or (outside-problem open column)
      (inside-closed-problem open closed column)))

(defun line-indentation (text start)
  "Return the indentation of the line starting at START in TEXT as
(values COLUMN TABP), or NIL when the line is blank, a comment, or starts
with ) and so only closes forms."
  (let* ((end (or (position-if-not (lambda (char) (member char '(#\Space #\Tab)))
                                   text :start start)
                  (length text)))
         (first (and (< end (length text)) (char text end))))
    (unless (or (null first)
                (member first '(#\Newline #\Return #\; #\)))
                (and (char= first #\#)
                     (< (1+ end) (length text))
                     (char= (char text (1+ end)) #\|)))
      (values (- end start) (find #\Tab text :start start :end end)))))

(defun structure-stage (file text)
  "Compare the indentation of each code line in TEXT, the contents of FILE,
with the paren nesting at its start. Strings, comments, |symbols| and escaped
characters such as #\\( are skipped, and lines starting inside a string or
block comment are not checked. Indentation must be spaces: the first tab found
in indentation is reported and ends the stage."
  (let ((ok t) (open '()) (closed '()) (line 1) (column 0) (escaped nil)
        (in-string nil) (in-bars nil) (in-comment nil) (block-depth 0))
    (labels ((problem (message)
               (setf ok nil)
               (report file line "structure" message))
             (check-line (start)
               (multiple-value-bind (indent tabp) (line-indentation text start)
                 (cond ((null indent))
                       (tabp
                        (problem "indentation contains a tab; indent with spaces only")
                        (return-from structure-stage nil))
                       (t (let ((message (indentation-problem open closed indent)))
                            (setf closed '())
                            (when message (problem message)))))))
             (next-is (i char)
               (and (< (1+ i) (length text)) (char= (char text (1+ i)) char))))
      (check-line 0)
      (loop for i from 0 below (length text)
            for char = (char text i)
            for skip = escaped
            do (setf escaped nil)
               (cond (skip)
                     (in-comment (when (char= char #\Newline) (setf in-comment nil)))
                     (in-string (case char
                                  (#\\ (setf escaped t))
                                  (#\" (setf in-string nil))))
                     (in-bars (case char
                                (#\\ (setf escaped t))
                                (#\| (setf in-bars nil))))
                     ((plusp block-depth)
                      (cond ((and (char= char #\|) (next-is i #\#))
                             (decf block-depth)
                             (setf escaped t))
                            ((and (char= char #\#) (next-is i #\|))
                             (incf block-depth)
                             (setf escaped t))))
                     (t (case char
                          (#\" (setf in-string t))
                          (#\| (setf in-bars t))
                          (#\\ (setf escaped t))
                          (#\; (setf in-comment t))
                          (#\# (when (next-is i #\|)
                                 (incf block-depth)
                                 (setf escaped t)))
                          (#\( (push (make-open-paren line column (form-head text (1+ i)))
                                     open))
                          (#\) (let ((depth (length open))
                                      (paren (pop open)))
                                  (when paren
                                    (push (make-closed-paren paren depth line)
                                          closed)))))))
               (cond ((char/= char #\Newline) (incf column))
                     (t (incf line)
                        (setf column 0)
                        (unless (or skip in-string in-bars (plusp block-depth))
                          (check-line (1+ i)))))))
    ok))

(defun warning-line (text condition)
  "Return the line in TEXT of the top-level form CONDITION was signalled for,
or NIL. Uses Allegro internals, so any surprise yields NIL."
  (let* ((plist (ignore-errors (slot-value condition 'excl::plist)))
         (position (or (second (getf plist :loc))
                       (ignore-errors
                        (excl::source-context-start-char (getf plist :source-context))))))
    (when (integerp position)
      (line-at text position))))

(defun parent-directory (directory)
  (let ((parts (pathname-directory directory)))
    (when (rest parts)
      (make-pathname :directory (butlast parts) :name nil :type nil :defaults directory))))

(defun project-asd-files (file)
  "Return the *.asd files of the nearest directory, starting at FILE's own and
going up, that has any. The search stops after a directory holding .git."
  (loop for directory = (make-pathname :name nil :type nil :defaults (truename file))
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
  "Load ASDF quietly and keep its compiled files in *SCRATCH-DIRECTORY*."
  (let ((*load-verbose* nil))
    (require :streama)
    (require :asdf))
  (asdf-call "INITIALIZE-OUTPUT-TRANSLATIONS"
             `(:output-translations
               (t (,(concatenate 'string *scratch-directory* "lisp-check-asdf/")
                   :implementation))
               :ignore-inherited-configuration)))

(defun call-quietly (function)
  (let* ((quiet (make-broadcast-stream))
         (*standard-output* quiet)
         (*error-output* quiet)
         (*package* (find-package :cl-user)))
    (handler-bind ((warning #'muffle-warning))
      (funcall function))))

(defun report-system-error (file asd-file condition)
  (report file nil "system"
          (format nil "could not load system ~s from ~a: ~a"
                  (pathname-name asd-file) (namestring asd-file)
                  (one-line condition))))

(defun load-systems (file asd-files)
  "Register every ASD-FILE, then load the system named like each one."
  (dolist (asd-file asd-files)
    (handler-case (call-quietly (lambda () (asdf-call "LOAD-ASD" asd-file)))
      (error (condition)
        (report-system-error file asd-file condition)
        (return-from load-systems nil))))
  (dolist (asd-file asd-files t)
    (handler-case (call-quietly (lambda () (asdf-call "LOAD-SYSTEM" (pathname-name asd-file))))
      (error (condition)
        (report-system-error file asd-file condition)
        (return-from load-systems nil)))))

(defun system-stage (file)
  "Load the systems of FILE's project, if it has any, so the file can use the
project's packages. Warnings are left to the compile stage."
  (let ((asd-files (project-asd-files file)))
    (or (null asd-files)
        (progn (require-asdf)
               (load-systems file asd-files)))))

(defun fasl-path ()
  (format nil "~alisp-check-~d.fasl" *scratch-directory* (excl::getpid)))

(defun compile-stage (file text fasl)
  "Compile FILE, whose contents are TEXT, into FASL. Every warning is a problem."
  (let ((ok t)
        (error-position nil))
    (handler-case
        (handler-bind ((warning
                         (lambda (condition)
                           (setf ok nil)
                           (report file (warning-line text condition) "compile"
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
            (compile-file file :output-file fasl :verbose nil :print nil
                               :external-format :utf-8)))
      (error (condition)
        (setf ok nil)
        (report file (and error-position (line-at text (1- error-position)))
                "compile" condition)))
    ok))

(defun test-stage (file fasl)
  "Load FASL, which runs FILE's top-level tester assertions.
Tester prints each failing assertion itself; this adds one summary line."
  (let ((*load-verbose* nil))
    (require :tester))
  (let ((errors (find-symbol "*TEST-ERRORS*" :util.test))
        (successes (find-symbol "*TEST-SUCCESSES*" :util.test)))
    (progv (list errors successes) (list 0 0)
      (handler-case (let ((*package* (find-package :cl-user)))
                      (load fasl :verbose nil :print nil))
        (error (condition)
          (report file nil "test" (format nil "error while running the tests: ~a"
                                          (one-line condition)))
          (return-from test-stage nil)))
      (let ((failed (symbol-value errors))
            (passed (symbol-value successes)))
        (cond ((plusp failed)
               (report file nil "test" (format nil "~d of ~d assertions failed"
                                               failed (+ failed passed)))
               nil)
              ((zerop passed)
               (report file nil "test" "no tester assertions ran (write them as top-level (test ...) forms, not inside with-tests)")
               nil)
              (t t))))))

(defun main ()
  (let* ((arguments (rest (sys:command-line-arguments :application t)))
         (file (first arguments))
         (text (file-text file))
         (fasl (fasl-path))
         (ok (unwind-protect
                  (and (read-stage file text)
                       (let ((structure-ok (structure-stage file text)))
                         (and (system-stage file)
                              (compile-stage file text fasl)
                              (or (not (member "--test" arguments :test #'string=))
                                  (test-stage file fasl))
                              structure-ok)))
               (ignore-errors (delete-file fasl)))))
    (format t "~:[FAIL~;OK~]~%" ok)
    (finish-output)
    (excl:exit (if ok 0 1) :quiet t)))
