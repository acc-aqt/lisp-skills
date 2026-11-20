---
name: lisp-project
description: Project structure for Common Lisp on Allegro CL. Use when creating or changing a .asd system, a package.lisp, a project's file layout or dependencies, or a project's tester tests.
---

A Lisp project is one system definition (`NAME.asd`), one package file, the
source files and a tests file. Copy the shape of `examples/tally/`, which
loads through ASDF and passes `lisp-check`.

## Layout

```
tally/
  tally.asd          system definition
  package.lisp       defpackage, loaded first
  tally.lisp         source, starts with (in-package :tally)
  tally-tests.lisp   tester tests
```

A bigger project puts source in `src/` and tests in `tests/`, like
`examples/shapes/`; see `references/asdf.md`. Keep the `.asd` at the
project root.

## Packages

Define the package once, in `package.lisp`:

```lisp
(defpackage :tally
  (:use :cl)
  (:export #:split-words
           #:tally-words
           #:word-count
           #:top-words))
```

- Name symbols as `#:name` or `:name`, in lower case (case-mode rule below).
- `:use` only `:cl`, plus `:util.test` in a tests package. Refer to any other
  package's symbols with a prefix: `excl.osi:command-output`, `tally:tally-words`.
- `:export` every symbol other packages or the tests call.
- Every other source file starts with `(in-package :tally)` and defines no
  package of its own.
- A tests file defines its own package, named `NAME-tests`, that `:use`s the
  package under test.

## The system definition

From `examples/tally/tally.asd`:

```lisp
(asdf:defsystem "tally"
  :description "Count how often each word occurs in a text."
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:file "tally"))
  :in-order-to ((test-op (load-op "tally/tests"))))

(asdf:defsystem "tally/tests"
  :depends-on ("tally" (:require "tester"))
  :components ((:file "tally-tests")))
```

- Name the file after the system: system `"tally"` lives in `tally.asd`.
  A second system in the same file is named `"tally/tests"`.
- `:serial t` loads the components in the order listed, so the order is the
  load order:
  1. `package` first, because every other file says `(in-package :tally)`.
  2. Then each file before the files that use its macros, variables or
     classes. A macro must be loaded before any file that calls it.
- `:file` takes the name without `.lisp`.
- When you add a source file, add it to `:components` in the right place.
  A file missing from the `.asd` is never loaded.
- The tests system is separate, so loading `"tally"` does not run the tests.

## Dependencies

There is no Quicklisp and no other package manager, and the machine may have
no network. A project uses only:

- Allegro's built-in modules, loaded with `require`. In a source file:
  `(eval-when (:compile-toplevel :load-toplevel :execute) (require :osi))`.
  In the `.asd`: `:depends-on ((:require "osi"))`.
- Other ASDF systems that already exist in the project or on the machine, by
  name in `:depends-on`.

When the code needs a library the project does not have (for example
`alexandria`, `cl-ppcre` or `split-sequence`), write the few functions it
needs in the project, or ask the user.

## Loading and testing

At the REPL, with the `.asd` file's absolute path:

```lisp repl
(require :asdf)
(asdf:load-asd #p"/path/to/tally/tally.asd")
(asdf:load-system "tally")
(asdf:test-system "tally")    ; loads "tally/tests", which runs the tests
```

`lisp-check` does the loading for you: when the file's directory or a parent
has `.asd` files, it loads those systems before compiling the file. So check
every project file on its own:

```sh
lisp-check tally/package.lisp
lisp-check tally/tally.lisp
lisp-check --test tally/tally-tests.lisp
```

A `system:` problem means the project failed to load. The message names the
`.asd` and usually the file that broke: run `lisp-check` on that file and fix
it first, or fix the `.asd`.

Some mistakes show only when the code loads, for example a `defmethod` whose
arguments do not match its `defgeneric`. After changing source, run the tests
file with `--test`.

## Tests

Write tests with Allegro's built-in `tester` module (package `util.test`),
in `NAME-tests.lisp`, as top-level `(test ...)` forms. The file format and the
rules are in the lisp-verify skill's `references/tester-tests.md`. Read it
before writing a tests file. A project tests file differs in one line: its
package also uses the package under test.

```lisp
(defpackage :tally-tests
  (:use :cl :util.test :tally))
```

## Case mode: alisp unless the project says otherwise

Assume `alisp`, Allegro's ANSI mode, which reads `foo` and `FOO` as the same
symbol. Switch to `mlisp` (case-sensitive) only when the project says so, for
example in its README or build scripts, or when the user does. Write all code
and all `defpackage` names in lower case so it works in both. The lisp-writing
skill has the details. (Allegro Express has no `mlisp`, so `mlisp` behaviour is
not verified here.)

## References

- `references/asdf.md`: `src/` and `tests/` modules, `:depends-on` between
  components, loading a project by hand, where ASDF puts compiled files.
