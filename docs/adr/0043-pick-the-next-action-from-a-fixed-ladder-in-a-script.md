---
status: proposed
date: 2026-11-12
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next.sh, skills/groma-methodology/scripts/status.sh, tests/scripts/next.bats]
origin: c007-next-action#D2
---

# Pick the next action from a fixed ladder in a script, built on status.sh

## Context and Problem Statement

`status.sh` lists every open reminder. Users need the single one to act on, picked the same way every time and fast enough for a status line.

## Decision Drivers

* Deterministic and free of tokens
* One source of truth for the reminder checks

## Considered Options

* A fixed ladder in `next.sh` that maps `status.sh` lines to rungs
* A second, independent implementation of the checks
* Let the agent pick the next step

## Decision Outcome

Chosen option: "A fixed ladder in `next.sh`", because it reuses `status.sh` and its order is visible and tested. The rungs: rebase or merge in progress, docs open, verify, uncommitted work, milestone gate, unpushed commits (unless `git.push: never`), proposed ADR of an archived change, active change with the newest commit. `next.sh` checks only what `status.sh` does not report: the rebase or merge state and the last rung. A cache keyed on `HEAD`, the working tree and the refs keeps repeated runs cheap.

### Consequences

* Good, because the order is one table, tested rung by rung.
* Bad, because a wrong order annoys until the table is changed.

### Confirmation

`tests/scripts/next.bats` tests every rung and its precedence over the next one.

## Pros and Cons of the Options

### Independent implementation

* Bad, because two sources of truth for reminders drift apart.

### Let the agent pick

* Bad, because it is not deterministic and costs tokens.

## More Information

From design decision D2 of c007-next-action. Related: ADR 0029.
