#!/bin/sh
# Runs lisp-check on every skill example and expects OK for each.
#
# Every .lisp file under plugins/lisp-skills/skills/*/examples/ (at any depth)
# is an example. Files named *-tests.lisp are checked with --test.
# It also runs every "```lisp repl" block in the skills, and checks that the
# snippets in lisp-writing's references/parens.md come from its example (see below).
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

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/prelude.lisp" <<EOF
(require :asdf)
(asdf:initialize-output-translations
 '(:output-translations (t ("$tmp/asdf/" :implementation)) :ignore-inherited-configuration))
EOF
cat > "$tmp/verdict.lisp" <<'EOF'
(let ((failed (symbol-value (find-symbol "*TEST-ERRORS*" :util.test)))
      (passed (symbol-value (find-symbol "*TEST-SUCCESSES*" :util.test))))
  (format t "~&~d of ~d assertions failed~%" failed (+ failed passed))
  (exit (if (and (zerop failed) (plusp passed)) 0 1) :quiet t))
EOF

# write_sessions MD SKILL: writes each "```lisp repl" block of MD to its own
# file in $tmp, with /path/to/ pointing at SKILL's examples/.
write_sessions() {
    awk -v out="$tmp/$(printf '%s' "$1" | tr / _)" -v examples="$root/plugins/lisp-skills/skills/$2/examples/" '
        $0 == "```lisp repl" { n++; file = out "-" n ".session"; next }
        file != "" && $0 == "```" { close(file); file = ""; next }
        file != "" { gsub("/path/to/", examples); print > file }
    ' "$1"
}

# A "```lisp repl" block in a skill is a REPL session: make check runs it in a
# fresh Lisp, and it must run tester assertions without a failure.
for md in plugins/lisp-skills/skills/*/SKILL.md plugins/lisp-skills/skills/*/references/*.md; do
    skill=${md#plugins/lisp-skills/skills/}
    write_sessions "$md" "${skill%%/*}"
done
sessions=0
for session in "$tmp"/*.session; do
    [ -f "$session" ] || continue
    sessions=$((sessions + 1))
    if ! output=$("${LISP_BIN:-alisp}" -qq -batch -L "$tmp/prelude.lisp" -L "$session" \
                  -L "$tmp/verdict.lisp" -kill 2>&1 </dev/null); then
        fail "REPL session $(basename "$session" .session) did not pass"
        printf '%s\n' "$output" | indent
    fi
done
[ "$sessions" -gt 0 ] || fail "no \"\`\`\`lisp repl\" blocks found in the skills"

# unverified_snippets MD EXAMPLE: prints the first line of each code fragment
# in MD's "```lisp" blocks that does not appear in EXAMPLE. A fragment is a run
# of lines that are neither blank nor ;; comments. It appears when EXAMPLE has
# the same lines, shifted right by the column where its first line starts,
# after nothing but spaces and an optional ". Only ) and " may follow its last
# line: the ends of enclosing forms or strings. A fragment with unbalanced
# parens must be a whole string in EXAMPLE, so no ) can hide in what follows.
# In EXAMPLE, \" counts as ".
unverified_snippets() {
    awk '
        NR == FNR { gsub(/\\"/, "\""); example[++lines] = $0; next }
        function balance(    j, text) {
            for (j = 1; j <= n; j++) text = text frag[j]
            return gsub(/\(/, "", text) - gsub(/\)/, "", text)
        }
        function found(    i, j, at, pad, prefix, last, rest) {
            for (i = 1; i + n - 1 <= lines; i++) {
                at = index(example[i], frag[1])
                if (at == 0) continue
                prefix = substr(example[i], 1, at - 1)
                if (prefix !~ /^ *"?$/) continue
                pad = sprintf("%" length(prefix) "s", "")
                if (n > 1 && example[i] != prefix frag[1]) continue
                for (j = 2; j < n; j++)
                    if (example[i + j - 1] != pad frag[j]) break
                if (j < n) continue
                last = (n == 1) ? prefix frag[1] : pad frag[n]
                if (index(example[i + n - 1], last) != 1) continue
                rest = substr(example[i + n - 1], length(last) + 1)
                if (rest !~ /^[)"]*$/) continue
                if (balance() != 0 && (prefix !~ /"$/ || rest !~ /^"/)) continue
                return 1
            }
            return 0
        }
        function flush() { if (n > 0 && !found()) print frag[1]; n = 0 }
        $0 == "```lisp" { inblock = 1; n = 0; next }
        inblock && $0 == "```" { flush(); inblock = 0; next }
        inblock && ($0 == "" || $0 ~ /^;;/) { flush(); next }
        inblock { frag[++n] = $0 }
    ' "$2" "$1"
}

# Every snippet in the parens reference comes from its tested example.
parens_md=plugins/lisp-skills/skills/lisp-writing/references/parens.md
parens_example=plugins/lisp-skills/skills/lisp-writing/examples/parens-tests.lisp
missing=$(unverified_snippets "$parens_md" "$parens_example")
[ -z "$missing" ] || fail "$parens_md has snippets not in $parens_example: $missing"

finish "example checks" "$count examples, $sessions REPL sessions"
