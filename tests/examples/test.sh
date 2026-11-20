#!/bin/sh
# Runs lisp-check on every skill example and expects OK for each.
#
# Every .lisp file under plugins/lisp-skills/skills/*/examples/ (at any depth)
# is an example. Files named *-tests.lisp are checked with --test.
set -u
. "$(dirname "$0")/../lib.sh"

check="$root/plugins/lisp-skills/bin/lisp-check"

# check_example FILE: runs lisp-check on FILE the way an example is checked.
check_example() {
    case $1 in
        *-tests.lisp) "$check" --test "$1" ;;
        *) "$check" "$1" ;;
    esac
}

cd "$root" || exit 1

# Self-check: the fixture compiles cleanly and only fails with --test.
fixture=tests/examples/fixtures/failing-tests.lisp
"$check" "$fixture" >/dev/null 2>&1 || fail "$fixture should pass without --test"
if check_example "$fixture" >/dev/null 2>&1; then
    fail "$fixture passed: *-tests.lisp files are not checked with --test"
fi

examples=$(find plugins/lisp-skills/skills/*/examples -name '*.lisp' -type f 2>/dev/null | sort)
[ -n "$examples" ] || fail "no examples found under plugins/lisp-skills/skills/*/examples/"
count=0
while IFS= read -r example; do
    [ -n "$example" ] || continue
    count=$((count + 1))
    if ! output=$(check_example "$example" 2>&1 </dev/null); then
        fail "lisp-check $example"
        printf '%s\n' "$output" | indent
    fi
done <<EOF
$examples
EOF

finish "example checks" "$count examples"
