### Allegro CL extensions

These are not portable. Use one only when ANSI Common Lisp has no way to do
the job. Every call below is from `examples/allegro-tests.lisp`, which passes
`lisp-check --test` on Allegro CL 11.0 (`alisp`).

Load the module before use, at compile time too:

```lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :osi)        ; excl.osi:command-output
  (require :regexp2))   ; excl:match-re, excl:split-re
```

#### Running shell commands

| Need                                | Use |
|-------------------------------------|-----|
| run a command, get the exit code    | `(excl:run-shell-command "exit 3")` => `3` |
| get stdout as a list of lines       | `(values (excl.osi:command-output "printf 'a\\nb\\n'"))` => `("a" "b")` |
| get the exit code from that         | `(nth-value 2 (excl.osi:command-output "exit 4"))` => `4` |
| run a program without a shell       | `(excl.osi:command-output #("/bin/echo" "/bin/echo" "x y"))` => `("x y")` |

- A string command runs through `/bin/sh`. Quote arguments for the shell, or
  pass a vector `#(program argv0 arg ...)` to skip the shell.
- `excl:run-shell-command` sends the command's output to Lisp's standard
  output. Use `excl.osi:command-output` to capture it.
- `excl.osi:command-output` returns three values: stdout lines, stderr
  lines, exit code.

Read output as a stream. With `:wait nil`, close the stream and reap the
process yourself:

```lisp
(defun read-line-from-command (command)
  (multiple-value-bind (stream error-stream pid)
      (excl:run-shell-command command :output :stream :wait nil)
    (declare (ignore error-stream))
    (unwind-protect (values (read-line stream nil))
      (close stream)
      (sys:reap-os-subprocess :pid pid))))
```

#### Other `excl:` and `sys:` utilities

| Call | Result |
|------|--------|
| `(sys:getenv "HOME")` | the value, or `nil` when unset |
| `(excl:delimited-string-to-list "a,b,,c" #\,)` | `("a" "b" "" "c")` |
| `(excl:list-to-delimited-string '("a" "b") #\,)` | `"a,b"` |
| `(excl:split-re "," "a,b,c")` | `("a" "b" "c")` |
| `(nth-value 2 (excl:match-re "([0-9]+)" "id-123"))` | `"123"` (first group) |
| `(excl:string-to-octets "abc" :null-terminate nil)` | 3 bytes (without the keyword: 4, with a 0 byte) |
| `(excl:octets-to-string octets)` | a string |
| `excl:*current-case-mode*` | `:case-insensitive-upper` in `alisp` |

- `excl:match-re` returns `(values matched-p whole-match group-1 ...)`.
- `excl:exit` ends Lisp with an exit code: `(excl:exit 1 :quiet t)`.
- Your own packages use only `:cl`, so write the package prefix: `excl:exit`,
  not `exit`.
- In `mlisp`, `excl:*current-case-mode*` is `:case-sensitive-lower`. This is
  not verified here: Allegro Express ships only `alisp`.
