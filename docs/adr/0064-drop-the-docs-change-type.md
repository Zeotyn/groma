---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/lib-changes.sh, skills/groma-methodology/scripts/next-change-id.sh, skills/groma-methodology/references/naming-rule.md, tests/scripts/conventions.bats]
origin: c017-change-naming#D3
---

# Drop the docs change type

## Context and Problem Statement

The convention had a type `d` for docs-only changes. None of the 22 changes archived in this repository is a `d` change: docs moved with the change that caused them, which the docs gate (C004) enforces.

## Decision Drivers

* Few types, each with a reason
* Docs stay tied to the change that causes them

## Considered Options

* Remove `d` from the default types
* Keep `d` for docs-only work

## Decision Outcome

Chosen option: "remove `d`", because it was never used, and the docs gate already puts doc updates into the causing change.

Details:
- Default types are `m`, `c`, `f`, `s`, `r`. `next-change-id.sh d` reports an unknown type and says where docs belong.
- Old `d` names stay valid through the conventions baseline; a project whose config still lists `d` keeps it as a custom type.
- README or planning work runs as a `c` change or without a change.

### Consequences

* Good, because there is one type less to explain and to map to a commit type.
* Bad, because a large docs-only effort has no type of its own and is named `c`.

### Confirmation

`tests/scripts/conventions.bats`: `d` is unknown with the default types, a `d` name outside the baseline is a violation, one inside is accepted.

## Pros and Cons of the Options

### Keep `d`

* Good, because docs-only work is visible as such.
* Bad, because zero of 22 changes used it.

## More Information

From design decision D3 of c017-change-naming. Related: ADR 0024 (docs gate).
