---
title: Code style
status: draft
last_reviewed: 2026-11-11
review_after_days: 90
owner: Eugen Waldschmidt
sources: [.editorconfig, scripts/test.sh, skills/, tests/, cli/, install.sh, uninstall.sh]
---

# Code style

How code in this repository is written. Agents read this before writing code and run the check commands after each task. Rules that a tool enforces live in that tool's config; this doc links the config and does not restate its rules.

## Enforced by tools

| Tool | Config | Check | Fix |
|---|---|---|---|
| EditorConfig | [.editorconfig](../.editorconfig) | `sh skills/groma-survey/scripts/style-drift.sh .` | editor plugin, or fix by hand |
| shellcheck | none; flags live in [scripts/test.sh](../scripts/test.sh) (`-x -s sh`) | `scripts/test.sh structure` | by hand |
| pytest (structure checks) | [tests/structure/check.py](../tests/structure/check.py) | `scripts/test.sh structure` | by hand |

No formatter or linter is configured for the CLI's JavaScript (`cli/`, `bin/`) or the test Python (`tests/structure/`). Not yet decided.

## Conventions

One rule per line. `EXTRACTED` comes from configuration or an accepted ADR, `INFERRED` from the code.

- Shell scripts are POSIX `sh`: `#!/bin/sh`, `set -eu`, no bashisms, and every `*.sh` passes `shellcheck -s sh` (EXTRACTED, [ADR 0005](adr/0005-posix-sh-scripts.md), `scripts/test.sh:24`).
- No `A && B || C` as an if-else (shellcheck SC2015): write `if`; a bare `[ cond ] && cmd` is used only as the last statement or when `cmd` cannot fail (INFERRED, `skills/groma-lay-out/scripts/docs-impact.sh:168`, `skills/groma-survey/scripts/style-drift.sh:145`).
- Every script starts with a comment header: purpose, `Usage:` line, inputs, output format, exit codes; usage errors exit 2 (INFERRED, `skills/groma-lay-out/scripts/docs-impact.sh:1-27`, `skills/groma-survey/scripts/freshness.sh:1-12`).
- Script output is tab-separated with a fixed first field (`note`, `impact`, `drift`, ...) and ends with one `summary` line; deterministic text parsing is done in `awk`, never in a language runtime (INFERRED, `skills/groma-lay-out/scripts/docs-impact.sh:21-26`, `skills/groma-survey/scripts/style-drift.sh:18-23`).
- Scripts in `skills/*/scripts/` are read-only toward the target project and never print credentials (EXTRACTED, [ADR 0006](adr/0006-additive-writes-only.md), [ADR 0007](adr/0007-data-model-from-files-no-db.md)).
- Stack knowledge lives in Markdown tables under `references/`, parsed by scripts and read by agents; no per-language branches in scripts (EXTRACTED, [ADR 0004](adr/0004-stack-knowledge-in-reference-tables.md), `skills/groma-detect/references/signals.md`).
- Tests: one bats file per script in `tests/scripts/<script>.bats` using `helpers.bash` (`make_repo`, `commit_at`, `assert_output_contains`); structure checks are Python under `tests/structure/` with their own pytest file (EXTRACTED, `scripts/test.sh:17-45`; INFERRED, `tests/scripts/docs-impact.bats:1-12`).
- Markdown tables: a header row, a `|---|` separator without alignment colons, one row per item, paths and commands in backticks, no trailing spaces (INFERRED, `skills/groma-lay-out/references/doc-slots.md:5-16`).
- Markdown docs carry the frontmatter keys `title`, `status`, `last_reviewed`, `review_after_days`, `owner`, `sources`; lists use `-`; indentation is two spaces (EXTRACTED, `.editorconfig`, `skills/groma-lay-out/templates/docs/`).
- Skills: `SKILL.md` with `name` equal to the folder, a description of at most 1024 characters, numbered steps that each end in a "Done when" sentence, paths relative to the skill folder (EXTRACTED, `tests/structure/check.py` `check_skills`; INFERRED, `skills/groma-survey/SKILL.md`).
- CLI JavaScript: ESM, single quotes, semicolons, two-space indentation, tests with `node:test` next to the code in `cli/test/` (INFERRED, `cli/main.js:1-8`, `cli/test/`).
- Python: four-space indentation, type hints, `from __future__ import annotations`, module constants in upper case (INFERRED, `tests/structure/check.py:7-20`).
- All artifacts, skills, docs and messages are in English (EXTRACTED, `AGENTS.md`).

## Decisions

- [ADR 0004: Keep stack knowledge in reference tables, not code](adr/0004-stack-knowledge-in-reference-tables.md)
- [ADR 0005: Write runtime scripts in POSIX sh](adr/0005-posix-sh-scripts.md)
- [ADR 0031: Link tool configs from the code-style doc instead of restating their rules](adr/0031-link-tool-configs-from-the-code-style-doc.md)
- [ADR 0032: Report style drift statically without running project tools](adr/0032-report-style-drift-statically-without-running-project-tools.md)
