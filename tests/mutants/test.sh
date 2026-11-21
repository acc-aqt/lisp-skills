#!/bin/sh
# Runs lisp-check on every mutant in tests/mutants/ and reports how many
# misplaced parens the structure stage catches. A mutant is a skill example
# with one ) moved (made by scripts/generate-mutants): it compiles clean but
# fails its tests. Each mutant's header uses the tests/lisp-check/ convention
# plus two fields:
#
#   ;;; expect: FAIL                     required: --test always fails
#   ;;; flags: --test                    required: run the mutant's tests
#   ;;; expect-output: TEXT              optional, repeatable: TEXT appears in the output
#   ;;; expect-no-output: TEXT           optional, repeatable: TEXT does not appear
#   ;;; mutant-kind: original-indentation | re-indented
#   ;;; expect-structure: caught | missed
#
# A mutant passes when the structure stage reports a problem exactly when the
# header says caught, and the test stage reports a failure.
set -u
. "$(dirname "$0")/../lib.sh"

check="$root/plugins/lisp-skills/bin/lisp-check"
kinds="original-indentation re-indented"

# check_header NAME: the header has the fields every mutant needs.
check_header() {
    name=$1
    [ "$(header "$name" expect)" = FAIL ] || fail "$name: header lacks ';;; expect: FAIL'"
    [ "$(header "$name" flags)" = --test ] || fail "$name: header lacks ';;; flags: --test'"
    case $(header "$name" mutant-kind) in
        original-indentation|re-indented) ;;
        *) fail "$name: mutant-kind must be original-indentation or re-indented" ;;
    esac
    case $(header "$name" expect-structure) in
        caught|missed) ;;
        *) fail "$name: expect-structure must be caught or missed" ;;
    esac
}

check_mutant() {
    name=$1
    before=$failures
    check_header "$name"
    [ "$failures" -eq "$before" ] || return
    output=$("$check" --test "$name" 2>&1 </dev/null)
    status=$?
    last=$(printf '%s\n' "$output" | tail -n 1)
    [ "$last" = FAIL ] && [ "$status" -eq 1 ] \
        || fail "$name: ended with '$last' and exit status $status, expected FAIL and 1"
    printf '%s\n' "$output" | grep -q ': test: ' \
        || fail "$name: the test stage reported no failure"
    if printf '%s\n' "$output" | grep -q ': structure: '; then actual=caught; else actual=missed; fi
    expected=$(header "$name" expect-structure)
    [ "$actual" = "$expected" ] || fail "$name: structure stage $actual it, header says $expected"
    check_texts "$name" "$output"
    [ "$failures" -eq "$before" ] || printf '%s\n' "$output" | indent
    kind=$(header "$name" mutant-kind)
    echo "$kind $actual" >> "$tally"
}

# rate KIND: prints "KIND CAUGHT/TOTAL".
rate() {
    total=$(grep -c "^$1 " "$tally")
    caught=$(grep -c "^$1 caught$" "$tally")
    printf '%s %s/%s' "$1" "$caught" "$total"
}

cd "$root" || exit 1
tally=$(mktemp)
trap 'rm -f "$tally"' EXIT
count=0
for mutant in tests/mutants/*.lisp; do
    [ -f "$mutant" ] || continue
    count=$((count + 1))
    check_mutant "$mutant"
done
[ "$count" -gt 0 ] || fail "no mutants found in tests/mutants/"

rates=
for kind in $kinds; do
    rates="${rates:+$rates, }$(rate "$kind")"
done
finish "mutant tests" "$count mutants, structure caught $rates"
