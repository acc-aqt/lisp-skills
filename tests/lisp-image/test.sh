#!/bin/sh
# Drives lisp-image and lisp-eval end to end against a real image, kept in a
# temporary LISP_IMAGE_DIR and stopped on exit.
set -u
. "$(dirname "$0")/../lib.sh"

image="$root/plugins/lisp-skills/bin/lisp-image"
eval_="$root/plugins/lisp-skills/bin/lisp-eval"
tmp=$(mktemp -d)
LISP_IMAGE_DIR="$tmp/image"
export LISP_IMAGE_DIR
trap '"$image" stop >/dev/null 2>&1; rm -rf "$tmp"' EXIT

# expect_run DESCRIPTION WANT_STATUS WANT_TEXT COMMAND...: COMMAND exits with
# WANT_STATUS and prints WANT_TEXT. Status 0 must end in OK, status 1 in FAIL.
expect_run() {
    description=$1 want_status=$2 want_text=$3
    shift 3
    output=$("$@" 2>&1)
    status=$?
    last=$(printf '%s\n' "$output" | tail -n 1)
    case $want_status in
        0) want_last=OK ;;
        1) want_last=FAIL ;;
        *) want_last=$last ;;
    esac
    if [ "$status" -ne "$want_status" ] || [ "$last" != "$want_last" ] \
        || ! printf '%s\n' "$output" | grep -qF -- "$want_text"; then
        fail "$description: exit $status, wanted $want_status with '$want_text'"
        printf '%s\n' "$output" | indent
    fi
}

expect_run "eval without an image" 2 "lisp-image start" "$eval_" "(+ 1 2)"
expect_run "status without an image" 1 "not running" "$image" status
expect_run "start" 0 "started" "$image" start
expect_run "start again" 0 "already running" "$image" start
expect_run "status" 0 "running (pid" "$image" status

expect_run "eval a form" 0 "=> 3" "$eval_" "(+ 1 2)"
cp "$LISP_IMAGE_DIR/token" "$tmp/token"
echo wrong > "$LISP_IMAGE_DIR/token"
expect_run "a request without the image's token" 2 "refused" "$eval_" "(+ 1 2)"
cp "$tmp/token" "$LISP_IMAGE_DIR/token"
expect_run "values print in full when user code prints" 0 "(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51)" \
    "$eval_" "(let ((*print-right-margin* 1000)) (prin1 (loop for i below 52 collect i)) nil)"
expect_run "eval prints output, then values" 0 "hi
=> 1
=> 2" "$eval_" '(progn (princ "hi") (values 1 2))'
expect_run "definitions stay in the image" 0 "=> 42" "$eval_" "(defparameter *x* 41)" "(1+ *x*)"
expect_run "state carries over between calls" 0 "=> 42" "$eval_" "(1+ *x*)"
expect_run "forms from standard input" 0 "=> 7" sh -c "printf '(+ 3\\n 4)\\n' | '$eval_'"
expect_run "an error fails the call" 1 "eval: error: boom" "$eval_" '(error "boom")'
expect_run "the image survives an error" 0 "=> 2" "$eval_" "(+ 1 1)"
expect_run "invoke-debugger fails the call" 1 "eval: error: deep" \
    "$eval_" '(invoke-debugger (make-condition (quote simple-error) :format-control "deep"))'
expect_run "break fails the call" 1 "eval: error: stop here" "$eval_" '(break "stop here")'
expect_run "a form that does not read" 1 "eval: read:" "$eval_" "(+ 1"
expect_run "in-package carries over" 0 '=> #<The SCRATCH package>' \
    "$eval_" "(defpackage :scratch (:use :cl))" "(in-package :scratch)"
expect_run "...to the next call" 0 '=> "SCRATCH"' "$eval_" "(package-name *package*)"
"$eval_" "(in-package :cl-user)" >/dev/null
expect_run "a call over the time limit" 1 "timed out after 1 seconds" \
    env LISP_EVAL_TIMEOUT=1 "$eval_" "(loop (sleep 0.01))"
expect_run "the image survives a timeout" 0 "=> 2" "$eval_" "(+ 1 1)"

# --load checks a file like lisp-check, then loads it into the image.
cp -R "$root/tests/lisp-check/projects/greet" "$tmp/greet"
mkdir "$tmp/greet/.git"
expect_run "load a test file of a project" 0 "OK" "$eval_" --load "$tmp/greet/greet-tests.lisp"
expect_run "its definitions are in the image" 0 '=> "Hello, Bo!"' "$eval_" '(greet:greeting "Bo")'
# File dates count whole seconds; ASDF misses an edit in the second it compiled.
sleep 1
sed 's/Hello/Bye/' "$tmp/greet/greet.lisp" > "$tmp/greet/new" && mv "$tmp/greet/new" "$tmp/greet/greet.lisp"
expect_run "a changed project file is reloaded" 1 "greet-tests.lisp:?: test: 1 of 1 assertions failed" \
    "$eval_" --load "$tmp/greet/greet-tests.lisp"
expect_run "...and redefined in the image" 0 '=> "Bye, Bo!"' "$eval_" '(greet:greeting "Bo")'
printf '(defun sloppy (a b)\n  a)\n' > "$tmp/sloppy.lisp"
expect_run "load reports compile problems" 1 "sloppy.lisp:1: compile: style-warning" \
    "$eval_" --load "$tmp/sloppy.lisp"
expect_run "load of a missing file" 2 "no such file" "$eval_" --load "$tmp/missing.lisp"

expect_run "restart" 0 "started" "$image" restart
expect_run "restart forgets definitions" 1 "eval: error" "$eval_" "*x*"
expect_run "stop" 0 "stopped" "$image" stop
expect_run "status after stop" 1 "not running" "$image" status
expect_run "unknown command" 2 "Usage" "$image" bogus

finish "lisp-image tests"
