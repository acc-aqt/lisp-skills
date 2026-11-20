# Shared by tests/*/test.sh, which source it with: . "$(dirname "$0")/../lib.sh"
# Sets root (the repository) and failures, and provides fail, indent and finish.

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

# finish NAME [DETAIL]: prints "NAME: OK (DETAIL)" or "NAME: N failure(s)", then exits.
finish() {
    if [ "$failures" -eq 0 ]; then
        echo "$1: OK${2:+ ($2)}"
        exit 0
    fi
    echo "$1: $failures failure(s)"
    exit 1
}
