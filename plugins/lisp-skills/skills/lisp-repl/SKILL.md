---
name: lisp-repl
description: Live Common Lisp image for a session. Use when you will check or test Lisp files many times, or when a project's systems are slow to load, to keep one Allegro image running and load changed files into it with lisp-eval.
---

`lisp-check` starts a fresh Lisp for every check and loads the whole project
each time. A live image stays running: you load the project once, then load
only what changed and call functions in it, like a Lisp developer at a REPL.

The image is for working fast. `lisp-check` is still the gate: a file is
done only when `lisp-check` prints `OK` for it.

## The session

1. Start the image in the project directory:

   ```sh
   lisp-image start
   ```

2. Edit a file, then load it into the image:

   ```sh
   lisp-eval --load src/math.lisp
   lisp-eval --load tests/math-tests.lisp
   ```

   `--load` checks the file the way `lisp-check` does, loads the project's
   ASDF systems first (only the files that changed are compiled again), and
   then loads the file. Loading a test file runs its `tester` assertions.

3. If the last line is `FAIL`, fix the first problem line, as in the
   lisp-verify loop, and load the file again. Repeat until `OK`.

4. Call functions to see what they do:

   ```sh
   lisp-eval '(math:add1 41)'
   ```

5. When the work is done, run `lisp-check` on every file you changed, with
   `--test` on test files, until each prints `OK`. Then stop the image:

   ```sh
   lisp-image stop
   ```

## Change code in files

Write every change to a definition into its file, then `lisp-eval --load` the
file. Use plain `lisp-eval 'FORMS'` to call and inspect: run a function, look
at a variable, try an expression. A definition typed only into `lisp-eval`
exists in the image and nowhere else, so it is lost at the next restart and
`lisp-check` never sees it.

The image keeps everything it was ever given. A function you renamed or
deleted in a file still exists in the image, so code that calls the old name
keeps working there. The fresh Lisp in `lisp-check` catches this; that is
why step 5 runs it. When the image seems to disagree with the files, start
over with:

```sh
lisp-image restart
```

## Reading the output

Every command ends with exactly one `OK` or `FAIL` line. The exit code is `0`
for `OK`, `1` for `FAIL`, and `2` when the command itself could not run.

`lisp-eval 'FORMS'` prints what the forms print, then the values of each form
after `=> `. Long lists are cut off with `...`.

```
$ lisp-eval '(format t "sum~%")' '(values 1 2)'
sum
=> NIL
=> 1
=> 2
OK
```

An error stops at the form that signalled it. The image keeps running.

```
$ lisp-eval '(car 5)'
eval: error: Attempt to take the car of 5 which is not listp.
FAIL
```

`eval: read:` means a form does not read; check its parens and quotes.
`eval: timed out after 60 seconds` means the call ran too long, usually an
endless loop. Set `LISP_EVAL_TIMEOUT` to a larger number of seconds only
when the work really is slow.

`lisp-eval --load` prints problems as `FILE:LINE: STAGE: MESSAGE`, the same
stages as `lisp-check` (lisp-verify explains each one), plus `load` for an
error while loading the compiled file.

Lines starting with `lisp-image:` or `lisp-eval:` are about the image, not
your code. `no image is running` means you need `lisp-image start`. `the image
closed the connection` means the image stopped, for example after `(exit)`:
run `lisp-image restart`.

## Commands

```sh
lisp-image start      # start the image for this project (does nothing if one runs)
lisp-image status     # is it running?
lisp-image restart    # stop it and start a fresh one
lisp-image stop
lisp-eval 'FORMS'     # evaluate forms in the image
lisp-eval < forms.lisp
lisp-eval --load FILE # check and load a file into the image
```

- There is one image per project (the git repository around the current
  directory). It runs in the directory where you started it.
- `in-package` carries over to the next `lisp-eval`, as at a REPL. Write
  package-qualified names (`math:add1`) to avoid depending on it.
- If the shell says `command not found`, run the scripts from the plugin's
  `bin/` by full path, as for `lisp-check`.
