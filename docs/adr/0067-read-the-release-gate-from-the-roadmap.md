---
status: proposed
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/status.sh, skills/groma-methodology/scripts/next.sh, tests/scripts/status.bats, tests/scripts/next.bats]
origin: c017-change-naming#D6
---

# Read the release gate from the roadmap

## Context and Problem Statement

F002 added a gate reminder because the release gate of a milestone was forgotten once its children were archived (ADR 0027). The gate tasks lived in the umbrella change. Without umbrella changes (ADR 0062) the gate needs a new home, and the test reminder needs a new list of types that ship no code.

## Decision Drivers

* The gate is not forgotten
* No change owns the release

## Considered Options

* A `**Release gate:**` checklist in the milestone section; `status.sh` names its first open item when the milestone has changes and none of them is active
* Drop the gate reminder
* Keep gate tasks in the last change of a milestone

## Decision Outcome

Chosen option: "a checklist in the milestone section", because the gate belongs to the milestone, and the roadmap section is the milestone.

Details:
- `status.sh` prints `M<N>  gate: <first open item>` after the change lines; `next.sh` maps it to rung 5 (`gate M3`).
- No line while a change of milestone N is active: a name `m<N>-…`, an old child with `Milestone: mNNN`, or the old umbrella change itself.
- No line for a planned milestone: the section needs at least one change of milestone N, active or archived. Otherwise a roadmap that plans ahead would put a gate on rung 5 and hide push, proposed ADRs and the change to continue.
- The checklist is the `- [ ]` lines after `**Release gate:**`; nested items count like top-level ones, and the first open one in file order is named.
- Old umbrella milestone changes keep their own gate line from their tasks.
- No test reminder for spikes and refactors (`s`, `r`, `m<N>-spike-`, `m<N>-refactor-`), old umbrella milestones and old `d` changes.

### Consequences

* Good, because the release steps stay visible after the last change of a milestone is archived.
* Bad, because a milestone that is released without a single change (only a gate) never gets the reminder.

### Confirmation

`tests/scripts/status.bats` and `tests/scripts/next.bats`: gate from the checklist, silent for a planned milestone and while a change of the milestone is active, nested items, CRLF files, umbrella gate from the baseline, types without a test reminder.

## Pros and Cons of the Options

### Drop the gate reminder

* Bad, because F002 added it after a gate was forgotten.

### Gate tasks in the last change of a milestone

* Bad, because no change owns the release, and the last change is not known in advance.

## More Information

From design decision D6 of c017-change-naming. Extends ADR 0027 to roadmap sections. Related: ADR 0043 (next-action ladder).
