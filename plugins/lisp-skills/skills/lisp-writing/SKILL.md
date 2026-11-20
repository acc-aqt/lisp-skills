---
name: lisp-writing
description: Rules for writing Common Lisp for Allegro CL. Use when writing or editing Lisp code (.lisp, .cl), before running lisp-check.
---

Write Common Lisp the way a Lisp developer would. Follow every rule below.
Then check each file with `lisp-check` (the lisp-verify skill).

## Portable ANSI first

- Write portable ANSI Common Lisp. Use only the `cl` package by default.
- Use an Allegro extension (`excl:`, `excl.osi:`, `sys:`) only when ANSI
  has no way to do the job, for example running a shell command.
  Then read `references/allegro.md`.
- Load Allegro modules with `require`, for example `(require :osi)`.
  Assume no Quicklisp and no network.

## Common Lisp, not Scheme or Clojure

| Instead of             | Write                                        |
|------------------------|----------------------------------------------|
| `(define (f x) ...)`   | `(defun f (x) ...)`                          |
| `(define x 1)`         | `(defparameter *x* 1)` or `(let ((x 1)) ...)`|
| `(defn f [x] ...)`     | `(defun f (x) ...)`                          |
| `(fn [x] ...)`         | `(lambda (x) ...)`                           |
| `#t` / `#f`            | `t` / `nil`                                  |
| `'()` and `#f` as two values | `nil`: the empty list is false |
| `null?`, `pair?`       | `null`, `consp`                              |
| `set!`                 | `setf`                                       |
| `(f x)` where `f` is a variable holding a function | `(funcall f x)` |
| `begin`, Clojure `do`  | `progn`                                      |
| `cond` with `else`     | `cond` with `(t ...)` as the last clause     |
| `[1 2 3]`, `{:a 1}`    | `(list 1 2 3)`, a hash table                 |
| `"\n"`                 | `~%` inside `format` (`"\n"` is just `"n"`) |
| recursion for every loop | `loop`, `dolist`, `dotimes`                |

- Predicates end in `p`: `evenp`, `has-items-p`. Not `?`.
- `(first '())` and `(rest '())` return `nil`. They do not signal an error.
- A function and a variable can have the same name. Pass a function with
  `#'name`, call a function held in a variable with `funcall` or `apply`.

## Variables

- Global variables have earmuffs: `*name*`. Constants: `+name+` with `defconstant`.
- `defparameter` sets the value every time the file loads. Use it for
  settings you may change and reload.
- `defvar` sets the value only if the variable has none yet. Use it for state
  that must survive a reload, such as a cache or a counter.
- Define every global with `defvar` or `defparameter` before its first use.
  Plain `(setf *x* 1)` on an undefined variable is a compiler warning.
- Local variables: `let` binds all at once, `let*` binds in order, so a later
  binding can use an earlier one.
- Change a place with `setf`, `incf`, `decf`, `push`, `pop`.

## Equality

| Compare                         | Use                           |
|---------------------------------|-------------------------------|
| symbols, the same object        | `eq`                          |
| numbers of the same type, characters | `eql` (the default test) |
| numbers by value (`1` and `1.0`)| `=`                           |
| strings, case-sensitive         | `string=`                     |
| strings, case-insensitive       | `string-equal`                |
| lists, conses, strings          | `equal`                       |
| anything, ignoring case and number type | `equalp`              |

- `member`, `assoc`, `find`, `position`, `remove` and `gethash` use `eql` by
  default. `eql` is false for two strings with the same text. Pass
  `:test #'string=` or `:test #'equal` for strings and lists.
- A hash table with string keys needs `(make-hash-table :test #'equal)`.
- `gethash` returns two values: the value and whether the key was found.

## Case mode: alisp and mlisp

- `alisp` is ANSI mode, the default here. The reader turns symbol names to
  upper case: `foo`, `Foo` and `FOO` are the same symbol, named `"FOO"`.
- `mlisp` is case-sensitive: `foo` and `FOO` are different symbols, and
  `foo` is named `"foo"`. (Allegro Express ships only `alisp`, so `mlisp`
  behaviour is not verified here.)
- Write all code in lower case. Then it works in both modes.
- Never write a symbol name as a string. Make the name from a symbol:
  `(string '#:red)`, `(symbol-name 'red)`. In `defpackage`, write names as
  `#:name` or `:name`, not `"NAME"`.
- `(intern "foo")` and `(find-symbol "foo")` find a different symbol than
  `'foo` in `alisp`.

## More traps

- `sort` and `nreverse` destroy their argument. Sort a copy:
  `(sort (copy-list items) #'<)`. Never change a quoted literal like `'(3 1 2)`.
- Many functions return more than one value: `parse-integer`, `gethash`,
  `read-line`, `floor`. Wrap the call in `values` to keep only the first.
- `parse-integer` signals `parse-error` for bad input. Catch it with
  `handler-case` or pass `:junk-allowed t`.
- Use `cond` for more than two branches, `when`/`unless` for one branch.
  `if` takes exactly one then-form and one else-form; use `progn` for more.
- Keep a function short and give it a docstring.
- Unused argument: `(declare (ignore x))` as the first form of the body.

## Bracket structure

- Put a form's closing parens at the end of its last line, all together:
  `(incf count)))`. Never put `)` on a line of its own.
- Start each sub-form on its own line, indented under its parent. The
  indentation then shows which form each line belongs to.

From `examples/parens-tests.lisp`:

```lisp
(defun count-long (words)
  (let ((count 0))
    (dolist (word words)
      (when (> (length word) 3)
        (incf count)))
    count))
```

After writing a form, check that its parens match its indentation. A `)` in
the wrong place often still compiles, but the code does something else.
Common misplacements, each with a wrong and a right version:
`references/parens.md`.

## Packages

Start each file with its package (from `examples/greeting.lisp`):

```lisp
(defpackage :greeting
  (:use :cl)
  (:export #:greet))

(in-package :greeting)

(defparameter *greeting* "Hello"
  "The word GREET puts before the name.")

(defun greet (name)
  "Return a greeting for NAME, for example \"Hello, Ada!\"."
  (format nil "~a, ~a!" *greeting* name))
```

For systems, ASDF and tests, use the lisp-project skill.

## References

Open a reference when you write that kind of code:

- `references/loop.md`: `loop` clauses (collect, sum, across, hash tables, return).
- `references/format.md`: `format` directives (`~a`, `~d`, `~%`, `~{~}`, padding).
- `references/clos.md`: `defclass`, `defgeneric`, `defmethod`, `print-object`.
- `references/conditions.md`: `handler-case`, `define-condition`, restarts,
  `unwind-protect`.
- `references/parens.md`: misplaced parens in `when`, `if`, `cond` and `defun`.
- `references/allegro.md`: shell commands, `excl:` string and regexp utilities,
  environment variables, case mode.

Every example in the references comes from a file in `examples/` that passes
`lisp-check --test`. `examples/traps-tests.lisp` shows each trap above.
