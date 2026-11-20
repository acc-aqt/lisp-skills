<p align="center"><img src="assets/icon.svg" width="120" alt="lisp-skills icon"></p>

# lisp-skills

Agent skills that help LLMs, both Claude and small on-prem models such as qwen3-8b, write **Common Lisp for Allegro CL** that actually reads, compiles and passes its tests.

> [!WARNING]
> **Status: pre-alpha. Nothing is usable yet.**
> This repo currently holds only the plan. Implementation is **blocked** because the Allegro CL 11.0 Express image won't start on macOS 27 / Apple Silicon (the error is `Aclmalloc heap has to be relocated -- this isn't supported yet`). We have reported it to Franz support and are waiting for a fixed build. Details: [#2](https://github.com/acc-aqt/lisp-skills/issues/2).

## What this will be

- A **Claude Code plugin** with three skills:
  - `lisp-writing`: idioms, plus traps from Scheme, Clojure and case mode
  - `lisp-verify`: a loop of write → check → fix the first error → repeat
  - `lisp-project`: packages, ASDF and `tester` tests
- **`lisp-check`**: one command that reads, compiles and optionally tests a Lisp file with Allegro in batch mode, ending in `OK` or `FAIL`.
- **A flat rules file** for open harnesses (OpenCode, Continue, Cline, Aider and others) running small local models.

It will contain generic Common Lisp and Allegro CL knowledge only.

## Plan and progress

- Spec: [#1](https://github.com/acc-aqt/lisp-skills/issues/1)
- Tickets: the [sub-issues of #1](https://github.com/acc-aqt/lisp-skills/issues/1), in dependency order

| Ticket | State |
|---|---|
| [#2](https://github.com/acc-aqt/lisp-skills/issues/2) Install Allegro CL Express | **Blocked**: image fails to start; waiting on Franz |
| [#3](https://github.com/acc-aqt/lisp-skills/issues/3)–[#7](https://github.com/acc-aqt/lisp-skills/issues/7) `lisp-check` and the skills | Waiting on #2 (they need a running Allegro) |
| [#8](https://github.com/acc-aqt/lisp-skills/issues/8) Export, [#9](https://github.com/acc-aqt/lisp-skills/issues/9) README and issue form | Not started; can go ahead without Allegro (#9 after #8) |
| [#10](https://github.com/acc-aqt/lisp-skills/issues/10) Release check | Waiting on all of the above |

## How you can help

- **You have a working Allegro CL** (any platform): please comment on [#2](https://github.com/acc-aqt/lisp-skills/issues/2). Being able to run batch checks on another machine would unblock development.
- **You write Common Lisp:** review the spec in [#1](https://github.com/acc-aqt/lisp-skills/issues/1) and comment on anything that doesn't match how you work.

This README will be expanded with install and usage instructions once v1 exists.
