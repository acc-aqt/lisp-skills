;;; expect: FAIL
;;; expect-output: uses-broken.lisp:?: system: could not load system "broken" from
;;; expect-output: broken.asd
;;; expect-no-output: compile:
;;; A clean file in a project whose system fails to load: the check stops at the
;;; system stage and names the .asd.

(defpackage :uses-broken
  (:use :cl :broken))

(in-package :uses-broken)

(defun quarter (x)
  (half (half x)))
