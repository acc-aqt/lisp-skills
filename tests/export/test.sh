#!/bin/sh
# Runs scripts/export-rules against a fixture plugin and against the real
# plugin, and checks that the committed dist/lisp-rules.md is up to date.
# Never writes to dist/.
set -u

. "$(dirname "$0")/../lib.sh"

fixture="$root/tests/export/fixtures/plugin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

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

committed="$root/dist/lisp-rules.md"
fresh="$tmp/lisp-rules.md"
(unset PLUGIN_DIR; "$root/scripts/export-rules" "$fresh") || fail "export of the real plugin exited non-zero"
if [ -f "$fresh" ]; then
    for skill_dir in "$root"/plugins/lisp-skills/skills/*/; do
        [ -f "$skill_dir/SKILL.md" ] || continue
        expect_line "$fresh" "## $(basename "$skill_dir")"
    done
    cmp -s "$fresh" "$committed" || fail "dist/lisp-rules.md is stale; run scripts/export-rules (or make export)"
else
    fail "export of the real plugin did not create $fresh"
fi

finish "export tests"
