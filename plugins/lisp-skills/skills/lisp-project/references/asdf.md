<!-- essential -->
# ASDF details

ASDF 3 ships with Allegro CL: `(require :asdf)`. This file covers what the
skill leaves out.

## Source in `src/`, tests in `tests/`

`examples/shapes/` passes `lisp-check`:

```
shapes/
  shapes.asd
  src/package.lisp
  src/macros.lisp
  src/area.lisp
  src/report.lisp          uses excl.osi, from the built-in osi module
  tests/shapes-tests.lisp
```

```lisp
(asdf:defsystem "shapes"
  :depends-on ((:require "osi"))
  :components ((:module "src"
                :components ((:file "package")
                             (:file "macros" :depends-on ("package"))
                             (:file "area" :depends-on ("package" "macros"))
                             (:file "report" :depends-on ("area")))))
  :in-order-to ((test-op (load-op "shapes/tests"))))

(asdf:defsystem "shapes/tests"
  :depends-on ("shapes" (:require "tester"))
  :components ((:module "tests"
                :components ((:file "shapes-tests")))))
```

- `(:module "src" :components (...))` loads files from the `src/` directory.
- Order the components one of two ways:
  - `:serial t` on the system or module: each file depends on all files
    listed before it. Simple; use it for small projects.
  - `:depends-on ("file" ...)` on each component: names the files in the same
    module that must load first. The `package` file comes first in every
    chain, and a file that uses a macro depends on the file defining it.
- `:depends-on` on the system lists other systems and built-in modules:
  `"other-system"`, `(:require "osi")`, `(:require "tester")`.
- `lisp-check` finds `shapes.asd` from `src/` and `tests/` too: it looks in
  the file's directory, then each parent, up to the directory holding `.git`.

## Loading a project by hand

```lisp repl
(require :asdf)
(asdf:load-asd #p"/path/to/shapes/shapes.asd")   ; absolute path
(asdf:load-system "shapes")
(asdf:test-system "shapes")
```

- `load-asd` tells ASDF about the systems in that file. Do it once per `.asd`
  before `load-system`.
- `load-system` compiles each file whose source changed, then loads it.
- `test-system` runs the system's `test-op`, which here loads
  `"shapes/tests"`. Loading the tests file runs its top-level assertions.
  Failures print `Test failed:` blocks; the counts are in
  `util.test:*test-errors*` and `util.test:*test-successes*`.

## Where compiled files go

ASDF writes fasls to `~/.cache/common-lisp/<implementation>/`, under the
source file's absolute path, never next to the source. `lisp-check` sends
them to `/tmp/lisp-check-asdf/` instead. Keep `*.fasl` in `.gitignore` anyway.

## Common mistakes

- A file that is not in `:components` is never loaded. Add every new file.
- The `package` file must load before any file that says `in-package`.
- The main system has a different name than its `.asd` file. `lisp-check`
  loads the system named like the file: `"shapes"` from `shapes.asd`.
- `:depends-on` names a system that is not on the machine, for example a
  Quicklisp library. Write the code in the project instead.
