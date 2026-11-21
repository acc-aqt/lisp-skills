;;; expect: OK
;;; Parens inside strings, ; comments, nested #| |# comments, character
;;; literals and |symbols| do not count. Each one below is an unclosed (, so
;;; counting it would make every later top-level form look nested. Lines that
;;; start inside a multi-line string or block comment are not checked.

(defun open-paren-char ()
  "Return the character #\\(.
This docstring line starts at column 0, (inside the string,
  so it is not checked."
  #\()

(defun paren-strings ()
  (list "(" "((" "\"(" #\( '|(| '\())

; a comment with an open paren (
(defun after-comment ()
  1) ; and another one (

#| a block comment with an open paren (
   #| a nested block comment ( |#
(defun not-code ()
|#
(defun after-block-comment ()
  2)
