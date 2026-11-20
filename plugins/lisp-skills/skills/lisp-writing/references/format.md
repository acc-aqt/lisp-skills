### `format` cheat-sheet

`(format nil ...)` returns a string. `(format t ...)` prints to standard
output. `(format stream ...)` writes to `stream`. Every line below is an
assertion in `examples/format-tests.lisp`, which passes `lisp-check --test`.

| Call                                        | Result          |
|---------------------------------------------|-----------------|
| `(format nil "Hello, ~a!" "Ada")`           | `Hello, Ada!`   |
| `(format nil "~s" "Ada")`                   | `"Ada"` (with quotes) |
| `(format nil "~d" 42)`                      | `42`            |
| `(format nil "~4d" 42)`                     | `  42`          |
| `(format nil "~4,'0d" 42)`                  | `0042`          |
| `(format nil "~:d" 1234567)`                | `1,234,567`     |
| `(format nil "~,2f" 3.14159)`               | `3.14`          |
| `(format nil "~(~x~)" 255)`                 | `ff`            |
| `(format nil "~b" 5)`                       | `101`           |
| `(format nil "[~4a]" "a")`                 | `[a   ]`        |
| `(format nil "[~4@a]" "a")`                | `[   a]`        |
| `(format nil "~d file~:p" 2)`               | `2 files` (`1 file` for 1) |
| `(format nil "~{~a~^, ~}" '("a" "b" "c"))`  | `a, b, c`       |
| `(format nil "~:[no~;yes~]" t)`             | `yes`           |
| `(format nil "line 1~%line 2")`             | two lines       |
| `(format nil "~~")`                         | `~`             |

- `~a` prints for people, `~s` prints for the reader (strings get quotes).
- `~%` is a newline. `~&` is a newline only if the output is not already at
  the start of a line. Lisp strings have no `\n` escape.
- `~{...~}` loops over a list. `~^` stops before the separator after the
  last element.
- Use `~d` for integers and `~f` for floats, not `%d` or `{}`.

Write to a stream passed in, so callers choose where the text goes:

```lisp
(defun write-report (stream name count)
  (format stream "~&~a: ~d item~:p~%" name count))

(with-output-to-string (s) (write-report s "disk" 3))   ; => "disk: 3 items
                                                         ;    "
```
