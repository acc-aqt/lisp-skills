---
name: lisp-verify
description: Check loop for Common Lisp. Use after writing or editing any Lisp source or test file (.lisp, .cl) to run lisp-check, fix the first error, and repeat until OK.
---

Every Lisp file you write must pass `lisp-check`. A file is done only when
`lisp-check` prints `OK` for it.

For many rounds on one project, the lisp-repl skill keeps a live Lisp image
running so each round skips reloading the project. Finish with this loop.

## The loop

For each Lisp file you created or changed:

1. Run `lisp-check path/to/file.lisp`. If the file has `tester` tests, run
   `lisp-check --test path/to/file.lisp` instead.
2. Read the output. The last line is `OK` or `FAIL`.
3. If the last line is `OK`, this file is done. Go to the next file.
4. If the last line is `FAIL`, fix **only the first problem line** in the output.
   Make the smallest edit that fixes it. Keep the rest of the file as it is.
5. Go back to step 1.

Fix one problem per round. Later problems are often caused by the first one,
so they may disappear once it is fixed.

Finish the loop before you report the work as done. When you report, say that
`lisp-check` printed `OK` for each file.

## Editing an existing file

Replace a complete top-level form: from the `(` of its `defun` (or other
top-level form) to its last `)`. Write the new form in full, with all its
closing parens. Never replace only part of a form; the closing `)))` of the
changed function must stay intact.

## When to use `--test`

`--test` also loads the compiled file, which runs its top-level `tester`
assertions (`(test ...)`, `(test-error ...)`).

- Use `--test` on every test file, usually named `NAME-tests.lisp`. To
  write one, see [references/tester-tests.md](references/tester-tests.md).
- Check other files without `--test`: a file with no assertions fails with
  `no tester assertions ran`.
- When you change code that a test file covers, run the loop on the test
  file with `--test` too.

## Reading the output

Each problem is one line:

```
FILE:LINE: STAGE: MESSAGE
```

- `LINE` is the line number to look at. `?` means the line is unknown.
- `STAGE` says which check found the problem.
- `MESSAGE` says what is wrong.

After the problem lines comes exactly one summary line: `OK` or `FAIL`.
The exit code is `0` for `OK`, `1` when the file has problems, and `2` when
`lisp-check` itself could not run.

### Stage `read`

The file does not read as Lisp. Usually the parentheses or quotes do not
balance.

```
src/math.lisp:9: read: form starting here is never closed (missing ')', '"' or '|#')
FAIL
```

This means the top-level form that starts on line 9 is missing a closing
`)`, a closing `"` or a closing `|#`. The missing character belongs somewhere
inside that form, not at the end of the file. To fix it:

1. Go to the form that starts on that line.
2. Count `(` and `)` in that form, one inner form at a time.
3. Add the missing `)` where the inner form should end.
4. Check that every string `"` and every `#|` comment is closed.

```
src/math.lisp:7: read: Invalid unmatched right parenthesis read.
FAIL
```

Line 7 has one `)` too many. Remove the extra `)` on that line, or add the
`(` that is missing before it.

Other `read` messages name the bad syntax, for example
`Comma not inside a backquote.` Fix the syntax on that line.

### Stage `structure`

The file reads, but a line's indentation does not match where the parens put
it. Usually a `)` is in the wrong place: a form ended up inside a `let`,
`when` or `if` branch that should have closed before it, or a form escaped
one because its `)` came too early.

```
src/math.lisp:11: structure: line is indented as if it came after the (let form starting at line 9, but the parens keep it inside that form; by its indentation it belongs in the (defun form starting at line 8
src/math.lisp:20: structure: line is indented as if it were inside the (when form starting at line 19, but that form was closed on line 19; by the parens it is in the (dolist form starting at line 18
FAIL
```

Line 11 is indented like the next form after the `let` on line 9, but the
`let`'s closing `)` comes later, so line 11 is inside the `let`. Line 20 is
indented like the body of the `when` on line 19, but the `when` already
closed on line 19, so line 20 is outside it. To fix a `structure` problem:

1. Work out what the code should do: should the line be inside the form the
   message names, or outside it?
2. Move the `)` that closes that form so the nesting matches. If the form
   closes too late (line 11), move its `)` to before the line. If it closed
   too early (line 20), move its `)` from the line it closed on to the end of
   the last form that belongs inside it. The parens must still balance.
3. Never re-indent the code only to make this check pass. That hides the
   misplaced `)` and leaves the program wrong.
4. If the parens are right and only the indentation is wrong, re-indent that
   one form so each line sits to the right of the `(` of the form it is in,
   and not to the right of a form that closed before it.

Indent with spaces. A tab in a line's indentation is reported as
`indentation contains a tab; indent with spaces only`, and the rest of the
file is not checked for structure until the tabs are replaced with spaces.

### Stage `system`

The file is in a project (a `.asd` in its directory or a parent), and
`lisp-check` could not load that ASDF system. Run `lisp-check` on the project
file the message names and fix it first, or fix the `.asd` (lisp-project skill).

### Stage `compile`

The file reads, and `lisp-check` compiled it. Every compiler warning is a
problem, including a style warning.

```
src/math.lisp:5: compile: style-warning: Variable B is never used.
src/math.lisp:12: compile: warning: CAR should be given exactly 1 argument.  It was given 2 arguments.
src/math.lisp:20: compile: Package "UTILS" not found.
FAIL
```

`LINE` is where the **top-level form** containing the problem starts, usually
a `defun`. Search that whole form for the name in the message, and fix the
cause in the code so the warning goes away. Fixes for common warnings:
[references/compile-warnings.md](references/compile-warnings.md).

### Stage `test` (only with `--test`)

The file compiled, and loading it ran the assertions. `tester` prints a
`Test failed:` block for each failed assertion, before the `test:` line:

```
Test failed: (ADD1 1)
  wanted: 5
     got: 2
src/math-tests.lisp:?: test: 1 of 4 assertions failed
FAIL
```

Fix the first `Test failed:` block. Change the code under test so the form
returns the wanted value; change the assertion only when its wanted value is
wrong. For other `test` messages, see
[references/tester-tests.md](references/tester-tests.md).

### Lines that start with `lisp-check:`

```
lisp-check: Lisp binary 'alisp' not found. Install Allegro CL or set LISP_BIN to its path.
FAIL
```

A line that starts with `lisp-check:` is about the check itself, not your
file (exit code `2`). Leave the Lisp file as it is. Fix the command, or tell
the user what the message says and stop.

## Running lisp-check

```sh
lisp-check path/to/file.lisp
lisp-check --test path/to/file-tests.lisp
```

- Check one file per command.
- `lisp-check` runs Allegro CL in batch mode. It uses the binary named in the
  `LISP_BIN` environment variable, or `alisp` when `LISP_BIN` is not set:
  `LISP_BIN=/path/to/alisp lisp-check file.lisp`
- If the shell says `lisp-check: command not found`, run the `bin/lisp-check`
  script from the lisp-skills plugin by its full path. In Claude Code that is
  `${CLAUDE_PLUGIN_ROOT}/bin/lisp-check`.
