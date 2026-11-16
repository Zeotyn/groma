---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/next-change-id.sh, skills/groma-methodology/scripts/check-conventions.sh, skills/groma/scripts/validate-config.sh, tests/scripts/conventions.bats, tests/scripts/validate-config.bats]
origin: c017-change-naming#D4
---

# Number changes without zero padding

## Context and Problem Statement

Ids had three digits (`c004`), configurable through `conventions.changes.digits`. The padding gives nothing: tools compare numbers, natural sort orders `c2` before `c10`, and the padded form produces badges like `M001` and stops at 999.

## Decision Drivers

* Short ids
* One format for every tool

## Considered Options

* No leading zeros; `digits` ignored with a validator warning
* Keep padding configurable

## Decision Outcome

Chosen option: "no leading zeros", because two formats would have to be accepted by every tool for no ordering benefit.

Details:
- `next-change-id.sh` keeps its flags and prints `c17`. It reads old padded names as numbers, so `c016-x` in the archive makes the next change `c17`.
- The check compares ids as numbers: `c005-a` from the baseline and a new `c5-b` are duplicates.
- `conventions.changes.digits` is ignored; `validate-config.sh` warns and the config template no longer has the key.

### Consequences

* Good, because ids read the way people say them (`C17`, `M4`).
* Bad, because a plain `ls` sorts `c10` before `c2`.
* Bad, because old and new names look different in one project until the old ones are archived.

### Confirmation

`tests/scripts/conventions.bats` (next id without padding, old padded archive counted, numeric duplicates) and `tests/scripts/validate-config.bats` (warning for `digits`).

## Pros and Cons of the Options

### Keep padding configurable

* Good, because existing projects keep one look.
* Bad, because every script and every rule text would carry two formats.

## More Information

From design decision D4 of c017-change-naming. Breaking for tools outside groma that parse `c001-*`; none is known.
