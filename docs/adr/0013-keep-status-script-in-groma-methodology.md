---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/status.sh, tests/scripts/status.bats]
origin: c002-review-loop#D5
---

# Keep the status script in groma-methodology

## Context and Problem Statement

A status report must be cheap enough to run on every session start. It reads change folders and conventions.

## Considered Options

* `status.sh` in `groma-methodology/scripts/`, read-only and based on git and file reads only

No alternatives were recorded.

## Decision Outcome

Chosen option: "`status.sh` in `groma-methodology/scripts/`", because that skill owns the change folders and conventions the script reads. It is read-only and fast, so it can run on every session start.

### Consequences

* Good, because the script sits next to the knowledge it depends on.
* Bad, because `groma-loop` must reach it through the methodology skill.

### Confirmation

`tests/scripts/status.bats` tests the script.

## More Information

From design decision D5 of c002-review-loop. No alternatives were recorded. Related: ADR 0003.
