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

(defstruct lexer
  "Where a scan of Lisp text stands: inside a string, |symbol|, ; comment or
#| |# block comment (nested BLOCK-DEPTH deep), or right after an escape."
  escaped in-string in-bars in-comment (block-depth 0))

(defun next-char-is (text i char)
  (and (< (1+ i) (length text)) (char= (char text (1+ i)) char)))

(defun lex-char (lexer text i)
  "Advance LEXER past the character at I in TEXT. Return true if that character
is code: outside strings, |symbols|, comments and escapes. A newline that ends
a ; comment counts as code."
  (let ((char (char text i))
        (escaped (lexer-escaped lexer)))
    (setf (lexer-escaped lexer) nil)
    (cond (escaped nil)
          ((lexer-in-comment lexer)
           (when (char= char #\Newline)
             (setf (lexer-in-comment lexer) nil)
             t))
          ((lexer-in-string lexer)
           (case char
             (#\\ (setf (lexer-escaped lexer) t))
             (#\" (setf (lexer-in-string lexer) nil)))
           nil)
          ((lexer-in-bars lexer)
           (case char
             (#\\ (setf (lexer-escaped lexer) t))
             (#\| (setf (lexer-in-bars lexer) nil)))
           nil)
          ((plusp (lexer-block-depth lexer))
           (cond ((and (char= char #\|) (next-char-is text i #\#))
                  (decf (lexer-block-depth lexer))
                  (setf (lexer-escaped lexer) t))
                 ((and (char= char #\#) (next-char-is text i #\|))
                  (incf (lexer-block-depth lexer))
                  (setf (lexer-escaped lexer) t)))
           nil)
          (t (case char
               (#\" (setf (lexer-in-string lexer) t) nil)
               (#\| (setf (lexer-in-bars lexer) t) nil)
               (#\\ (setf (lexer-escaped lexer) t) nil)
               (#\; (setf (lexer-in-comment lexer) t) nil)
               (#\# (cond ((next-char-is text i #\|)
                           (incf (lexer-block-depth lexer))
                           (setf (lexer-escaped lexer) t)
                           nil)
                          (t t)))
               (t t))))))

(defun structure-stage (file text)
  "Compare the indentation of each code line in TEXT, the contents of FILE,
with the paren nesting at its start. Strings, comments, |symbols| and escaped
characters such as #\\( are skipped, and lines starting inside a string or
block comment are not checked. Indentation must be spaces: the first tab found
in indentation is reported and ends the stage. A tab after the indentation
advances the column to the next multiple of 8."
  (let ((ok t) (open '()) (closed '()) (line 1) (column 0) (lexer (make-lexer)))
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
             (close-paren ()
               (let ((depth (length open))
                     (paren (pop open)))
                 (when paren
                   (push (make-closed-paren paren depth line) closed)))))
      (check-line 0)
      (loop for i from 0 below (length text)
            for char = (char text i)
            for code = (lex-char lexer text i)
            do (when code
                 (case char
                   (#\( (push (make-open-paren line column (form-head text (1+ i)))
                              open))
                   (#\) (close-paren))))
               (case char
                 (#\Tab (setf column (* 8 (1+ (floor column 8)))))
                 (#\Newline (incf line)
                  (setf column 0)
                  (when code (check-line (1+ i))))
                 (t (incf column)))))
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

(defun load-assertions (file fasl stage error-message)
  "Load FASL, which runs FILE's top-level tester assertions, and return the
numbers of failed and passed assertions. If loading signals an error, report
it under STAGE after ERROR-MESSAGE and return NIL."
  (let ((*load-verbose* nil))
    (require :tester))
  (let ((errors (find-symbol "*TEST-ERRORS*" :util.test))
        (successes (find-symbol "*TEST-SUCCESSES*" :util.test)))
    (progv (list errors successes) (list 0 0)
      (handler-case (let ((*package* (find-package :cl-user)))
                      (load fasl :verbose nil :print nil))
        (error (condition)
          (report file nil stage (format nil "~a: ~a" error-message (one-line condition)))
          (return-from load-assertions nil)))
      (values (symbol-value errors) (symbol-value successes)))))

(defun report-failed-assertions (file failed passed)
  (report file nil "test" (format nil "~d of ~d assertions failed"
                                  failed (+ failed passed))))

(defun test-stage (file fasl)
  "Load FASL, which runs FILE's top-level tester assertions.
Tester prints each failing assertion itself; this adds one summary line."
  (multiple-value-bind (failed passed)
      (load-assertions file fasl "test" "error while running the tests")
    (cond ((null failed) nil)
          ((plusp failed)
           (report-failed-assertions file failed passed)
           nil)
          ((zerop passed)
           (report file nil "test" "no tester assertions ran (write them as top-level (test ...) forms, not inside with-tests)")
           nil)
          (t t))))

(defun check-file (file last-stage)
  "Run the stages on FILE and return true if it has no problems. LAST-STAGE,
if not NIL, is called with FILE and its compiled fasl after a clean compile."
  (let ((text (file-text file))
        (fasl (fasl-path)))
    (unwind-protect
         (and (read-stage file text)
              (let ((structure-ok (structure-stage file text)))
                (and (system-stage file)
                     (compile-stage file text fasl)
                     (or (null last-stage) (funcall last-stage file fasl))
                     structure-ok)))
      (ignore-errors (delete-file fasl)))))

(defun main ()
  (let* ((arguments (rest (sys:command-line-arguments :application t)))
         (ok (check-file (first arguments)
                         (and (member "--test" arguments :test #'string=)
                              #'test-stage))))
    (format t "~:[FAIL~;OK~]~%" ok)
    (finish-output)
    (excl:exit (if ok 0 1) :quiet t)))
