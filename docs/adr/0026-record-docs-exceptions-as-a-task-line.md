---
status: accepted
date: 2026-11-04
decision-makers: Eugen Waldschmidt
evidence: [skills/groma-lay-out/scripts/docs-impact.sh, tests/scripts/docs-impact.bats]
origin: c004-living-docs#D5
---

# Record docs exceptions as a task line with a reason

## Context and Problem Statement

Some changes touch code listed in a doc's `sources` without making the doc wrong. The check needs an escape that does not force empty edits.

## Considered Options

* A line `Docs: <path> unchanged, because <reason>` in the tasks file, matching `because .+`
* A frontmatter flag on the doc
* A separate ignore file

## Decision Outcome

Chosen option: "A task line", because it is reviewed with the change and archived with it. A reason is required. A frontmatter flag changes the doc only to silence the check. An ignore file outlives the change and hides future impact.

### Consequences

* Good, because every exception has a stated reason in the change history.
* Bad, because a reason is only checked for presence, not for quality.

### Confirmation

`tests/scripts/docs-impact.bats` checks that a line with a reason clears the doc and one without does not. The reviewer reads the reasons.

## More Information

From design decision D5 of c004-living-docs. Related: ADR 0022, ADR 0024.
