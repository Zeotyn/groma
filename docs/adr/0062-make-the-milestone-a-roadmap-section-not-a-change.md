---
status: accepted
date: 2026-11-16
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/references/conventions.md, skills/groma-methodology/templates/roadmap-section.md, skills/groma-methodology/scripts/lib-changes.sh, tests/scripts/conventions.bats]
origin: c017-change-naming#D1
---

# Make the milestone a roadmap section, not a change

## Context and Problem Statement

A milestone was its own change (`m003-v0-3`) with no specs and no real tasks, only ticks for its children and a release gate. On a board and in `openspec list` it looked like work that never moves. Children were found by a `Milestone: mNNN` line that three scripts grepped out of every `proposal.md`.

## Decision Drivers

* Every change on a board is real work
* Tools group changes without parsing proposals
* Goal and release gate stay where people read milestones

## Considered Options

* A section `## M<N>: <title>` in `docs/roadmap.md` with goal and release gate; changes belong by the prefix `m<N>-`
* Keep umbrella changes with `skip_specs`
* A separate `milestones.yaml`

## Decision Outcome

Chosen option: "a section in `docs/roadmap.md`", because the roadmap is already the place where milestones are read, and a name prefix needs no parsing.

Details:
- The section is hand-written: `## M<N>: <title>`, a `**Goal:**` line, a `**Release gate:**` checklist and a marker block for the change list (ADR 0066).
- A change belongs to milestone N exactly when its name starts with `m<N>-`. Several changes share N.
- `next-change-id.sh m` prints the next free milestone number from the headings and the `m<N>-` names.
- Old umbrella changes stay valid through the conventions baseline (ADR 0068).

### Consequences

* Good, because a milestone can no longer sit on a board as a change that cannot be started or verified.
* Good, because status, next action and roadmap find the changes of a milestone by name alone.
* Bad, because a change that moves to another milestone must be renamed.
* Bad, because the roadmap is one more hand-written file that can drift from the plan.

### Confirmation

`tests/scripts/conventions.bats` checks the milestone number from headings and names; `tests/scripts/roadmap.bats` and `tests/scripts/status.bats` check grouping by prefix without any proposal line.

## Pros and Cons of the Options

### Keep umbrella changes with `skip_specs`

* Good, because nothing changes for existing projects.
* Bad, because they never move on a board and grouping needs text parsing.

### A separate `milestones.yaml`

* Good, because it is easy to parse.
* Bad, because it is one more file format, and people read milestones in the roadmap.

## More Information

From design decision D1 of c017-change-naming. Replaces the milestone part of the convention from c001-groma-suite. Related: ADR 0027 (gate of umbrella milestones), ADR 0063, ADR 0066, ADR 0067.
