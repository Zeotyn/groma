---
status: accepted
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/references/code-style-tools.md, skills/groma-survey/scripts/style-drift.sh, tests/structure/check.py]
origin: c005-code-style#D2
---

# Drive style detection and setup from one reference table

## Context and Problem Statement

Style tools differ per stack: config files, check and fix commands, install commands, base configs. groma-survey needs them to detect tools, groma-lay-out needs them to set tools up and to fill the tools table of `docs/code-style.md`. Where does this knowledge live, so that adding a tool needs no change to skill or script logic (ADR 0004)?

## Considered Options

* One table `skills/groma-lay-out/references/code-style-tools.md` with the columns stack, tool, role, config patterns, check, fix, install, template and default, plus tables for the places where checks run and the runner prefixes; groma-survey reads it through `../groma-lay-out/references/`, templates live in `skills/groma-lay-out/templates/code-style/<tool>/`
* One table per skill
* Detect style tools in `groma-detect`'s `detect.sh`

## Decision Outcome

Chosen option: "one table in groma-lay-out", because two tables would be two sources of truth for the same patterns, and detection only decides greenfield or brownfield while style detection belongs to the survey. When groma-survey is installed without groma-lay-out, `style-drift.sh` prints "style tools not detected (groma-lay-out missing)" and does not guess. A tool without a template has an empty template column; its setup is the install command or, when it lives inside an existing build file, a snippet in the findings report. The structure check enforces the columns, the roles, exactly one default per stack and role, and that every named template exists.

### Consequences

* Good, because a new tool, CI system or runner is one table row.
* Good, because the structure check catches an inconsistent table before release.
* Bad, because groma-survey depends on a sibling skill's file for tool detection; the degradation message makes that visible.

### Confirmation

`tests/structure/check.py` (`check_code_style_table`) and `tests/scripts/style-drift.bats` ("missing reference table", "configured tools are listed").

## More Information

From design decision D2 of c005-code-style. Related: ADR 0004, ADR 0032.
