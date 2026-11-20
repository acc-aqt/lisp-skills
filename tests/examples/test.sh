#!/bin/sh
# Runs lisp-check on every skill example and expects OK for each.
#
# Every .lisp file under plugins/lisp-skills/skills/*/examples/ (at any depth)
# is an example. Files named *-tests.lisp are checked with --test.
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
check="$root/plugins/lisp-skills/bin/lisp-check"
failures=0

# check_examples DIR... : checks every example under DIRs, prints a FAIL line
# for each one that does not pass, and sets count and failed.
check_examples() {
    count=0
    failed=0
    examples=$(find "$@" -name '*.lisp' -type f 2>/dev/null | sort)
    for example in $examples; do
        count=$((count + 1))
        case $example in
            *-tests.lisp) set -- --test "$example" ;;
            *) set -- "$example" ;;
        esac
        if ! output=$("$check" "$@" 2>&1); then
            echo "FAIL: lisp-check $*"
            printf '%s\n' "$output" | sed 's/^/    | /'
            failed=$((failed + 1))
        fi
    done
}

cd "$root" || exit 1

# Self-check: the fixture compiles cleanly and only fails with --test.
check_examples tests/examples/fixtures >/dev/null
if [ "$failed" -ne 1 ]; then
    echo "FAIL: tests/examples/fixtures/failing-tests.lisp passed: *-tests.lisp files are not checked with --test"
    failures=$((failures + 1))
fi

check_examples plugins/lisp-skills/skills/*/examples
failures=$((failures + failed))
if [ "$count" -eq 0 ]; then
    echo "FAIL: no examples found under plugins/lisp-skills/skills/*/examples/"
    failures=$((failures + 1))
fi

if [ "$failures" -eq 0 ]; then
    echo "example checks: OK ($count examples)"
else
    echo "example checks: $failures failure(s)"
    exit 1
fi
