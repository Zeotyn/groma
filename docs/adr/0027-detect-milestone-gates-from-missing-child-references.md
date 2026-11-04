---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-methodology/scripts/status.sh, tests/scripts/status.bats]
origin: f002-status-milestone-gates#D1
---

# Detect a milestone gate when no active change references the milestone

## Context and Problem Statement

`status.sh` printed "nothing open" while a milestone had all children archived and its release gate tasks open. The script needs a rule for when a milestone waits at its gate, so it can name the next gate task.

## Decision Drivers

* Works for milestones written by hand, not only from groma's template
* Reads files that are kept up to date anyway, no prose maintained by hand
* Fast enough for a session hook

## Considered Options

* No active change has a `Milestone: mNNN` line for the milestone
* Parse milestone task groups by heading ("Child changes" ticked, "Release gate" open)
* Read the Status column of the milestone's child table

## Decision Outcome

Chosen option: "No active change references the milestone", because child proposals already carry the `Milestone:` line and an archived child no longer counts. The reminder is `gate: <first open task>`, cut to 60 characters, and replaces the stale reminder for that milestone.

### Consequences

* Good, because it needs one `sed` per active proposal and no template headings.
* Bad, because a milestone whose children lack the `Milestone:` line always looks at its gate. The message names the task, so the wrong case is visible.

### Confirmation

`tests/scripts/status.bats` covers a milestone at its gate, one with an active child, the 60-character cut and the gate replacing the stale reminder.

## Pros and Cons of the Options

### Parse task groups by heading

* Good, because it reads the milestone alone.
* Bad, because it depends on headings from groma's template; milestones written by hand differ.

### Read the child table's Status column

* Good, because the table is already in the milestone.
* Bad, because it is prose maintained by hand and lagged behind in C004.

## More Information

From design decision D1 of f002-status-milestone-gates. Related: ADR 0013.
