### Conditions cheat-sheet

From `examples/conditions-tests.lisp`, which passes `lisp-check --test`.
Common Lisp has conditions, not exceptions: no `try`, `catch` or `throw` for
errors (`catch`/`throw` exist, but they are for non-local exits).

Catch an error and return a value with `handler-case`. Catch the most
specific type you expect:

```lisp
(defun parse-number-or-default (string default)
  (handler-case (values (parse-integer string))
    (parse-error () default)))
```

Define your own condition. `:report` gives its message:

```lisp
(define-condition invalid-age (error)
  ((age :initarg :age :reader invalid-age-value))
  (:report (lambda (condition stream)
             (format stream "Age ~a is not valid." (invalid-age-value condition)))))

(defun check-age (age)
  (unless (<= 0 age 150)
    (error 'invalid-age :age age))
  age)
```

Bind the condition to read it. `princ-to-string` gives the report text:

```lisp
(handler-case (check-age age)
  (invalid-age (condition) (princ-to-string condition)))   ; "Age -1 is not valid."
```

Offer a way to recover with `restart-case`. A `handler-bind` higher up
chooses it with `invoke-restart`, and the code continues where it was:

```lisp
(defun parse-entry (string)
  (restart-case (parse-integer string)
    (use-value (value)
      :report "Use a different value."
      value)))

(defun parse-all (strings)
  (handler-bind ((parse-error (lambda (condition)
                                (declare (ignore condition))
                                (invoke-restart 'use-value 0))))
    (mapcar #'parse-entry strings)))   ; ("1" "x" "3") => (1 0 3)
```

Clean up whatever happens with `unwind-protect`:

```lisp
(unwind-protect (error "Something failed.")
  (setf status :closed))               ; runs even though the body failed
```

- `(error "text ~a" x)` signals a `simple-error`. `(error 'type :slot value)`
  signals your own type.
- `(warn "text")` signals a warning and continues.
- `ignore-errors` returns `nil` on any error. Use it only when the error
  really does not matter.
- `with-open-file` already closes the file for you; it uses `unwind-protect`.
