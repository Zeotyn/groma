---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/status.sh, skills/groma/scripts/validate-config.sh, skills/groma/templates/config.yaml]
origin: f002-status-milestone-gates#D3
---

# Toggle the uncommitted and unpushed reminders separately

## Context and Problem Statement

The new repository reminders need a way to be turned off in `.groma/config.yaml`, like the existing reminders.

## Decision Drivers

* Follow the existing `reminders` pattern (`untested_tasks`)
* Users who never push from a clone still want the uncommitted reminder

## Considered Options

* Two toggles, `reminders.uncommitted` and `reminders.unpushed`, default `true`
* One `reminders.repository` toggle

## Decision Outcome

Chosen option: "Two toggles", because pushing and committing are separate habits. Missing keys mean `true`, and the validator accepts only `true` and `false`. C006 later sets `unpushed: false` when `git.push` is `never`.

### Consequences

* Good, because each reminder can be turned off without losing the other.
* Bad, because the config gains two keys instead of one.

### Confirmation

`tests/scripts/status.bats` checks both toggles off; `tests/scripts/validate-config.bats` rejects other values with the line number.

## Pros and Cons of the Options

### One repository toggle

* Good, because the config stays smaller.
* Bad, because turning off the unpushed reminder also hides uncommitted work.

## More Information

From design decision D3 of f002-status-milestone-gates. Related: ADR 0029.
