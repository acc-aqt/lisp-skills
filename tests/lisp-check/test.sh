#!/bin/sh
# Runs lisp-check on every fixture in tests/lisp-check/ and compares the result
# with the expectations written in the fixture's own header comments:
#
#   ;;; expect: OK | FAIL      required: the summary line; OK means exit 0, FAIL non-zero
#   ;;; expect-output: TEXT    optional, repeatable: TEXT appears in the output
#   ;;; expect-no-output: TEXT optional, repeatable: TEXT does not appear in the output
#   ;;; flags: --test          optional: extra lisp-check arguments
set -u
. "$(dirname "$0")/../lib.sh"

check="$root/plugins/lisp-skills/bin/lisp-check"
count=0

header() {
    sed -n "s/^;;; $2: //p" "$1"
}

# check_summary NAME EXPECTED STATUS OUTPUT: the last line, exit status and
# number of OK/FAIL lines agree with EXPECTED.
check_summary() {
    name=$1 expected=$2 status=$3 output=$4
    last=$(printf '%s\n' "$output" | tail -n 1)
    summaries=$(printf '%s\n' "$output" | grep -cxE 'OK|FAIL')
    [ "$last" = "$expected" ] || fail "$name: last line is '$last', expected '$expected'"
    if [ "$expected" = OK ]; then
        [ "$status" -eq 0 ] || fail "$name: exit status $status, expected 0"
    else
        [ "$status" -ne 0 ] || fail "$name: exit status 0, expected non-zero"
    fi
    [ "$summaries" -eq 1 ] || fail "$name: $summaries OK/FAIL lines, expected exactly 1"
}

# check_texts NAME OUTPUT: every expect-output text appears in OUTPUT and no
# expect-no-output text does.
check_texts() {
    name=$1 output=$2
    missing=$(header "$name" expect-output | while IFS= read -r text; do
        printf '%s\n' "$output" | grep -qF -- "$text" || printf '%s\n' "$text"
    done)
    [ -z "$missing" ] || fail "$name: output lacks: $missing"
    unwanted=$(header "$name" expect-no-output | while IFS= read -r text; do
        printf '%s\n' "$output" | grep -qF -- "$text" && printf '%s\n' "$text"
    done)
    [ -z "$unwanted" ] || fail "$name: output must not contain: $unwanted"
}

check_fixture() {
    name=$1
    expected=$(header "$name" expect)
    if [ "$expected" != OK ] && [ "$expected" != FAIL ]; then
        fail "$name has no ';;; expect: OK' or ';;; expect: FAIL' line"
        return
    fi
    flags=$(header "$name" flags)
    # shellcheck disable=SC2086
    output=$("$check" $flags "$name" 2>&1)
    status=$?
    before=$failures
    check_summary "$name" "$expected" "$status" "$output"
    check_texts "$name" "$output"
    [ "$failures" -eq "$before" ] || printf '%s\n' "$output" | indent
}

# expect_run DESCRIPTION WANT_STATUS WANT_TEXT COMMAND...: COMMAND exits with
# WANT_STATUS, prints WANT_TEXT, and ends with OK (status 0) or FAIL.
expect_run() {
    description=$1 want_status=$2 want_text=$3
    shift 3
    if [ "$want_status" -eq 0 ]; then want_last=OK; else want_last=FAIL; fi
    output=$("$@" 2>&1)
    status=$?
    last=$(printf '%s\n' "$output" | tail -n 1)
    if [ "$status" -ne "$want_status" ] || [ "$last" != "$want_last" ] \
        || ! printf '%s\n' "$output" | grep -qF -- "$want_text"; then
        fail "$description: exit $status, wanted $want_status with '$want_text'"
        printf '%s\n' "$output" | indent
    fi
}

cd "$root" || exit 1
# Every top-level .lisp file is a fixture. Under projects/, which holds small
# ASDF projects, only files with an expect header are; the rest are project source.
project_fixtures=$(grep -rlx --include='*.lisp' ';;; expect: .*' tests/lisp-check/projects | sort)
for fixture in tests/lisp-check/*.lisp $project_fixtures; do
    [ -f "$fixture" ] || continue
    count=$((count + 1))
    check_fixture "$fixture"
done

[ "$count" -gt 0 ] || fail "no fixtures found in tests/lisp-check/"
leftovers=$( (find tests/lisp-check -name '*.fasl'; find /tmp -maxdepth 1 -name 'lisp-check-*.fasl') 2>/dev/null)
[ -z "$leftovers" ] || fail "compiled files were left behind: $leftovers"

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

finish "lisp-check tests" "$count fixtures"
