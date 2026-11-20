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
    # The expected file pins down the generated notice, skill order and heading
    # nesting: skill bodies and essential references sit below "## <skill>",
    # and lines inside code fences are left alone.
    diff -u "$fixture/../expected.md" "$out" | indent
    cmp -s "$fixture/../expected.md" "$out" || fail "fixture export differs from tests/export/fixtures/expected.md"
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
    stray=$(awk '/^(```|~~~)/ { fenced = !fenced } !fenced && /^## / { print }' "$fresh" \
        | grep -vxE '## lisp-[a-z-]+')
    [ -z "$stray" ] || fail "headings in the real export not nested under a skill: $stray"
    cmp -s "$fresh" "$committed" || fail "dist/lisp-rules.md is stale; run scripts/export-rules (or make export)"
else
    fail "export of the real plugin did not create $fresh"
fi

finish "export tests"
