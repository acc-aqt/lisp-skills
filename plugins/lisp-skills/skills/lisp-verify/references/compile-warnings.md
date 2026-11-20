<!-- essential -->
# Fixing compile warnings

Fix the first warning in the `lisp-check` output:

- `Variable B is never used`: remove `B`, use it, or add
  `(declare (ignore b))` when the argument must stay.
- `Free reference to undeclared variable *X*`: define `*X*` with
  `defvar` or `defparameter` above its first use, or fix the misspelled name.
- `undefined functions were referenced: F`: define `F`, fix the misspelled
  name, or add the package prefix.
- Wrong number of arguments: match the call to the function's lambda list.
- `Package "P" not found`: fix the package name, or define the package
  with `defpackage` before the code that uses it.

Fix the cause in the code so the warning goes away. The one declaration that
counts as a fix is `(declare (ignore ...))` for an argument the function must
accept but does not use.
