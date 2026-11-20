#!/bin/sh
# Runs lisp-check on every fixture in tests/lisp-check/ and compares the result
# with the expectations written in the fixture's own header comments:
#
#   ;;; expect: OK | FAIL      required: the summary line; OK means exit 0, FAIL non-zero
#   ;;; expect-output: TEXT    optional, repeatable: TEXT appears in the output
#   ;;; flags: --test          optional: extra lisp-check arguments
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
check="$root/plugins/lisp-skills/bin/lisp-check"
failures=0
count=0

fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

header() {
    sed -n "s/^;;; $2: //p" "$1"
}

check_fixture() {
    name=$1
    expected=$(header "$name" expect)
    flags=$(header "$name" flags)
    if [ "$expected" != OK ] && [ "$expected" != FAIL ]; then
        fail "$name has no ';;; expect: OK' or ';;; expect: FAIL' line"
        return
    fi

    # shellcheck disable=SC2086
    output=$("$check" $flags "$name" 2>&1)
    status=$?
    last=$(printf '%s\n' "$output" | tail -n 1)
    summaries=$(printf '%s\n' "$output" | grep -cxE 'OK|FAIL')

    [ "$last" = "$expected" ] || fail "$name: last line is '$last', expected '$expected'"
    if [ "$expected" = OK ]; then
        [ "$status" -eq 0 ] || fail "$name: exit status $status, expected 0"
    else
        [ "$status" -ne 0 ] || fail "$name: exit status 0, expected non-zero"
    fi
    [ "$summaries" -eq 1 ] || fail "$name: $summaries OK/FAIL lines, expected exactly 1"

    missing=$(header "$name" expect-output | while IFS= read -r text; do
        printf '%s\n' "$output" | grep -qF -- "$text" || printf '%s\n' "$text"
    done)
    if [ -n "$missing" ]; then
        fail "$name: output lacks: $missing"
    fi
}

cd "$root" || exit 1
for fixture in tests/lisp-check/*.lisp; do
    [ -f "$fixture" ] || continue
    count=$((count + 1))
    before=$failures
    check_fixture "$fixture"
    if [ "$failures" -ne "$before" ]; then
        printf '%s\n' "$output" | sed 's/^/    | /'
    fi
done

[ "$count" -gt 0 ] || fail "no fixtures found in tests/lisp-check/"

# expect_run DESCRIPTION WANT_STATUS WANT_TEXT COMMAND...
expect_run() {
    description=$1 want_status=$2 want_text=$3
    shift 3
    output=$("$@" 2>&1)
    status=$?
    last=$(printf '%s\n' "$output" | tail -n 1)
    if [ "$status" -ne "$want_status" ] || [ "$last" != "$( [ "$want_status" -eq 0 ] && echo OK || echo FAIL)" ] \
        || ! printf '%s\n' "$output" | grep -qF -- "$want_text"; then
        fail "$description: exit $status, wanted $want_status with '$want_text'"
        printf '%s\n' "$output" | sed 's/^/    | /'
    fi
}

clean=tests/lisp-check/clean.lisp
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/fake-lisp" <<EOF
#!/bin/sh
echo "fake lisp ran" > "$tmp/fake-lisp-ran"
exec ${LISP_BIN:-alisp} "\$@"
EOF
chmod +x "$tmp/fake-lisp"

expect_run "LISP_BIN override" 0 "OK" env LISP_BIN="$tmp/fake-lisp" "$check" "$clean"
[ -f "$tmp/fake-lisp-ran" ] || fail "LISP_BIN override: the binary named by LISP_BIN was not run"
expect_run "missing Lisp binary" 2 "LISP_BIN" env LISP_BIN=/nonexistent/alisp "$check" "$clean"
expect_run "missing file" 2 "no-such-file.lisp" "$check" no-such-file.lisp
expect_run "no arguments" 2 "Usage" "$check"
expect_run "unknown option" 2 "Usage" "$check" --bogus "$clean"

if [ "$failures" -eq 0 ]; then
    echo "lisp-check tests: OK ($count fixtures)"
else
    echo "lisp-check tests: $failures failure(s)"
    exit 1
fi
