---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/SKILL.md, skills/groma-loop/references/methodology-adapters.md]
origin: c002-review-loop#D1
---

# Run change orchestration in a separate skill, groma-loop

## Context and Problem Statement

Something must drive each change through propose, review, apply and archive. `groma` runs once per project, while this orchestration runs repeatedly for every change.

## Considered Options

* A separate skill `groma-loop` that reads `review` from the config and calls the methodology's workflows
* Put the orchestration into the `groma` skill

## Decision Outcome

Chosen option: "A separate skill `groma-loop`", because it runs for every change while `groma` runs once per project. Methodology adapters live in `references/methodology-adapters.md`: OpenSpec full, Spec Kit specify/plan/tasks/implement, others by convention (propose writes a proposal, apply works through tasks).

### Consequences

* Good, because the loop can be installed and invoked on its own.
* Good, because new methodologies need only an adapter row, not new skill logic.
* Bad, because the suite gains one more skill folder to keep in sync.

### Confirmation

`tests/structure/check.py` checks the skill folder name and SKILL.md `name`. Review checks that the loop calls methodology workflows through the adapters file.

## More Information

From design decision D1 of c002-review-loop. Related: ADR 0003, ADR 0004.
