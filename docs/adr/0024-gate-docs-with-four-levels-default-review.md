---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma/scripts/validate-config.sh, skills/groma/templates/config.yaml, skills/groma-loop/SKILL.md]
origin: c004-living-docs#D3
---

# Gate docs with four levels and default to review

## Context and Problem Statement

Solo projects want reminders without blocking, and teams want blocking. A first run on a brownfield project with old docs must not stop everything.

## Considered Options

* Four levels that build on each other: `off`, `remind`, `review`, `strict`, default `review`
* A boolean on/off
* Block by default

## Decision Outcome

Chosen option: "Four levels, default `review`", because `review` fits the autonomous loop: the author must answer docs findings like any high finding, and a human is pulled in only on disagreement. `strict` blocks archive for teams that want it. A boolean cannot serve both solo and team use. Blocking by default is too strict for brownfield docs.

### Consequences

* Good, because each project picks its strictness. Missing config keys mean `review`.
* Bad, because four levels are more to document and test than two.

### Confirmation

`tests/scripts/validate-config.bats` rejects unknown values with the closest match; `tests/scripts/status.bats` checks that `off` silences the docs reminders.

## More Information

From design decision D3 of c004-living-docs. Related: ADR 0022.
