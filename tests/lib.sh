# Shared by tests/*/test.sh, which source it with: . "$(dirname "$0")/../lib.sh"
# Sets root (the repository) and failures, and provides fail, indent, header,
# check_texts and finish.

root=$(cd "$(dirname "$0")/../.." && pwd)
failures=0

fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# indent: prints its input prefixed with "    | ", to show output under a FAIL line.
indent() {
    sed 's/^/    | /'
}

# header FILE FIELD: prints the value of every ";;; FIELD: VALUE" line in FILE.
header() {
    sed -n "s/^;;; $2: //p" "$1"
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

# finish NAME [DETAIL]: prints "NAME: OK (DETAIL)" or "NAME: N failure(s)", then exits.
finish() {
    if [ "$failures" -eq 0 ]; then
        echo "$1: OK${2:+ ($2)}"
        exit 0
    fi
    echo "$1: $failures failure(s)"
    exit 1
}
