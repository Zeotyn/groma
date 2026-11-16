---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/lib-changes.sh, skills/groma-agents/references/git-strategies.md, tests/scripts/git-integrate.bats, tests/scripts/status.bats]
origin: c017-change-naming#D2
---

# Carry the type inside a milestone as a type word

## Context and Problem Statement

With `m<N>-<slug>` the type letter is gone from the name of a change in a milestone. The commit type (C006) and the rule that spikes and refactors get no test reminder and no spec deltas need the type.

## Decision Drivers

* The name alone carries milestone and type
* No text parsing of proposals

## Considered Options

* A type word right after the prefix: `m<N>-spike-`, `m<N>-fix-`, `m<N>-refactor-`; none means a change
* Only `-spike-`
* Let `f` and `r` changes join a milestone through a proposal line

## Decision Outcome

Chosen option: "a type word for spike, fix and refactor", because a fix or refactor in a milestone keeps its type for commits and reminders without any second source.

Details:
- `lib-changes.sh` gives the type letter of a name: `m3-fix-x` is `f`, `m3-x` is `c`. The word counts only directly after `m<N>-` and only when a slug follows (`m3-spikes` is a change).
- Commit types come from the "Commit type" table in `git-strategies.md`: `m<N>-` and `c` feat, `-fix-` and `f` fix, `-refactor-` and `r` refactor, `-spike-` and `s` chore; an old padded umbrella milestone change (`m003-v0-3`) is chore by the first row of the table.
- Spikes and refactors, inside or outside a milestone, get no test reminder and no spec deltas.

### Consequences

* Good, because commit type, reminders and spec-delta rule work the same inside and outside a milestone.
* Bad, because a slug cannot start with `spike-`, `fix-` or `refactor-` inside a milestone without being read as that type.

### Confirmation

`tests/scripts/git-integrate.bats` derives the commit type of names from the table; `tests/scripts/status.bats` checks the test reminder for each type word.

## Pros and Cons of the Options

### Only `-spike-`

* Bad, because a fix or refactor in a milestone would lose its type.

### A proposal line for `f` and `r` changes

* Bad, because it brings back the text parsing that ADR 0062 removes.

## More Information

From design decision D2 of c017-change-naming. Related: ADR 0062, ADR 0041 (commit per review unit).
