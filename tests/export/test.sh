#!/bin/sh
# Runs scripts/export-rules against a fixture plugin and against the real plugin.
set -u

root=$(cd "$(dirname "$0")/../.." && pwd)
fixture="$root/tests/export/fixtures/plugin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

expect_line() {
    grep -qxF -- "$2" "$1" || fail "$1 lacks line: $2"
}

out="$tmp/rules.md"
PLUGIN_DIR="$fixture" "$root/scripts/export-rules" "$out" || fail "export exited non-zero"

if [ -f "$out" ]; then
    head -n 1 "$out" | grep -q 'GENERATED' || fail "first line is not the generated notice"
    head -n 1 "$out" | grep -qF 'scripts/export-rules' || fail "first line does not name scripts/export-rules"
    expect_line "$out" "## alpha"
    expect_line "$out" "## beta"
    expect_line "$out" "Alpha body rule."
    expect_line "$out" "Essential alpha reference."
    grep -qF 'Optional alpha reference.' "$out" && fail "non-essential reference was exported"
    grep -qF -- '<!-- essential -->' "$out" && fail "essential marker leaked into export"
    grep -qxF -- 'name: alpha' "$out" && fail "frontmatter leaked into export"
else
    fail "export did not create $out"
fi

default_out="$root/dist/lisp-rules.md"
(unset PLUGIN_DIR; "$root/scripts/export-rules") || fail "default export exited non-zero"
if [ -f "$default_out" ]; then
    head -n 1 "$default_out" | grep -q 'GENERATED' || fail "default export lacks the generated notice"
    for skill_dir in "$root"/plugins/lisp-skills/skills/*/; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        expect_line "$default_out" "## $(basename "$skill_dir")"
    done
else
    fail "default export did not create $default_out"
fi

if [ "$failures" -eq 0 ]; then
    echo "export tests: OK"
else
    echo "export tests: $failures failure(s)"
    exit 1
fi
