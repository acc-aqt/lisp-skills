<p align="center"><img src="assets/icon.svg" width="120" alt="lisp-skills icon"></p>

# lisp-skills

Agent skills that help LLMs, both Claude and small on-prem models such as qwen3-8b, write **Common Lisp for Allegro CL** that actually reads, compiles and passes its tests.

> [!WARNING]
> **v0.1: written by AI and not reviewed by a Lisp developer.**
> Every Lisp example in the skills is checked by running it through Allegro CL, but no Lisp developer has read the advice yet. Treat it as a draft, review it critically, and please [report anything wrong](#reporting-a-problem).

## What's in it

- A **Claude Code plugin**, `lisp-skills`, with three skills:
  - `lisp-writing`: idioms, plus traps from Scheme, Clojure and case mode
  - `lisp-verify`: a loop of write → check → fix the first error → repeat
  - `lisp-project`: packages, ASDF and `tester` tests
- **`lisp-check`**: one command that reads, compiles and optionally tests a Lisp file with Allegro in batch mode, ending in `OK` or `FAIL`.
- **A flat rules file**, [`dist/lisp-rules.md`](dist/lisp-rules.md), with the same content for open harnesses running small local models.

It contains generic Common Lisp and Allegro CL knowledge only.

## Install

### Claude Code

```
/plugin marketplace add acc-aqt/lisp-skills
/plugin install lisp-skills@lisp-skills
```

### Open harnesses (OpenCode, Continue, Cline, Aider and others)

Point the harness's rules or system-prompt file setting at [`dist/lisp-rules.md`](dist/lisp-rules.md), or copy the file into your project. It is generated from the skills; after changing a skill, rebuild it with:

```sh
make export    # or: scripts/export-rules
```

`make check` fails while the committed file is out of date with the skills.

## Running `lisp-check`

`lisp-check` needs an Allegro CL binary. It uses `$LISP_BIN`, which defaults to `alisp`. With the plugin installed, Claude Code has `lisp-check` on its `PATH`; in a clone of this repo it is `plugins/lisp-skills/bin/lisp-check`.

```sh
plugins/lisp-skills/bin/lisp-check file.lisp           # read and compile
plugins/lisp-skills/bin/lisp-check --test file.lisp    # also run the file's tester tests
LISP_BIN=/path/to/alisp plugins/lisp-skills/bin/lisp-check file.lisp
```

If the file belongs to an ASDF project, that is, its directory or a parent (up to the one holding `.git`) contains `*.asd` files, `lisp-check` loads the system named like each `.asd` before compiling the file (`foo.asd` → system `"foo"`), so a file such as `foo-tests.lisp` can use the project's packages. A system that fails to load is reported as `FILE:?: system: MESSAGE`. ASDF's compiled files go to `/tmp/lisp-check-asdf/`, never into the project. A file that reads cleanly is compiled with `compile-file` into a temporary fasl that is deleted afterwards. Any compiler warning, style warnings included, fails the check. With `--test`, the compiled file is then loaded, which runs its top-level `tester` (`util.test`) assertions; a failed assertion, an error while loading, or a file with no assertions fails the check. Each problem is printed as `FILE:LINE: STAGE: MESSAGE`, where `STAGE` is `read`, `structure`, `system`, `compile` or `test`, the order the stages run in. The last line of the output is `OK` or `FAIL`; the exit code is 0 for `OK`, 1 when the file has problems and 2 when `lisp-check` could not run.

`make check` runs `lisp-check` over its test files in `tests/lisp-check/` and over every `.lisp` file under a skill's `examples/` (each must print `OK`; files named `*-tests.lisp` are checked with `--test`), runs each code block marked `lisp repl` in the skills in a fresh Lisp (its tester assertions must pass), runs the mutant test, and runs the repo's script tests. The mutant test runs `lisp-check --test` on each file in `tests/mutants/`, a skill example with one `)` moved so it compiles but fails its tests; each file's header says whether the `structure` stage should catch it, and the test prints the catch rate per kind of mutant. The mutants were made with `scripts/generate-mutants`, a one-off maintainer tool that `make check` does not run. `make docker-check` runs `make check` inside the Docker image described below.

Only `alisp` has been verified. Allegro CL Express ships only `alisp`, so behaviour with `mlisp` (modern, case-sensitive mode) is **unverified**.

### The `structure` stage

A misplaced `)` often still reads and compiles: a form ends up inside a `let`, `when` or `if` branch it should have followed, or escapes one too early, and only the tests notice. After the file reads, the `structure` stage compares each line's indentation with the paren nesting at its start. It reports a line indented as if it came after a form that the parens keep open, and a line indented as if it were inside a form that already closed. A `structure` problem fails the check, but the `system`, `compile` and `test` stages still run, so their problems are reported too. Lines starting with `)`, comment lines and lines inside strings or block comments are not checked. Indentation must be spaces: the first tab in a line's indentation is reported and the rest of the file is not checked for structure.

The stage only sees a misplaced `)` that leaves some line indented for the other nesting. It cannot see:

- code re-indented to match the wrong nesting, for example by an editor or a model after the `)` moved;
- a `)` moved within one line, since no line starts between its old and new place;
- some `)` moved across lines, when the next line still sits to the right of an open paren and the closed form is at the same depth;
- two `cond` clauses merged with the swallowed test indented inside the first clause, as in the example in `lisp-writing`'s `references/parens.md`; a swallowed clause still indented as a sibling clause is caught.

The mutant test that `make check` runs measures this on skill examples with one `)` moved: the stage currently catches 8 of 12 mutants that keep their original indentation and 0 of 6 re-indented ones. Three of the four original-indentation misses move a `)` within one line, which no indentation check can see; the fourth moves one across lines into a form at the same depth.

### Where Allegro runs

Linux is the reference platform. Verification runs in a Docker image built from the [`Dockerfile`](Dockerfile) at the repo root, which installs Allegro CL 11.0 Express (download the tarball from Franz yourself; the Dockerfile header has the build command). Native Allegro CL Express currently fails to start on macOS on Apple Silicon ([#2](https://github.com/acc-aqt/lisp-skills/issues/2)), so on a Mac use the image:

```sh
docker run --rm --platform linux/amd64 -v "$PWD":/work lisp-skills-allegro make check
```

## Review checklist for Lisp developers

If you write Common Lisp, a short review helps a lot. Pick any of these:

1. **Read the skills.** Skim `plugins/lisp-skills/skills/*/SKILL.md` and their `references/`. Flag advice that is wrong, outdated or not how you would write it.
2. **Check the examples.** Look at the `.lisp` files under each skill's `examples/`. They compile, but are they idiomatic?
3. **Check the Allegro specifics.** Batch flags, `compile-file` warnings, `tester` (`util.test`), packages and ASDF: do they match your experience?
4. **Check the traps.** `lisp-writing` lists mistakes models carry over from Scheme, Clojure and case mode. Are any missing or wrong?
5. **Try it on a real task.** Ask a model with the skills (or the rules file) to write something small you know well, and run `lisp-check` on the result.
6. **Look for false `structure` problems.** Run `lisp-check` on real code you trust. If it reports a `structure` problem where the parens are right, that is an indentation style the check wrongly flags; please report it with the lines involved.
7. **Try `mlisp`** if you have it: `LISP_BIN=mlisp make check`. Nobody has tested that yet.

Report what you find with the form below, or comment on the spec, [#1](https://github.com/acc-aqt/lisp-skills/issues/1).

## Reporting a problem

When a skill or the rules file leads a model to wrong Lisp, [open a skill failure report](https://github.com/acc-aqt/lisp-skills/issues/new?template=skill-failure.yml). The form asks for the harness, model, skill, prompt, model output, `lisp-check` output and the result you expected, so the failure can be reproduced. New reports are labelled `needs-triage` automatically.

Please paste only generic code; this repository is public.

## Plan

The spec is [#1](https://github.com/acc-aqt/lisp-skills/issues/1); its sub-issues are the tickets.

## License

MIT, see [LICENSE](LICENSE).
