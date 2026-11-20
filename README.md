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
scripts/export-rules
```

## Running `lisp-check`

`lisp-check` needs an Allegro CL binary. It uses `$LISP_BIN`, which defaults to `alisp`. With the plugin installed, Claude Code has `lisp-check` on its `PATH`; in a clone of this repo it is `plugins/lisp-skills/bin/lisp-check`.

```sh
plugins/lisp-skills/bin/lisp-check file.lisp           # read and compile
plugins/lisp-skills/bin/lisp-check --test file.lisp    # also run the file's tester tests
LISP_BIN=/path/to/alisp plugins/lisp-skills/bin/lisp-check file.lisp
```

Status: only the read stage exists so far. The compile stage ([#4](https://github.com/acc-aqt/lisp-skills/issues/4)) and `--test` ([#5](https://github.com/acc-aqt/lisp-skills/issues/5)) are in progress; until then `--test` stops with `FAIL`.

Each problem is printed as `FILE:LINE: STAGE: MESSAGE`. The last line of the output is `OK` or `FAIL`; the exit code is 0 for `OK`, 1 when the file has problems and 2 when `lisp-check` could not run.

`make check` runs `lisp-check` over its test files in `tests/lisp-check/` and over every `.lisp` file under a skill's `examples/` (each must print `OK`; files named `*-tests.lisp` are checked with `--test`), and runs the repo's script tests. `make docker-check` runs `make check` inside the Docker image described below.

Only `alisp` has been verified. Allegro CL Express ships only `alisp`, so behaviour with `mlisp` (modern, case-sensitive mode) is **unverified**.

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
6. **Try `mlisp`** if you have it: `LISP_BIN=mlisp make check`. Nobody has tested that yet.

Report what you find with the form below, or comment on the spec, [#1](https://github.com/acc-aqt/lisp-skills/issues/1).

## Reporting a problem

When a skill or the rules file leads a model to wrong Lisp, [open a skill failure report](https://github.com/acc-aqt/lisp-skills/issues/new?template=skill-failure.yml). The form asks for the harness, model, skill, prompt, model output, `lisp-check` output and the result you expected, so the failure can be reproduced. New reports are labelled `needs-triage` automatically.

Please paste only generic code; this repository is public.

## Plan

The spec is [#1](https://github.com/acc-aqt/lisp-skills/issues/1); its sub-issues are the tickets.
