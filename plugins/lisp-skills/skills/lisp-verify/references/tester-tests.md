<!-- essential -->
# Tests for `lisp-check --test`

`lisp-check --test` loads the compiled file, and loading runs every top-level
`tester` assertion in it. Write test files in this shape:

```lisp
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :tester))

(defpackage :math-tests
  (:use :cl :util.test))

(in-package :math-tests)

(test 2 (add1 1))
(test "ab" (concatenate 'string "a" "b") :test #'string=)
(test '(1 2) (list 1 2) :test #'equal)
(test-error (parse-age "x"))
```

- Name the file `NAME-tests.lisp`.
- Start with the `eval-when` / `require` form, so the `util.test` package
  exists when the file compiles.
- Put each assertion at top level. `lisp-check` counts top-level assertions
  only; assertions inside `with-tests` give `no tester assertions ran`.
- `(test WANTED FORM)` compares with `eql`. Compare strings with
  `:test #'string=` and lists with `:test #'equal`.
- `test` fails with `additional value were returned from test form` when
  FORM returns more than one value, as `gethash`, `parse-integer` and
  `read-line` do. Keep only the first value:
  `(test 2 (values (gethash "and" *counts*)))`.
- A tests file for a project uses the project's package:
  `(:use :cl :util.test :tally)`. `lisp-check` loads the project's `.asd`
  first (lisp-project skill).
- `(test-error FORM)` passes when FORM signals a `simple-error`, which
  `(error "...")` does. For another condition class add
  `:condition-type 'CLASS`. Test errors your code signals itself: compiled
  code may skip type checks, so `(car 1)` can return garbage instead of
  signalling `type-error`.

## Test output

```
 * * * UNEXPECTED TEST FAILURE * * *
Test failed: (ADD1 1)
  wanted: 5
     got: 2
src/math-tests.lisp:?: test: 1 of 4 assertions failed
FAIL
```

`tester` prints a block for each failed assertion: the form it ran, the value
wanted and the value it got. A `test-error` block says
`Reason: expected but did not detect an error`.

Other `test` messages:

- `error while running the tests: MESSAGE`: a top-level form signalled an
  error, so the assertions after it did not run. Fix that error first.
- `no tester assertions ran`: the file has no top-level assertions. Add
  them, or check the file without `--test` if it is not a test file.
