;;; expect: FAIL
;;; expect-output: structure-tab-indentation.lisp:9: structure: indentation contains a tab
;;; expect-no-output: structure-tab-indentation.lisp:12:
;;; Tabs make indentation depend on the editor, so lisp-check asks for
;;; spaces. The first tab is reported and the rest of the file is not
;;; checked for structure.

(defun add1 (x)
	(+ x 1))

(defun add2 (x)
	(+ x 2))
