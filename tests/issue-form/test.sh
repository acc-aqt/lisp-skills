#!/bin/sh
# Checks the skill-failure issue form: it exists, labels new issues
# needs-triage, and marks every field a reproducible report needs as required.
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
form="$root/.github/ISSUE_TEMPLATE/skill-failure.yml"
failures=0

fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# Prints the body item with the given id, from its "- type:" line to the next one.
field_block() {
    awk -v id="$1" '
        /^  - type:/ { if (found) exit; block = $0 "\n"; next }
        { block = block $0 "\n" }
        $0 ~ "^    id: " id "$" { found = 1 }
        END { if (found) printf "%s", block }
    ' "$form"
}

if [ ! -f "$form" ]; then
    fail "issue form missing: $form"
else
    grep -qE '^labels: *\[ *"?needs-triage"? *\]' "$form" \
        || fail "form does not apply the needs-triage label"
    for id in harness model skill prompt model-output lisp-check-output expected; do
        block=$(field_block "$id")
        if [ -z "$block" ]; then
            fail "form lacks field: $id"
        else
            printf '%s' "$block" | grep -qE '^      required: true$' \
                || fail "field is not required: $id"
        fi
    done
    for option in lisp-writing lisp-verify lisp-project; do
        field_block skill | grep -qE "^        - \"?$option\"?$" \
            || fail "skill dropdown lacks option: $option"
    done
fi

if [ "$failures" -eq 0 ]; then
    echo "issue form tests: OK"
else
    echo "issue form tests: $failures failure(s)"
    exit 1
fi
