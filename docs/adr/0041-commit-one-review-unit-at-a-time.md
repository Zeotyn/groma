---
status: accepted
date: 2026-11-11
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-loop/SKILL.md, skills/groma-loop/references/methodology-adapters.md, tests/evals/assert.sh]
origin: c006-git-workflow#D5
---

# Commit one review unit at a time

## Context and Problem Statement

groma-loop implements a change in review units (task, task group or the whole change), each gated by tests and a review. When does the loop commit, and what goes into a commit?

## Considered Options

* One commit per review unit: after a unit's tests pass and its review stops clean, the loop stages the files `git status --porcelain` lists (all of them belong to the unit, because the tree was clean at start) and commits with the user's git identity; the subject follows `commits` (`feat(c007-cache): add cache layer` in the conventional style, the unit title otherwise); the archive gets its own commit, `docs(<scope>): archive <change-id>`
* One commit per change
* One commit per task

## Decision Outcome

Chosen option: "one commit per review unit", because the review records refer to units, so the history matches what was reviewed and tested; one commit per change loses that, and one commit per task is noisy for tasks that are reviewed together. The archive commit is separate because it moves the change folder and syncs specs and docs, which reads better apart from code.

### Consequences

* Good, because every commit on a change branch was green and reviewed when it was made.
* Good, because the dirty-tree rule (ADR 0039) guarantees that the loop never commits files the user had modified before it started.
* Bad, because with `per: change` the whole change is one commit; projects that want finer history set `per: task-group`.

### Confirmation

`tests/evals/assert.sh` (loop-openspec): a `feat(c001-add-farewell): …` commit and a `docs(openspec): archive c001-add-farewell` commit on main, no merge commit, clean tree at the end.

## More Information

From design decision D5 of c006-git-workflow. Related: ADR 0012 (review the task-group diff), ADR 0039.
