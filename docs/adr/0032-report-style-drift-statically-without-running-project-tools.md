---
status: accepted
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-survey/scripts/style-drift.sh, tests/scripts/style-drift.bats, skills/groma-lay-out/references/code-style-tools.md]
origin: c005-code-style#D3
---

# Report style drift statically without running project tools

## Context and Problem Statement

A documented style that the code ignores misleads agents. The survey should say where code and `.editorconfig` disagree and which configured tools nobody runs. The survey is read-only and must not execute project code.

## Considered Options

* `style-drift.sh <dir>`: parse `.editorconfig` sections and check tracked text files with `awk` for `indent_style`, `end_of_line`, `insert_final_newline` and `trim_trailing_whitespace`; report a configured tool as `unchecked` when its check command appears in no CI workflow, `package.json` script, `Makefile` or `justfile`
* Run `prettier --check` and the other tools' check commands during the survey
* Skip drift entirely

## Decision Outcome

Chosen option: "static drift via `style-drift.sh`", because running a project's formatter or linter executes project code (JS configs, plugins) and needs installed dependencies, which a read-only survey must not require. The `unchecked` lookup reads the table's check column and the list of places where checks run, so a new CI system is a table row. Skipping drift was rejected because the doc would then describe a style the code does not have.

### Consequences

* Good, because the report is deterministic, needs no dependencies and runs in every survey.
* Bad, because only the four editorconfig properties are checked; tool-specific rules are not verified until groma-loop runs the check commands.

### Confirmation

`tests/scripts/style-drift.bats` covers every property, section globs, untracked and binary files, the `unchecked` sources and the fixtures `python-django-stale-docs` (tabs against spaces, Ruff unchecked) and `node-prisma` (Prettier unchecked, ESLint via `npm run lint`).

## More Information

From design decision D3 of c005-code-style. Related: ADR 0006 (additive writes), ADR 0031.
