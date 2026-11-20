;;; expect: OK
;;; Code behind a feature expression for another implementation is skipped.

#+sbcl (sb-ext:exit :code 1)

(defun greeting ()
  #+allegro "Hello from Allegro"
  #-allegro "Hello")
