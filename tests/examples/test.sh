#!/bin/sh
# Runs lisp-check on every skill example and expects OK for each.
#
# Every .lisp file under plugins/lisp-skills/skills/*/examples/ (at any depth)
# is an example. Files named *-tests.lisp are checked with --test.
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
check="$root/plugins/lisp-skills/bin/lisp-check"
failures=0
count=0

cd "$root" || exit 1
examples=$(find plugins/lisp-skills/skills/*/examples -name '*.lisp' -type f 2>/dev/null | sort)

for example in $examples; do
    count=$((count + 1))
    case $example in
        *-tests.lisp) set -- --test "$example" ;;
        *) set -- "$example" ;;
    esac
    if ! output=$("$check" "$@" 2>&1); then
        echo "FAIL: lisp-check $*"
        printf '%s\n' "$output" | sed 's/^/    | /'
        failures=$((failures + 1))
    fi
done

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
